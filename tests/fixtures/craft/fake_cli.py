import json
import re
import socket
import sys

args = sys.argv[1:]
connected = "--connect" in args or "--bridge" in args
port = int(re.findall(r"\d+", args[-1])[-1]) if connected else None


def reachable():
    try:
        socket.create_connection(("127.0.0.1", port), 0.5).close()
        return True
    except OSError:
        return False


def reply(msg_id, result):
    sys.stdout.write(json.dumps({"jsonrpc": "2.0", "id": msg_id, "result": result}) + "\n")
    sys.stdout.flush()


tools = [{"name": "a", "inputSchema": {"type": "object"}}]
if connected:
    tools.append({"name": "ui_x", "inputSchema": {"type": "object"}})

for line in sys.stdin:
    msg = json.loads(line)
    method, msg_id = msg.get("method"), msg.get("id")
    if msg_id is None:
        continue
    if method == "initialize":
        reply(msg_id, {"protocolVersion": "2025-06-18", "capabilities": {"tools": {}}, "serverInfo": {"name": "fake", "version": "0"}})
    elif method == "tools/list":
        reply(msg_id, {"tools": tools})
    elif method == "tools/call":
        if connected and not reachable():
            reply(msg_id, {"content": [{"type": "text", "text": "cannot connect"}], "isError": True})
        else:
            mode = "connected" if connected else "windowless"
            reply(msg_id, {"content": [{"type": "text", "text": f"{mode}:{msg['params']['name']}"}]})
    else:
        reply(msg_id, {})
