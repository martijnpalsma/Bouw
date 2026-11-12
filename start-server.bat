@echo off
cls
echo.
echo ================================================
echo   🏗️  Bouw Informatie Systeem Server
echo ================================================
echo.

REM Get IP Address
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set IP=%%a
    goto :found
)
:found
set IP=%IP:~1%

if "%IP%"=="" (
    set IP=localhost
)

set PORT=8000

echo ✅ Server wordt gestart...
echo.
echo 📱 Open op je iPhone:
echo.
echo    http://%IP%:%PORT%
echo.
echo 💻 Of lokaal op deze computer:
echo.
echo    http://localhost:%PORT%
echo.
echo ================================================
echo.
echo 🔥 Server draait! Druk Ctrl+C om te stoppen
echo.
echo ================================================
echo.

REM Check if Python is available
python --version >nul 2>&1
if %errorlevel% equ 0 (
    python -m http.server %PORT%
) else (
    py --version >nul 2>&1
    if %errorlevel% equ 0 (
        py -m http.server %PORT%
    ) else (
        echo ❌ Python is niet geïnstalleerd!
        echo Installeer Python eerst: https://www.python.org/downloads/
        pause
        exit /b 1
    )
)
