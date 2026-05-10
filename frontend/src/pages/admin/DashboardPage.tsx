import { useState, useEffect } from 'react';
import { Users, Building2, Zap, BarChart3, Loader2 } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';
import { api } from '../../services/api';
import StatCard from '../../components/ui/StatCard';
import StatusBadge from '../../components/ui/StatusBadge';

export default function AdminDashboardPage() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get('/dashboard/admin').then(r => {
      if (r.data) setData(r.data);
    }).finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;
  if (!data) return <div className="text-center py-20 text-slate-400">Không có dữ liệu</div>;

  const c = data.counts || {};
  const chartData = (data.revenueByDay || []).map((r: any) => ({
    date: r.Date?.slice(0, 10),
    revenue: r.TotalRevenue || r.Revenue || 0,
  }));

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">Toàn cảnh hệ thống</h1>
        <p className="text-sm text-slate-500 mt-1">Thống kê tổng quan hệ thống EV Charging</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard title="Người dùng" value={c.TotalUsers || 0} icon={<Users className="w-6 h-6" />} color="blue" />
        <StatCard title="Trạm sạc" value={c.TotalStations || 0} icon={<Building2 className="w-6 h-6" />} color="green" />
        <StatCard title="Phiên hoàn thành" value={c.TotalSessions || 0} icon={<Zap className="w-6 h-6" />} color="purple" />
        <StatCard title="Doanh thu" value={`${(c.TotalRevenue || 0).toLocaleString()} VND`} icon={<BarChart3 className="w-6 h-6" />} color="orange" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 bg-white rounded-2xl border border-slate-200 p-6">
          <h3 className="font-semibold text-slate-900 mb-4">Xu hướng doanh thu</h3>
          {chartData.length > 0 ? (
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={chartData}>
                <XAxis dataKey="date" tick={{ fontSize: 12 }} />
                <YAxis tick={{ fontSize: 12 }} />
                <Tooltip />
                <Line type="monotone" dataKey="revenue" stroke="#3b82f6" strokeWidth={2} dot={false} />
              </LineChart>
            </ResponsiveContainer>
          ) : <p className="text-center text-slate-400 py-8">Chưa có dữ liệu</p>}
        </div>

        <div className="bg-white rounded-2xl border border-slate-200 p-6">
          <h3 className="font-semibold text-slate-900 mb-4">Top trạm</h3>
          <div className="space-y-3">
            {(data.topStations || []).slice(0, 5).map((st: any, i: number) => (
              <div key={i} className="flex items-center justify-between p-2.5 bg-slate-50 rounded-lg">
                <div>
                  <p className="text-sm font-medium">{st.StationName}</p>
                  <p className="text-xs text-slate-500">{st.Sessions} phiên</p>
                </div>
                <p className="text-sm font-bold">{(st.Revenue || 0).toLocaleString()}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white rounded-2xl border border-slate-200 p-6">
          <h3 className="font-semibold text-slate-900 mb-4">Đặt lịch gần đây</h3>
          {(data.recentBookings || []).slice(0, 5).map((b: any) => (
            <div key={b.BookingID} className="flex justify-between p-2.5 bg-slate-50 rounded-lg mb-2 text-sm">
              <span className="font-medium">{b.StationName}</span>
              <span className="text-slate-500">{new Date(b.StartTime).toLocaleString('vi-VN')}</span>
              <StatusBadge status={b.Status} />
            </div>
          ))}
          {(!data.recentBookings || data.recentBookings.length === 0) && (
            <p className="text-center text-slate-400 py-4 text-sm">Chưa có đặt lịch</p>
          )}
        </div>
        <div className="bg-white rounded-2xl border border-slate-200 p-6">
          <h3 className="font-semibold text-slate-900 mb-4">Lỗi gần đây</h3>
          {(data.recentErrors || []).slice(0, 5).map((e: any) => (
            <div key={e.ErrorLogID} className="flex justify-between p-2.5 bg-red-50 rounded-lg mb-2 text-sm">
              <span className="font-medium">{e.ErrorCode}</span>
              <span className="text-slate-500">{e.PointCode}</span>
              <StatusBadge status={e.Severity} />
            </div>
          ))}
          {(!data.recentErrors || data.recentErrors.length === 0) && (
            <p className="text-center text-slate-400 py-4 text-sm">Không có lỗi</p>
          )}
        </div>
      </div>
    </div>
  );
}
