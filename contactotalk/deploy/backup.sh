#!/bin/bash

#################################################################
# Contactotalk Database Backup Script
#
# This script creates a backup of the PostgreSQL database
# Usage: sudo bash backup.sh
#
# Backups are stored in: /home/ubuntu/backups/
# Retention: Last 7 days (older backups automatically deleted)
#################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
BACKUP_DIR="/home/ubuntu/backups"
DB_NAME="contactotalk"
DB_USER="contactotalk"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql.gz"
RETENTION_DAYS=7

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Contactotalk Database Backup${NC}"
echo -e "${GREEN}========================================${NC}"

# Create backup directory if it doesn't exist
echo -e "${YELLOW}[1/4] Preparing backup directory...${NC}"
mkdir -p $BACKUP_DIR

# Backup database
echo -e "${YELLOW}[2/4] Backing up database...${NC}"
echo -e "Database: ${GREEN}$DB_NAME${NC}"
echo -e "Backup file: ${GREEN}$BACKUP_FILE${NC}"

sudo -u postgres pg_dump $DB_NAME | gzip > $BACKUP_FILE

# Check if backup was successful
if [ -f "$BACKUP_FILE" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo -e "${GREEN}✓ Backup created successfully (Size: $BACKUP_SIZE)${NC}"
else
    echo -e "${RED}✗ Backup failed${NC}"
    exit 1
fi

# Remove old backups
echo -e "${YELLOW}[3/4] Cleaning up old backups...${NC}"
echo -e "Retention period: ${GREEN}${RETENTION_DAYS} days${NC}"

find $BACKUP_DIR -name "${DB_NAME}_*.sql.gz" -mtime +$RETENTION_DAYS -delete

REMAINING_BACKUPS=$(ls -1 $BACKUP_DIR/${DB_NAME}_*.sql.gz 2>/dev/null | wc -l)
echo -e "${GREEN}✓ Cleanup complete (${REMAINING_BACKUPS} backups remaining)${NC}"

# List all backups
echo -e "${YELLOW}[4/4] Current backups:${NC}"
echo ""
ls -lh $BACKUP_DIR/${DB_NAME}_*.sql.gz 2>/dev/null || echo "No backups found"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Backup complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}To restore from this backup:${NC}"
echo -e "gunzip < $BACKUP_FILE | sudo -u postgres psql $DB_NAME"
echo ""
echo -e "${YELLOW}To automate daily backups, add to crontab:${NC}"
echo -e "0 2 * * * /home/ubuntu/contactotalk/deploy/backup.sh > /var/log/backup.log 2>&1"
