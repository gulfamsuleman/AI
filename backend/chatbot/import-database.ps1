# Automated Database Import Script for Docker SQL Server
# This script ensures your database is imported correctly with all data
 
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  QProcess Chatbot - Database Import" -ForegroundColor Cyan
Write-Host "================================================`n" -ForegroundColor Cyan
 
# Configuration
$bacpacFile = ".\database\backups\Qtasks.bacpac"
$sqlServer = "localhost,1433"
$dbName = "QTasks"
$username = "sa"
$password = "YourStrong@Passw0rd"
 
# Check if Docker containers are running
Write-Host "Checking Docker containers..." -ForegroundColor Yellow
$containers = docker-compose ps --format json | ConvertFrom-Json
$sqlserverRunning = $containers | Where-Object { $_.Service -eq "sqlserver" -and $_.State -eq "running" }
 
if (-not $sqlserverRunning) {
    Write-Host "✗ SQL Server container is not running!" -ForegroundColor Red
    Write-Host "Please start it first: docker-compose up -d sqlserver" -ForegroundColor Yellow
    exit 1
}
 
Write-Host "✓ SQL Server container is running" -ForegroundColor Green
 
# Check if .bacpac file exists
if (-not (Test-Path $bacpacFile)) {
    Write-Host "✗ Database file not found: $bacpacFile" -ForegroundColor Red
    Write-Host "Please place your Qtasks.bacpac file in database/backups/" -ForegroundColor Yellow
    exit 1
}
 
$fileSize = [math]::Round((Get-Item $bacpacFile).Length / 1MB, 2)
Write-Host "✓ Found database file: $bacpacFile ($fileSize MB)" -ForegroundColor Green
 
# Check if database already has data
Write-Host "`nChecking existing database..." -ForegroundColor Yellow
$checkData = docker exec qprocess_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U $username -P $password -C -Q "USE QTasks; SELECT COUNT(*) FROM QCheck_Users" -h -1 2>&1
 
if ($checkData -match "(\d+)") {
    $userCount = [int]$matches[1]
    if ($userCount -gt 0) {
        Write-Host "✓ Database already has $userCount users. Data is present." -ForegroundColor Green
        $reimport = Read-Host "`nDatabase already has data. Reimport anyway? (yes/no)"
        if ($reimport -ne "yes") {
            Write-Host "Skipping import. Database is ready to use!" -ForegroundColor Green
            exit 0
        }
    }
}
 
# Check if SqlPackage is installed
Write-Host "`nChecking for SqlPackage..." -ForegroundColor Yellow
try {
    $sqlpackageVersion = & sqlpackage /version 2>&1 | Select-String "Version"
    Write-Host "✓ SqlPackage found: $sqlpackageVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ SqlPackage not found!" -ForegroundColor Red
    Write-Host "`nInstalling SqlPackage..." -ForegroundColor Yellow
    try {
        dotnet tool install -g microsoft.sqlpackage
        Write-Host "✓ SqlPackage installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to install SqlPackage" -ForegroundColor Red
        Write-Host "Please install manually: dotnet tool install -g microsoft.sqlpackage" -ForegroundColor Yellow
        exit 1
    }
}
 
# Stop backend to release database connections
Write-Host "`nStopping backend..." -ForegroundColor Yellow
docker-compose stop backend | Out-Null
Write-Host "✓ Backend stopped" -ForegroundColor Green
 
# Drop existing database if needed
Write-Host "`nPreparing for import..." -ForegroundColor Yellow
$dropResult = docker exec qprocess_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U $username -P $password -C -Q "IF EXISTS (SELECT name FROM sys.databases WHERE name = '$dbName') BEGIN ALTER DATABASE $dbName SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE $dbName; PRINT 'Database dropped'; END ELSE BEGIN PRINT 'No existing database'; END" 2>&1
 
Write-Host "✓ Ready for import" -ForegroundColor Green
 
# Import the database
Write-Host "`nImporting database (this takes 10-15 minutes)..." -ForegroundColor Yellow
Write-Host "File: $bacpacFile" -ForegroundColor White
Write-Host "Target: $sqlServer / $dbName" -ForegroundColor White
Write-Host ""
 
$startTime = Get-Date
 
try {
    & sqlpackage `
        /Action:Import `
        /SourceFile:"$bacpacFile" `
        /TargetDatabaseName:$dbName `
        /TargetServerName:$sqlServer `
        /TargetUser:$username `
        /TargetPassword:$password `
        /TargetTrustServerCertificate:True `
        /p:CommandTimeout=3600
   
    if ($LASTEXITCODE -eq 0) {
        $duration = ((Get-Date) - $startTime).TotalMinutes
        Write-Host "`n✓ Database imported successfully!" -ForegroundColor Green
        Write-Host "  Time taken: $([math]::Round($duration, 1)) minutes" -ForegroundColor White
    } else {
        throw "Import failed with exit code: $LASTEXITCODE"
    }
} catch {
    Write-Host "`n✗ Import failed: $_" -ForegroundColor Red
    Write-Host "`nStarting backend anyway..." -ForegroundColor Yellow
    docker-compose start backend | Out-Null
    exit 1
}
 
# Verify import
Write-Host "`nVerifying import..." -ForegroundColor Yellow
$verifyResults = docker exec qprocess_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U $username -P $password -C -Q "USE $dbName; SELECT COUNT(*) AS Users FROM QCheck_Users; SELECT COUNT(*) AS Groups FROM QCheck_Groups; SELECT COUNT(*) AS TaskTypes FROM QStatus_TaskTypes;" 2>&1
 
if ($verifyResults -match "Users.*?(\d+).*?Groups.*?(\d+).*?TaskTypes.*?(\d+)") {
    Write-Host "✓ Users: $($matches[1])" -ForegroundColor Green
    Write-Host "✓ Groups: $($matches[2])" -ForegroundColor Green
    Write-Host "✓ Task Types: $($matches[3])" -ForegroundColor Green
}
 
# Start backend
Write-Host "`nStarting backend..." -ForegroundColor Yellow
docker-compose start backend | Out-Null
Start-Sleep -Seconds 10
 
# Final status check
Write-Host "`nFinal Status:" -ForegroundColor Cyan
docker-compose ps
 
Write-Host "`n✓ Database import complete and verified!" -ForegroundColor Green
Write-Host "`nYou can now access:" -ForegroundColor Cyan
Write-Host "  • Backend API: http://localhost:8000" -ForegroundColor White
Write-Host "  • Admin Panel: http://localhost:8000/admin" -ForegroundColor White
Write-Host "  • SQL Server: localhost,1433" -ForegroundColor White
Write-Host ""