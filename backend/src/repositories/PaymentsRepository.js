const BaseRepository = require('./BaseRepository');
const { PaymentGateway, Transaction, TransactionStatusHistory, GatewayTransaction, RefundTransaction, Wallet, WalletTransaction, Invoice, InvoiceLineItem } = require('../models/Payments');

const PaymentGatewayRepository = new BaseRepository('PaymentGateway', 'Payments', 'GatewayID', PaymentGateway);
const TransactionRepository = new BaseRepository('Transaction', 'Payments', 'TransactionID', Transaction);
const TransactionStatusHistoryRepository = new BaseRepository('TransactionStatusHistory', 'Payments', 'StatusHistoryID', TransactionStatusHistory);
const GatewayTransactionRepository = new BaseRepository('GatewayTransaction', 'Payments', 'GatewayTransactionID', GatewayTransaction);
const RefundTransactionRepository = new BaseRepository('RefundTransaction', 'Payments', 'RefundID', RefundTransaction);
const WalletRepository = new BaseRepository('Wallet', 'Payments', 'WalletID', Wallet);
const WalletTransactionRepository = new BaseRepository('WalletTransaction', 'Payments', 'WalletTransactionID', WalletTransaction);
const InvoiceRepository = new BaseRepository('Invoice', 'Payments', 'InvoiceID', Invoice);
const InvoiceLineItemRepository = new BaseRepository('InvoiceLineItem', 'Payments', 'LineItemID', InvoiceLineItem);

module.exports = {
  PaymentGatewayRepository, TransactionRepository, TransactionStatusHistoryRepository,
  GatewayTransactionRepository, RefundTransactionRepository,
  WalletRepository, WalletTransactionRepository,
  InvoiceRepository, InvoiceLineItemRepository,
};
