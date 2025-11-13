#!/bin/bash

# Olist dbt Project Setup Script
# This script automates the initial setup of the dbt project

set -e  # Exit on error

echo "========================================="
echo "Olist dbt Project Setup"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Check Python
echo -e "${YELLOW}[1/6] Checking Python installation...${NC}"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✓ Found: $PYTHON_VERSION${NC}"
else
    echo -e "${RED}✗ Python 3 not found. Please install Python 3.7+${NC}"
    exit 1
fi

# Step 2: Check PostgreSQL
echo -e "\n${YELLOW}[2/6] Checking PostgreSQL...${NC}"
if command -v psql &> /dev/null; then
    PG_VERSION=$(psql --version)
    echo -e "${GREEN}✓ Found: $PG_VERSION${NC}"
else
    echo -e "${RED}✗ PostgreSQL not found. Please install PostgreSQL${NC}"
    exit 1
fi

# Step 3: Install dbt
echo -e "\n${YELLOW}[3/6] Installing dbt packages...${NC}"
pip install --upgrade pip
pip install dbt-core dbt-postgres
echo -e "${GREEN}✓ dbt installed successfully${NC}"

# Step 4: Verify dbt installation
echo -e "\n${YELLOW}[4/6] Verifying dbt installation...${NC}"
DBT_VERSION=$(dbt --version | head -n 1)
echo -e "${GREEN}✓ $DBT_VERSION${NC}"

# Step 5: Install dbt packages
echo -e "\n${YELLOW}[5/6] Installing dbt dependencies...${NC}"
cd "$(dirname "$0")"
dbt deps
echo -e "${GREEN}✓ dbt packages installed${NC}"

# Step 6: Configure profiles
echo -e "\n${YELLOW}[6/6] Configuring dbt profiles...${NC}"
echo "Please update the database credentials in profiles.yml"
echo "Edit the file and update:"
echo "  - host (default: localhost)"
echo "  - user (default: postgres)"
echo "  - password (REQUIRED)"
echo "  - dbname (default: olist_ecommerce)"
echo ""
read -p "Press Enter to continue after updating profiles.yml..."

# Test connection
echo -e "\n${YELLOW}Testing database connection...${NC}"
if dbt debug; then
    echo -e "${GREEN}✓ Database connection successful!${NC}"
else
    echo -e "${RED}✗ Database connection failed. Please check profiles.yml${NC}"
    exit 1
fi

echo ""
echo "========================================="
echo -e "${GREEN}Setup Complete! 🎉${NC}"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Load raw data: cd .. && python load_olist_data_to_postgres.py"
echo "  2. Run dbt models: dbt run"
echo "  3. Run tests: dbt test"
echo "  4. Generate docs: dbt docs generate && dbt docs serve"
echo ""
