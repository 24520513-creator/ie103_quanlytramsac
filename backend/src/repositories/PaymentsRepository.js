const BaseRepository = require('./BaseRepository');
const { Transaction, Wallet, WalletTransaction } = require('../models/Payments');

const TransactionRepository = new BaseRepository('Transaction', 'Payments', 'TransactionID', Transaction);
const WalletRepository = new BaseRepository('Wallet', 'Payments', 'WalletID', Wallet);
const WalletTransactionRepository = new BaseRepository('WalletTransaction', 'Payments', 'WalletTransactionID', WalletTransaction);

module.exports = { TransactionRepository, WalletRepository, WalletTransactionRepository };
