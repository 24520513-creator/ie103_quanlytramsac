import { useState, useEffect } from 'react';
import { Search, Loader2 } from 'lucide-react';
import { api } from '../../services/api';
import PageHeader from '../../components/ui/PageHeader';
import StatusBadge from '../../components/ui/StatusBadge';
import DataTable from '../../components/ui/DataTable';
import type { ChargingSession } from '../../types';
import type { Column } from '../../components/ui/DataTable';

export default function ManagerSessionsPage() {
  const [sessions, setSessions] = useState<ChargingSession[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('');

  useEffect(() => {
    api.get('/sessions').then(r => {
      setSessions(Array.isArray(r.data) ? r.data : []);
    }).finally(() => setLoading(false));
  }, []);

  const filtered = sessions.filter(s => {
    const matchSearch = !search || s.StationName?.toLowerCase().includes(search.toLowerCase()) || s.FullName?.toLowerCase().includes(search.toLowerCase());
    const matchFilter = !filter || s.SessionStatus === filter;
    return matchSearch && matchFilter;
  });

  const columns: Column<ChargingSession>[] = [
    { key: 'SessionCode', label: 'Mã', render: (v, r) => v || `#${r.SessionID}` },
    { key: 'FullName', label: 'Khách hàng' },
    { key: 'StationName', label: 'Trạm' },
    { key: 'PointCode', label: 'Điểm' },
    { key: 'StartTime', label: 'Bắt đầu', render: v => new Date(v).toLocaleString('vi-VN') },
    { key: 'TotalKWh', label: 'kWh', render: v => v?.toFixed(1) || '-' },
    { key: 'CostTotal', label: 'Chi phí', render: v => v ? `${v.toLocaleString()} VND` : '-' },
    { key: 'SessionStatus', label: 'Trạng thái', render: v => <StatusBadge status={v} /> },
  ];

  if (loading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;

  return (
    <div className="space-y-6">
      <PageHeader title="Phiên sạc" subtitle={`${sessions.length} phiên`} />
      <div className="flex gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
          <input type="text" value={search} onChange={e => setSearch(e.target.value)} placeholder="Tìm kiếm..."
            className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500 text-sm" />
        </div>
        <select value={filter} onChange={e => setFilter(e.target.value)}
          className="px-4 py-2.5 bg-white border border-slate-200 rounded-xl outline-none text-sm">
          <option value="">Tất cả</option>
          <option value="Charging">Đang sạc</option>
          <option value="Completed">Hoàn thành</option>
          <option value="Cancelled">Đã hủy</option>
          <option value="Failed">Lỗi</option>
        </select>
      </div>
      <DataTable columns={columns} data={filtered} />
    </div>
  );
}
