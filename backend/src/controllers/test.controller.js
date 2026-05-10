const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');
const { success } = require('../utils/response');

exports.testdb = asyncHandler(async (req, res) => {
  const startTime = Date.now();
  const [dbResult, timeResult, customerCountResult, stationCountResult, versionResult, sampleCustomersResult] = await Promise.all([
    query(`SELECT DB_NAME() AS DatabaseName`),
    query(`SELECT GETDATE() AS ServerTime`),
    query(`SELECT COUNT(*) AS CustomerCount FROM Users.[User] WHERE Role = 'Customer'`),
    query(`SELECT COUNT(*) AS StationCount FROM Infrastructure.ChargingStation WHERE IsActive = 1`),
    query(`SELECT @@VERSION AS SqlVersion`),
    query(`SELECT TOP 5 u.UserID, u.FullName, u.Email FROM Users.[User] u WHERE u.Role = 'Customer'`)
  ]);
  const queryExecutionTime = Date.now() - startTime;
  const responseData = {
    database: dbResult.recordset[0].DatabaseName,
    serverTime: timeResult.recordset[0].ServerTime.toISOString(),
    customerCount: customerCountResult.recordset[0].CustomerCount,
    stationCount: stationCountResult.recordset[0].StationCount,
    sqlServerVersion: versionResult.recordset[0].SqlVersion.split('\n')[0],
    sampleCustomers: sampleCustomersResult.recordset,
    queryExecutionTime: `${queryExecutionTime}ms`
  };
  console.log(`[TESTDB] Database connection successful`);
  res.json(success(responseData, 'Database connection successful'));
});

exports.customers = asyncHandler(async (req, res) => {
  const result = await query(
    `SELECT TOP 10 u.UserID, u.Email, u.Phone, u.AccountStatus, u.FullName, u.CreatedAt
     FROM [Users].[User] u
     WHERE u.Role = 'Customer'
     ORDER BY u.UserID`
  );
  res.json(success(result.recordset, 'Customers retrieved'));
});

exports.stations = asyncHandler(async (req, res) => {
  const result = await query(
    `SELECT TOP 10 StationID, StationCode, StationName, StationStatus, Latitude, Longitude, CreatedAt
     FROM [Infrastructure].[ChargingStation]
     WHERE IsActive = 1
     ORDER BY StationID`
  );
  res.json(success(result.recordset, 'Stations retrieved'));
});

exports.protected = asyncHandler(async (req, res) => {
  res.json(success({
    message: 'You have accessed a protected route',
    user: req.user,
    timestamp: new Date().toISOString(),
  }, 'Protected route accessed successfully'));
});

exports.databaseInfo = asyncHandler(async (req, res) => {
  const startTime = Date.now();
  const [dbResult, timeResult, versionResult] = await Promise.all([
    query(`SELECT DB_NAME() AS DatabaseName`),
    query(`SELECT GETDATE() AS ServerTime`),
    query(`SELECT @@VERSION AS SqlVersion`)
  ]);
  const queryExecutionTime = Date.now() - startTime;
  const responseData = {
    database: dbResult.recordset[0].DatabaseName,
    serverTime: timeResult.recordset[0].ServerTime.toISOString(),
    sqlServerVersion: versionResult.recordset[0].SqlVersion.split('\n')[0],
    queryExecutionTime: `${queryExecutionTime}ms`
  };
  console.log(`[DB-INFO] Database info retrieved in ${queryExecutionTime}ms`);
  res.json(success(responseData, 'Database info retrieved'));
});
