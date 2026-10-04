"""Local demo console on http://localhost:3000 (the console origin the stack trusts).

Serves index.html and forwards /api/* to the gateway (same origin, so the refresh cookie and the Origin
check behave as they will for the real console). Three /dev/* helpers do what only the inside network
can: read the last email Mailpit caught, grant prepaid credit, read a balance. Demo only, never deployed.
Run after: docker compose up -d --wait (in ../docker)   then: python serve.py
"""
import json
import os
import subprocess
import urllib.error
import urllib.parse
import urllib.request
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

GATEWAY = os.environ.get("GATEWAY", "http://localhost:8080")
HERE = os.path.dirname(os.path.abspath(__file__))
COMPOSE = ["docker", "compose", "-f", os.path.join(HERE, "..", "docker", "compose.yaml")]
FORWARD = ("Content-Type", "Authorization", "Cookie", "Origin")
BACK = ("Content-Type", "Set-Cookie", "X-Request-Id", "x-ratelimit-remaining-requests", "x-ratelimit-limit-requests")


def inside(*command):
    """Runs a command in the llama container (it has curl and sits on the internal network)."""
    return subprocess.run(COMPOSE + ["exec", "-T", "llama", *command], capture_output=True, text=True, timeout=30).stdout


class Demo(SimpleHTTPRequestHandler):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=HERE, **kwargs)

    def do_GET(self):
        self.route()

    def do_POST(self):
        self.route()

    def do_DELETE(self):
        self.route()

    def route(self):
        url = urllib.parse.urlsplit(self.path)
        query = dict(urllib.parse.parse_qsl(url.query))
        if url.path.startswith("/api/"):
            return self.forward(url.path[4:] + ("?" + url.query if url.query else ""))
        if url.path == "/dev/mail":
            return self.json(self.last_mail(query["to"]))
        if url.path == "/dev/grant":
            body = json.dumps({"organizationId": query["org"], "amountMicroBrl": 10_000_000, "reason": "demo",
                               "idempotencyKey": "demo-" + query["org"]})
            code = inside("curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", "-H", "Content-Type: application/json",
                          "-X", "POST", "http://billing:8080/billing/grants", "-d", body)
            return self.json({"status": code})
        if url.path == "/dev/balance":
            sql = f"SELECT coalesce((SELECT amount FROM billing.balance WHERE organization_id = '{query['org']}'), 0)"
            out = subprocess.run(COMPOSE + ["exec", "-T", "db", "sh", "-c",
                                            'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tA -c "$1"', "sh", sql],
                                 capture_output=True, text=True, timeout=30).stdout.strip()
            return self.json({"microBrl": int(out or 0)})
        return super().do_GET() if self.command == "GET" else self.send_error(404)

    def forward(self, path):
        length = int(self.headers.get("Content-Length") or 0)
        request = urllib.request.Request(GATEWAY + path, data=self.rfile.read(length) if length else None, method=self.command)
        for name in FORWARD:
            if self.headers.get(name):
                request.add_header(name, self.headers[name])
        try:
            response = urllib.request.urlopen(request, timeout=120)
        except urllib.error.HTTPError as error:
            response = error
        self.send_response(response.status)
        for name in BACK:
            for value in response.headers.get_all(name) or []:
                self.send_header(name, value)
        self.send_header("Connection", "close")
        self.end_headers()
        while chunk := response.read1(4096) if hasattr(response, "read1") else response.read(4096):
            self.wfile.write(chunk)   # streams (SSE) pass through as they arrive
            self.wfile.flush()

    def last_mail(self, to):
        found = json.loads(inside("curl", "-s", "http://mailpit:8025/api/v1/search?query=" + urllib.parse.quote(f'to:"{to}"')) or "{}")
        messages = found.get("messages") or []
        if not messages:
            return {}
        message = json.loads(inside("curl", "-s", "http://mailpit:8025/api/v1/message/" + messages[0]["ID"]))
        return {"subject": message.get("Subject"), "text": message.get("Text")}

    def json(self, value):
        body = json.dumps(value).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass   # quiet: tokens and emails go through here


if __name__ == "__main__":
    print("demo console on http://localhost:3000")
    ThreadingHTTPServer(("localhost", 3000), Demo).serve_forever()
