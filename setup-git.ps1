# Git Setup Script for Final_Mix Project
# This script helps initialize Git repository and make the first commit

Write-Host "🚀 Setting up Git repository for Final_Mix project..." -ForegroundColor Green

# Check if Git is installed
try {
    git --version | Out-Null
    Write-Host "✅ Git is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Git is not installed. Please install Git first." -ForegroundColor Red
    exit 1
}

# Check if we're in a Git repository
if (Test-Path ".git") {
    Write-Host "ℹ️  Git repository already exists" -ForegroundColor Yellow
} else {
    # Initialize Git repository
    Write-Host "📁 Initializing Git repository..." -ForegroundColor Blue
    git init
    Write-Host "✅ Git repository initialized" -ForegroundColor Green
}

# Add all files
Write-Host "📦 Adding files to Git..." -ForegroundColor Blue
git add .

# Check if there are any files to commit
$status = git status --porcelain
if ($status) {
    Write-Host "✅ Files added successfully" -ForegroundColor Green
    
    # Make initial commit
    Write-Host "💾 Making initial commit..." -ForegroundColor Blue
    git commit -m "Initial commit: Final_Mix AI Chatbot with Task Management

Features:
- Django backend with Claude AI integration
- ASP.NET frontend with modern UI
- Single-tap chatbot toggle functionality
- Intelligent name resolution with clarification prompts
- Task creation with natural language processing
- Alert system for overdue tasks
- Timezone support and status reporting
- Comprehensive error handling and logging

Technical improvements:
- Fixed name resolution to show full names in clarification messages
- Implemented single-tap toggle for chat window
- Updated color scheme to match application theme
- Removed suggestion prompts for cleaner interface
- Added proper .gitignore files for all components"
    
    Write-Host "✅ Initial commit completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎉 Your Final_Mix project is now ready for Git!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Add your remote repository: git remote add origin <your-repo-url>" -ForegroundColor White
    Write-Host "2. Push to remote: git push -u origin main" -ForegroundColor White
    Write-Host "3. Start developing! 🚀" -ForegroundColor White
} else {
    Write-Host "ℹ️  No files to commit (all files may be ignored by .gitignore)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Summary of .gitignore files created:" -ForegroundColor Cyan
Write-Host "- Root level: .gitignore (general project ignores)" -ForegroundColor White
Write-Host "- Backend: backend/.gitignore (Python/Django specific)" -ForegroundColor White
Write-Host "- Frontend: frontend/.gitignore (already existed - ASP.NET specific)" -ForegroundColor White

Write-Host ""
Write-Host "🔒 Sensitive files that are now ignored:" -ForegroundColor Cyan
Write-Host "- Environment files (.env)" -ForegroundColor White
Write-Host "- Virtual environments (venv/, env/)" -ForegroundColor White
Write-Host "- Log files (*.log)" -ForegroundColor White
Write-Host "- Database files (*.db, *.sqlite)" -ForegroundColor White
Write-Host "- API keys and certificates (*.key, *.pem)" -ForegroundColor White
Write-Host "- Token usage tracking (token_usage.csv)" -ForegroundColor White
Write-Host "- Compiled Python files (__pycache__/, *.pyc)" -ForegroundColor White
Write-Host "- IDE files (.vscode/, .idea/)" -ForegroundColor White
