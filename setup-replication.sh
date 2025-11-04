#!/bin/bash

# Setup MySQL Replication with GTID
# This script configures the replica to replicate from the source

set -e

echo "Waiting for MySQL source to be ready..."
sleep 15

echo "Configuring replication on replica..."

# Configure the replica to connect to the source
docker exec -i mysql-replica mysql -uroot -prootpass <<'EOF'
-- Stop any existing replication
STOP REPLICA;

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

-- Show replica status
SHOW REPLICA STATUS\G
EOF

echo ""
echo "Replication setup completed!"
echo ""
echo "To check replication status, run:"
echo "docker exec mysql-replica mysql -uroot -prootpass -e 'SHOW REPLICA STATUS\G'"
