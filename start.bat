@echo off
echo ============================================
echo    Gebouw Foto Analyse Systeem - Startup
echo ============================================
echo.

REM Check if .env exists
if not exist .env (
    echo WARNING: .env bestand niet gevonden!
    echo Kopieer .env.example naar .env en configureer je API key:
    echo   copy .env.example .env
    echo.
    echo Druk op een toets om in demo mode te starten ^(zonder API key^)...
    pause > nul
)

REM Check if virtual environment exists
if not exist venv\ (
    echo Geen virtual environment gevonden. Wil je er een aanmaken? ^(Y/N^)
    set /p response=
    if /i "%response%"=="Y" (
        echo Aanmaken virtual environment...
        python -m venv venv
        echo Virtual environment aangemaakt
    )
)

REM Activate virtual environment if it exists
if exist venv\ (
    echo Activeren virtual environment...
    call venv\Scripts\activate.bat
)

REM Check if requirements are installed
echo Controleren dependencies...
pip show flask >nul 2>&1
if errorlevel 1 (
    echo Installeren dependencies...
    pip install -r requirements.txt
    echo Dependencies geinstalleerd
) else (
    echo Dependencies al geinstalleerd
)

REM Create uploads directory if it doesn't exist
if not exist uploads\ (
    mkdir uploads
    echo Uploads directory aangemaakt
)

echo.
echo Starten server...
echo De applicatie draait op: http://localhost:5000
echo Foto analyse: http://localhost:5000/foto-analyse.html
echo.
echo Druk op CTRL+C om te stoppen
echo.

REM Start the Flask application
python app.py
