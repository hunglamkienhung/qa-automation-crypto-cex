#!/usr/bin/env bash
# Run mini-cex against a local SQLite file, or stop it.
#   ./serve.sh up | down | status
# Detached with setsid so it survives the launching shell (a WSL session tears
# down plain-nohup children on exit). The WAL store must live on a native Linux
# filesystem for a WSL reader to memory-map it -- set MINI_CEX_DB to a /tmp path.
set -euo pipefail
cd "$(dirname "$0")"
PORT="${MINI_CEX_PORT:-8110}"
export MINI_CEX_PORT="${PORT}"
LOG="${MINI_CEX_LOG:-/tmp/mini-cex-${PORT}.log}"
PIDFILE="/tmp/mini-cex-${PORT}.pid"
free_port() {
  # Kill whatever still holds the port, however it was launched. A stale server
  # left on this port from an earlier run keeps answering, so a fresh bind that
  # silently fails looks "up" while serving an empty store -- turning every
  # downstream case into a spurious Blocked. Freeing the port is the only
  # reliable guard: pkill-by-name misses a server launched as bare
  # `node server.js`, and a leftover pidfile may not name a live process.
  if command -v fuser >/dev/null 2>&1; then fuser -k "${PORT}/tcp" 2>/dev/null || true
  elif command -v lsof >/dev/null 2>&1; then lsof -ti tcp:"${PORT}" 2>/dev/null | xargs -r kill 2>/dev/null || true; fi
}
case "${1:-up}" in
  up)
    [ -f "${PIDFILE}" ] && kill "$(cat "${PIDFILE}")" 2>/dev/null || true
    pkill -f "mini-cex/server.js" 2>/dev/null || true
    free_port
    sleep 0.4
    # Fresh store every run: scenarios assert on deltas and use fixed keys
    # (idempotency), so a run must start from the seed.
    if [ -n "${MINI_CEX_DB:-}" ]; then rm -f "${MINI_CEX_DB}" "${MINI_CEX_DB}-shm" "${MINI_CEX_DB}-wal" 2>/dev/null || true; else rm -rf ./data 2>/dev/null || true; fi
    setsid nohup node "$(pwd)/server.js" > "${LOG}" 2>&1 < /dev/null &
    echo $! > "${PIDFILE}"; disown || true
    for i in $(seq 1 40); do curl -sf "http://127.0.0.1:${PORT}/assets" >/dev/null 2>&1 && break; sleep 0.2; done
    curl -s "http://127.0.0.1:${PORT}/assets" >/dev/null && echo "mini-cex up on ${PORT} (db ${MINI_CEX_DB:-./data/mini-cex.db})" || { echo "did not come up"; cat "${LOG}"; exit 1; }
    ;;
  down) [ -f "${PIDFILE}" ] && kill "$(cat "${PIDFILE}")" 2>/dev/null || true; rm -f "${PIDFILE}"; echo "stopped" ;;
  status) curl -s "http://127.0.0.1:${PORT}/assets" && echo || echo "not running" ;;
  *) echo "usage: $0 up|down|status" >&2; exit 2 ;;
esac
