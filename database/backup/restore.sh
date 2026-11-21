#!/bin/bash
if [ -z "$1" ]; then
    echo "Su dung: ./restore.sh <duong-dan-file-dump>"
    exit 1
fi

echo "Dang phuc hoi CSDL tu $1..."
docker exec -i hospital_postgres pg_restore -U postgres -d hospital -c < "$1"
echo "Phuc hoi thanh cong!"
