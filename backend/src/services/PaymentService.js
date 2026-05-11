const { execute } = require('../config/database');
const { NotFoundError, ValidationError, successResponse } = require('../utils/response');
const { Transaction, Wallet } = require('../models/Payments');
const socketService = require('./socketService');
const notificationService = require('./NotificationService');

class PaymentService {
  async createPayment({ UserID, SessionID, PaymentMethod }) {
    const result = await execute('Payments.sp_CreatePayment', {
      UserID, SessionID, PaymentMethod: PaymentMethod || 'Wallet',
    });
    if (!result.recordset || result.recordset.length === 0) {
      throw new Error('Payment processing returned no result');
    }
    const payment = new Transaction(result.recordset[0]);
    socketService.sendToUser(UserID, 'payment:created', payment);
    return successResponse(payment, 'Payment processed successfully');
  }

  async getUserWallet(userId) {
    const result = await execute('Payments.sp_GetOrCreateWallet', { UserID: userId });
    if (!result.recordset || result.recordset.length === 0) {
      throw new NotFoundError('Wallet');
    }
    return successResponse(new Wallet(result.recordset[0]));
  }

  async topUpWallet(userId, amount, paymentMethod) {
    if (!amount || amount <= 0) throw new ValidationError('Amount must be positive');

    const result = await execute('Payments.sp_TopUpWallet', {
      UserID: userId, Amount: amount, PaymentMethod: paymentMethod || 'BankTransfer',
    });
    if (!result.recordset || result.recordset.length === 0) {
      throw new Error('Top-up returned no result');
    }
    const { TransactionID, NewBalance } = result.recordset[0];

    try {
      socketService.sendToUser(userId, 'wallet:updated', { Balance: NewBalance });
      const txn = { TransactionID, Amount: amount };
      socketService.sendToUser(userId, 'transaction:new', txn);
      await notificationService.create(userId, {
        Title: 'Nạp tiền thành công',
        Body: `Ví của bạn đã được nạp ${amount.toLocaleString()} VND. Số dư mới: ${NewBalance.toLocaleString()} VND.`,
        Type: 'Success',
        ReferenceType: 'Transaction',
        ReferenceID: TransactionID,
      });
    } catch (notifyErr) {
      console.error('Post-commit notification failed:', notifyErr.message);
    }

    return successResponse({ transaction: { TransactionID, Amount: amount }, newBalance: NewBalance }, 'Wallet topped up');
  }

  async getTransactionHistory(userId, filters = {}) {
    const params = { UserID: userId, Page: filters.page || 1, Limit: filters.limit || 50 };
    if (filters.status) params.Status = filters.status;
    if (filters.type) params.Type = filters.type;

    const result = await execute('Payments.sp_GetTransactionHistory', params);
    return result.recordset || [];
  }
}

module.exports = new PaymentService();
