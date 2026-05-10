import { useState, useEffect } from 'react';
import { Search, Download, Loader2 } from 'lucide-react';
import { api } from '../../services/api';
import PageHeader from '../../components/ui/PageHeader';
import StatusBadge from '../../components/ui/StatusBadge';
import type { ChargingSession } from '../../types';

export default function HistoryPage() {
  const [sessions, setSessions] = useState<ChargingSession[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('');

  useEffect(() => {
    api.get('/sessions/history').then(r => {
      setSessions(Array.isArray(r.data) ? r.data : []);
    }).finally(() => setLoading(false));
  }, []);

  const filtered = sessions.filter(s => {
    const matchSearch = !search ||
      s.StationName?.toLowerCase().includes(search.toLowerCase()) ||
      s.SessionCode?.toLowerCase().includes(search.toLowerCase());
    const matchFilter = !filter || s.SessionStatus === filter;
    return matchSearch && matchFilter;
  });

  if (loading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;

  return (
    <div className="space-y-6">
      <PageHeader title="Lịch sử sạc" subtitle={`${sessions.length} phiến sạc`}
        actions={<button className="flex items-center gap-2 px-4 py-2.5 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 text-sm font-medium">
          <Download className="w-4 h-4" /> Xuất Excel</button>} />

      <div className="flex gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
          <input type="text" value={search} onChange={e => setSearch(e.target.value)}
            placeholder="Tìm kiếm..." className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500 text-sm" />
        </div>
        <select value={filter} onChange={e => setFilter(e.target.value)}
          className="px-4 py-2.5 bg-white border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500 text-sm">
          <option value="">Tất cả</option>
          <option value="Completed">Hoàn thành</option>
          <option value="Cancelled">Đã hủy</option>
          <option value="Failed">Lỗi</option>
        </select>
      </div>

      <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden">
        <table className="w-full">
          <thead>
            <tr className="bg-slate-50 border-b border-slate-200">
              <th className="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase">Mã phiên</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase">Trạm</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase">Thời gian</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase">kWh</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase">Chi phí</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase">Trạng thái</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {filtered.map(s => (
              <tr key={s.SessionID} className="hover:bg-slate-50">
                <td className="px-4 py-3 text-sm font-medium text-slate-900">{s.SessionCode || `#${s.SessionID}`}</td>
                <td className="px-4 py-3 text-sm text-slate-700">{s.StationName || `Trạm #${s.StationID}`}</td>
                <td className="px-4 py-3 text-sm text-slate-500">{new Date(s.StartTime).toLocaleString('vi-VN')}</td>
                <td className="px-4 py-3 text-sm font-medium">{s.TotalKWh?.toFixed(1)}</td>
                <td className="px-4 py-3 text-sm font-medium">{s.CostTotal?.toLocaleString()} VND</td>
                <td className="px-4 py-3"><StatusBadge status={s.SessionStatus} /></td>
              </tr>
            ))}
          </tbody>
        </table>
        {filtered.length === 0 && <p className="text-center text-slate-400 py-8">Không có dữ liệu</p>}
      </div>
    </div>
  );
}
