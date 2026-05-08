const { query } = require('../config/database');
const { NotFoundError, ValidationError, successResponse } = require('../utils/response');
const { Transaction, Wallet } = require('../models/Payments');

class PaymentService {
  async createPayment({ UserID, SessionID, PaymentMethod, GatewayID }) {
    const sessionResult = await query(`SELECT * FROM [Operations].[ChargingSession] WHERE SessionID = @SessionID AND IsDeleted = 0`, { SessionID });
    if (sessionResult.recordset.length === 0) throw new NotFoundError('ChargingSession');
    const session = sessionResult.recordset[0];
    if (session.SessionStatus !== 'Completed') throw new ValidationError('Session must be completed before payment');
    if (!session.CostTotal || session.CostTotal <= 0) throw new ValidationError('Invalid payment amount');

    const existing = await query(`SELECT TransactionID FROM [Payments].[Transaction] WHERE SessionID = @SessionID AND TransactionStatus = 'Completed' AND IsDeleted = 0`, { SessionID });
    if (existing.recordset.length > 0) throw new ValidationError('Payment already completed for this session');

    const txnCode = `TXN-${new Date().toISOString().slice(0,10).replace(/-/g,'')}-${Date.now().toString(36).toUpperCase()}`;

    const txnResult = await query(`INSERT INTO [Payments].[Transaction]
      (TransactionCode, UserID, SessionID, GatewayID, TransactionType, Direction, Amount, CurrencyCode,
       TransactionStatus, PaymentMethod, TransactedAt, CreatedAt)
      OUTPUT INSERTED.*
      VALUES (@Code, @UserID, @SessionID, @GatewayID, 'ChargingPayment', 'D', @Amount, 'VND',
       'Pending', @PaymentMethod, SYSDATETIME(), SYSDATETIME())`, {
      Code: txnCode, UserID, SessionID, GatewayID: GatewayID || null,
      Amount: session.CostTotal, PaymentMethod: PaymentMethod || 'Wallet',
    });
    const transaction = txnResult.recordset[0];

    if (PaymentMethod === 'Wallet') {
      const walletResult = await query(`SELECT * FROM [Payments].[Wallet] WHERE UserID = @UserID AND IsActive = 1`, { UserID });
      if (walletResult.recordset.length === 0) throw new ValidationError('No active wallet found');
      const wallet = walletResult.recordset[0];

      if (parseFloat(wallet.Balance) < parseFloat(session.CostTotal)) {
        await query(`UPDATE [Payments].[Transaction] SET TransactionStatus = 'Failed' WHERE TransactionID = @TxnID`, { TxnID: transaction.TransactionID });
        throw new ValidationError('Insufficient wallet balance');
      }

      await query(`UPDATE [Payments].[Wallet] SET Balance = Balance - @Amount, LastTransactionAt = SYSDATETIME() WHERE WalletID = @WalletID`,
        { Amount: session.CostTotal, WalletID: wallet.WalletID });

      await query(`INSERT INTO [Payments].[WalletTransaction] (WalletID, TransactionID, Amount, BalanceBefore, Direction, TransactionType, CreatedAt)
        VALUES (@WalletID, @TxnID, -@Amount, @Balance, 'D', 'ChargingPayment', SYSDATETIME())`, {
        WalletID: wallet.WalletID, TxnID: transaction.TransactionID,
        Amount: session.CostTotal, Balance: wallet.Balance,
      });

      await query(`UPDATE [Payments].[Transaction] SET TransactionStatus = 'Completed', SettledAt = SYSDATETIME() WHERE TransactionID = @TxnID`, { TxnID: transaction.TransactionID });
    }

    await query(`INSERT INTO [Payments].[TransactionStatusHistory] (TransactionID, PreviousStatus, NewStatus, ChangedAt)
      VALUES (@TxnID, 'Pending', @NewStatus, SYSDATETIME())`, { TxnID: transaction.TransactionID, NewStatus: PaymentMethod === 'Wallet' ? 'Completed' : 'Processing' });

    const final = await query(`SELECT * FROM [Payments].[Transaction] WHERE TransactionID = @TxnID`, { TxnID: transaction.TransactionID });
    return successResponse(new Transaction(final.recordset[0]), 'Payment processed successfully');
  }

