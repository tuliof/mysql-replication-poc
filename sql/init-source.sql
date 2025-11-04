-- Create replication user for the replica to connect
CREATE USER IF NOT EXISTS 'repl_user'@'%' IDENTIFIED BY 'repl_pass';
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';
FLUSH PRIVILEGES;

-- Use the demo database
USE demo_db;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create products table
CREATE TABLE IF NOT EXISTS products (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name),
    INDEX idx_price (price),
    INDEX idx_created_at (created_at),
    CONSTRAINT chk_price_positive CHECK (price >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create orders table (needed as parent for order_items)
CREATE TABLE IF NOT EXISTS orders (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create order_items table
CREATE TABLE IF NOT EXISTS order_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    quantity INT UNSIGNED NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_order_id (order_id),
    INDEX idx_product_id (product_id),
    INDEX idx_created_at (created_at),
    CONSTRAINT chk_quantity_positive CHECK (quantity > 0),
    CONSTRAINT chk_unit_price_positive CHECK (unit_price >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert mock data for users
INSERT INTO users (full_name, email) VALUES
    ('John Doe', 'john.doe@example.com'),
    ('Jane Smith', 'jane.smith@example.com'),
    ('Bob Johnson', 'bob.johnson@example.com'),
    ('Alice Williams', 'alice.williams@example.com'),
    ('Charlie Brown', 'charlie.brown@example.com');

-- Insert mock data for products
INSERT INTO products (name, price, currency) VALUES
    ('Laptop Pro 15"', 1299.99, 'USD'),
    ('Wireless Mouse', 29.99, 'USD'),
    ('Mechanical Keyboard', 89.99, 'USD'),
    ('USB-C Hub', 49.99, 'USD'),
    ('Monitor 27"', 399.99, 'USD'),
    ('Laptop Stand', 39.99, 'USD'),
    ('Webcam HD', 79.99, 'USD'),
    ('Desk Lamp LED', 34.99, 'USD'),
    ('Ergonomic Chair', 299.99, 'USD'),
    ('Phone Case', 19.99, 'USD');

-- Insert mock data for orders
INSERT INTO orders (user_id, total_amount, status) VALUES
    (1, 1419.97, 'completed'),
    (2, 169.97, 'completed'),
    (3, 499.98, 'pending'),
    (4, 129.98, 'completed'),
    (5, 734.97, 'shipped');

-- Insert mock data for order_items
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
    -- Order 1: John's order
    (1, 1, 1, 1299.99),
    (1, 2, 2, 29.99),
    (1, 4, 1, 49.99),
    -- Order 2: Jane's order
    (2, 3, 1, 89.99),
    (2, 7, 1, 79.99),
    -- Order 3: Bob's order
    (3, 5, 1, 399.99),
    (3, 6, 1, 39.99),
    (3, 2, 2, 29.99),
    -- Order 4: Alice's order
    (4, 10, 2, 19.99),
    (4, 8, 1, 34.99),
    (4, 4, 1, 49.99),
    -- Order 5: Charlie's order
    (5, 1, 1, 1299.99),
    (5, 9, 1, 299.99),
    (5, 3, 1, 89.99),
    (5, 6, 1, 39.99);

-- Display summary
SELECT 'Database initialization completed' AS status;
SELECT COUNT(*) AS user_count FROM users;
SELECT COUNT(*) AS product_count FROM products;
SELECT COUNT(*) AS order_count FROM orders;
SELECT COUNT(*) AS order_item_count FROM order_items;
