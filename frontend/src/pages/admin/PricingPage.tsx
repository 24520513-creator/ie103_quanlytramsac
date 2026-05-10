import { useState, useEffect } from 'react';
import { Plus, Loader2 } from 'lucide-react';
import { motion } from 'motion/react';
import { api } from '../../services/api';
import PageHeader from '../../components/ui/PageHeader';
import StatusBadge from '../../components/ui/StatusBadge';
import type { PricingPolicy } from '../../types';

export default function AdminPricingPage() {
  const [policies, setPolicies] = useState<PricingPolicy[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get('/pricing-policies').then(r => {
      setPolicies(Array.isArray(r.data) ? r.data : []);
    }).finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;

  return (
    <div className="space-y-6">
      <PageHeader title="Chính sách giá" subtitle={`${policies.length} chính sách`}
        actions={<button className="flex items-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-xl hover:bg-blue-700 text-sm font-medium">
          <Plus className="w-4 h-4" /> Thêm chính sách</button>} />

      {policies.length === 0 ? (
        <div className="text-center py-20 text-slate-400">Chưa có chính sách giá</div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
          {policies.map(p => (
            <motion.div key={p.PolicyID} whileHover={{ y: -2 }}
              className="bg-white rounded-2xl border border-slate-200 p-5">
              <div className="flex items-start justify-between mb-3">
                <div>
                  <h3 className="font-semibold text-slate-900">{p.PolicyName}</h3>
                  <p className="text-xs text-slate-500">{p.PolicyCode}</p>
                </div>
                <StatusBadge status={p.IsActive ? 'Active' : 'Inactive'} />
              </div>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between p-2 bg-slate-50 rounded-lg">
                  <span className="text-slate-600">Giá cơ bản</span>
                  <span className="font-bold">{p.BasePricePerKWh?.toLocaleString()} VND/kWh</span>
                </div>
                <div className="flex justify-between p-2 bg-slate-50 rounded-lg">
                  <span className="text-slate-600">Giờ cao điểm</span>
                  <span className="font-medium">{p.PeakMultiplier ? `${p.PeakMultiplier}x` : 'Không'}</span>
                </div>
                <div className="flex justify-between p-2 bg-slate-50 rounded-lg">
                  <span className="text-slate-600">Hiệu lực</span>
                  <span className="font-medium text-xs">
                    {new Date(p.AppliedFrom).toLocaleDateString('vi-VN')}
                    {p.AppliedTo ? ` - ${new Date(p.AppliedTo).toLocaleDateString('vi-VN')}` : ''}
                  </span>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      )}
    </div>
  );
}
