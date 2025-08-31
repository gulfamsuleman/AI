@echo off
echo ========================================
echo ChatBot Frontend-Backend Startup Script
echo ========================================
echo.

echo Starting Django Backend...
echo.

cd backend\chatbot

echo Checking if Python virtual environment exists...
if not exist "venv\Scripts\activate.bat" (
    echo Virtual environment not found. Creating one...
    python -m venv venv
    echo Virtual environment created.
)

echo Activating virtual environment...
call venv\Scripts\activate.bat

echo Installing/updating dependencies...
pip install -r requirements.txt

echo.
echo Starting Django development server...
echo Backend will be available at: http://localhost:8000
echo.
echo Press Ctrl+C to stop the backend server
echo.

python manage.py runserver

echo.
echo Backend server stopped.
echo.
pause
