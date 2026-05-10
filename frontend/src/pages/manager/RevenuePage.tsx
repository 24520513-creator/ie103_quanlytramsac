import { useState, useEffect } from 'react';
import { BarChart3, Download, Loader2 } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';
import { api } from '../../services/api';
import PageHeader from '../../components/ui/PageHeader';

export default function ManagerRevenuePage() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get('/dashboard/admin').then(r => {
      if (r.data) setData(r.data);
    }).finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;
  if (!data) return <div className="text-center py-20 text-slate-400">Không có dữ liệu doanh thu</div>;

  const c = data.counts || {};
  const chartData = (data.revenueByDay || []).map((r: any) => ({
    date: r.Date?.slice(0, 10),
    revenue: r.TotalRevenue || r.Revenue || 0,
    sessions: r.SessionCount || 0,
  }));

  return (
    <div className="space-y-8">
      <PageHeader title="Doanh thu" subtitle="Thống kê doanh thu hệ thống"
        actions={<button className="flex items-center gap-2 px-4 py-2.5 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 text-sm font-medium">
          <Download className="w-4 h-4" /> Xuất PDF</button>} />

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white rounded-2xl border border-slate-200 p-6">
          <p className="text-sm font-medium text-slate-500">Tổng doanh thu</p>
          <p className="text-3xl font-bold text-slate-900 mt-1">{(c.TotalRevenue || 0).toLocaleString()} VND</p>
        </div>
        <div className="bg-white rounded-2xl border border-slate-200 p-6">
          <p className="text-sm font-medium text-slate-500">Tổng kWh</p>
          <p className="text-3xl font-bold text-slate-900 mt-1">{(c.TotalKWh || 0).toFixed(1)}</p>
        </div>
        <div className="bg-white rounded-2xl border border-slate-200 p-6">
          <p className="text-sm font-medium text-slate-500">Tổng phiên</p>
          <p className="text-3xl font-bold text-slate-900 mt-1">{c.TotalSessions || 0}</p>
        </div>
      </div>

      <div className="bg-white rounded-2xl border border-slate-200 p-6">
        <h3 className="font-semibold text-slate-900 mb-4">Doanh thu theo ngày</h3>
        {chartData.length > 0 ? (
          <ResponsiveContainer width="100%" height={350}>
            <AreaChart data={chartData}>
              <defs>
                <linearGradient id="revGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                </linearGradient>
              </defs>
              <XAxis dataKey="date" tick={{ fontSize: 12 }} />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip />
              <Area type="monotone" dataKey="revenue" stroke="#3b82f6" fill="url(#revGrad)" strokeWidth={2} />
            </AreaChart>
          </ResponsiveContainer>
        ) : (
          <p className="text-center text-slate-400 py-8">Chưa có dữ liệu doanh thu</p>
        )}
      </div>

      <div className="bg-white rounded-2xl border border-slate-200 p-6">
        <h3 className="font-semibold text-slate-900 mb-4">Top trạm theo doanh thu</h3>
        <div className="space-y-3">
          {(data.topStations || []).slice(0, 10).map((st: any, i: number) => (
            <div key={i} className="flex items-center justify-between p-3 bg-slate-50 rounded-xl">
              <div className="flex items-center gap-3">
                <span className="w-6 h-6 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center text-xs font-bold">{i + 1}</span>
                <span className="font-medium text-sm">{st.StationName}</span>
              </div>
              <div className="text-right">
                <p className="text-sm font-bold">{(st.Revenue || 0).toLocaleString()} VND</p>
                <p className="text-xs text-slate-500">{st.Sessions} phiên · {(st.KWh || 0).toFixed(1)} kWh</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
