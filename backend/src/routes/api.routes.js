const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { authenticate } = require('../middleware/auth');
const { query } = require('../config/db');
const { success } = require('../utils/response');
const authConfig = require('../config/auth');
const ds = require('../services/dataService');

// ===================== AUTH =====================

router.post('/auth/login', async (req, res, next) => {
  try {
    const { Email, Password } = req.body;
    const userResult = await query(`SELECT * FROM [Users].[User] WHERE (Email = @Email OR Username = @Email)`,
      { Email });
    if (userResult.recordset.length === 0) return res.status(401).json({ success: false, message: 'Invalid credentials' });
    const user = userResult.recordset[0];
    if (user.AccountStatus !== 'Active') return res.status(401).json({ success: false, message: `Account is ${user.AccountStatus}` });

    const valid = await bcrypt.compare(Password, user.PasswordHash);
    if (!valid) return res.status(401).json({ success: false, message: 'Invalid credentials' });

    const token = jwt.sign({
      UserID: user.UserID, Username: user.Username, Email: user.Email,
      Role: user.Role, FullName: user.FullName, FranchiseID: user.FranchiseID,
    }, authConfig.jwtSecret, { expiresIn: authConfig.jwtExpiresIn });

    await query(`UPDATE [Users].[User] SET LastLoginAt = SYSDATETIME() WHERE UserID = @UserID`, { UserID: user.UserID });

    const frontendRole = user.Role === 'Admin' ? 'admin' : user.Role === 'Manager' ? 'manager' : 'customer';
    res.json(success({ token, user: { UserID: user.UserID, FullName: user.FullName, Email: user.Email, Phone: user.Phone, Role: user.Role, FranchiseID: user.FranchiseID, frontendRole } }));
  } catch (err) { next(err); }
});

router.post('/auth/register', async (req, res, next) => {
  try {
    let { Username, Email, Password, FullName, Phone, Role } = req.body;
    const existing = await query(`SELECT UserID FROM [Users].[User] WHERE Email = @Email OR Username = @Username`,
      { Email, Username: Username || Email });
    if (existing.recordset.length > 0) return res.status(422).json({ success: false, message: 'Username or email already exists' });

    Role = (Role || 'Customer').trim();
    if (!['Customer', 'Manager', 'Admin'].includes(Role)) return res.status(400).json({ success: false, message: 'Invalid role' });

    const salt = await bcrypt.genSalt(authConfig.bcryptSaltRounds);
    const hash = await bcrypt.hash(Password, salt);
    const username = Username || Email.split('@')[0];

    const userResult = await query(`INSERT INTO [Users].[User] (Username, Email, Phone, PasswordHash, FullName, Role, AccountStatus, CreatedAt)
      OUTPUT INSERTED.* VALUES (@Username, @Email, @Phone, @Hash, @FullName, @Role, 'Active', SYSDATETIME())`, {
      Username: username, Email, Phone: Phone || null, Hash: hash, FullName: FullName || username, Role,
    });
    const user = userResult.recordset[0];

    await query(`INSERT INTO Payments.Wallet (UserID, WalletCode, Balance) VALUES (@UserID, @Code, 0)`,
      { UserID: user.UserID, Code: 'WAL-' + username });
    res.status(201).json(success({ UserID: user.UserID, Username: user.Username, Email: user.Email, Role }));
  } catch (err) { next(err); }
});

router.post('/auth/forgot-password', async (req, res, next) => {
  try {
    const r = await query(`SELECT UserID, Email FROM [Users].[User] WHERE Email = @Email`, { Email: req.body.Email });
    if (r.recordset.length > 0) {
      const token = jwt.sign({ UserID: r.recordset[0].UserID, Email: r.recordset[0].Email, purpose: 'password-reset' }, authConfig.jwtSecret, { expiresIn: '15m' });
      return res.json(success({ message: 'If the email exists, a reset link has been sent.', resetToken: token }));
    }
    res.json(success({ message: 'If the email exists, a reset link has been sent.' }));
  } catch (err) { next(err); }
});

