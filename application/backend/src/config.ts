// This file holds database configuration.
// It reads sensitive information from environment variables.

// Make sure to set these environment variables in your deployment (e.g., via Kubernetes Secrets)
// and potentially in a .env file for local development (add .env to .gitignore).

const dbConfig = {
  host: process.env.DB_HOST || 'localhost',        // Default to localhost for local dev
  user: process.env.DB_USER || 'user',
  password: process.env.DB_PASSWORD || 'password',
  database: process.env.DB_NAME || 'mydatabase',
  port: parseInt(process.env.DB_PORT || '3306', 10), // Default MySQL/MariaDB port
  dialect: 'mysql' as const, // Change to 'postgres', 'sqlite', 'mariadb', 'mssql' as needed

  // Example for Sequelize connection pooling (optional)
  pool: {
    max: 5,     // Maximum number of connection in pool
    min: 0,     // Minimum number of connection in pool
    acquire: 30000, // The maximum time, in milliseconds, that pool will try to get connection before throwing error
    idle: 10000     // The maximum time, in milliseconds, that a connection can be idle before being released
  }
};

export default dbConfig; 