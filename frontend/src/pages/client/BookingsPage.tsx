import { useState, type FormEvent } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { Calendar, Plus, X, Loader2 } from 'lucide-react';
import { motion } from 'motion/react';
import { api } from '../../services/api';
import { useSocketEvent } from '../../lib/useSocket';
import { useBookings, useStations, usePoints } from '../../lib/useApi';
import { queryKeys } from '../../lib/queryKeys';
import PageHeader from '../../components/ui/PageHeader';
import StatusBadge from '../../components/ui/StatusBadge';

export default function BookingsPage() {
  const qc = useQueryClient();
  const { data: bookings = [], isLoading: bookingsLoading } = useBookings();
  const { data: stations = [], isLoading: stationsLoading } = useStations();
  const { data: points = [], isLoading: pointsLoading } = usePoints();
  const [showCreate, setShowCreate] = useState(false);
  const [form, setForm] = useState({ StationID: 0, PointID: 0, BookedFrom: '', BookedTo: '' });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  useSocketEvent('booking:created', () => {
    qc.invalidateQueries({ queryKey: queryKeys.bookings.all() });
  });

  useSocketEvent('booking:confirmed', () => {
    qc.invalidateQueries({ queryKey: queryKeys.bookings.all() });
  });

  useSocketEvent('booking:cancelled', () => {
    qc.invalidateQueries({ queryKey: queryKeys.bookings.all() });
  });

  const handleCreate = async (e: FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setError('');
    try {
      const normalizeDate = (d: string) => d && d.length === 16 ? d + ':00' : d;
      const payload = {
        ...form,
        BookedFrom: normalizeDate(form.BookedFrom),
        BookedTo: normalizeDate(form.BookedTo),
      };
      await api.post('/bookings', payload);
      setShowCreate(false);
      setForm({ StationID: 0, PointID: 0, BookedFrom: '', BookedTo: '' });
      qc.invalidateQueries({ queryKey: queryKeys.bookings.all() });
    } catch (err: any) { setError(err.message); }
    finally { setSaving(false); }
  };

  const handleCancel = async (id: number) => {
    try {
      await api.post(`/bookings/${id}/cancel`, { reason: 'CancelledByUser' });
      qc.invalidateQueries({ queryKey: queryKeys.bookings.all() });
    } catch (err: any) { alert(err.message); }
  };

  const handleConfirm = async (id: number) => {
    try {
      await api.post(`/bookings/${id}/confirm`);
      qc.invalidateQueries({ queryKey: queryKeys.bookings.all() });
    } catch (err: any) { alert(err.message); }
  };

  const filteredPoints = form.StationID ? points.filter((p: any) => p.StationID === form.StationID) : [];

  if (bookingsLoading || stationsLoading || pointsLoading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;

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
                  {new Date(b.BookedFrom).toLocaleString('vi-VN')} - {new Date(b.BookedTo).toLocaleTimeString('vi-VN')}
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
              <input type="datetime-local" value={form.BookedFrom} onChange={e => setForm(p => ({...p, BookedFrom: e.target.value}))} required
                className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl outline-none" />
              <input type="datetime-local" value={form.BookedTo} onChange={e => setForm(p => ({...p, BookedTo: e.target.value}))} required
                className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl outline-none" />
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
