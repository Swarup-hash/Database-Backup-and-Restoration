#!/bin/bash

# Database Backup and Restoration Script

# Configuration
BACKUP_DIR="/path/to/backup/directory"
MYSQL_USER="your_mysql_user"
MYSQL_PASSWORD="your_mysql_password"
MYSQL_DATABASE="your_mysql_database"
PGSQL_USER="your_pgsql_user"
PGSQL_DATABASE="your_pgsql_database"
ENCRYPTION_PASSWORD="your_encryption_password"
FULL_BACKUP_INTERVAL_DAYS=7

# Function to perform a full MySQL backup
full_mysql_backup() {
    echo "Performing full MySQL backup..."
    mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE | gzip | openssl enc -aes-256-cbc -salt -k $ENCRYPTION_PASSWORD > $BACKUP_DIR/mysql_full_$(date +%F).sql.gz.enc
    echo "Full MySQL backup completed."
}

# Function to perform an incremental MySQL backup
incremental_mysql_backup() {
    echo "Performing incremental MySQL backup..."
    mysqlbinlog --user=$MYSQL_USER --password=$MYSQL_PASSWORD --read-from-remote-server --raw --stop-never mysql-bin.000001 | gzip | openssl enc -aes-256-cbc -salt -k $ENCRYPTION_PASSWORD > $BACKUP_DIR/mysql_incremental_$(date +%F_%T).sql.gz.enc
    echo "Incremental MySQL backup completed."
}

# Function to restore a MySQL backup
restore_mysql_backup() {
    read -p "Enter the path to the MySQL backup file: " backup_file
    gunzip < $backup_file | openssl enc -aes-256-cbc -d -k $ENCRYPTION_PASSWORD | mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE
    echo "MySQL backup restored."
}

# Function to perform a full PostgreSQL backup
full_pgsql_backup() {
    echo "Performing full PostgreSQL backup..."
    pg_dump -U $PGSQL_USER $PGSQL_DATABASE | gzip | openssl enc -aes-256-cbc -salt -k $ENCRYPTION_PASSWORD > $BACKUP_DIR/pgsql_full_$(date +%F).sql.gz.enc
    echo "Full PostgreSQL backup completed."
}

# Function to perform an incremental PostgreSQL backup
incremental_pgsql_backup() {
    echo "Performing incremental PostgreSQL backup..."
    pg_basebackup -U $PGSQL_USER -D $BACKUP_DIR/pgsql_incremental_$(date +%F_%T) -Ft -z -P --wal-method=stream
    echo "Incremental PostgreSQL backup completed."
}

# Function to restore a PostgreSQL backup
restore_pgsql_backup() {
    read -p "Enter the path to the PostgreSQL backup file: " backup_file
    gunzip < $backup_file | openssl enc -aes-256-cbc -d -k $ENCRYPTION_PASSWORD | psql -U $PGSQL_USER $PGSQL_DATABASE
    echo "PostgreSQL backup restored."
}

# Function to check the integrity of a backup file
check_backup_integrity() {
    read -p "Enter the path to the backup file: " backup_file
    openssl enc -aes-256-cbc -d -k $ENCRYPTION_PASSWORD -in $backup_file -out /dev/null
    if [ $? -eq 0 ]; then
        echo "Backup file integrity check passed."
    else
        echo "Backup file integrity check failed."
    fi
}

# Main menu
while true; do
    echo "Database Backup and Restoration Script"
    echo "1. Full MySQL Backup"
    echo "2. Incremental MySQL Backup"
    echo "3. Restore MySQL Backup"
    echo "4. Full PostgreSQL Backup"
    echo "5. Incremental PostgreSQL Backup"
    echo "6. Restore PostgreSQL Backup"
    echo "7. Check Backup Integrity"
    echo "8. Exit"
    read -p "Choose an option (1-8): " choice

    case $choice in
        1) full_mysql_backup ;;
        2) incremental_mysql_backup ;;
        3) restore_mysql_backup ;;
        4) full_pgsql_backup ;;
        5) incremental_pgsql_backup ;;
        6) restore_pgsql_backup ;;
        7) check_backup_integrity ;;
        8) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option, please try again." ;;
    esac
done
