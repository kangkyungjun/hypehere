#!/bin/bash

#################################################################
# Contactotalk Quick Update Script
#
# This script updates both backend and frontend code
# Usage: sudo bash update.sh
#################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="/home/ubuntu/contactotalk"
FRONTEND_DIR="/home/ubuntu/contactotalk-frontend"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Contactotalk Update Script${NC}"
echo -e "${GREEN}========================================${NC}"

# Update Backend
echo -e "${YELLOW}[1/4] Updating backend code...${NC}"
cd $PROJECT_DIR

# Activate virtual environment
source venv/bin/activate

# Install/update dependencies
pip install -r requirements.production.txt

# Run migrations
export DJANGO_ENV=production
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Update Frontend
echo -e "${YELLOW}[2/4] Updating frontend code...${NC}"
cd $FRONTEND_DIR

# Install/update dependencies
npm install

# Build Next.js
npm run build

# Restart Services
echo -e "${YELLOW}[3/4] Restarting services...${NC}"
systemctl restart gunicorn
systemctl restart daphne
systemctl restart celery
systemctl restart nextjs

# Wait a moment for services to start
sleep 3

# Check Service Status
echo -e "${YELLOW}[4/4] Checking service status...${NC}"
echo ""
echo -e "${GREEN}Gunicorn:${NC}"
systemctl status gunicorn --no-pager -l | head -5

echo ""
echo -e "${GREEN}Daphne:${NC}"
systemctl status daphne --no-pager -l | head -5

echo ""
echo -e "${GREEN}Next.js:${NC}"
systemctl status nextjs --no-pager -l | head -5

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Update complete!${NC}"
echo -e "${GREEN}========================================${NC}"
