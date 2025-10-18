#!/bin/bash

#################################################################
# Contactotalk Backend Deployment Script
#
# This script updates only the Django backend
# Usage: sudo bash deploy-backend.sh
#################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="/home/ubuntu/contactotalk"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Contactotalk Backend Deployment${NC}"
echo -e "${GREEN}========================================${NC}"

# Stop services
echo -e "${YELLOW}[1/6] Stopping backend services...${NC}"
systemctl stop gunicorn daphne celery

# Update code
echo -e "${YELLOW}[2/6] Updating backend code...${NC}"
cd $PROJECT_DIR

# Activate virtual environment
source venv/bin/activate

# Install/update dependencies
echo -e "${YELLOW}[3/6] Installing dependencies...${NC}"
pip install -r requirements.production.txt

# Run migrations
echo -e "${YELLOW}[4/6] Running database migrations...${NC}"
export DJANGO_ENV=production
python manage.py migrate

# Collect static files
echo -e "${YELLOW}[5/6] Collecting static files...${NC}"
python manage.py collectstatic --noinput

# Start services
echo -e "${YELLOW}[6/6] Starting backend services...${NC}"
systemctl start gunicorn daphne celery

# Wait for services to start
sleep 3

# Check status
echo ""
echo -e "${GREEN}Service Status:${NC}"
echo ""
systemctl status gunicorn --no-pager -l | head -5
echo ""
systemctl status daphne --no-pager -l | head -5
echo ""
systemctl status celery --no-pager -l | head -5

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Backend deployment complete!${NC}"
echo -e "${GREEN}========================================${NC}"
