import { useState, useEffect } from 'react';
import { Search, Loader2 } from 'lucide-react';
import { api } from '../../services/api';
import PageHeader from '../../components/ui/PageHeader';
import StatusBadge from '../../components/ui/StatusBadge';
import DataTable from '../../components/ui/DataTable';
import type { User } from '../../types';
import type { Column } from '../../components/ui/DataTable';

export default function AdminUsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    api.get('/users').then(r => {
      setUsers(Array.isArray(r.data) ? r.data : []);
    }).finally(() => setLoading(false));
  }, []);

  const filtered = users.filter(u =>
    u.FullName?.toLowerCase().includes(search.toLowerCase()) ||
    u.Email?.toLowerCase().includes(search.toLowerCase()) ||
    u.Username?.toLowerCase().includes(search.toLowerCase())
  );

  const columns: Column<User>[] = [
    { key: 'Username', label: 'Username' },
    { key: 'FullName', label: 'Họ tên' },
    { key: 'Email', label: 'Email' },
    { key: 'Phone', label: 'Điện thoại' },
    { key: 'Role', label: 'Vai trò', render: v => <StatusBadge status={v} /> },
    { key: 'AccountStatus', label: 'Trạng thái', render: v => <StatusBadge status={v} /> },
    { key: 'CreatedAt', label: 'Ngày tạo', render: v => v ? new Date(v).toLocaleDateString('vi-VN') : '-' },
  ];

  if (loading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;

  return (
    <div className="space-y-6">
      <PageHeader title="Quản lý người dùng" subtitle={`${users.length} người dùng`} />
      <div className="relative">
        <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
        <input type="text" value={search} onChange={e => setSearch(e.target.value)} placeholder="Tìm người dùng..."
          className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl outline-none text-sm" />
      </div>
      <DataTable columns={columns} data={filtered} />
    </div>
  );
}
