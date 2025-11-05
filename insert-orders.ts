import mysql from "mysql2/promise";

// Configuration
const DB_CONFIG = {
	host: process.env.MYSQL_HOST || "localhost",
	port: Number.parseInt(process.env.MYSQL_PORT || "3306", 10),
	user: process.env.MYSQL_USER || "demo_user",
	password: process.env.MYSQL_PASSWORD || "demo_pass",
	database: process.env.MYSQL_DATABASE || "demo_db",
};

const INSERT_INTERVAL_MS = Number.parseInt(
	process.env.INSERT_INTERVAL_MS || "5000",
	10,
); // Default: 5 seconds

// Order status options
const ORDER_STATUSES = ["pending", "processing", "shipped", "completed"];

/**
 * Get a random element from an array
 */
function getRandomElement<T>(array: T[]): T {
	if (array.length === 0) {
		throw new Error("Cannot get random element from empty array");
	}
	return array[Math.floor(Math.random() * array.length)] as T;
}

/**
 * Get a random integer between min and max (inclusive)
 */
function getRandomInt(min: number, max: number): number {
	return Math.floor(Math.random() * (max - min + 1)) + min;
}

/**
 * Fetch all users from the database
 */
async function getUsers(connection: mysql.Connection): Promise<number[]> {
	const [rows] = await connection.query("SELECT id FROM users");
	return (rows as Array<{ id: number }>).map((row) => row.id);
}

/**
 * Fetch all products from the database
 */
async function getProducts(
	connection: mysql.Connection,
): Promise<Array<{ id: number; price: number }>> {
	const [rows] = await connection.query("SELECT id, price FROM products");
	// Convert price from string to number
	return (rows as Array<{ id: number; price: string }>).map((row) => ({
		id: row.id,
		price: Number.parseFloat(row.price),
	}));
}

/**
 * Insert a new order with random items
 */
async function insertOrder(
	connection: mysql.Connection,
	userIds: number[],
	products: Array<{ id: number; price: number }>,
): Promise<void> {
	// Select a random user
	const userId = getRandomElement(userIds);

	// Select random products (1-5 items, but not more than available products)
	const numberOfItems = Math.min(getRandomInt(1, 5), products.length);
	const selectedProducts = [];
	const usedProductIds = new Set<number>();

	for (let i = 0; i < numberOfItems; i++) {
		let product = getRandomElement(products);
		// Avoid duplicates in the same order
		while (
			usedProductIds.has(product.id) &&
			usedProductIds.size < products.length
		) {
			product = getRandomElement(products);
		}
		usedProductIds.add(product.id);
		selectedProducts.push(product);
	}

	// Calculate total amount
	let totalAmount = 0;
	const orderItems = selectedProducts.map((product) => {
		const quantity = getRandomInt(1, 3);
		const itemTotal = product.price * quantity;
		totalAmount += itemTotal;
		return {
			productId: product.id,
			quantity,
			unitPrice: product.price,
		};
	});

	// Select a random status
	const status = getRandomElement(ORDER_STATUSES);

	try {
		await connection.beginTransaction();

		// Insert the order
		const [orderResult] = await connection.query(
			"INSERT INTO orders (user_id, total_amount, status) VALUES (?, ?, ?)",
			[userId, totalAmount.toFixed(2), status],
		);

		const orderId = (orderResult as mysql.ResultSetHeader).insertId;

		// Insert order items
		for (const item of orderItems) {
			await connection.query(
				"INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES (?, ?, ?, ?)",
				[orderId, item.productId, item.quantity, item.unitPrice.toFixed(2)],
			);
		}

		await connection.commit();

		const timestamp = new Date().toISOString();
		console.log(
			`[${timestamp}] ✓ Order #${orderId} created - User: ${userId}, Items: ${numberOfItems}, Total: $${totalAmount.toFixed(2)}, Status: ${status}`,
		);
	} catch (error) {
		await connection.rollback();
		console.error("Error inserting order:", error);
		throw error;
	}
}

/**
 * Main function to continuously insert orders
 */
async function main() {
	console.log("🚀 Starting order insertion script...");
	console.log(`📊 Configuration:`);
	console.log(`   - Host: ${DB_CONFIG.host}:${DB_CONFIG.port}`);
	console.log(`   - Database: ${DB_CONFIG.database}`);
	console.log(`   - User: ${DB_CONFIG.user}`);
	console.log(
		`   - Insert Interval: ${INSERT_INTERVAL_MS}ms (${INSERT_INTERVAL_MS / 1000}s)`,
	);
	console.log("");

	let connection: mysql.Connection | null = null;

	try {
		// Create database connection
		console.log("🔌 Connecting to MySQL...");
		connection = await mysql.createConnection(DB_CONFIG);
		console.log("✓ Connected to MySQL");
		console.log("");

		// Fetch users and products
		console.log("📦 Loading users and products...");
		const userIds = await getUsers(connection);
		const products = await getProducts(connection);
		console.log(
			`✓ Loaded ${userIds.length} users and ${products.length} products`,
		);
		console.log("");

		if (userIds.length === 0 || products.length === 0) {
			console.error(
				"❌ No users or products found in database. Please initialize the database first.",
			);
			process.exit(1);
		}

		console.log("🔄 Starting continuous order insertion...");
		console.log("   Press Ctrl+C to stop");
		console.log("");

		// Insert orders continuously
		while (true) {
			await insertOrder(connection, userIds, products);
			await Bun.sleep(INSERT_INTERVAL_MS);
		}
	} catch (error) {
		console.error("❌ Fatal error:", error);
		process.exit(1);
	} finally {
		if (connection) {
			await connection.end();
			console.log("\n🔌 Database connection closed");
		}
	}
}

// Handle graceful shutdown
process.on("SIGINT", () => {
	console.log("\n\n⏹️  Received SIGINT, shutting down gracefully...");
	process.exit(0);
});

process.on("SIGTERM", () => {
	console.log("\n\n⏹️  Received SIGTERM, shutting down gracefully...");
	process.exit(0);
});

// Run the script
main();
