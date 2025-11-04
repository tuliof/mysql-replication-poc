# MySQL 8 Read Replica with GTID Demo

This project demonstrates MySQL 8 replication using GTID (Global Transaction Identifier) with a source-replica setup.

## Architecture

- **Source (Master)**: MySQL 8 instance running on port 3306
- **Replica (Slave)**: MySQL 8 instance running on port 3307
- **Replication Mode**: GTID-based replication with ROW binlog format

## Features

- ✅ GTID-based replication for automatic failover support
- ✅ Complete database schema with foreign keys and indexes
- ✅ Mock data for testing
- ✅ Health checks for both instances
- ✅ Read-only replica configuration

## Database Schema

The demo includes the following tables:

### users
- `id` (BIGINT UNSIGNED, PRIMARY KEY, AUTO_INCREMENT)
- `full_name` (VARCHAR(255), NOT NULL)
- `email` (VARCHAR(255), NOT NULL, UNIQUE)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

### products
- `id` (BIGINT UNSIGNED, PRIMARY KEY, AUTO_INCREMENT)
- `name` (VARCHAR(255), NOT NULL)
- `price` (DECIMAL(10,2), NOT NULL)
- `currency` (VARCHAR(3), DEFAULT 'USD')
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

### orders
- `id` (BIGINT UNSIGNED, PRIMARY KEY, AUTO_INCREMENT)
- `user_id` (BIGINT UNSIGNED, NOT NULL, FOREIGN KEY)
- `total_amount` (DECIMAL(10,2), NOT NULL)
- `status` (VARCHAR(50), DEFAULT 'pending')
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

### order_items
- `id` (BIGINT UNSIGNED, PRIMARY KEY, AUTO_INCREMENT)
- `order_id` (BIGINT UNSIGNED, NOT NULL, FOREIGN KEY)
- `product_id` (BIGINT UNSIGNED, NOT NULL, FOREIGN KEY)
- `quantity` (INT UNSIGNED, NOT NULL)
- `unit_price` (DECIMAL(10,2), NOT NULL)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

## Prerequisites

- Docker
- Docker Compose

## Quick Start

### 1. Start the MySQL instances

```bash
docker-compose up -d
```

This will start both the source and replica MySQL instances. The source will automatically initialize with the schema and mock data.

### 2. Set up replication

Wait for the containers to be fully ready (about 20-30 seconds), then run:

```bash
./setup-replication.sh
```

This script configures the replica to start replicating from the source using GTID.

### 3. Verify replication status

Check the replica status:

```bash
docker exec mysql-replica mysql -uroot -prootpass -e "SHOW REPLICA STATUS\G"
```

Look for:
- `Replica_IO_Running: Yes`
- `Replica_SQL_Running: Yes`
- `Retrieved_Gtid_Set` and `Executed_Gtid_Set` should show GTID values

### 4. Test replication

**Insert data on the source:**

```bash
docker exec mysql-source mysql -uroot -prootpass demo_db -e "
INSERT INTO users (full_name, email) VALUES ('Test User', 'test@example.com');
SELECT * FROM users WHERE email = 'test@example.com';
"
```

**Verify on the replica:**

```bash
docker exec mysql-replica mysql -uroot -prootpass demo_db -e "
SELECT * FROM users WHERE email = 'test@example.com';
"
```

The new user should appear on the replica within seconds.

## Accessing the Databases

### Source Database
```bash
docker exec -it mysql-source mysql -uroot -prootpass demo_db
```

### Replica Database
```bash
docker exec -it mysql-replica mysql -uroot -prootpass demo_db
```

### Connection Details

**Source:**
- Host: localhost
- Port: 3306
- Database: demo_db
- User: demo_user / root
- Password: demo_pass / rootpass

**Replica:**
- Host: localhost
- Port: 3307
- Database: demo_db
- User: demo_user / root
- Password: demo_pass / rootpass

## Monitoring Replication

### Check GTID Status

**On source:**
```bash
docker exec mysql-source mysql -uroot -prootpass -e "SHOW MASTER STATUS\G"
```

**On replica:**
```bash
docker exec mysql-replica mysql -uroot -prootpass -e "SHOW REPLICA STATUS\G"
```

### View Binary Logs

```bash
docker exec mysql-source mysql -uroot -prootpass -e "SHOW BINARY LOGS;"
```

### Check Replication Lag

```bash
docker exec mysql-replica mysql -uroot -prootpass -e "
SELECT 
    CASE 
        WHEN LAST_APPLIED_TRANSACTION = '' THEN 0 
        ELSE GTID_SUBTRACT(RECEIVED_TRANSACTION_SET, LAST_APPLIED_TRANSACTION) 
    END AS replication_lag 
FROM performance_schema.replication_connection_status;
"
```

## Troubleshooting

### Replication not starting

1. Check if both containers are healthy:
```bash
docker-compose ps
```

2. Check container logs:
```bash
docker-compose logs mysql-source
docker-compose logs mysql-replica
```

3. Verify GTID is enabled:
```bash
docker exec mysql-source mysql -uroot -prootpass -e "SHOW VARIABLES LIKE 'gtid_mode';"
docker exec mysql-replica mysql -uroot -prootpass -e "SHOW VARIABLES LIKE 'gtid_mode';"
```

### Reset replication

If you need to reset and reconfigure replication:

```bash
docker exec mysql-replica mysql -uroot -prootpass -e "STOP REPLICA; RESET REPLICA ALL;"
./setup-replication.sh
```

## Stopping and Cleaning Up

### Stop the containers
```bash
docker-compose down
```

### Remove volumes (WARNING: This deletes all data)
```bash
docker-compose down -v
```

## File Structure

```
.
├── docker-compose.yml          # Docker Compose configuration
├── mysql-config/
│   ├── source.cnf             # Source MySQL configuration (GTID enabled)
│   └── replica.cnf            # Replica MySQL configuration (GTID enabled)
├── sql/
│   └── init-source.sql        # Database schema and mock data
├── setup-replication.sh       # Script to configure replication
└── README.md                  # This file
```

## Notes

- The replica is configured as read-only (`super-read-only = ON`)
- GTID mode enables automatic positioning for failover scenarios
- Binary logs are retained for 10 days on the source
- The source creates a replication user (`repl_user`) automatically
- Mock data includes 5 users, 10 products, 5 orders, and 15 order items

## Learn More

- [MySQL 8 Replication Documentation](https://dev.mysql.com/doc/refman/8.0/en/replication.html)
- [MySQL GTID Documentation](https://dev.mysql.com/doc/refman/8.0/en/replication-gtids.html)
