# ChatBot Frontend-Backend Startup Script (PowerShell)
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ChatBot Frontend-Backend Startup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Starting Django Backend..." -ForegroundColor Green
Write-Host ""

# Change to backend directory
Set-Location "backend\chatbot"

# Check if virtual environment exists
if (-not (Test-Path "venv\Scripts\Activate.ps1")) {
    Write-Host "Virtual environment not found. Creating one..." -ForegroundColor Yellow
    python -m venv venv
    Write-Host "Virtual environment created." -ForegroundColor Green
}

# Activate virtual environment
Write-Host "Activating virtual environment..." -ForegroundColor Yellow
& "venv\Scripts\Activate.ps1"

# Install/update dependencies
Write-Host "Installing/updating dependencies..." -ForegroundColor Yellow
pip install -r requirements.txt

Write-Host ""
Write-Host "Starting Django development server..." -ForegroundColor Green
Write-Host "Backend will be available at: http://localhost:8000" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop the backend server" -ForegroundColor Yellow
Write-Host ""

# Start Django server
python manage.py runserver

Write-Host ""
Write-Host "Backend server stopped." -ForegroundColor Red
Write-Host ""
Read-Host "Press Enter to exit"
