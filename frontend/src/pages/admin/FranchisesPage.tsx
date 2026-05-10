import { useState, useEffect } from 'react';
import { Plus, Search, Loader2 } from 'lucide-react';
import { api } from '../../services/api';
import PageHeader from '../../components/ui/PageHeader';
import StatusBadge from '../../components/ui/StatusBadge';
import DataTable from '../../components/ui/DataTable';
import Modal from '../../components/ui/Modal';
import type { Franchise } from '../../types';
import type { Column } from '../../components/ui/DataTable';

export default function AdminFranchisesPage() {
  const [franchises, setFranchises] = useState<Franchise[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    api.get('/franchises').then(r => {
      setFranchises(Array.isArray(r.data) ? r.data : []);
    }).finally(() => setLoading(false));
  }, []);

  const filtered = franchises.filter(f =>
    f.FranchiseName?.toLowerCase().includes(search.toLowerCase()) ||
    f.TaxCode?.toLowerCase().includes(search.toLowerCase())
  );

  const columns: Column<Franchise>[] = [
    { key: 'FranchiseCode', label: 'Mã' },
    { key: 'FranchiseName', label: 'Tên đối tác' },
    { key: 'TaxCode', label: 'Mã số thuế' },
    { key: 'ContactPerson', label: 'Người liên hệ' },
    { key: 'ContactPhone', label: 'Điện thoại' },
    { key: 'RevenueShareRate', label: 'Hoa hồng', render: v => `${v || 0}%` },
    { key: 'ContractSignedDate', label: 'Ngày ký', render: v => v ? new Date(v).toLocaleDateString('vi-VN') : '-' },
    { key: 'IsActive', label: 'Trạng thái', render: v => <StatusBadge status={v ? 'Active' : 'Inactive'} /> },
  ];

  if (loading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;

  return (
    <div className="space-y-6">
      <PageHeader title="Đối tác nhượng quyền" subtitle={`${franchises.length} đối tác`}
        actions={<button className="flex items-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-xl hover:bg-blue-700 text-sm font-medium">
          <Plus className="w-4 h-4" /> Thêm đối tác</button>} />
      <div className="relative">
        <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
        <input type="text" value={search} onChange={e => setSearch(e.target.value)} placeholder="Tìm đối tác..."
          className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl outline-none text-sm" />
      </div>
      <DataTable columns={columns} data={filtered} />
    </div>
  );
}
