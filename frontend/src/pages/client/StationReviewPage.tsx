import { useState, useEffect, type FormEvent } from 'react';
import { Star, Loader2 } from 'lucide-react';
import { motion } from 'motion/react';
import { cn } from '../../lib/utils';
import { api } from '../../services/api';
import PageHeader from '../../components/ui/PageHeader';
import type { StationReview, ChargingStation } from '../../types';

export default function StationReviewPage() {
  const [reviews, setReviews] = useState<StationReview[]>([]);
  const [stations, setStations] = useState<ChargingStation[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ StationID: 0, Rating: 5, Comment: '' });
  const [saving, setSaving] = useState(false);

  const load = () => {
    Promise.all([
      api.get('/station-reviews').catch(() => ({ data: [] })),
      api.get('/stations').catch(() => ({ data: [] })),
    ]).then(([rRes, sRes]) => {
      setReviews(Array.isArray(rRes?.data) ? rRes.data : []);
      setStations(Array.isArray(sRes?.data) ? sRes.data : []);
    }).finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setSaving(true);
    try {
      await api.post('/station-reviews', form);
      setShowForm(false);
      setForm({ StationID: 0, Rating: 5, Comment: '' });
      load();
    } catch (err: any) { alert(err.message); }
    finally { setSaving(false); }
  };

  if (loading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;

  return (
    <div className="space-y-6">
      <PageHeader title="Đánh giá trạm sạc" subtitle={`${reviews.length} đánh giá`}
        actions={<button onClick={() => setShowForm(true)}
          className="px-4 py-2.5 bg-blue-600 text-white rounded-xl hover:bg-blue-700 text-sm font-medium">
          Viết đánh giá</button>} />

      {reviews.length === 0 ? (
        <div className="text-center py-16 text-slate-400">
          <Star className="w-16 h-16 mx-auto mb-4 opacity-50" />
          <p>Chưa có đánh giá</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {reviews.map(r => (
            <motion.div key={r.ReviewID} whileHover={{ y: -1 }}
              className="bg-white rounded-2xl border border-slate-200 p-5">
              <div className="flex items-center gap-1 mb-2">
                {[1,2,3,4,5].map(i => (
                  <Star key={i} className={cn('w-4 h-4', i <= r.Rating ? 'text-amber-400 fill-amber-400' : 'text-slate-200')} />
                ))}
                <span className="text-sm font-medium text-slate-600 ml-2">{r.Rating}/5</span>
              </div>
              {r.Comment && <p className="text-sm text-slate-700 mb-2">{r.Comment}</p>}
              <p className="text-xs text-slate-400">{r.FullName || 'Người dùng'} · {new Date(r.CreatedAt || '').toLocaleDateString('vi-VN')}</p>
            </motion.div>
          ))}
        </div>
      )}

      {showForm && (
        <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm flex items-center justify-center"
          onClick={() => setShowForm(false)}>
          <motion.div initial={{ scale: 0.9 }} animate={{ scale: 1 }}
            className="bg-white rounded-2xl max-w-lg w-full mx-4 p-6" onClick={e => e.stopPropagation()}>
            <h2 className="text-lg font-bold mb-4">Viết đánh giá</h2>
            <form onSubmit={handleSubmit} className="space-y-4">
              <select value={form.StationID} onChange={e => setForm(p => ({...p, StationID: parseInt(e.target.value)}))} required
                className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl outline-none">
                <option value={0}>Chọn trạm</option>
                {stations.filter(s => s.IsActive !== false).map(s => (
                  <option key={s.StationID} value={s.StationID}>{s.StationName}</option>
                ))}
              </select>
              <div className="flex items-center gap-2">
                <span className="text-sm font-medium">Đánh giá:</span>
                {[1,2,3,4,5].map(i => (
                  <button key={i} type="button" onClick={() => setForm(p => ({...p, Rating: i}))}>
                    <Star className={cn('w-6 h-6', i <= form.Rating ? 'text-amber-400 fill-amber-400' : 'text-slate-200')} />
                  </button>
                ))}
              </div>
              <textarea value={form.Comment} onChange={e => setForm(p => ({...p, Comment: e.target.value}))}
                placeholder="Chia sẻ trải nghiệm của bạn..." rows={3}
                className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl outline-none resize-none" />
              <button type="submit" disabled={saving}
                className="w-full py-3 bg-blue-600 text-white font-bold rounded-xl hover:bg-blue-700 disabled:opacity-50">
                {saving ? 'Đang gửi...' : 'Gửi đánh giá'}
              </button>
            </form>
          </motion.div>
        </div>
      )}
    </div>
  );
}
