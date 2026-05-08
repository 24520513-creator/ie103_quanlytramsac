const BaseModel = require('./BaseModel');

class PaymentGateway extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.GatewayID = row.GatewayID;
      this.GatewayCode = row.GatewayCode;
      this.GatewayName = row.GatewayName;
      this.GatewayType = row.GatewayType;
      this.ApiEndpoint = row.ApiEndpoint;
      this.MerchantID = row.MerchantID;
      this.IsActive = row.IsActive ?? true;
    }
  }
}

class Transaction extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.TransactionID = row.TransactionID;
      this.TransactionCode = row.TransactionCode;
      this.UserID = row.UserID;
      this.SessionID = row.SessionID;
      this.InvoiceID = row.InvoiceID;
      this.GatewayID = row.GatewayID;
      this.TransactionType = row.TransactionType;
      this.Direction = row.Direction;
      this.Amount = row.Amount;
      this.CurrencyCode = row.CurrencyCode;
      this.ExchangeRate = row.ExchangeRate;
      this.AmountBaseCurrency = row.AmountBaseCurrency;
      this.FeeAmount = row.FeeAmount;
      this.NetAmount = row.NetAmount;
      this.TransactionStatus = row.TransactionStatus;
      this.PaymentMethod = row.PaymentMethod;
      this.ReferenceCode = row.ReferenceCode;
      this.Description = row.Description;
      this.TransactedAt = row.TransactedAt;
      this.SettledAt = row.SettledAt;
      this.IsDeleted = row.IsDeleted ?? false;
    }
  }
}

class TransactionStatusHistory extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.StatusHistoryID = row.StatusHistoryID;
      this.TransactionID = row.TransactionID;
      this.PreviousStatus = row.PreviousStatus;
      this.NewStatus = row.NewStatus;
      this.ChangedBy = row.ChangedBy;
      this.Reason = row.Reason;
      this.ChangedAt = row.ChangedAt;
    }
  }
}

class GatewayTransaction extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.GatewayTransactionID = row.GatewayTransactionID;
      this.TransactionID = row.TransactionID;
      this.GatewayID = row.GatewayID;
      this.GatewayReferenceID = row.GatewayReferenceID;
      this.RequestPayload = row.RequestPayload;
      this.ResponsePayload = row.ResponsePayload;
      this.GatewayStatus = row.GatewayStatus;
      this.GatewayMessage = row.GatewayMessage;
      this.AttemptCount = row.AttemptCount;
      this.AttemptedAt = row.AttemptedAt;
      this.CompletedAt = row.CompletedAt;
    }
  }
}

class RefundTransaction extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.RefundID = row.RefundID;
      this.OriginalTransactionID = row.OriginalTransactionID;
      this.RefundCode = row.RefundCode;
      this.RefundAmount = row.RefundAmount;
      this.RefundReason = row.RefundReason;
      this.RefundType = row.RefundType;
      this.RefundStatus = row.RefundStatus;
      this.ApprovedBy = row.ApprovedBy;
      this.ApprovedAt = row.ApprovedAt;
      this.GatewayRefundID = row.GatewayRefundID;
      this.Notes = row.Notes;
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
      this.PendingBalance = row.PendingBalance;
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

class Invoice extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.InvoiceID = row.InvoiceID;
      this.InvoiceCode = row.InvoiceCode;
      this.UserID = row.UserID;
      this.InvoiceType = row.InvoiceType;
      this.InvoiceStatus = row.InvoiceStatus;
      this.SubTotal = row.SubTotal;
      this.TaxAmount = row.TaxAmount;
      this.TaxRate = row.TaxRate;
      this.DiscountAmount = row.DiscountAmount;
      this.TotalAmount = row.TotalAmount;
      this.CurrencyCode = row.CurrencyCode;
      this.BillingAddress = row.BillingAddress;
      this.InvoiceDate = row.InvoiceDate;
      this.DueDate = row.DueDate;
      this.PaidAt = row.PaidAt;
      this.Notes = row.Notes;
      this.IsDeleted = row.IsDeleted ?? false;
    }
  }
}

class InvoiceLineItem extends BaseModel {
  constructor(row) {
    super();
    if (row) {
      this.LineItemID = row.LineItemID;
      this.InvoiceID = row.InvoiceID;
      this.SessionID = row.SessionID;
      this.Description = row.Description;
      this.Quantity = row.Quantity;
      this.UnitPrice = row.UnitPrice;
      this.LineTotal = row.LineTotal;
      this.TaxRate = row.TaxRate;
    }
  }
}

module.exports = {
  PaymentGateway, Transaction, TransactionStatusHistory,
  GatewayTransaction, RefundTransaction,
  Wallet, WalletTransaction, Invoice, InvoiceLineItem,
};
