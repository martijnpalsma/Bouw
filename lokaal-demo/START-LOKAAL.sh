#!/bin/bash
cd "$(dirname "$0")"
PORT="${PORT:-8765}"
IP=$(hostname -I 2>/dev/null | awk '{print $1}')
echo ""
echo "  RisicoScan LOKAAL"
echo "  ================="
echo "  Computer:  http://localhost:${PORT}"
if [ -n "$IP" ]; then
  echo "  Telefoon:  http://${IP}:${PORT}"
fi
echo ""
echo "  Niets wordt gepubliceerd. Stop met Ctrl+C."
echo ""
python3 -m http.server "$PORT" --bind 0.0.0.0
