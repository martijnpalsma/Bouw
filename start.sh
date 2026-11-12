#!/bin/bash

echo "🏗️ Gebouw Foto Analyse Systeem - Startup Script"
echo "=============================================="
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  .env bestand niet gevonden!"
    echo "Kopieer .env.example naar .env en configureer je API key:"
    echo "  cp .env.example .env"
    echo ""
    echo "Druk op Enter om in demo mode te starten (zonder API key)..."
    read
fi

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Geen virtual environment gevonden. Wil je er een aanmaken? (y/n)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Aanmaken virtual environment..."
        python3 -m venv venv
        echo "✅ Virtual environment aangemaakt"
    fi
fi

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    echo "🔄 Activeren virtual environment..."
    source venv/bin/activate
fi

# Check if requirements are installed
echo "📦 Controleren dependencies..."
pip show flask > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "⚙️  Installeren dependencies..."
    pip install -r requirements.txt
    echo "✅ Dependencies geïnstalleerd"
else
    echo "✅ Dependencies al geïnstalleerd"
fi

# Create uploads directory if it doesn't exist
if [ ! -d "uploads" ]; then
    mkdir uploads
    echo "📁 Uploads directory aangemaakt"
fi

echo ""
echo "🚀 Starten server..."
echo "📍 De applicatie draait op: http://localhost:5000"
echo "📸 Foto analyse: http://localhost:5000/foto-analyse.html"
echo ""
echo "Druk op CTRL+C om te stoppen"
echo ""

# Load environment variables if .env exists
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Start the Flask application
python app.py
