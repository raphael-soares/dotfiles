import signal
import socket
import sys
import time

port, mode = int(sys.argv[1]), sys.argv[2]
signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
if mode == "silent":
    while True:
        time.sleep(1)
srv = socket.socket()
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("127.0.0.1", port))
srv.listen()
held = []
while True:
    conn, _ = srv.accept()
    held.append(conn)
