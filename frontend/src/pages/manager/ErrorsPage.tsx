import { useState, useEffect } from 'react';
import { AlertTriangle, CheckCircle, Loader2 } from 'lucide-react';
import { motion } from 'motion/react';
import { api } from '../../services/api';
import PageHeader from '../../components/ui/PageHeader';
import StatusBadge from '../../components/ui/StatusBadge';
import type { ErrorLog } from '../../types';

export default function ManagerErrorsPage() {
  const [errors, setErrors] = useState<ErrorLog[]>([]);
  const [loading, setLoading] = useState(true);

  const load = () => {
    api.get('/error-logs').then(r => {
      setErrors(Array.isArray(r.data) ? r.data : []);
    }).finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  const handleResolve = async (id: number) => {
    try {
      await api.post(`/errors/${id}/resolve`);
      load();
    } catch (err: any) { alert(err.message); }
  };

  if (loading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;

  const unresolved = errors.filter(e => !e.IsResolved);
  const resolved = errors.filter(e => e.IsResolved);

  return (
    <div className="space-y-6">
      <PageHeader title="Lỗi hệ thống" subtitle={`${unresolved.length} lỗi chưa xử lý`} />

      {unresolved.length > 0 && (
        <div className="space-y-3">
          <h3 className="font-semibold text-slate-900">Chưa xử lý</h3>
          {unresolved.map(e => (
            <motion.div key={e.ErrorLogID} whileHover={{ y: -1 }}
              className="bg-white rounded-2xl border-l-4 border-l-red-500 border border-slate-200 p-5">
              <div className="flex items-start justify-between">
                <div className="flex items-start gap-3">
                  <AlertTriangle className="w-5 h-5 text-red-500 mt-0.5" />
                  <div>
                    <p className="font-semibold text-slate-900">{e.ErrorCode}</p>
                    <p className="text-sm text-slate-600">{e.Message || e.ErrorSource}</p>
                    <div className="flex items-center gap-3 mt-2 text-xs text-slate-500">
                      <StatusBadge status={e.Severity} />
                      <span>Điểm {e.PointCode || `#${e.PointID}`}</span>
                      <span>{new Date(e.CreatedAt || '').toLocaleString('vi-VN')}</span>
                    </div>
                  </div>
                </div>
                <button onClick={() => handleResolve(e.ErrorLogID)}
                  className="flex items-center gap-1 px-3 py-1.5 bg-emerald-50 text-emerald-700 rounded-lg text-sm font-medium hover:bg-emerald-100">
                  <CheckCircle className="w-4 h-4" /> Xử lý
                </button>
              </div>
            </motion.div>
          ))}
        </div>
      )}

      {resolved.length > 0 && (
        <div className="space-y-3">
          <h3 className="font-semibold text-slate-900">Đã xử lý</h3>
          {resolved.map(e => (
            <div key={e.ErrorLogID} className="bg-slate-50 rounded-2xl border border-slate-200 p-4 opacity-70">
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <CheckCircle className="w-5 h-5 text-emerald-500" />
                  <div>
                    <p className="font-medium text-slate-700">{e.ErrorCode}</p>
                    <p className="text-xs text-slate-400">{new Date(e.ResolvedAt || '').toLocaleString('vi-VN')}</p>
                  </div>
                </div>
                <StatusBadge status="resolved" />
              </div>
            </div>
          ))}
        </div>
      )}

      {errors.length === 0 && (
        <div className="text-center py-20 text-slate-400">
          <AlertTriangle className="w-16 h-16 mx-auto mb-4 opacity-50" />
          <p>Không có lỗi nào</p>
        </div>
      )}
    </div>
  );
}
