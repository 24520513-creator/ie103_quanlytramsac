const { query, execute } = require('../config/database');
const { NotFoundError, ValidationError, successResponse } = require('../utils/response');
const { Transaction, Wallet } = require('../models/Payments');

class PaymentService {
  async createPayment({ UserID, SessionID, PaymentMethod }) {
    const result = await execute('Payments.sp_CreatePayment', {
      UserID, SessionID, PaymentMethod: PaymentMethod || 'Wallet',
    });
    return successResponse(new Transaction(result.recordset[0]), 'Payment processed successfully');
  }

  async getUserWallet(userId) {
    let wallet = await query(`SELECT * FROM [Payments].[Wallet] WHERE UserID = @UserID AND IsActive = 1`,
      { UserID: userId });
    if (wallet.recordset.length === 0) {
      const user = await query(`SELECT Username FROM [Users].[User] WHERE UserID = @UserID`, { UserID: userId });
      const walletCode = 'WAL-' + (user.recordset[0]?.Username || userId);
      await query(`INSERT INTO [Payments].[Wallet] (UserID, WalletCode, Balance, CreatedAt)
        VALUES (@UserID, @Code, 0, SYSDATETIME())`, { UserID: userId, Code: walletCode });
      wallet = await query(`SELECT * FROM [Payments].[Wallet] WHERE UserID = @UserID`, { UserID: userId });
    }
    return successResponse(new Wallet(wallet.recordset[0]));
  }

  async topUpWallet(userId, amount, paymentMethod) {
    if (amount <= 0) throw new ValidationError('Amount must be positive');
    const wallet = await query(`SELECT * FROM [Payments].[Wallet] WHERE UserID = @UserID AND IsActive = 1`,
      { UserID: userId });
    if (wallet.recordset.length === 0) throw new NotFoundError('Wallet');

    const txnCode = `TXN-${new Date().toISOString().slice(0,10).replace(/-/g,'')}-${Date.now().toString(36).toUpperCase()}`;
    const txnResult = await query(`INSERT INTO [Payments].[Transaction]
      (TransactionCode, UserID, TransactionType, Direction, Amount, CurrencyCode, TransactionStatus, PaymentMethod, TransactedAt, CreatedAt)
      OUTPUT INSERTED.*
      VALUES (@Code, @UserID, 'WalletTopUp', 'C', @Amount, 'VND', 'Completed', @PayMethod, SYSDATETIME(), SYSDATETIME())`, {
      Code: txnCode, UserID: userId, Amount: amount, PayMethod: paymentMethod || 'BankTransfer',
    });
    const txn = txnResult.recordset[0];

    const w = wallet.recordset[0];
    await query(`UPDATE [Payments].[Wallet] SET Balance = Balance + @Amount, LastTransactionAt = SYSDATETIME() WHERE WalletID = @WalletID`,
      { Amount: amount, WalletID: w.WalletID });

    await query(`INSERT INTO [Payments].[WalletTransaction] (WalletID, TransactionID, Amount, BalanceBefore, Direction, TransactionType, CreatedAt)
      VALUES (@WalletID, @TxnID, @Amount, @Balance, 'C', 'WalletTopUp', SYSDATETIME())`, {
      WalletID: w.WalletID, TxnID: txn.TransactionID, Amount, Balance: w.Balance,
    });

    return successResponse({ transaction: txn, newBalance: parseFloat(w.Balance) + amount }, 'Wallet topped up');
  }

  async getTransactionHistory(userId, filters = {}) {
    let q = `SELECT t.*, cs.SessionCode FROM [Payments].[Transaction] t
      LEFT JOIN [Operations].[ChargingSession] cs ON t.SessionID = cs.SessionID
      WHERE 1=1`;
    const params = {};
    if (userId) { q += ` AND t.UserID = @UserID`; params.UserID = userId; }
    if (filters.status) { q += ` AND t.TransactionStatus = @Status`; params.Status = filters.status; }
    if (filters.type) { q += ` AND t.TransactionType = @Type`; params.Type = filters.type; }
    q += ` ORDER BY t.TransactedAt DESC`;
    if (filters.page && filters.limit) {
      const offset = (filters.page - 1) * filters.limit;
      q += ` OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY`;
      params.Offset = offset;
      params.Limit = filters.limit;
    }
    const result = await query(q, params);
    return result.recordset;
  }
}

module.exports = new PaymentService();
