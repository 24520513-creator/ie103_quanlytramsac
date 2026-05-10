import { useState, useEffect } from 'react';
import { Wallet, Zap, Battery, History, Loader2 } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';
import { api } from '../../services/api';
import StatCard from '../../components/ui/StatCard';
import StatusBadge from '../../components/ui/StatusBadge';
import type { Wallet as WalletType, ChargingSession } from '../../types';

export default function DashboardPage() {
  const [loading, setLoading] = useState(true);
  const [wallet, setWallet] = useState<WalletType | null>(null);
  const [sessions, setSessions] = useState<ChargingSession[]>([]);
  const [error, setError] = useState('');

  useEffect(() => {
    Promise.all([
      api.get('/wallet/my').catch(() => null),
      api.get('/sessions/my').catch(() => null),
    ]).then(([walletRes, sessRes]) => {
      if (walletRes?.data) setWallet(walletRes.data);
      if (sessRes?.data) setSessions(Array.isArray(sessRes.data) ? sessRes.data : []);
    }).catch(err => setError(err.message))
    .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;

  const totalKWh = sessions.reduce((s, c) => s + (c.TotalKWh || 0), 0);
  const totalCost = sessions.reduce((s, c) => s + (c.CostTotal || 0), 0);
  const activeSessions = sessions.filter(s => s.SessionStatus === 'Charging').length;

  const chartData = [...sessions]
    .filter(s => s.SessionStatus === 'Completed')
    .slice(-7)
    .map(s => ({
      date: s.StartTime?.slice(0, 10),
      kWh: s.TotalKWh || 0,
      cost: s.CostTotal || 0,
    }));

  return (
    <div className="space-y-8">
      {error && <div className="bg-red-50 text-red-600 p-3 rounded-xl text-sm">{error}</div>}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard title="Số dư ví" value={`${wallet?.Balance?.toLocaleString() || 0} VND`} icon={<Wallet className="w-6 h-6" />} color="blue" />
        <StatCard title="Tiêu thụ tháng" value={`${totalKWh.toFixed(1)} kWh`} icon={<Zap className="w-6 h-6" />} color="green" />
        <StatCard title="Tổng chi tiêu" value={`${totalCost.toLocaleString()} VND`} icon={<Battery className="w-6 h-6" />} color="purple" />
        <StatCard title="Phiên đang sạc" value={activeSessions} icon={<History className="w-6 h-6" />} color="orange" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-2xl border border-slate-200 p-6">
          <h3 className="font-semibold text-slate-900 mb-4">Tiêu thụ năng lượng</h3>
          <ResponsiveContainer width="100%" height={250}>
            <AreaChart data={chartData}>
              <defs>
                <linearGradient id="kwhGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                </linearGradient>
              </defs>
              <XAxis dataKey="date" tick={{ fontSize: 12 }} />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip />
              <Area type="monotone" dataKey="kWh" stroke="#3b82f6" fill="url(#kwhGrad)" strokeWidth={2} />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        <div className="bg-white rounded-2xl border border-slate-200 p-6">
          <h3 className="font-semibold text-slate-900 mb-4">Phiên sạc gần đây</h3>
          {sessions.length === 0 ? (
            <p className="text-slate-400 text-center py-8">Chưa có phiên sạc nào</p>
          ) : (
            <div className="space-y-3">
              {sessions.slice(0, 5).map(s => (
                <div key={s.SessionID} className="flex items-center justify-between p-3 bg-slate-50 rounded-xl">
                  <div>
                    <p className="text-sm font-medium text-slate-900">{s.StationName || `Trạm #${s.StationID}`}</p>
                    <p className="text-xs text-slate-500">{new Date(s.StartTime).toLocaleString('vi-VN')}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-semibold">{s.TotalKWh?.toFixed(1)} kWh</p>
                    <StatusBadge status={s.SessionStatus} />
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
