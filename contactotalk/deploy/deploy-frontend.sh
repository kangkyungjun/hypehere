#!/bin/bash

#################################################################
# Contactotalk Frontend Deployment Script
#
# This script updates only the Next.js frontend
# Usage: sudo bash deploy-frontend.sh
#################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FRONTEND_DIR="/home/ubuntu/contactotalk-frontend"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Contactotalk Frontend Deployment${NC}"
echo -e "${GREEN}========================================${NC}"

# Stop Next.js service
echo -e "${YELLOW}[1/4] Stopping Next.js service...${NC}"
systemctl stop nextjs

# Update code
echo -e "${YELLOW}[2/4] Updating frontend code...${NC}"
cd $FRONTEND_DIR

# Install/update dependencies
npm install

# Build Next.js
echo -e "${YELLOW}[3/4] Building Next.js...${NC}"
npm run build

# Start service
echo -e "${YELLOW}[4/4] Starting Next.js service...${NC}"
systemctl start nextjs

# Wait for service to start
sleep 3

# Check status
echo ""
echo -e "${GREEN}Service Status:${NC}"
echo ""
systemctl status nextjs --no-pager -l | head -10

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Frontend deployment complete!${NC}"
echo -e "${GREEN}========================================${NC}"
