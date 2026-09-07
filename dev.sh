#!/usr/bin/env bash
# Single entry point for local dev commands. Run `./dev.sh help` for usage.
set -euo pipefail

VENV_DIR=".venv"
IMAGE_NAME="python-http-sever"
PORT="${PORT:-8080}"

venv_python() {
  echo "$VENV_DIR/bin/python"
}

cmd_setup() {
  python3 -m venv "$VENV_DIR"
  "$(venv_python)" -m pip install --upgrade pip
  "$(venv_python)" -m pip install -r requirements.txt
  echo "Done. Activate with: source $VENV_DIR/bin/activate"
}

cmd_run() {
  "$(venv_python)" main.py
}

cmd_test() {
  "$(venv_python)" -m pytest "$@"
}

cmd_docker_build() {
  docker build -t "$IMAGE_NAME" .
}

cmd_docker_run() {
  docker run --rm -it -p "${PORT}:${PORT}" -e "PORT=${PORT}" "$IMAGE_NAME"
}

cmd_help() {
  cat <<EOF
Usage: ./dev.sh <command>

Commands:
  setup         Create .venv and install requirements.txt
  run           Run main.py using the venv's Python
  test [args]   Run pytest (any extra args are passed through)
  docker-build  Build the Docker image
  docker-run    Run the Docker image, publishing PORT (default 8080)
  help          Show this message
EOF
}

case "${1:-help}" in
  setup) cmd_setup ;;
  run) cmd_run ;;
  test) shift; cmd_test "$@" ;;
  docker-build) cmd_docker_build ;;
  docker-run) cmd_docker_run ;;
  help|-h|--help) cmd_help ;;
  *)
    echo "Unknown command: $1" >&2
    cmd_help
    exit 1
    ;;
esac
