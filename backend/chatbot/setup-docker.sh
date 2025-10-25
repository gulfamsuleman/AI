#!/bin/bash

# Bash script to set up Docker environment for QProcess Chatbot Backend

echo "=================================================="
echo "QProcess Chatbot Backend - Docker Setup"
echo "=================================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if Docker is installed
echo -e "${YELLOW}Checking Docker installation...${NC}"
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo -e "${GREEN}✓ Docker found: $DOCKER_VERSION${NC}"
else
    echo -e "${RED}✗ Docker not found. Please install Docker first.${NC}"
    echo -e "${YELLOW}Visit: https://docs.docker.com/get-docker/${NC}"
    exit 1
fi

# Check if docker-compose is installed
echo -e "${YELLOW}Checking Docker Compose installation...${NC}"
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version)
    echo -e "${GREEN}✓ Docker Compose found: $COMPOSE_VERSION${NC}"
else
    echo -e "${RED}✗ Docker Compose not found. Please install it.${NC}"
    exit 1
fi

echo ""

# Check if .env file exists
if [ -f ".env" ]; then
    echo -e "${GREEN}✓ .env file already exists${NC}"
    read -p "Do you want to recreate it from template? (y/N): " overwrite
    if [[ $overwrite == "y" || $overwrite == "Y" ]]; then
        cp env.template .env
        echo -e "${GREEN}✓ .env file recreated from template${NC}"
        echo -e "${YELLOW}⚠ Please edit .env file with your actual credentials!${NC}"
    fi
else
    echo -e "${YELLOW}Creating .env file from template...${NC}"
    cp env.template .env
    echo -e "${GREEN}✓ .env file created${NC}"
    echo -e "${YELLOW}⚠ Please edit .env file with your actual credentials!${NC}"
fi

echo ""

# Create necessary directories
echo -e "${YELLOW}Creating necessary directories...${NC}"
directories=("logs" "sessions" "staticfiles")
for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo -e "${GREEN}✓ Created directory: $dir${NC}"
    else
        echo -e "${GREEN}✓ Directory already exists: $dir${NC}"
    fi
done

# Set permissions (Linux/Mac only)
if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
    echo ""
    echo -e "${YELLOW}Setting directory permissions...${NC}"
    chmod -R 755 logs sessions staticfiles 2>/dev/null || true
    echo -e "${GREEN}✓ Permissions set${NC}"
fi

echo ""
echo -e "${CYAN}==================================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${CYAN}==================================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Edit .env file with your API key and passwords"
echo "   - Set ANTHROPIC_API_KEY"
echo "   - Optionally change SA_PASSWORD and DB_PASSWORD"
echo "2. Run: docker-compose up --build"
echo ""
echo -e "${CYAN}The setup will automatically:${NC}"
echo -e "${GREEN}  ✓ Start SQL Server in Docker${NC}"
echo -e "${GREEN}  ✓ Create QTasks database${NC}"
echo -e "${GREEN}  ✓ Start Django backend${NC}"
echo -e "${GREEN}  ✓ Run migrations${NC}"
echo ""
echo -e "${CYAN}For detailed instructions, see QUICK_START_WITH_SQLSERVER.md${NC}"
echo ""

# Ask if user wants to open .env file for editing
read -p "Do you want to open .env file for editing now? (Y/n): " edit
if [[ $edit != "n" && $edit != "N" ]]; then
    if command -v nano &> /dev/null; then
        nano .env
    elif command -v vim &> /dev/null; then
        vim .env
    elif command -v vi &> /dev/null; then
        vi .env
    else
        echo -e "${YELLOW}No text editor found. Please edit .env manually.${NC}"
    fi
fi

echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"

