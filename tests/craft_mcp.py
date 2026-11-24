import json
import os
import queue
import signal
import socket
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from pathlib import Path

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROXY = os.path.join(REPO, "design", "bin", "craft-mcp")
FIXTURES = os.path.join(REPO, "tests", "fixtures", "craft")


def free_port():
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


class Proxy:
    def __init__(self, app, env):
        self.proc = subprocess.Popen([sys.executable, PROXY, app], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, env=env)
        self.messages = queue.Queue()
        self.notifications = []
        threading.Thread(target=self._read, daemon=True).start()
        self.next_id = 1

    def _read(self):
        for line in self.proc.stdout:
            self.messages.put(json.loads(line))

    def request(self, method, params=None):
        msg_id = self.next_id
        self.next_id += 1
        msg = {"jsonrpc": "2.0", "id": msg_id, "method": method}
        if params is not None:
            msg["params"] = params
        self.proc.stdin.write(json.dumps(msg) + "\n")
        self.proc.stdin.flush()
        deadline = time.time() + 10
        while True:
            m = self.messages.get(timeout=max(0.1, deadline - time.time()))
            if m.get("id") == msg_id and "method" not in m:
                return m
            self.notifications.append(m)

    def handshake(self):
        r = self.request("initialize", {"protocolVersion": "2025-06-18", "capabilities": {}, "clientInfo": {"name": "t", "version": "0"}})
        self.proc.stdin.write(json.dumps({"jsonrpc": "2.0", "method": "notifications/initialized"}) + "\n")
        self.proc.stdin.flush()
        return r

    def tool_names(self):
        return [t["name"] for t in self.request("tools/list")["result"]["tools"]]

    def call(self, name, arguments=None):
        return self.request("tools/call", {"name": name, "arguments": arguments or {}})["result"]

    def close(self):
        self.proc.stdin.close()
        self.proc.terminate()
        self.proc.wait(5)
        self.proc.stdout.close()
        self.proc.stderr.close()


def text(result):
    return result["content"][0]["text"]


class CraftMcpTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = self.tmp.name
        self.port = free_port()
        table = os.path.join(self.dir, "apps")
        with open(table, "w") as f:
            f.write("# name | port | token | windowless | connected\n")
            f.write(f"vectorcraft | {self.port} | - | mcp --headless | mcp --connect 127.0.0.1:{{port}}\n")
            f.write("pdfcraft | - | - | mcp --compact | -\n")
        self.env = dict(
            os.environ,
            PATH=FIXTURES + os.pathsep + os.environ["PATH"],
            FAKE_DIR=self.dir,
            FAKE_PORT=str(self.port),
            FAKE_INSTALLED="vectorcraft pdfcraft",
            CRAFT_MCP_APPS=table,
            CRAFT_MCP_LOG_DIR=os.path.join(self.dir, "logs"),
            CRAFT_MCP_WAIT="5",
            CRAFT_MCP_GRACE="1",
        )
        self.proxies = []
        self.apps = []

    def tearDown(self):
        for p in self.proxies:
            p.close()
        pid_file = os.path.join(self.dir, "app.pid")
        if os.path.exists(pid_file):
            try:
                os.kill(int(Path(pid_file).read_text()), signal.SIGTERM)
            except ProcessLookupError:
                pass
        for a in self.apps:
            a.terminate()
            a.wait(5)
        self.tmp.cleanup()

    def proxy(self, app="vectorcraft"):
        p = Proxy(app, self.env)
        self.proxies.append(p)
        return p

    def log(self):
        path = os.path.join(self.dir, "log")
        return Path(path).read_text().splitlines() if os.path.exists(path) else []

    def start_app(self):
        a = subprocess.Popen([sys.executable, os.path.join(FIXTURES, "fake_app.py"), str(self.port), "listen"])
        self.apps.append(a)
        for _ in range(50):
            try:
                socket.create_connection(("127.0.0.1", self.port), 0.2).close()
                return a
            except OSError:
                time.sleep(0.1)
        self.fail("fake app did not listen")

    def kill_launched_app(self):
        os.kill(int(Path(self.dir, "app.pid").read_text()), signal.SIGTERM)
        for _ in range(50):
            try:
                socket.create_connection(("127.0.0.1", self.port), 0.2).close()
                time.sleep(0.1)
            except OSError:
                return

    def test_lists_windowless_tools_plus_open_window(self):
        p = self.proxy()
        init = p.handshake()
        self.assertTrue(init["result"]["capabilities"]["tools"]["listChanged"])
        self.assertEqual(p.tool_names(), ["a", "open_window"])
        self.assertFalse([l for l in self.log() if l.startswith("app")])
        self.assertIn("unset=VECTORCRAFT_CONTROL_PORT", self.log()[0])
        self.assertIn("cli mcp --headless", self.log()[0])

    def test_call_runs_windowless(self):
        p = self.proxy()
        p.handshake()
        self.assertEqual(text(p.call("a")), "windowless:a")

    def test_open_window_launches_app_on_path_and_switches(self):
        p = self.proxy()
        p.handshake()
        p.tool_names()
        r = p.call("open_window", {"path": "/x/y.svg"})
        self.assertFalse(r.get("isError"), r)
        self.assertIn("app /x/y.svg", self.log())
        connected = [l for l in self.log() if "--connect" in l]
        self.assertEqual(len(connected), 1)
        self.assertIn(f"127.0.0.1:{self.port}", connected[0])
        self.assertIn("VECTORCRAFT_AUTOMATION_READ_ROOT", connected[0])
        self.assertIn("ui_x", p.tool_names())
        self.assertIn("notifications/tools/list_changed", [n.get("method") for n in p.notifications])
        self.assertEqual(text(p.call("a")), "connected:a")

    def test_open_window_joins_running_app(self):
        self.start_app()
        p = self.proxy()
        p.handshake()
        r = p.call("open_window", {"path": "/x/y.svg"})
        self.assertFalse(r.get("isError"), r)
        self.assertIn("already open", text(r))
        self.assertFalse([l for l in self.log() if l.startswith("app")])
        self.assertEqual(text(p.call("a")), "connected:a")

    def test_running_without_port_says_reopen(self):
        open(os.path.join(self.dir, "running"), "w").close()
        p = self.proxy()
        p.handshake()
        r = p.call("open_window", {"path": "/x/y.svg"})
        self.assertTrue(r.get("isError"))
        self.assertIn("close and reopen VectorCraft", text(r))
        self.assertFalse([l for l in self.log() if l.startswith("app")])

    def test_failed_open_keeps_windowless(self):
        open(os.path.join(self.dir, "silent"), "w").close()
        self.env["CRAFT_MCP_WAIT"] = "1"
        p = self.proxy()
        p.handshake()
        r = p.call("open_window", {"path": "/x/y.svg"})
        self.assertTrue(r.get("isError"))
        self.assertEqual(text(p.call("a")), "windowless:a")

    def test_window_closed_falls_back_once(self):
        p = self.proxy()
        p.handshake()
        p.call("open_window", {"path": "/x/y.svg"})
        self.kill_launched_app()
        r = p.call("a")
        self.assertTrue(r.get("isError"))
        self.assertIn("window was closed", text(r))
        self.assertIn("/x/y.svg", text(r))
        self.assertEqual(text(p.call("a")), "windowless:a")
        self.assertNotIn("ui_x", p.tool_names())

    def test_window_closed_notice_survives_tools_list(self):
        p = self.proxy()
        p.handshake()
        p.call("open_window", {"path": "/x/y.svg"})
        self.kill_launched_app()
        self.assertNotIn("ui_x", p.tool_names())
        r = p.call("a")
        self.assertTrue(r.get("isError"))
        self.assertIn("/x/y.svg", text(r))

    def test_uninstalled_app_exits_naming_launcher(self):
        self.env["FAKE_INSTALLED"] = "pdfcraft"
        p = Proxy("vectorcraft", self.env)
        _, err = p.proc.communicate(timeout=10)
        self.assertNotEqual(p.proc.returncode, 0)
        self.assertIn("ArtCraft Launcher", err)

    def test_pdfcraft_has_no_open_window(self):
        p = self.proxy("pdfcraft")
        p.handshake()
        self.assertEqual(p.tool_names(), ["a"])
        self.assertIn("cli mcp --compact", self.log()[0])


if __name__ == "__main__":
    unittest.main()
