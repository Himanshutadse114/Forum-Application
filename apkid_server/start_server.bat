@echo off
echo ============================================================
echo   APKiD Scanner Server - Setup and Start
echo ============================================================
echo.

REM Check Python
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found! Please install Python 3.8+ from python.org
    pause
    exit /b 1
)

echo [1/3] Installing dependencies...
pip install -r requirements.txt
if errorlevel 1 (
    echo [ERROR] Failed to install dependencies!
    pause
    exit /b 1
)

echo.
echo [2/3] Verifying APKiD installation...
python -m apkid --version
if errorlevel 1 (
    echo [WARNING] APKiD may not be installed correctly. Trying apkid command...
    apkid --version
)

echo.
echo [3/3] Starting server on http://0.0.0.0:5000
echo.
echo  To connect from Android device (USB/WiFi):
echo  Find your PC IP: ipconfig
echo  Use: http://YOUR_PC_IP:5000
echo.
echo  To connect from Android Emulator:
echo  Use: http://10.0.2.2:5000
echo.
echo ============================================================
python server.py
pause
