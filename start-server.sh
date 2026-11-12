#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

clear
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🏗️  Bouw Informatie Systeem Server"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get IP address (try multiple methods)
if command -v ipconfig &> /dev/null; then
    # Mac
    IP=$(ipconfig getifaddr en0 2>/dev/null)
    if [ -z "$IP" ]; then
        IP=$(ipconfig getifaddr en1 2>/dev/null)
    fi
elif command -v hostname &> /dev/null; then
    # Linux
    IP=$(hostname -I 2>/dev/null | awk '{print $1}')
fi

# Fallback
if [ -z "$IP" ]; then
    IP="localhost"
fi

PORT=8000

echo -e "${GREEN}✅ Server wordt gestart...${NC}"
echo ""
echo -e "${BLUE}📱 Open op je iPhone:${NC}"
echo ""
echo -e "   ${YELLOW}http://$IP:$PORT${NC}"
echo ""
echo -e "${BLUE}💻 Of lokaal op deze computer:${NC}"
echo ""
echo -e "   ${YELLOW}http://localhost:$PORT${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}🔥 Server draait! Druk Ctrl+C om te stoppen${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if Python 3 is available
if command -v python3 &> /dev/null; then
    python3 -m http.server $PORT
elif command -v python &> /dev/null; then
    python -m http.server $PORT
else
    echo "❌ Python is niet geïnstalleerd!"
    echo "Installeer Python eerst: https://www.python.org/downloads/"
    exit 1
fi
