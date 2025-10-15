#!/bin/bash

#################################################################
# Contactotalk AWS EC2 Server Setup Script
#
# This script automatically installs and configures:
# - Python 3.11, Node.js 18
# - PostgreSQL, Redis
# - Nginx, SSL (Let's Encrypt)
# - Django, Next.js, Gunicorn, Daphne, Celery
#
# Usage: sudo bash setup-server.sh your-domain.com
#################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Check domain argument
if [ -z "$1" ]; then
    echo -e "${RED}Usage: sudo bash setup-server.sh your-domain.com${NC}"
    exit 1
fi

DOMAIN=$1
PROJECT_DIR="/home/ubuntu/contactotalk"
FRONTEND_DIR="/home/ubuntu/contactotalk-frontend"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Contactotalk Server Setup${NC}"
echo -e "${GREEN}Domain: $DOMAIN${NC}"
echo -e "${GREEN}========================================${NC}"

# Update system
echo -e "${YELLOW}[1/12] Updating system packages...${NC}"
apt update && apt upgrade -y

# Install essential packages
echo -e "${YELLOW}[2/12] Installing essential packages...${NC}"
apt install -y \
    build-essential \
    git \
    curl \
    wget \
    vim \
    software-properties-common \
    certbot \
    python3-certbot-nginx

# Install Python 3.11
echo -e "${YELLOW}[3/12] Installing Python 3.11...${NC}"
add-apt-repository ppa:deadsnakes/ppa -y
apt update
apt install -y python3.11 python3.11-venv python3.11-dev python3-pip

# Install PostgreSQL
echo -e "${YELLOW}[4/12] Installing PostgreSQL...${NC}"
apt install -y postgresql postgresql-contrib

# Configure PostgreSQL
echo -e "${YELLOW}Configuring PostgreSQL database...${NC}"
sudo -u postgres psql <<EOF
CREATE DATABASE contactotalk;
CREATE USER contactotalk WITH PASSWORD 'contactotalk_password_123';
ALTER ROLE contactotalk SET client_encoding TO 'utf8';
ALTER ROLE contactotalk SET default_transaction_isolation TO 'read committed';
ALTER ROLE contactotalk SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE contactotalk TO contactotalk;
\q
EOF

# Install Redis
echo -e "${YELLOW}[5/12] Installing Redis...${NC}"
apt install -y redis-server
systemctl enable redis-server
systemctl start redis-server

# Install Node.js 18
echo -e "${YELLOW}[6/12] Installing Node.js 18...${NC}"
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Install Nginx
echo -e "${YELLOW}[7/12] Installing Nginx...${NC}"
apt install -y nginx
systemctl enable nginx

# Clone repositories (if not exists)
echo -e "${YELLOW}[8/12] Setting up project directories...${NC}"
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Please upload your Django project to $PROJECT_DIR${NC}"
    echo -e "${RED}Then run this script again${NC}"
    exit 1
fi

if [ ! -d "$FRONTEND_DIR" ]; then
    echo -e "${RED}Please upload your Next.js project to $FRONTEND_DIR${NC}"
    echo -e "${RED}Then run this script again${NC}"
    exit 1
fi

# Setup Django Backend
echo -e "${YELLOW}[9/12] Setting up Django backend...${NC}"
cd $PROJECT_DIR

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install Python dependencies
pip install --upgrade pip
pip install -r requirements.production.txt

# Create .env.production file
if [ ! -f ".env.production" ]; then
    cp .env.production.example .env.production
    echo -e "${YELLOW}Please edit $PROJECT_DIR/.env.production with your settings${NC}"
    read -p "Press enter when done..."
fi

# Django setup
export DJANGO_ENV=production
python manage.py collectstatic --noinput
python manage.py migrate

# Create logs directory
mkdir -p logs

# Setup Next.js Frontend
echo -e "${YELLOW}[10/12] Setting up Next.js frontend...${NC}"
cd $FRONTEND_DIR

# Install Node dependencies
npm install

# Create .env.production file
if [ ! -f ".env.production" ]; then
    cp .env.production.example .env.production
    sed -i "s/your-domain.com/$DOMAIN/g" .env.production
fi

# Build Next.js
npm run build

# Configure Nginx
echo -e "${YELLOW}[11/12] Configuring Nginx...${NC}"
cp $PROJECT_DIR/deploy/nginx.conf /etc/nginx/sites-available/contactotalk
sed -i "s/your-domain.com/$DOMAIN/g" /etc/nginx/sites-available/contactotalk

# Remove default nginx site
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/contactotalk /etc/nginx/sites-enabled/

# Test nginx configuration
nginx -t

# Setup systemd services
echo -e "${YELLOW}[12/12] Setting up systemd services...${NC}"

# Copy service files
cp $PROJECT_DIR/deploy/gunicorn.service /etc/systemd/system/
cp $PROJECT_DIR/deploy/daphne.service /etc/systemd/system/
cp $PROJECT_DIR/deploy/celery.service /etc/systemd/system/
cp $PROJECT_DIR/deploy/nextjs.service /etc/systemd/system/

# Reload systemd
systemctl daemon-reload

# Enable and start services
systemctl enable gunicorn daphne celery nextjs nginx
systemctl start gunicorn daphne celery nextjs

# Reload Nginx
systemctl reload nginx

# Setup SSL with Let's Encrypt
echo -e "${YELLOW}Setting up SSL certificate...${NC}"
certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN

# Setup automatic certificate renewal
systemctl enable certbot.timer

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Server setup complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Your application is now running at:${NC}"
echo -e "${GREEN}https://$DOMAIN${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Update DNS records to point to this server's IP"
echo -e "2. Create Django superuser: cd $PROJECT_DIR && source venv/bin/activate && python manage.py createsuperuser"
echo -e "3. Access admin panel: https://$DOMAIN/admin"
echo -e "${GREEN}========================================${NC}"

# Show service status
echo -e "${YELLOW}Service Status:${NC}"
systemctl status gunicorn --no-pager -l
systemctl status daphne --no-pager -l
systemctl status nginx --no-pager -l
