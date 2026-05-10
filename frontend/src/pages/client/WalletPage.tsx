import { useState, useEffect } from 'react';
import { Wallet, Plus, ArrowUpRight, ArrowDownLeft, Loader2 } from 'lucide-react';
import { motion } from 'motion/react';
import { api } from '../../services/api';
import PageHeader from '../../components/ui/PageHeader';
import Modal from '../../components/ui/Modal';
import StatusBadge from '../../components/ui/StatusBadge';
import type { Wallet as WalletType, Transaction } from '../../types';

export default function WalletPage() {
  const [wallet, setWallet] = useState<WalletType | null>(null);
  const [txns, setTxns] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [showTopUp, setShowTopUp] = useState(false);
  const [amount, setAmount] = useState(100000);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [txFilter, setTxFilter] = useState('');

  const load = () => {
    Promise.all([
      api.get('/wallet/my').catch(() => ({ data: null })),
      api.get('/transactions/my').catch(() => ({ data: [] })),
    ]).then(([wRes, tRes]) => {
      if (wRes?.data) setWallet(wRes.data);
      setTxns(Array.isArray(tRes?.data) ? tRes.data : []);
    }).finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  const handleTopUp = async () => {
    if (amount <= 0) return;
    setSaving(true);
    setError('');
    try {
      await api.post('/wallet/topup', { amount, paymentMethod: 'BankTransfer' });
      setShowTopUp(false);
      load();
    } catch (err: any) { setError(err.message); }
    finally { setSaving(false); }
  };

  const presets = [50000, 100000, 200000, 500000, 1000000, 2000000];

  const filtered = txns.filter(t => !txFilter || t.TransactionType === txFilter);

  if (loading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;

  return (
    <div className="space-y-6">
      <PageHeader title="Ví điện tử"
        actions={<button onClick={() => setShowTopUp(true)}
          className="flex items-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-xl hover:bg-blue-700 font-medium text-sm">
          <Plus className="w-4 h-4" /> Nạp tiền</button>} />

      <motion.div initial={{ scale: 0.95 }} animate={{ scale: 1 }}
        className="bg-gradient-to-br from-blue-600 to-indigo-700 rounded-2xl p-6 text-white">
        <p className="text-sm font-medium text-blue-100 mb-1">Số dư hiện tại</p>
        <p className="text-4xl font-bold mb-4">{wallet?.Balance?.toLocaleString() || 0} VND</p>
        <div className="flex items-center gap-2 text-blue-100 text-sm">
          <Wallet className="w-4 h-4" />
          <span>{wallet?.WalletCode || 'Ví điện tử'}</span>
        </div>
      </motion.div>

      <div className="bg-white rounded-2xl border border-slate-200 p-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-semibold text-slate-900">Lịch sử giao dịch</h3>
          <select value={txFilter} onChange={e => setTxFilter(e.target.value)}
            className="px-3 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-sm outline-none">
            <option value="">Tất cả</option>
            <option value="WalletTopUp">Nạp tiền</option>
            <option value="ChargingPayment">Sạc xe</option>
          </select>
        </div>
        <div className="space-y-3">
          {filtered.slice(0, 10).map(t => (
            <div key={t.TransactionID} className="flex items-center justify-between p-3 bg-slate-50 rounded-xl">
              <div className="flex items-center gap-3">
                <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${
                  t.Direction === 'C' ? 'bg-emerald-50' : 'bg-red-50'
                }`}>
                  {t.Direction === 'C'
                    ? <ArrowDownLeft className="w-5 h-5 text-emerald-600" />
                    : <ArrowUpRight className="w-5 h-5 text-red-500" />}
                </div>
                <div>
                  <p className="text-sm font-medium text-slate-900">
                    {t.TransactionType === 'WalletTopUp' ? 'Nạp tiền' :
                     t.TransactionType === 'ChargingPayment' ? 'Thanh toán sạc' : 'Giao dịch'}
                  </p>
                  <p className="text-xs text-slate-500">{new Date(t.TransactedAt).toLocaleString('vi-VN')}</p>
                </div>
              </div>
              <div className="text-right">
                <p className={`text-sm font-bold ${t.Direction === 'C' ? 'text-emerald-600' : 'text-red-500'}`}>
                  {t.Direction === 'C' ? '+' : '-'}{t.Amount?.toLocaleString()} VND
                </p>
                <StatusBadge status={t.TransactionStatus || 'Completed'} />
              </div>
            </div>
          ))}
          {filtered.length === 0 && <p className="text-center text-slate-400 py-4">Chưa có giao dịch</p>}
        </div>
      </div>

      <Modal open={showTopUp} onClose={() => setShowTopUp(false)} title="Nạp tiền vào ví">
        {error && <div className="bg-red-50 text-red-600 text-sm p-3 rounded-xl mb-4">{error}</div>}
        <div className="grid grid-cols-3 gap-3 mb-4">
          {presets.map(p => (
            <button key={p} onClick={() => setAmount(p)}
              className={`p-3 rounded-xl border text-center font-medium transition-all ${
                amount === p ? 'border-blue-500 bg-blue-50 text-blue-600' : 'border-slate-200 hover:border-blue-300'
              }`}>
              {p.toLocaleString()} VND
            </button>
          ))}
        </div>
        <div className="mb-4">
          <label className="block text-xs font-bold text-slate-500 uppercase mb-1">Số tiền khác</label>
          <input type="number" value={amount} onChange={e => setAmount(parseInt(e.target.value) || 0)}
            className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
        </div>
        <button onClick={handleTopUp} disabled={saving || amount <= 0}
          className="w-full py-3 bg-blue-600 text-white font-bold rounded-xl hover:bg-blue-700 disabled:opacity-50">
          {saving ? 'Đang xử lý...' : `Nạp ${amount.toLocaleString()} VND`}
        </button>
      </Modal>
    </div>
  );
}
