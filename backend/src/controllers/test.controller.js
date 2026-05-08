const { query } = require('../config/db');
const { asyncHandler } = require('../middleware/error.middleware');
const { success } = require('../utils/response');

exports.testdb = asyncHandler(async (req, res) => {
  const startTime = Date.now();
  
  // Execute all required queries in parallel
  const [
    dbResult,
    timeResult,
    customerCountResult,
    stationCountResult,
    versionResult,
    sampleCustomersResult
  ] = await Promise.all([
    query(`SELECT DB_NAME() AS DatabaseName`),
    query(`SELECT GETDATE() AS ServerTime`),
    query(`SELECT COUNT(*) AS CustomerCount FROM Users.[User]`),
    query(`SELECT COUNT(*) AS StationCount FROM Infrastructure.ChargingStation`),
    query(`SELECT @@VERSION AS SqlVersion`),
    query(`SELECT TOP 5 u.UserID, up.FullName, u.Email FROM Users.[User] u LEFT JOIN Users.UserProfile up ON u.UserID = up.UserID WHERE u.IsDeleted = 0`)
  ]);
  
  const queryExecutionTime = Date.now() - startTime;

  // Extract values from results
  const database = dbResult.recordset[0].DatabaseName;
  const serverTime = timeResult.recordset[0].ServerTime;
  const customerCount = customerCountResult.recordset[0].CustomerCount;
  const stationCount = stationCountResult.recordset[0].StationCount;
  const sqlServerVersion = versionResult.recordset[0].SqlVersion;
  const sampleCustomers = sampleCustomersResult.recordset;

  // Format response according to requirements
  const responseData = {
    database,
    serverTime: serverTime.toISOString(),
    customerCount,
    stationCount,
    sqlServerVersion: sqlServerVersion.split('\n')[0], // Get first line of version
    sampleCustomers,
    queryExecutionTime: `${queryExecutionTime}ms` // Bonus: query execution time
  };

  // Bonus: colored console logs
  console.log(`\x1b[32m[TESTDB] Database connection successful\x1b[0m`);
  console.log(`\x1b[34m[TESTDB] Database: \x1b[37m${database}\x1b[0m`);
  console.log(`\x1b[34m[TESTDB] Server Time: \x1b[37m${serverTime.toISOString()}\x1b[0m`);
  console.log(`\x1b[34m[TESTDB] Customer Count: \x1b[37m${customerCount}\x1b[0m`);
  console.log(`\x1b[34m[TESTDB] Station Count: \x1b[37m${stationCount}\x1b[0m`);
  console.log(`\x1b[34m[TESTDB] SQL Version: \x1b[37m${sqlServerVersion.split('\n')[0]}\x1b[0m`);
  console.log(`\x1b[34m[TESTDB] Query Execution Time: \x1b[37m${queryExecutionTime}ms\x1b[0m\n`);

  res.json(success(responseData, 'Database connection successful'));
});

exports.customers = asyncHandler(async (req, res) => {
  const result = await query(
    `SELECT TOP 10 u.UserID, u.Email, u.Phone, u.AccountStatus, u.CreatedAt,
            up.FullName
     FROM [Users].[User] u
     LEFT JOIN [Users].[UserProfile] up ON u.UserID = up.UserID
     WHERE u.IsDeleted = 0
     ORDER BY u.UserID`
  );
  res.json(success(result.recordset, 'Customers retrieved'));
});

exports.stations = asyncHandler(async (req, res) => {
  const result = await query(
    `SELECT TOP 10 StationID, StationCode, StationName, Address, Latitude, Longitude,
              Status, PowerCapacity, CreatedAt
     FROM [Infrastructure].[ChargingStation]
     WHERE IsDeleted = 0
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
  
  const [
    dbResult,
    timeResult,
    versionResult
  ] = await Promise.all([
    query(`SELECT DB_NAME() AS DatabaseName`),
    query(`SELECT GETDATE() AS ServerTime`),
    query(`SELECT @@VERSION AS SqlVersion`)
  ]);
  
  const queryExecutionTime = Date.now() - startTime;

  const responseData = {
    database: dbResult.recordset[0].DatabaseName,
    serverTime: timeResult.recordset[0].ServerTime.toISOString(),
    sqlServerVersion: versionResult.recordset[0].SqlVersion.split('\n')[0],
    queryExecutionTime: `${queryExecutionTime}ms` // Bonus: query execution time
  };

  // Bonus: colored console logs
  console.log(`\x1b[36m[DB-INFO] Database info retrieved in \x1b[37m${queryExecutionTime}ms\x1b[0m`);

  res.json(success(responseData, 'Database info retrieved'));
});