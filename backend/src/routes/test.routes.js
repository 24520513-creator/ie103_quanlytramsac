const express = require('express');
const router = express.Router();
const testController = require('../controllers/test.controller');
const { verifyToken } = require('../middleware/auth.middleware');

/**
 * @swagger
 * /api/test/testdb:
 *   get:
 *     tags: [Test]
 *     summary: Test database connection
 *     responses:
 *       200:
 *         description: Database connection successful
 */
router.get('/testdb', testController.testdb);

/**
 * @swagger
 * /api/test/customers:
 *   get:
 *     tags: [Test]
 *     summary: Get top 10 customers
 *     responses:
 *       200:
 *         description: Customers retrieved
 */
router.get('/customers', testController.customers);

/**
 * @swagger
 * /api/test/stations:
 *   get:
 *     tags: [Test]
 *     summary: Get top 10 charging stations
 *     responses:
 *       200:
 *         description: Stations retrieved
 */
router.get('/stations', testController.stations);

/**
 * @swagger
 * /api/test/database-info:
 *   get:
 *     tags: [Test]
 *     summary: Get database information
 *     responses:
 *       200:
 *         description: Database info retrieved
 */
router.get('/database-info', testController.databaseInfo);

/**
 * @swagger
 * /api/test/protected:
 *   get:
 *     tags: [Test]
 *     summary: Test JWT-protected route
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: Protected route accessed
 *       401:
 *         description: Unauthorized
 */
router.get('/protected', verifyToken, testController.protected);

module.exports = router;
