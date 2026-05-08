import React, { useEffect, useState } from 'react';
import api from '../api';

export default function TransactionsPage() {
  const [txns, setTxns] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('');

  const fetchTxns = async () => {
    try {
      const params = {};
      if (filter) params.status = filter;
      const res = await api.get('/transactions/my', { params });
      setTxns(res.data.data || []);
    } catch (err) { console.error(err); } finally { setLoading(false); }
  };

  useEffect(() => { fetchTxns(); }, [filter]);

  if (loading) return <div className="loading">Loading transactions...</div>;

  return (
    <div>
      <div className="page-header">
        <h1>Transaction History</h1>
        <select value={filter} onChange={(e) => { setFilter(e.target.value); setLoading(true); }} style={{ padding: '8px 12px', border: '1px solid #ddd', borderRadius: '6px' }}>
          <option value="">All Status</option>
          <option value="Completed">Completed</option>
          <option value="Pending">Pending</option>
          <option value="Failed">Failed</option>
          <option value="Refunded">Refunded</option>
        </select>
      </div>

      {txns.length === 0 ? (
        <div className="empty-state"><h3>No transactions yet</h3></div>
      ) : (
        <div className="data-table">
          <table>
            <thead>
              <tr><th>Code</th><th>Type</th><th>Direction</th><th>Amount</th><th>Status</th><th>Method</th><th>Date</th></tr>
            </thead>
            <tbody>
              {txns.map((t) => (
                <tr key={t.TransactionID}>
                  <td style={{ fontFamily: 'monospace', fontSize: '12px' }}>{t.TransactionCode}</td>
                  <td>{t.TransactionType}</td>
                  <td><span className={`badge ${t.Direction === 'C' ? 'badge-success' : 'badge-warning'}`}>{t.Direction === 'C' ? 'Credit' : 'Debit'}</span></td>
                  <td><strong>{parseFloat(t.Amount).toLocaleString()} VND</strong></td>
                  <td><span className={`badge badge-${t.TransactionStatus === 'Completed' ? 'success' : t.TransactionStatus === 'Pending' ? 'warning' : 'danger'}`}>{t.TransactionStatus}</span></td>
                  <td>{t.PaymentMethod || '-'}</td>
                  <td>{t.TransactedAt ? new Date(t.TransactedAt).toLocaleDateString() : '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
