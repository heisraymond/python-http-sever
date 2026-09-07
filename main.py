"""Stage 1: Bind and listen.

Open a TCP socket, accept one connection, and print whatever bytes the
client sends. No parsing, no response yet — just proving the socket
plumbing works. See docs/notes.md for the full staged roadmap.
"""

import os
import socket

HOST = "localhost"
PORT = int(os.environ.get("PORT", 8080))


def main():
    # SO_REUSEADDR lets us restart the server quickly without hitting
    # "Address already in use" while the OS still has the old socket
    # in TIME_WAIT.
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server_socket.bind((HOST, PORT))
    server_socket.listen()
    print(f"Listening on {HOST}:{PORT}")

    # accept() blocks until a client connects. It hands back a new socket
    # dedicated to that connection, plus the client's address.
    connection, address = server_socket.accept()
    print(f"Connection from {address}")

    with connection:
        # A single recv() isn't guaranteed to return the whole request —
        # TCP is a stream, not messages. That's fine for now since we're
        # just observing; real parsing (and reading until we have it all)
        # comes in a later stage.
        data = connection.recv(1024)
        print(f"Received {len(data)} bytes:")
        print(data)


if __name__ == "__main__":
    main()