  async processRefund({ OriginalTransactionID, Amount, Reason }) {
    const original = await query(`SELECT * FROM [Payments].[Transaction] WHERE TransactionID = @TxnID AND IsDeleted = 0`, { TxnID: OriginalTransactionID });
    if (original.recordset.length === 0) throw new NotFoundError('Original transaction');
    const origTxn = original.recordset[0];
    if (origTxn.TransactionStatus !== 'Completed') throw new ValidationError('Original transaction must be completed');

    const totalRefunded = await query(`SELECT ISNULL(SUM(RefundAmount), 0) AS Total FROM [Payments].[RefundTransaction]
      WHERE OriginalTransactionID = @TxnID AND RefundStatus = 'Completed'`, { TxnID: OriginalTransactionID });
    const refundedSoFar = parseFloat(totalRefunded.recordset[0].Total);
    const originalAmount = parseFloat(origTxn.Amount);

    if (Amount > (originalAmount - refundedSoFar)) throw new ValidationError('Refund amount exceeds remaining balance');

    const refundCode = `REF-${new Date().toISOString().slice(0,10).replace(/-/g,'')}-${Date.now().toString(36).toUpperCase()}`;
    const refundType = Amount >= originalAmount ? 'Full' : 'Partial';

    const refundResult = await query(`INSERT INTO [Payments].[RefundTransaction]
      (OriginalTransactionID, RefundCode, RefundAmount, RefundReason, RefundType, RefundStatus, CreatedAt)
      OUTPUT INSERTED.*
      VALUES (@OrigID, @Code, @Amount, @Reason, @Type, 'Pending', SYSDATETIME())`, {
      OrigID: OriginalTransactionID, Code: refundCode, Amount, Reason: Reason || 'Customer request', Type: refundType,
    });
    const refund = refundResult.recordset[0];

    const newStatus = (Amount >= (originalAmount - refundedSoFar - 0.01)) ? 'Refunded' : 'PartiallyRefunded';
    await query(`UPDATE [Payments].[Transaction] SET TransactionStatus = @Status WHERE TransactionID = @TxnID`,
      { Status: newStatus, TxnID: OriginalTransactionID });

    await query(`UPDATE [Payments].[RefundTransaction] SET RefundStatus = 'Completed', ApprovedAt = SYSDATETIME() WHERE RefundID = @RefundID`,
      { RefundID: refund.RefundID });

    return successResponse(refund, 'Refund processed successfully');
  }

  async getUserWallet(userId) {
    let wallet = await query(`SELECT * FROM [Payments].[Wallet] WHERE UserID = @UserID AND IsActive = 1`, { UserID: userId });
    if (wallet.recordset.length === 0) {
      const walletCode = `WAL-${userId}-${Date.now().toString(36).toUpperCase()}`;
      await query(`INSERT INTO [Payments].[Wallet] (UserID, WalletCode, Balance, CurrencyCode, CreatedAt)
        VALUES (@UserID, @Code, 0, 'VND', SYSDATETIME())`, { UserID: userId, Code: walletCode });
      wallet = await query(`SELECT * FROM [Payments].[Wallet] WHERE UserID = @UserID`, { UserID: userId });
    }
    return successResponse(new Wallet(wallet.recordset[0]));
  }

  async topUpWallet(userId, amount, paymentMethod) {
    if (amount <= 0) throw new ValidationError('Amount must be positive');
    const wallet = await query(`SELECT * FROM [Payments].[Wallet] WHERE UserID = @UserID AND IsActive = 1`, { UserID: userId });
    if (wallet.recordset.length === 0) throw new NotFoundError('Wallet');

    const txnCode = `TXN-${new Date().toISOString().slice(0,10).replace(/-/g,'')}-${Date.now().toString(36).toUpperCase()}`;
    const txnResult = await query(`INSERT INTO [Payments].[Transaction]
      (TransactionCode, UserID, TransactionType, Direction, Amount, CurrencyCode, TransactionStatus, PaymentMethod, TransactedAt, CreatedAt)
      OUTPUT INSERTED.*
      VALUES (@Code, @UserID, 'WalletTopUp', 'C', @Amount, 'VND', 'Completed', @PayMethod, SYSDATETIME(), SYSDATETIME())`, {
      Code: txnCode, UserID: userId, Amount: amount, PayMethod: paymentMethod || 'BankTransfer',
    });
    const txn = txnResult.recordset[0];

    await query(`UPDATE [Payments].[Wallet] SET Balance = Balance + @Amount, LastTransactionAt = SYSDATETIME() WHERE WalletID = @WalletID`,
      { Amount: amount, WalletID: wallet.recordset[0].WalletID });

    await query(`INSERT INTO [Payments].[WalletTransaction] (WalletID, TransactionID, Amount, BalanceBefore, Direction, TransactionType, CreatedAt)
      VALUES (@WalletID, @TxnID, @Amount, @Balance, 'C', 'WalletTopUp', SYSDATETIME())`, {
      WalletID: wallet.recordset[0].WalletID, TxnID: txn.TransactionID,
      Amount: amount, Balance: wallet.recordset[0].Balance,
    });

    return successResponse({ transaction: txn, newBalance: parseFloat(wallet.recordset[0].Balance) + amount }, 'Wallet topped up');
  }

  async getTransactionHistory(userId, filters = {}) {
    let q = `SELECT t.*, cs.SessionCode, cs.CostTotal AS SessionCost FROM [Payments].[Transaction] t
      LEFT JOIN [Operations].[ChargingSession] cs ON t.SessionID = cs.SessionID
      WHERE t.IsDeleted = 0`;
    const params = {};
    if (userId) { q += ` AND t.UserID = @UserID`; params.UserID = userId; }
    if (filters.status) { q += ` AND t.TransactionStatus = @Status`; params.Status = filters.status; }
    if (filters.type) { q += ` AND t.TransactionType = @Type`; params.Type = filters.type; }
    if (filters.fromDate) { q += ` AND t.TransactedAt >= @From`; params.From = filters.fromDate; }
    if (filters.toDate) { q += ` AND t.TransactedAt <= @To`; params.To = filters.toDate; }
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
