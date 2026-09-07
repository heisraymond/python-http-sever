# Build Notes: Python HTTP Server from Scratch

A learning-focused build plan for implementing an HTTP/1.1 server directly on
top of raw TCP sockets — standard library only, no frameworks. The goal is to
see what Flask/FastAPI/Django normally hide.

## The core insight

An HTTP server is a **TCP socket that reads text, interprets it against a set
of rules, and writes text back**. Routing, headers, and status codes are just
string parsing and string formatting on top of a byte stream.

The spec to keep open while building: [RFC 9112 (HTTP/1.1)](https://datatracker.ietf.org/doc/html/rfc9112).

A request:

```
GET /echo/hello HTTP/1.1\r\n       ← request line: METHOD PATH VERSION
Host: localhost:4221\r\n            ← headers, one per line
User-Agent: curl/8.0\r\n
\r\n                                 ← blank line = end of headers
<optional body>
```

A response is the mirror image: status line, headers, blank line, body. The
`\r\n` delimiters and the blank line are the entire framing protocol —
parsing a request is splitting on those.

## Staged roadmap

Work through these in order. Each stage should be its own commit (or tag)
so the git history reads as the tutorial — a later reader can `git checkout`
an earlier stage and see the minimal version before the next concept existed.

- [ ] **Stage 1 — Bind and listen.** Open a TCP socket on a port, `accept()`
      one connection, print whatever bytes arrive.
      Learn: sockets, the blocking accept loop.
- [ ] **Stage 2 — Hardcoded `200 OK`.** Write a valid response back and view
      it in a browser/`curl`.
      Learn: response framing, why `\r\n\r\n` matters.
- [ ] **Stage 3 — Parse the request line.** Extract method + path; return
      `404` for unknown paths.
      Learn: request parsing — this is routing in embryo.
- [ ] **Stage 4 — Dynamic body.** e.g. `/echo/{str}` echoes the string back,
      with a correct `Content-Length`.
      Learn: why `Content-Length` exists (how the client knows the body ended).
- [ ] **Stage 5 — Read request headers.** e.g. a `/user-agent` route that
      reads the `User-Agent` header.
      Learn: headers as a key-value map.
- [ ] **Stage 6 — Concurrency.** Handle multiple clients at once (see ladder
      below). This is the biggest real-world concern.
- [ ] **Stage 7 — Serve files.** A `/files/{name}` route reading from disk,
      with the right `Content-Type`.
      Learn: static file serving, MIME types.
- [ ] **Stage 8 — Read a request body.** Accept `POST` and write a file.
      Learn: bodies, methods beyond GET.

Extensions once the core is solid:

- [ ] **gzip compression** — `Accept-Encoding` request header →
      `Content-Encoding` response header.
- [ ] **Persistent connections** — HTTP/1.1 keep-alive (multiple requests
      over one TCP connection) and the `Connection: close` header.

## The concurrency ladder

Build these in order so each limitation is felt before it's fixed:

1. **Iterative (one connection at a time).** Dead simple, but a slow client
   blocks everyone. Start here so the problem is real.
2. **Thread-per-connection.** Spawn a thread per client. This is what
   `socketserver.ThreadingMixIn` does. Ceiling: thousands of threads don't
   scale, and the GIL limits CPU parallelism.
3. **`asyncio` / event loop.** One thread, non-blocking sockets, an event
   loop multiplexing many connections. This is the leap to how modern
   high-performance servers — and ASGI frameworks like FastAPI — work.

This ladder is also *why* WSGI (sync, one-request-per-worker: Flask/Django)
gave way to ASGI (async: FastAPI/Starlette).

## Two traps to get right early

- **`recv()` is not a message boundary.** TCP is a stream, not messages — a
  single `recv()` call is not guaranteed to return the full request. Read in
  a loop until you have it all.
- **Always send an accurate `Content-Length`**, or explicitly set
  `Connection: close`. Getting this wrong causes hangs that are confusing to
  debug from the client side.

## Repo conventions

- Standard library only for the server itself (`socket`, `threading`,
  `asyncio`) — no dependencies. The point is to show there's no magic.
  Dev/test tooling (in `requirements.txt`) is a separate concern.
- One stage = one commit, in order, on `main`.
- Tests start as plain `curl` commands (so the raw exchange is visible),
  graduating to `pytest` + `requests` once routes stabilize.

## Running it

Once `main.py` implements a stage, use `./dev.sh` for everything — see
`./dev.sh help`. Docker setup mirrors the same entry point so "run in a
container" and "run locally" stay identical.

## Sources

- [CodeCrafters – Build Your Own HTTP Server](https://app.codecrafters.io/courses/http-server/overview)
- [RFC 9112: HTTP/1.1](https://datatracker.ietf.org/doc/html/rfc9112)
- [HTTP Request explained (http.dev)](https://http.dev/request)
- [Building a basic HTTP Server from scratch in Python (Codementor)](https://www.codementor.io/@joaojonesventura/building-a-basic-http-server-from-scratch-in-python-1cedkg0842)
- [Concurrency in Python: threading, multiprocessing, asyncio](https://medium.com/@ark.iitkgp/concurrency-in-python-understanding-threading-multiprocessing-and-asyncio-03bd92ca298b)
