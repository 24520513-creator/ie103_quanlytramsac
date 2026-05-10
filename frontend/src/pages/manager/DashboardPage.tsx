import { useState, useEffect } from 'react';
import { Building2, Zap, AlertTriangle, BarChart3, Loader2 } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';
import { api } from '../../services/api';
import StatCard from '../../components/ui/StatCard';

export default function ManagerDashboardPage() {
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

  return (
    <div className="space-y-8">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard title="Tổng trạm" value={c.TotalStations || 0} icon={<Building2 className="w-6 h-6" />} color="blue" />
        <StatCard title="Phiên đang sạc" value={c.ActiveSessions || 0} icon={<Zap className="w-6 h-6" />} color="green" />
        <StatCard title="Lỗi chưa xử lý" value={c.UnresolvedErrors || 0} icon={<AlertTriangle className="w-6 h-6" />} color="red" />
        <StatCard title="Doanh thu" value={`${(c.TotalRevenue || 0).toLocaleString()} VND`} icon={<BarChart3 className="w-6 h-6" />} color="purple" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-2xl border border-slate-200 p-6">
          <h3 className="font-semibold text-slate-900 mb-4">Doanh thu theo trạm</h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={(data.topStations || []).slice(0, 5)}>
              <XAxis dataKey="StationName" tick={{ fontSize: 11 }} />
              <YAxis tick={{ fontSize: 11 }} />
              <Tooltip />
              <Bar dataKey="Revenue" fill="#3b82f6" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="bg-white rounded-2xl border border-slate-200 p-6">
          <h3 className="font-semibold text-slate-900 mb-4">Thống kê nhanh</h3>
          <div className="space-y-4">
            <div className="flex justify-between p-3 bg-slate-50 rounded-xl">
              <span className="text-sm text-slate-600">Tổng người dùng</span>
              <span className="font-bold">{c.TotalUsers || 0}</span>
            </div>
            <div className="flex justify-between p-3 bg-slate-50 rounded-xl">
              <span className="text-sm text-slate-600">Tổng đối tác</span>
              <span className="font-bold">{c.TotalFranchises || 0}</span>
            </div>
            <div className="flex justify-between p-3 bg-slate-50 rounded-xl">
              <span className="text-sm text-slate-600">Tổng phiên hoàn thành</span>
              <span className="font-bold">{c.TotalSessions || 0}</span>
            </div>
            <div className="flex justify-between p-3 bg-slate-50 rounded-xl">
              <span className="text-sm text-slate-600">Tổng kWh</span>
              <span className="font-bold">{(c.TotalKWh || 0).toFixed(1)}</span>
            </div>
            <div className="flex justify-between p-3 bg-slate-50 rounded-xl">
              <span className="text-sm text-slate-600">Bảo trì sắp tới</span>
              <span className="font-bold">{c.UpcomingMaintenance || 0}</span>
            </div>
            <div className="flex justify-between p-3 bg-slate-50 rounded-xl">
              <span className="text-sm text-slate-600">Thông báo chưa đọc</span>
              <span className="font-bold">{c.UnreadNotifications || 0}</span>
            </div>
          </div>
        </div>
      </div>

      {data.recentBookings && data.recentBookings.length > 0 && (
        <div className="bg-white rounded-2xl border border-slate-200 p-6">
          <h3 className="font-semibold text-slate-900 mb-4">Đặt lịch gần đây</h3>
          <div className="space-y-2">
            {data.recentBookings.map((b: any) => (
              <div key={b.BookingID} className="flex justify-between p-2.5 bg-slate-50 rounded-lg text-sm">
                <span className="font-medium">{b.StationName}</span>
                <span className="text-slate-500">{new Date(b.StartTime).toLocaleString('vi-VN')}</span>
                <span className={`font-medium ${b.Status === 'Pending' ? 'text-amber-600' : 'text-emerald-600'}`}>{b.Status}</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
