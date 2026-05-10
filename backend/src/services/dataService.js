const { query } = require('../config/db');

exports.getFranchisees = async () => {
  const r = await query(`SELECT FranchiseID, FranchiseName, TaxCode, ContactPerson, ContactPhone AS Phone, ContactEmail AS Email, RevenueShareRate, ContractSignedDate AS ContractDate FROM Infrastructure.Franchise WHERE IsActive = 1`);
  return r.recordset;
};

exports.getStations = async () => {
  const r = await query(`SELECT s.StationID, s.FranchiseID, s.StationName, a.FullAddress AS Address, s.StationStatus, s.Latitude, s.Longitude
    FROM Infrastructure.ChargingStation s LEFT JOIN Infrastructure.Address a ON s.AddressID = a.AddressID WHERE s.IsActive = 1`);
  return r.recordset;
};

exports.getPoints = async (stationId) => {
  let q = `SELECT PointID, StationID, PowerKW, ConnectorType, PointStatus FROM Infrastructure.ChargingPoint WHERE IsActive = 1`;
  const p = {};
  if (stationId) { q += ` AND StationID = @StationID`; p.StationID = stationId; }
  const r = await query(q, p);
  return r.recordset;
};

exports.getUserProfile = async (userId) => {
  const r = await query(`SELECT u.UserID, u.FullName, u.Email, u.Phone, u.Role, u.FranchiseID,
    COALESCE(w.Balance, 0) AS WalletBalance, u.AccountStatus
    FROM Users.[User] u
    LEFT JOIN Payments.Wallet w ON u.UserID = w.UserID
    WHERE u.UserID = @UserID`, { UserID: userId });
  return r.recordset[0] || null;
};

exports.getVehicles = async (userId) => {
  const r = await query(`SELECT VehicleID, UserID, PlateNumber, COALESCE(Brand, '') AS Brand, COALESCE(Model, '') AS Model,
    COALESCE(BatteryCapacityKWh, 0) AS BatteryCapacity_kWh, COALESCE(ConnectorType, 'CCS2') AS ConnectorType
    FROM Users.Vehicle WHERE UserID = @UserID AND IsActive = 1`, { UserID: userId });
  return r.recordset;
};

exports.addVehicle = async (userId, data) => {
  const r = await query(`INSERT INTO Users.Vehicle (UserID, PlateNumber, Brand, Model, BatteryCapacityKWh, ConnectorType)
    OUTPUT INSERTED.* VALUES (@UserID, @PlateNumber, @Brand, @Model, @Battery, @Connector)`,
    { UserID: userId, PlateNumber: data.PlateNumber, Brand: data.Brand || null,
      Model: data.Model || null, Battery: data.BatteryCapacity_kWh || null, Connector: data.ConnectorType || 'CCS2' });
  return r.recordset[0];
};

exports.deleteVehicle = async (vehicleId, userId) => {
  await query(`UPDATE Users.Vehicle SET IsActive = 0 WHERE VehicleID = @VehicleID AND UserID = @UserID`,
    { VehicleID: vehicleId, UserID: userId });
};

exports.getSessions = async (userId, limit = 10) => {
  const r = await query(`SELECT TOP (@Limit) SessionID, UserID, PointID, PolicyID, StartTime, EndTime,
    COALESCE(TotalKWh, 0) AS Total_kWh, COALESCE(CostTotal, 0) AS Cost_Total, SessionStatus AS Status
    FROM Operations.ChargingSession WHERE UserID = @UserID ORDER BY StartTime DESC`,
    { UserID: userId, Limit: limit });
  return r.recordset;
};

exports.getAllSessions = async () => {
  const r = await query(`SELECT TOP 50 SessionID, UserID, PointID, PolicyID, StartTime, EndTime,
    COALESCE(TotalKWh, 0) AS Total_kWh, COALESCE(CostTotal, 0) AS Cost_Total, SessionStatus AS Status
    FROM Operations.ChargingSession ORDER BY StartTime DESC`);
  return r.recordset;
};

