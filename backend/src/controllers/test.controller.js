const { query } = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');
const { successResponse } = require('../utils/response');

exports.testdb = asyncHandler(async (req, res) => {
  const startTime = Date.now();
  const [dbResult, timeResult, customerCountResult, stationCountResult, versionResult, sampleCustomersResult] = await Promise.all([
    query(`SELECT DB_NAME() AS DatabaseName`).catch(() => ({ recordset: [{ DatabaseName: 'ERROR' }] })),
    query(`SELECT GETDATE() AS ServerTime`).catch(() => ({ recordset: [{ ServerTime: new Date() }] })),
    query(`SELECT COUNT(*) AS CustomerCount FROM Users.[User] WHERE Role = 'Customer'`).catch(() => ({ recordset: [{ CustomerCount: 0 }] })),
    query(`SELECT COUNT(*) AS StationCount FROM Infrastructure.ChargingStation WHERE IsActive = 1`).catch(() => ({ recordset: [{ StationCount: 0 }] })),
    query(`SELECT @@VERSION AS SqlVersion`).catch(() => ({ recordset: [{ SqlVersion: 'Unknown' }] })),
    query(`SELECT TOP 5 u.UserID, u.FullName, u.Email FROM Users.[User] u WHERE u.Role = 'Customer'`).catch(() => ({ recordset: [] })),
  ]);
  const queryExecutionTime = Date.now() - startTime;
  res.json(successResponse({
    database: dbResult.recordset[0]?.DatabaseName,
    serverTime: timeResult.recordset[0]?.ServerTime?.toISOString?.() || new Date().toISOString(),
    customerCount: customerCountResult.recordset[0]?.CustomerCount || 0,
    stationCount: stationCountResult.recordset[0]?.StationCount || 0,
    sqlServerVersion: (versionResult.recordset[0]?.SqlVersion || '').split('\n')[0],
    sampleCustomers: sampleCustomersResult.recordset || [],
    queryExecutionTime: `${queryExecutionTime}ms`,
  }, 'Database connection successful'));
});

exports.customers = asyncHandler(async (req, res) => {
  const result = await query(
    `SELECT TOP 10 u.UserID, u.Email, u.Phone, u.AccountStatus, u.FullName, u.CreatedAt
     FROM [Users].[User] u WHERE u.Role = 'Customer' ORDER BY u.UserID`
  );
  res.json(successResponse(result.recordset, 'Customers retrieved'));
});

exports.stations = asyncHandler(async (req, res) => {
  const result = await query(
    `SELECT TOP 10 StationID, StationCode, StationName, StationStatus, Latitude, Longitude, CreatedAt
     FROM [Infrastructure].[ChargingStation] WHERE IsActive = 1 ORDER BY StationID`
  );
  res.json(successResponse(result.recordset, 'Stations retrieved'));
});

exports.protected = asyncHandler(async (req, res) => {
  // Only return safe subset of user data
  const safeUser = req.user ? {
    UserID: req.user.UserID,
    Email: req.user.Email,
    Role: req.user.Role,
    FullName: req.user.FullName,
  } : null;
  res.json(successResponse({
    message: 'You have accessed a protected route',
    user: safeUser,
    timestamp: new Date().toISOString(),
  }, 'Protected route accessed successfully'));
});

exports.databaseInfo = asyncHandler(async (req, res) => {
  const startTime = Date.now();
  const [dbResult, timeResult, versionResult] = await Promise.all([
    query(`SELECT DB_NAME() AS DatabaseName`).catch(() => ({ recordset: [{ DatabaseName: 'ERROR' }] })),
    query(`SELECT GETDATE() AS ServerTime`).catch(() => ({ recordset: [{ ServerTime: new Date() }] })),
    query(`SELECT @@VERSION AS SqlVersion`).catch(() => ({ recordset: [{ SqlVersion: 'Unknown' }] })),
  ]);
  const queryExecutionTime = Date.now() - startTime;
  res.json(successResponse({
    database: dbResult.recordset[0]?.DatabaseName,
    serverTime: timeResult.recordset[0]?.ServerTime?.toISOString?.() || new Date().toISOString(),
    sqlServerVersion: (versionResult.recordset[0]?.SqlVersion || '').split('\n')[0],
    queryExecutionTime: `${queryExecutionTime}ms`,
  }, 'Database info retrieved'));
});
