#!/usr/bin/env python3
"""Serves the whisper-asr-webservice API that Bazarr speaks on top of whisper.cpp's server."""
import io
import json
import os
import urllib.request
import uuid
import wave
from email.parser import BytesParser
from email.policy import HTTP
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

BACKEND = os.environ.get("WHISPER_BACKEND", "http://whisper-cpp:8080")
DETECT_SECONDS = 30
SAMPLE_RATE = 16000


def audio_from(handler):
    length = int(handler.headers["Content-Length"])
    head = f"Content-Type: {handler.headers['Content-Type']}\r\n\r\n".encode()
    message = BytesParser(policy=HTTP).parsebytes(head + handler.rfile.read(length))
    for part in message.iter_parts():
        if part.get_param("name", header="content-disposition") == "audio_file":
            return part.get_payload(decode=True)
    raise ValueError("audio_file missing")


def wav(pcm):
    buf = io.BytesIO()
    with wave.open(buf, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(pcm)
    return buf.getvalue()


def infer(pcm, **fields):
    boundary = uuid.uuid4().hex
    body = io.BytesIO()
    for key, value in fields.items():
        body.write(f'--{boundary}\r\nContent-Disposition: form-data; name="{key}"\r\n\r\n{value}\r\n'.encode())
    body.write(f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="a.wav"\r\n'
               "Content-Type: audio/wav\r\n\r\n".encode())
    body.write(wav(pcm))
    body.write(f"\r\n--{boundary}--\r\n".encode())
    req = urllib.request.Request(f"{BACKEND}/inference", data=body.getvalue(),
                                 headers={"Content-Type": f"multipart/form-data; boundary={boundary}"})
    with urllib.request.urlopen(req) as r:
        return r.read()


class Handler(BaseHTTPRequestHandler):
    def reply(self, code, body, kind):
        self.send_response(code)
        self.send_header("Content-Type", kind)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if urlparse(self.path).path == "/docs":
            self.reply(200, b"ok", "text/plain")
        else:
            self.reply(404, b"", "text/plain")

    def do_POST(self):
        url = urlparse(self.path)
        query = {k: v[0] for k, v in parse_qs(url.query).items()}
        try:
            pcm = audio_from(self)
            if url.path == "/asr":
                out = infer(pcm, response_format="srt", language=query.get("language") or "auto",
                            translate="true" if query.get("task") == "translate" else "false")
                self.reply(200, out, "text/plain; charset=utf-8")
            elif url.path == "/detect-language":
                res = json.loads(infer(pcm[:DETECT_SECONDS * SAMPLE_RATE * 2],
                                       response_format="verbose_json", language="auto"))
                probs = res.get("language_probabilities") or {"und": 1}
                code = max(probs, key=probs.get)
                self.reply(200, json.dumps({"detected_language": code, "language_code": code}).encode(),
                           "application/json")
            else:
                self.reply(404, b"", "text/plain")
        except Exception as e:
            self.reply(500, str(e).encode(), "text/plain")


ThreadingHTTPServer(("0.0.0.0", 9000), Handler).serve_forever()
