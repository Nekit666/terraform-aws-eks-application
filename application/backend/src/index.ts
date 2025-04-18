import express, { Express, Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
// import dbConfig from './config'; // Import DB config if you set it up

dotenv.config(); // Load environment variables from .env file

const app: Express = express();
const port = process.env.PORT || 8080;

// Middleware
app.use(cors()); // Enable CORS for all origins (adjust as needed for security)
app.use(express.json()); // Parse JSON request bodies
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded request bodies

// Simple Route
app.get('/', (req: Request, res: Response) => {
  res.json({ message: 'Welcome to JustEasyLearn backend API!' });
});

// Health Check Route
app.get('/health', (req: Request, res: Response) => {
  res.status(200).send('OK');
});

// Add your API routes here
// Example: app.use('/api/users', require('./routes/userRoutes'));

// Database Connection (Example - uncomment and adapt when DB is ready)
/*
import { Sequelize } from 'sequelize';
const sequelize = new Sequelize(dbConfig.database, dbConfig.user, dbConfig.password, {
  host: dbConfig.host,
  dialect: dbConfig.dialect,
});

sequelize.authenticate()
  .then(() => {
    console.log('Database connection has been established successfully.');
    // Start server only after DB connection is successful
    app.listen(port, () => {
      console.log(`[server]: Server is running at http://localhost:${port}`);
    });
  })
  .catch(err => {
    console.error('Unable to connect to the database:', err);
    process.exit(1); // Exit if DB connection fails
  });
*/

// Start server (use this if not waiting for DB connection above)
app.listen(port, () => {
  console.log(`[server]: Server is running at http://localhost:${port}`);
});

export default app; 