exports.getWallet = async (userId) => {
  const r = await query(`SELECT WalletID, UserID, WalletCode, COALESCE(Balance, 0) AS Balance FROM Payments.Wallet WHERE UserID = @UserID`,
    { UserID: userId });
  return r.recordset[0] || null;
};

exports.getTransactions = async (userId, limit = 20) => {
  const r = await query(`SELECT TOP (@Limit) wt.WalletTransactionID AS TransactionID, w.UserID, NULL AS SessionID,
    wt.Amount, wt.TransactionType, wt.CreatedAt AS Timestamp
    FROM Payments.WalletTransaction wt JOIN Payments.Wallet w ON wt.WalletID = w.WalletID
    WHERE w.UserID = @UserID ORDER BY wt.CreatedAt DESC`, { UserID: userId, Limit: limit });
  return r.recordset;
};

exports.topUpWallet = async (userId, amount) => {
  const wallet = await this.getWallet(userId);
  if (!wallet) throw new Error('Wallet not found');
  const balanceBefore = wallet.Balance;
  await query(`UPDATE Payments.Wallet SET Balance = Balance + @Amount, LastTransactionAt = SYSDATETIME() WHERE UserID = @UserID`,
    { UserID: userId, Amount: amount });
  await query(`INSERT INTO Payments.WalletTransaction (WalletID, Amount, BalanceBefore, Direction, TransactionType, Description)
    VALUES (@WalletID, @Amount, @BalanceBefore, 'C', 'WalletTopUp', N'Nạp tiền qua ví')`,
    { WalletID: wallet.WalletID, Amount: amount, BalanceBefore: balanceBefore });
};

exports.getPricingPolicies = async () => {
  const r = await query(`SELECT PolicyID, PolicyName, BasePricePerKWh AS BasePrice_kWh, PeakMultiplier,
    AppliedFrom, COALESCE(AppliedTo, '9999-12-31') AS AppliedTo
    FROM Operations.PricingPolicy WHERE IsActive = 1`);
  return r.recordset;
};

exports.getDashboardStats = async (userId) => {
  const wallet = await this.getWallet(userId);
  const sessions = await this.getSessions(userId, 100);
  const totalKwh = sessions.reduce((s, x) => s + Number(x.Total_kWh || 0), 0);
  const totalSessions = sessions.length;
  const vehicles = await this.getVehicles(userId);
  return { WalletBalance: wallet ? Number(wallet.Balance) : 0, TotalKwh: totalKwh, TotalSessions: totalSessions, Vehicles: vehicles };
};

exports.getManagerDashboard = async () => {
  const stations = await this.getStations();
  const points = await this.getPoints();
  const totalStations = stations.length;
  const busyPoints = points.filter(p => p.PointStatus === 'Busy').length;
  const totalPoints = points.length;
  const sessions = await this.getAllSessions();
  const totalRevenue = sessions.reduce((s, x) => s + Number(x.Cost_Total || 0), 0);
  return { totalStations, busyPoints, totalPoints, totalRevenue };
};

exports.getUsers = async () => {
  const r = await query(`SELECT u.UserID, u.FullName, u.Email, u.Phone, u.Role,
    COALESCE(w.Balance, 0) AS WalletBalance, u.CreatedAt, u.AccountStatus
    FROM Users.[User] u LEFT JOIN Payments.Wallet w ON u.UserID = w.UserID
    ORDER BY u.CreatedAt DESC`);
  return r.recordset;
};

exports.updateProfile = async (userId, data) => {
  const fields = [];
  const params = { UserID: userId };
  if (data.FullName) { fields.push('FullName = @FullName'); params.FullName = data.FullName; }
  if (data.Phone) { fields.push('Phone = @Phone'); params.Phone = data.Phone; }
  if (data.Email) { fields.push('Email = @Email'); params.Email = data.Email; }
  if (fields.length > 0) {
    await query(`UPDATE Users.[User] SET ${fields.join(', ')}, UpdatedAt = SYSDATETIME() WHERE UserID = @UserID`, params);
  }
  return this.getUserProfile(userId);
};
