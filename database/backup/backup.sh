#!/bin/bash
BACKUP_DIR="database/backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME="$BACKUP_DIR/hospital_backup_$TIMESTAMP.dump"

echo "Dang sao luu CSDL hospital..."
docker exec -t hospital_postgres pg_dump -U postgres -F c hospital > "$FILENAME"
echo "Sao luu thanh cong: $FILENAME"
