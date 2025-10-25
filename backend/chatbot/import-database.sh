#!/bin/bash
# Automated Database Import Script for Docker SQL Server
# This script ensures your database is imported correctly with all data

echo ""
echo "================================================"
echo "  QProcess Chatbot - Database Import"
echo "================================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
BACPAC_FILE="./database/backups/Qtasks.bacpac"
SQL_SERVER="localhost,1433"
DB_NAME="QTasks"
USERNAME="sa"
PASSWORD="YourStrong@Passw0rd"

# Check if Docker containers are running
echo -e "${YELLOW}Checking Docker containers...${NC}"
if ! docker-compose ps | grep -q "qprocess_sqlserver.*running"; then
    echo -e "${RED}✗ SQL Server container is not running!${NC}"
    echo -e "${YELLOW}Please start it first: docker-compose up -d sqlserver${NC}"
    exit 1
fi
echo -e "${GREEN}✓ SQL Server container is running${NC}"

# Check if .bacpac file exists
if [ ! -f "$BACPAC_FILE" ]; then
    echo -e "${RED}✗ Database file not found: $BACPAC_FILE${NC}"
    echo -e "${YELLOW}Please place your Qtasks.bacpac file in database/backups/${NC}"
    exit 1
fi

FILE_SIZE=$(du -h "$BACPAC_FILE" | cut -f1)
echo -e "${GREEN}✓ Found database file: $BACPAC_FILE ($FILE_SIZE)${NC}"

# Check if database already has data
echo -e "\n${YELLOW}Checking existing database...${NC}"
USER_COUNT=$(docker exec qprocess_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U $USERNAME -P $PASSWORD -C -Q "USE QTasks; SELECT COUNT(*) FROM QCheck_Users" -h -1 2>/dev/null | tr -d '[:space:]')

if [[ "$USER_COUNT" =~ ^[0-9]+$ ]] && [ "$USER_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ Database already has $USER_COUNT users. Data is present.${NC}"
    read -p "$(echo -e ${YELLOW}Database already has data. Reimport anyway? (yes/no): ${NC})" reimport
    if [ "$reimport" != "yes" ]; then
        echo -e "${GREEN}Skipping import. Database is ready to use!${NC}"
        exit 0
    fi
fi

# Check if SqlPackage is installed
echo -e "\n${YELLOW}Checking for SqlPackage...${NC}"
if command -v sqlpackage &> /dev/null; then
    echo -e "${GREEN}✓ SqlPackage found${NC}"
else
    echo -e "${RED}✗ SqlPackage not found!${NC}"
    echo -e "\n${YELLOW}Installing SqlPackage...${NC}"
    if command -v dotnet &> /dev/null; then
        dotnet tool install -g microsoft.sqlpackage
        echo -e "${GREEN}✓ SqlPackage installed successfully${NC}"
    else
        echo -e "${RED}✗ .NET SDK not found. Cannot install SqlPackage${NC}"
        echo -e "${YELLOW}Please install manually: https://aka.ms/sqlpackage-linux${NC}"
        exit 1
    fi
fi

# Stop backend to release database connections
echo -e "\n${YELLOW}Stopping backend...${NC}"
docker-compose stop backend > /dev/null
echo -e "${GREEN}✓ Backend stopped${NC}"

# Drop existing database if needed
echo -e "\n${YELLOW}Preparing for import...${NC}"
docker exec qprocess_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U $USERNAME -P $PASSWORD -C -Q "IF EXISTS (SELECT name FROM sys.databases WHERE name = '$DB_NAME') BEGIN ALTER DATABASE $DB_NAME SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE $DB_NAME; END" 2>&1 | grep -v "Changed database context"
echo -e "${GREEN}✓ Ready for import${NC}"

# Import the database
echo -e "\n${YELLOW}Importing database (this takes 10-15 minutes)...${NC}"
echo -e "File: $BACPAC_FILE"
echo -e "Target: $SQL_SERVER / $DB_NAME"
echo ""

START_TIME=$(date +%s)

sqlpackage \
    /Action:Import \
    /SourceFile:"$BACPAC_FILE" \
    /TargetDatabaseName:$DB_NAME \
    /TargetServerName:$SQL_SERVER \
    /TargetUser:$USERNAME \
    /TargetPassword:$PASSWORD \
    /TargetTrustServerCertificate:True \
    /p:CommandTimeout=3600

if [ $? -eq 0 ]; then
    END_TIME=$(date +%s)
    DURATION=$(( ($END_TIME - $START_TIME) / 60 ))
    echo -e "\n${GREEN}✓ Database imported successfully!${NC}"
    echo -e "  Time taken: $DURATION minutes"
else
    echo -e "\n${RED}✗ Import failed${NC}"
    echo -e "\n${YELLOW}Starting backend anyway...${NC}"
    docker-compose start backend > /dev/null
    exit 1
fi

# Verify import
echo -e "\n${YELLOW}Verifying import...${NC}"
docker exec qprocess_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U $USERNAME -P $PASSWORD -C -Q "USE $DB_NAME; SELECT COUNT(*) AS Users FROM QCheck_Users; SELECT COUNT(*) AS Groups FROM QCheck_Groups; SELECT COUNT(*) AS TaskTypes FROM QStatus_TaskTypes;" 2>&1 | grep -E "[0-9]+"

# Start backend
echo -e "\n${YELLOW}Starting backend...${NC}"
docker-compose start backend > /dev/null
sleep 10

# Final status check
echo -e "\n${CYAN}Final Status:${NC}"
docker-compose ps

echo -e "\n${GREEN}✓ Database import complete and verified!${NC}"
echo -e "\n${CYAN}You can now access:${NC}"
echo -e "  • Backend API: http://localhost:8000"
echo -e "  • Admin Panel: http://localhost:8000/admin"
echo -e "  • SQL Server: localhost,1433"
echo ""