router.post('/auth/reset-password', async (req, res, next) => {
  try {
    const decoded = jwt.verify(req.body.Token, authConfig.jwtSecret);
    if (decoded.purpose !== 'password-reset') return res.status(400).json({ success: false, message: 'Invalid reset token' });
    const salt = await bcrypt.genSalt(authConfig.bcryptSaltRounds);
    const hash = await bcrypt.hash(req.body.Password, salt);
    await query(`UPDATE [Users].[User] SET PasswordHash = @Hash, UpdatedAt = SYSDATETIME() WHERE UserID = @UserID`,
      { UserID: decoded.UserID, Hash: hash });
    res.json(success({ message: 'Password has been reset successfully.' }));
  } catch (err) { return res.status(400).json({ success: false, message: 'Invalid or expired reset token' }); }
});

// ===================== PROFILE =====================

router.get('/auth/profile', authenticate, async (req, res, next) => {
  try { res.json(success(await ds.getUserProfile(req.user.UserID))); }
  catch (err) { next(err); }
});

router.put('/auth/profile', authenticate, async (req, res, next) => {
  try { res.json(success(await ds.updateProfile(req.user.UserID, req.body))); }
  catch (err) { next(err); }
});

// ===================== CUSTOMER DATA =====================

router.get('/client/dashboard', authenticate, async (req, res, next) => {
  try { res.json(success(await ds.getDashboardStats(req.user.UserID))); }
  catch (err) { next(err); }
});

router.get('/stations', async (req, res, next) => {
  try { res.json(success(await ds.getStations())); }
  catch (err) { next(err); }
});

router.get('/points', async (req, res, next) => {
  try { res.json(success(await ds.getPoints(req.query.stationId))); }
  catch (err) { next(err); }
});

router.get('/vehicles', authenticate, async (req, res, next) => {
  try { res.json(success(await ds.getVehicles(req.user.UserID))); }
  catch (err) { next(err); }
});

router.post('/vehicles', authenticate, async (req, res, next) => {
  try { res.status(201).json(success(await ds.addVehicle(req.user.UserID, req.body))); }
  catch (err) { next(err); }
});

router.delete('/vehicles/:id', authenticate, async (req, res, next) => {
  try { await ds.deleteVehicle(req.params.id, req.user.UserID); res.json(success(null, 'Vehicle deleted')); }
  catch (err) { next(err); }
});

router.get('/sessions', authenticate, async (req, res, next) => {
  try { res.json(success(await ds.getSessions(req.user.UserID))); }
  catch (err) { next(err); }
});

router.get('/sessions/all', authenticate, async (req, res, next) => {
  try { res.json(success(await ds.getAllSessions())); }
  catch (err) { next(err); }
});

router.get('/wallet', authenticate, async (req, res, next) => {
  try { res.json(success(await ds.getWallet(req.user.UserID))); }
  catch (err) { next(err); }
});

router.post('/wallet/topup', authenticate, async (req, res, next) => {
  try { await ds.topUpWallet(req.user.UserID, req.body.Amount); res.json(success({ message: 'Top-up successful' })); }
  catch (err) { next(err); }
});

router.get('/transactions', authenticate, async (req, res, next) => {
  try { res.json(success(await ds.getTransactions(req.user.UserID))); }
  catch (err) { next(err); }
});

// ===================== MANAGER DATA =====================

router.get('/manager/dashboard', authenticate, async (req, res, next) => {
  try { res.json(success(await ds.getManagerDashboard())); }
  catch (err) { next(err); }
});

// ===================== ADMIN DATA =====================

router.get('/franchisees', authenticate, async (req, res, next) => {
  try { res.json(success(await ds.getFranchisees())); }
  catch (err) { next(err); }
});

router.get('/pricing', authenticate, async (req, res, next) => {
  try { res.json(success(await ds.getPricingPolicies())); }
  catch (err) { next(err); }
});

router.get('/users', authenticate, async (req, res, next) => {
  try { res.json(success(await ds.getUsers())); }
  catch (err) { next(err); }
});

// ===================== HEALTH =====================

router.get('/health', (req, res) => {
  res.json({ success: true, message: 'Service is running', data: { timestamp: new Date().toISOString() } });
});

module.exports = router;
