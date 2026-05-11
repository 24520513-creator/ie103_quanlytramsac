import { useState, useEffect } from 'react';
import { BarChart3, Download, Loader2 } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';
import { api } from '../../services/api';
import PageHeader from '../../components/ui/PageHeader';

export default function ManagerRevenuePage() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  let franchiseId: number | null = null;

  useEffect(() => {
    const userStr = localStorage.getItem('user');
    try {
      const u = JSON.parse(userStr || '{}');
      franchiseId = u.FranchiseID || null;
    } catch {}
    const endpoint = franchiseId ? `/dashboard/franchise/${franchiseId}` : '/stations';
    api.get(endpoint).then(r => {
      if (r.data) setData(r.data);
    }).catch(() => setData(null)).finally(() => setLoading(false));
  }, []);

  const handleExportPDF = async () => {
    if (!franchiseId) return;
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`${import.meta.env.VITE_API_URL || 'http://localhost:3000/api'}/export/revenue/${franchiseId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) throw new Error('Export failed');
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `revenue-${franchiseId}.pdf`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch (err: any) {
      alert('Xuất PDF thất bại: ' + err.message);
    }
  };

  if (loading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;
  if (!data) return <div className="text-center py-20 text-slate-400">Không có dữ liệu doanh thu</div>;

  const rev = data.revenue || {};
  const stations = data.stations || [];

  return (
    <div className="space-y-8">
      <PageHeader title="Doanh thu" subtitle={data.franchise?.FranchiseName || 'Thống kê doanh thu'}
        actions={<button onClick={handleExportPDF} className="flex items-center gap-2 px-4 py-2.5 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 text-sm font-medium">
          <Download className="w-4 h-4" /> Xuất PDF</button>} />

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white rounded-2xl border border-slate-200 p-6">
          <p className="text-sm font-medium text-slate-500">Tổng doanh thu</p>
          <p className="text-3xl font-bold text-slate-900 mt-1">{(rev.TotalRevenue || 0).toLocaleString()} VND</p>
        </div>
        <div className="bg-white rounded-2xl border border-slate-200 p-6">
          <p className="text-sm font-medium text-slate-500">Tổng kWh</p>
          <p className="text-3xl font-bold text-slate-900 mt-1">{(rev.TotalKWh || 0).toFixed(1)}</p>
        </div>
        <div className="bg-white rounded-2xl border border-slate-200 p-6">
          <p className="text-sm font-medium text-slate-500">Tổng phiên</p>
          <p className="text-3xl font-bold text-slate-900 mt-1">{rev.TotalSessions || 0}</p>
        </div>
      </div>

      <div className="bg-white rounded-2xl border border-slate-200 p-6">
        <h3 className="font-semibold text-slate-900 mb-4">Danh sách trạm</h3>
        <div className="space-y-3">
          {stations.map((st: any, i: number) => (
            <div key={st.StationID || i} className="flex items-center justify-between p-3 bg-slate-50 rounded-xl">
              <div className="flex items-center gap-3">
                <span className="w-6 h-6 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center text-xs font-bold">{i + 1}</span>
                <span className="font-medium text-sm">{st.StationName}</span>
              </div>
              <div className="text-right">
                <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                  st.StationStatus === 'Active' ? 'bg-emerald-100 text-emerald-700' : 'bg-amber-100 text-amber-700'
                }`}>{st.StationStatus}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
