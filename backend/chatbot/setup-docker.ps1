# PowerShell script to set up Docker environment for QProcess Chatbot Backend

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "QProcess Chatbot Backend - Docker Setup" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is installed
Write-Host "Checking Docker installation..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "✓ Docker found: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker not found. Please install Docker Desktop first." -ForegroundColor Red
    Write-Host "Download from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

# Check if docker-compose is installed
Write-Host "Checking Docker Compose installation..." -ForegroundColor Yellow
try {
    $composeVersion = docker-compose --version
    Write-Host "✓ Docker Compose found: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker Compose not found. Please install it." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Check if .env file exists
if (Test-Path ".env") {
    Write-Host "✓ .env file already exists" -ForegroundColor Green
    $overwrite = Read-Host "Do you want to recreate it from template? (y/N)"
    if ($overwrite -eq "y" -or $overwrite -eq "Y") {
        Copy-Item "env.template" ".env" -Force
        Write-Host "✓ .env file recreated from template" -ForegroundColor Green
        Write-Host "⚠ Please edit .env file with your actual credentials!" -ForegroundColor Yellow
    }
} else {
    Write-Host "Creating .env file from template..." -ForegroundColor Yellow
    Copy-Item "env.template" ".env"
    Write-Host "✓ .env file created" -ForegroundColor Green
    Write-Host "⚠ Please edit .env file with your actual credentials!" -ForegroundColor Yellow
}

Write-Host ""

# Create necessary directories
Write-Host "Creating necessary directories..." -ForegroundColor Yellow
$directories = @("logs", "sessions", "staticfiles")
foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
        Write-Host "✓ Created directory: $dir" -ForegroundColor Green
    } else {
        Write-Host "✓ Directory already exists: $dir" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Edit .env file with your API key and passwords" -ForegroundColor White
Write-Host "   - Set ANTHROPIC_API_KEY" -ForegroundColor White
Write-Host "   - Optionally change SA_PASSWORD and DB_PASSWORD" -ForegroundColor White
Write-Host "2. Run: docker-compose up --build" -ForegroundColor White
Write-Host ""
Write-Host "The setup will automatically:" -ForegroundColor Cyan
Write-Host "  ✓ Start SQL Server in Docker" -ForegroundColor Green
Write-Host "  ✓ Create QTasks database" -ForegroundColor Green
Write-Host "  ✓ Start Django backend" -ForegroundColor Green
Write-Host "  ✓ Run migrations" -ForegroundColor Green
Write-Host ""
Write-Host "For detailed instructions, see QUICK_START_WITH_SQLSERVER.md" -ForegroundColor Cyan
Write-Host ""

# Ask if user wants to open .env file for editing
$edit = Read-Host "Do you want to open .env file for editing now? (Y/n)"
if ($edit -ne "n" -and $edit -ne "N") {
    notepad .env
}

Write-Host ""
Write-Host "Happy coding! 🚀" -ForegroundColor Green

