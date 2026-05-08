import React, { useEffect, useState } from 'react';
import api from '../api';

export default function WalletPage() {
  const [wallet, setWallet] = useState(null);
  const [loading, setLoading] = useState(true);
  const [amount, setAmount] = useState('');
  const [paymentMethod, setPaymentMethod] = useState('BankTransfer');

  const fetchWallet = async () => {
    try {
      const res = await api.get('/wallet/my');
      setWallet(res.data);
    } catch (err) {
      console.error('Fetch wallet error:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchWallet(); }, []);

  const handleTopUp = async (e) => {
    e.preventDefault();
    const val = parseFloat(amount);
    if (!val || val <= 0) return alert('Enter a valid amount');

    try {
      await api.post('/wallet/topup', { amount: val, paymentMethod });
      alert(`Successfully added ${val.toLocaleString()} VND to your wallet!`);
      setAmount('');
      fetchWallet();
    } catch (err) {
      alert(err?.message || 'Top up failed');
    }
  };

  if (loading) return <div className="loading">Loading wallet...</div>;

  return (
    <div style={{ maxWidth: '600px' }}>
      <div className="page-header"><h1>My Wallet</h1></div>

      <div className="card" style={{ textAlign: 'center', padding: '40px', marginBottom: '25px' }}>
        <p style={{ fontSize: '13px', color: '#888', marginBottom: '5px' }}>Current Balance</p>
        <h1 style={{ fontSize: '36px', color: '#1a237e' }}>
          {wallet?.Balance !== undefined ? parseFloat(wallet.Balance).toLocaleString() : 0} VND
        </h1>
        {wallet?.WalletCode && <p style={{ fontSize: '12px', color: '#999' }}>Wallet: {wallet.WalletCode}</p>}
      </div>

      <div className="card">
        <h3 style={{ marginBottom: '15px' }}>Top Up Balance</h3>
        <form onSubmit={handleTopUp}>
          <div className="form-group">
            <label>Amount (VND)</label>
            <input
              type="number"
              placeholder="Enter amount"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              min="1000"
              required
            />
          </div>
          <div className="form-group">
            <label>Payment Method</label>
            <select value={paymentMethod} onChange={(e) => setPaymentMethod(e.target.value)}>
              <option value="BankTransfer">Bank Transfer</option>
              <option value="VNPay">VNPay</option>
              <option value="Momo">Momo</option>
              <option value="ZaloPay">ZaloPay</option>
              <option value="CreditCard">Credit Card</option>
            </select>
          </div>
          <button type="submit" className="btn btn-primary">Top Up Now</button>
        </form>
      </div>
    </div>
  );
}
