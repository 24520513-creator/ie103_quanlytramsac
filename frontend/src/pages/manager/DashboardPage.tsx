import { useState, useEffect } from 'react';
import { Building2, Zap, AlertTriangle, BarChart3, Loader2 } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';
import { api } from '../../services/api';
import StatCard from '../../components/ui/StatCard';

export default function ManagerDashboardPage() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const userStr = localStorage.getItem('user');
    let franchiseId: number | null = null;
    try {
      const u = JSON.parse(userStr || '{}');
      franchiseId = u.FranchiseID || null;
    } catch {}
    const endpoint = franchiseId ? `/dashboard/franchise/${franchiseId}` : '/stations';
    api.get(endpoint).then(r => {
      if (r.data) setData(r.data);
    }).catch(() => setData(null)).finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;
  if (!data) return <div className="text-center py-20 text-slate-400">Không có dữ liệu</div>;

  const stations = data.stations || [];
  const rev = data.revenue || {};

  return (
    <div className="space-y-8">
      {data.franchise && (
        <div>
          <h1 className="text-2xl font-bold text-slate-900">{data.franchise.FranchiseName}</h1>
          <p className="text-sm text-slate-500 mt-1">Dashboard quản lý đối tác</p>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard title="Tổng trạm" value={data.activeStations || 0} icon={<Building2 className="w-6 h-6" />} color="blue" />
        <StatCard title="Phiên hoàn thành" value={rev.TotalSessions || 0} icon={<Zap className="w-6 h-6" />} color="green" />
        <StatCard title="Tổng kWh" value={`${(rev.TotalKWh || 0).toFixed(1)}`} icon={<BarChart3 className="w-6 h-6" />} color="purple" />
        <StatCard title="Doanh thu" value={`${(rev.TotalRevenue || 0).toLocaleString()} VND`} icon={<BarChart3 className="w-6 h-6" />} color="orange" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-2xl border border-slate-200 p-6">
          <h3 className="font-semibold text-slate-900 mb-4">Danh sách trạm</h3>
          <div className="space-y-2">
            {stations.map((s: any) => (
              <div key={s.StationID} className="flex justify-between p-3 bg-slate-50 rounded-xl text-sm">
                <span className="font-medium">{s.StationName}</span>
                <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                  s.StationStatus === 'Active' ? 'bg-emerald-100 text-emerald-700' : 'bg-amber-100 text-amber-700'
                }`}>{s.StationStatus}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-white rounded-2xl border border-slate-200 p-6">
          <h3 className="font-semibold text-slate-900 mb-4">Thông tin đối tác</h3>
          {data.franchise && (
            <div className="space-y-3">
              <div className="flex justify-between p-3 bg-slate-50 rounded-xl">
                <span className="text-sm text-slate-600">Mã số thuế</span>
                <span className="font-bold text-sm">{data.franchise.TaxCode}</span>
              </div>
              <div className="flex justify-between p-3 bg-slate-50 rounded-xl">
                <span className="text-sm text-slate-600">Người liên hệ</span>
                <span className="font-bold text-sm">{data.franchise.ContactPerson}</span>
              </div>
              <div className="flex justify-between p-3 bg-slate-50 rounded-xl">
                <span className="text-sm text-slate-600">Email</span>
                <span className="font-bold text-sm">{data.franchise.ContactEmail}</span>
              </div>
              <div className="flex justify-between p-3 bg-slate-50 rounded-xl">
                <span className="text-sm text-slate-600">Tỷ lệ chia sẻ</span>
                <span className="font-bold text-sm">{data.franchise.RevenueShareRate}%</span>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
