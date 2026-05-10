import { useState, useEffect } from 'react';
import { Plus, Search, Loader2 } from 'lucide-react';
import { api } from '../../services/api';
import PageHeader from '../../components/ui/PageHeader';
import StatusBadge from '../../components/ui/StatusBadge';
import DataTable from '../../components/ui/DataTable';
import type { ElectricitySupplier } from '../../types';
import type { Column } from '../../components/ui/DataTable';

export default function AdminSuppliersPage() {
  const [suppliers, setSuppliers] = useState<ElectricitySupplier[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    api.get('/electricity-suppliers').then(r => {
      setSuppliers(Array.isArray(r.data) ? r.data : []);
    }).finally(() => setLoading(false));
  }, []);

  const filtered = suppliers.filter(s =>
    s.SupplierName?.toLowerCase().includes(search.toLowerCase())
  );

  const columns: Column<ElectricitySupplier>[] = [
    { key: 'SupplierCode', label: 'Mã' },
    { key: 'SupplierName', label: 'Tên nhà cung cấp' },
    { key: 'ContactPerson', label: 'Người liên hệ' },
    { key: 'ContactPhone', label: 'Điện thoại' },
    { key: 'ContactEmail', label: 'Email' },
    { key: 'IsActive', label: 'Trạng thái', render: v => <StatusBadge status={v ? 'Active' : 'Inactive'} /> },
  ];

  if (loading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;

  return (
    <div className="space-y-6">
      <PageHeader title="Nhà cung cấp điện" subtitle={`${suppliers.length} nhà cung cấp`}
        actions={<button className="flex items-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-xl hover:bg-blue-700 text-sm font-medium">
          <Plus className="w-4 h-4" /> Thêm</button>} />
      <div className="relative">
        <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
        <input type="text" value={search} onChange={e => setSearch(e.target.value)} placeholder="Tìm nhà cung cấp..."
          className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl outline-none text-sm" />
      </div>
      <DataTable columns={columns} data={filtered} />
    </div>
  );
}
