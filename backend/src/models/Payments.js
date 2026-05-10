const BaseModel = require('./BaseModel');

class Transaction extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.TransactionID = row.TransactionID;
      this.TransactionCode = row.TransactionCode;
      this.UserID = row.UserID;
      this.SessionID = row.SessionID;
      this.TransactionType = row.TransactionType;
      this.Direction = row.Direction;
      this.Amount = row.Amount;
      this.CurrencyCode = row.CurrencyCode;
      this.TransactionStatus = row.TransactionStatus;
      this.PaymentMethod = row.PaymentMethod;
      this.Description = row.Description;
      this.TransactedAt = row.TransactedAt;
      this.SettledAt = row.SettledAt;
    }
  }
}

class Wallet extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.WalletID = row.WalletID;
      this.UserID = row.UserID;
      this.WalletCode = row.WalletCode;
      this.Balance = row.Balance;
      this.CurrencyCode = row.CurrencyCode;
      this.IsActive = row.IsActive ?? true;
      this.LastTransactionAt = row.LastTransactionAt;
    }
  }
}

class WalletTransaction extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.WalletTransactionID = row.WalletTransactionID;
      this.WalletID = row.WalletID;
      this.TransactionID = row.TransactionID;
      this.Amount = row.Amount;
      this.BalanceBefore = row.BalanceBefore;
      this.BalanceAfter = row.BalanceAfter;
      this.Direction = row.Direction;
      this.TransactionType = row.TransactionType;
      this.Description = row.Description;
    }
  }
}

module.exports = { Transaction, Wallet, WalletTransaction };
