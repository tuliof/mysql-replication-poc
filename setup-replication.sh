#!/bin/bash

# Setup MySQL Replication with GTID
# This script configures the replica to replicate from the source

set -e

echo "Waiting for MySQL source to be ready..."
sleep 10

echo "Creating backup of source database with GTID position..."
docker exec mysql-source mysqldump -uroot -prootpass \
    --all-databases \
    --single-transaction \
    --triggers \
    --routines \
    --events \
    --set-gtid-purged=ON \
    > /tmp/source_backup.sql

echo "Waiting for replica to be ready..."
sleep 10

echo "Restoring backup to replica..."
docker exec -i mysql-replica mysql -uroot -prootpass < /tmp/source_backup.sql

echo "Configuring replication on replica..."
docker exec -i mysql-replica mysql -uroot -prootpass <<'EOF'
-- Stop any existing replication
STOP REPLICA;

-- Reset replica to clear any previous state
RESET REPLICA ALL;

-- Configure the source connection
CHANGE REPLICATION SOURCE TO
    SOURCE_HOST='mysql-source',
    SOURCE_PORT=3306,
    SOURCE_USER='repl_user',
    SOURCE_PASSWORD='repl_pass',
    SOURCE_AUTO_POSITION=1,
    GET_SOURCE_PUBLIC_KEY=1;

-- Start replication
START REPLICA;

-- Enable super read-only mode on the replica
SET GLOBAL super_read_only = ON;

-- Show replica status
SHOW REPLICA STATUS\G
EOF

echo ""
echo "Replication setup completed!"
echo ""
echo "To check replication status, run:"
echo "docker exec mysql-replica mysql -uroot -prootpass -e 'SHOW REPLICA STATUS\G'"
echo ""
echo "To test replication, insert data on source:"
echo "docker exec mysql-source mysql -uroot -prootpass demo_db -e \"INSERT INTO users (full_name, email) VALUES ('Test User', 'test@example.com');\""
echo "Then verify on replica:"
echo "docker exec mysql-replica mysql -uroot -prootpass demo_db -e \"SELECT * FROM users WHERE email = 'test@example.com';\""

