#!/usr/bin/env bash
set -euo pipefail

for _ in $(seq 1 30); do
    pgrep -f "quickshell.*noctalia-shell" >/dev/null 2>&1 && break
    sleep 1
done

exec /home/cookie/.local/bin/random-anime-wallpaper-noctalia -s
