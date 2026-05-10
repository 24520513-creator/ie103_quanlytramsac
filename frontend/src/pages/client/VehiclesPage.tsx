import { useState, useEffect, type FormEvent } from 'react';
import { Plus, Trash2, Car, Loader2 } from 'lucide-react';
import { motion } from 'motion/react';
import { api } from '../../services/api';
import PageHeader from '../../components/ui/PageHeader';
import Modal from '../../components/ui/Modal';
import StatusBadge from '../../components/ui/StatusBadge';
import type { Vehicle } from '../../types';

export default function VehiclesPage() {
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState({ PlateNumber: '', Brand: '', Model: '', ModelYear: '', BatteryCapacityKWh: '', ConnectorType: 'CCS2' });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const loadVehicles = () => {
    api.get('/vehicles').then(r => setVehicles(Array.isArray(r.data) ? r.data : []))
      .finally(() => setLoading(false));
  };

  useEffect(() => { loadVehicles(); }, []);

  const handleAdd = async (e: FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setError('');
    try {
      await api.post('/vehicles', {
        PlateNumber: form.PlateNumber,
        Brand: form.Brand,
        Model: form.Model,
        ModelYear: form.ModelYear ? parseInt(form.ModelYear) : null,
        BatteryCapacityKWh: form.BatteryCapacityKWh ? parseFloat(form.BatteryCapacityKWh) : null,
        ConnectorType: form.ConnectorType,
      });
      setShowModal(false);
      setForm({ PlateNumber: '', Brand: '', Model: '', ModelYear: '', BatteryCapacityKWh: '', ConnectorType: 'CCS2' });
      loadVehicles();
    } catch (err: any) { setError(err.message); }
    finally { setSaving(false); }
  };

  const handleDelete = async (id: number) => {
    if (!confirm('Xóa phương tiện này?')) return;
    try {
      await api.delete(`/vehicles/${id}`);
      loadVehicles();
    } catch (err: any) { alert(err.message); }
  };

  if (loading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;

  return (
    <div className="space-y-6">
      <PageHeader title="Quản lý xe" subtitle={`${vehicles.length} phương tiện`}
        actions={<button onClick={() => setShowModal(true)}
          className="flex items-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-xl hover:bg-blue-700 transition-colors font-medium text-sm">
          <Plus className="w-4 h-4" /> Thêm xe</button>} />

      {vehicles.length === 0 ? (
        <div className="text-center py-20 text-slate-400">
          <Car className="w-16 h-16 mx-auto mb-4 opacity-50" />
          <p className="text-lg">Chưa có phương tiện nào</p>
          <p className="text-sm">Thêm phương tiện để bắt đầu sạc</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {vehicles.map(v => (
            <motion.div key={v.VehicleID} whileHover={{ y: -2 }}
              className="bg-white rounded-2xl border border-slate-200 p-5">
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center">
                    <Car className="w-6 h-6 text-blue-600" />
                  </div>
                  <div>
                    <p className="font-semibold text-slate-900">{v.Brand} {v.Model}</p>
                    <p className="text-xs text-slate-500">{v.PlateNumber}</p>
                  </div>
                </div>
                <button onClick={() => handleDelete(v.VehicleID)}
                  className="p-2 hover:bg-red-50 rounded-lg text-red-400 hover:text-red-600 transition-colors">
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
              <div className="grid grid-cols-2 gap-2 text-sm">
                <div className="bg-slate-50 rounded-lg p-2">
                  <p className="text-xs text-slate-500">Pin</p>
                  <p className="font-medium">{v.BatteryCapacityKWh || '?'} kWh</p>
                </div>
                <div className="bg-slate-50 rounded-lg p-2">
                  <p className="text-xs text-slate-500">Kết nối</p>
                  <p className="font-medium">{v.ConnectorType || '?'}</p>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      )}

      <Modal open={showModal} onClose={() => setShowModal(false)} title="Thêm phương tiện">
        {error && <div className="bg-red-50 text-red-600 text-sm p-3 rounded-xl mb-4">{error}</div>}
        <form onSubmit={handleAdd} className="space-y-4">
          <div>
            <label className="block text-xs font-bold text-slate-500 uppercase mb-1">Biển số</label>
            <input type="text" value={form.PlateNumber} onChange={e => setForm(p => ({...p, PlateNumber: e.target.value}))} required
              className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold text-slate-500 uppercase mb-1">Hãng</label>
              <input type="text" value={form.Brand} onChange={e => setForm(p => ({...p, Brand: e.target.value}))} required
                className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-500 uppercase mb-1">Model</label>
              <input type="text" value={form.Model} onChange={e => setForm(p => ({...p, Model: e.target.value}))} required
                className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold text-slate-500 uppercase mb-1">Năm SX</label>
              <input type="number" value={form.ModelYear} onChange={e => setForm(p => ({...p, ModelYear: e.target.value}))}
                className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-500 uppercase mb-1">Dung lượng pin</label>
              <input type="number" step="0.1" value={form.BatteryCapacityKWh} onChange={e => setForm(p => ({...p, BatteryCapacityKWh: e.target.value}))}
                className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
          </div>
          <div>
            <label className="block text-xs font-bold text-slate-500 uppercase mb-1">Loại kết nối</label>
            <select value={form.ConnectorType} onChange={e => setForm(p => ({...p, ConnectorType: e.target.value}))}
              className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500">
              <option value="CCS2">CCS2</option>
              <option value="Type2">Type 2</option>
              <option value="CHAdeMO">CHAdeMO</option>
            </select>
          </div>
          <button type="submit" disabled={saving}
            className="w-full py-3 bg-blue-600 text-white font-bold rounded-xl hover:bg-blue-700 disabled:opacity-50">
            {saving ? 'Đang lưu...' : 'Thêm phương tiện'}
          </button>
        </form>
      </Modal>
    </div>
  );
}
