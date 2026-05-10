import { useState, useEffect, type FormEvent } from 'react';
import { Calendar, Plus, X, Loader2 } from 'lucide-react';
import { motion } from 'motion/react';
import { api } from '../../services/api';
import PageHeader from '../../components/ui/PageHeader';
import StatusBadge from '../../components/ui/StatusBadge';
import type { Booking, ChargingStation, ChargingPoint } from '../../types';

export default function BookingsPage() {
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [stations, setStations] = useState<ChargingStation[]>([]);
  const [points, setPoints] = useState<ChargingPoint[]>([]);
  const [form, setForm] = useState({ StationID: 0, PointID: 0, StartTime: '', EndTime: '', Notes: '' });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const load = () => {
    setLoading(true);
    Promise.all([
      api.get('/bookings').catch(() => ({ data: [] })),
      api.get('/stations').catch(() => ({ data: [] })),
      api.get('/points').catch(() => ({ data: [] })),
    ]).then(([bRes, sRes, pRes]) => {
      setBookings(Array.isArray(bRes?.data) ? bRes.data : []);
      setStations(Array.isArray(sRes?.data) ? sRes.data : []);
      setPoints(Array.isArray(pRes?.data) ? pRes.data : []);
    }).finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  const handleCreate = async (e: FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setError('');
    try {
      await api.post('/bookings', form);
      setShowCreate(false);
      setForm({ StationID: 0, PointID: 0, StartTime: '', EndTime: '', Notes: '' });
      load();
    } catch (err: any) { setError(err.message); }
    finally { setSaving(false); }
  };

  const handleCancel = async (id: number) => {
    try {
      await api.post(`/bookings/${id}/cancel`, { reason: 'CancelledByUser' });
      load();
    } catch (err: any) { alert(err.message); }
  };

  const handleConfirm = async (id: number) => {
    try {
      await api.post(`/bookings/${id}/confirm`);
      load();
    } catch (err: any) { alert(err.message); }
  };

  const filteredPoints = form.StationID ? points.filter(p => p.StationID === form.StationID) : [];

  if (loading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;

  return (
    <div className="space-y-6">
      <PageHeader title="Đặt lịch sạc" subtitle={`${bookings.length} lịch hẹn`}
        actions={<button onClick={() => setShowCreate(true)}
          className="flex items-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-xl hover:bg-blue-700 text-sm font-medium">
          <Plus className="w-4 h-4" /> Đặt lịch</button>} />

      <div className="space-y-4">
        {bookings.length === 0 ? (
          <div className="text-center py-16 text-slate-400">
            <Calendar className="w-16 h-16 mx-auto mb-4 opacity-50" />
            <p>Chưa có lịch đặt nào</p>
          </div>
        ) : (
          bookings.map(b => (
            <motion.div key={b.BookingID} whileHover={{ y: -1 }}
              className="bg-white rounded-2xl border border-slate-200 p-5">
              <div className="flex items-center justify-between mb-3">
                <div>
                  <p className="font-semibold text-slate-900">{b.StationName || `Trạm #${b.StationID}`}</p>
                  <p className="text-sm text-slate-500">Điểm {b.PointCode} · {b.PlateNumber || ''}</p>
                </div>
                <StatusBadge status={b.Status} />
              </div>
              <div className="flex items-center gap-4 text-sm text-slate-600 mb-3">
                <span className="flex items-center gap-1">
                  <Calendar className="w-4 h-4" />
                  {new Date(b.StartTime).toLocaleString('vi-VN')} - {new Date(b.EndTime).toLocaleTimeString('vi-VN')}
                </span>
              </div>
              <div className="flex gap-2">
                {b.Status === 'Pending' && (
                  <button onClick={() => handleConfirm(b.BookingID)}
                    className="px-4 py-2 bg-emerald-500 text-white rounded-lg text-sm font-medium hover:bg-emerald-600">
                    Xác nhận
                  </button>
                )}
                {(b.Status === 'Pending' || b.Status === 'Confirmed') && (
                  <button onClick={() => handleCancel(b.BookingID)}
                    className="px-4 py-2 bg-red-50 text-red-600 rounded-lg text-sm font-medium hover:bg-red-100">
                    Hủy
                  </button>
                )}
              </div>
            </motion.div>
          ))
        )}
      </div>

      {showCreate && (
        <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm flex items-center justify-center"
          onClick={() => setShowCreate(false)}>
          <motion.div initial={{ scale: 0.9 }} animate={{ scale: 1 }}
            className="bg-white rounded-2xl max-w-lg w-full mx-4 p-6" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-bold">Đặt lịch sạc</h2>
              <button onClick={() => setShowCreate(false)} className="p-1 hover:bg-slate-100 rounded-lg"><X className="w-5 h-5" /></button>
            </div>
            {error && <div className="bg-red-50 text-red-600 text-sm p-3 rounded-xl mb-4">{error}</div>}
            <form onSubmit={handleCreate} className="space-y-4">
              <select value={form.StationID} onChange={e => setForm(p => ({...p, StationID: parseInt(e.target.value), PointID: 0}))} required
                className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl outline-none">
                <option value={0}>Chọn trạm</option>
                {stations.filter(s => s.IsActive !== false).map(s => (
                  <option key={s.StationID} value={s.StationID}>{s.StationName}</option>
                ))}
              </select>
              <select value={form.PointID} onChange={e => setForm(p => ({...p, PointID: parseInt(e.target.value)}))} required
                className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl outline-none">
                <option value={0}>Chọn điểm sạc</option>
                {filteredPoints.filter(p => p.PointStatus === 'Available').map(p => (
                  <option key={p.PointID} value={p.PointID}>{p.PointCode} - {p.PowerKW}kW</option>
                ))}
              </select>
              <input type="datetime-local" value={form.StartTime} onChange={e => setForm(p => ({...p, StartTime: e.target.value}))} required
                className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl outline-none" />
              <input type="datetime-local" value={form.EndTime} onChange={e => setForm(p => ({...p, EndTime: e.target.value}))} required
                className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl outline-none" />
              <textarea value={form.Notes} onChange={e => setForm(p => ({...p, Notes: e.target.value}))} placeholder="Ghi chú"
                className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl outline-none resize-none" rows={2} />
              <button type="submit" disabled={saving}
                className="w-full py-3 bg-blue-600 text-white font-bold rounded-xl hover:bg-blue-700 disabled:opacity-50">
                {saving ? 'Đang đặt...' : 'Đặt lịch'}
              </button>
            </form>
          </motion.div>
        </div>
      )}
    </div>
  );
}
