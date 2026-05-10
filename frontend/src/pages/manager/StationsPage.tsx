import { useState, useEffect } from 'react';
import { Search, Plus, MapPin, Zap, Loader2, Wifi, WifiOff } from 'lucide-react';
import { motion } from 'motion/react';
import { api } from '../../services/api';
import PageHeader from '../../components/ui/PageHeader';
import StatusBadge from '../../components/ui/StatusBadge';
import type { ChargingStation, ChargingPoint } from '../../types';

export default function ManagerStationsPage() {
  const [stations, setStations] = useState<ChargingStation[]>([]);
  const [points, setPoints] = useState<ChargingPoint[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [selected, setSelected] = useState<ChargingStation | null>(null);

  useEffect(() => {
    Promise.all([
      api.get('/stations').catch(() => ({ data: [] })),
      api.get('/points').catch(() => ({ data: [] })),
    ]).then(([sRes, pRes]) => {
      setStations(Array.isArray(sRes.data) ? sRes.data : []);
      setPoints(Array.isArray(pRes.data) ? pRes.data : []);
    }).finally(() => setLoading(false));
  }, []);

  const filtered = stations.filter(s =>
    s.StationName?.toLowerCase().includes(search.toLowerCase()) && s.IsActive !== false
  );
  const stationPoints = selected ? points.filter(p => p.StationID === selected.StationID) : [];

  if (loading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;

  return (
    <div className="space-y-6">
      <PageHeader title="Quản lý trạm" subtitle={`${stations.length} trạm sạc`}
        actions={<button className="flex items-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-xl hover:bg-blue-700 text-sm font-medium">
          <Plus className="w-4 h-4" /> Thêm trạm</button>} />

      <div className="relative">
        <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
        <input type="text" value={search} onChange={e => setSearch(e.target.value)} placeholder="Tìm trạm..."
          className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500 text-sm" />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
        {filtered.map(st => {
          const pt = points.filter(p => p.StationID === st.StationID);
          const available = pt.filter(p => p.PointStatus === 'Available').length;
          return (
            <motion.div key={st.StationID} whileHover={{ y: -2 }}
              onClick={() => setSelected(st)}
              className="bg-white rounded-2xl border border-slate-200 p-5 cursor-pointer hover:shadow-lg transition-shadow">
              <div className="flex items-start justify-between mb-3">
                <div>
                  <h3 className="font-semibold text-slate-900">{st.StationName}</h3>
                  <p className="text-xs text-slate-500">{st.StationCode}</p>
                </div>
                <StatusBadge status={st.StationStatus} />
              </div>
              <div className="flex items-center gap-4 text-sm text-slate-600">
                <span className="flex items-center gap-1"><Zap className="w-4 h-4" />{st.MaxPowerKW || '?'} kW</span>
                <span className="flex items-center gap-1"><MapPin className="w-4 h-4" />{pt.length} điểm</span>
                <span className="flex items-center gap-1 text-emerald-600"><Wifi className="w-4 h-4" />{available} sẵn sàng</span>
              </div>
            </motion.div>
          );
        })}
      </div>

      {selected && (
        <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm flex items-center justify-center p-4"
          onClick={() => setSelected(null)}>
          <motion.div initial={{ scale: 0.9 }} animate={{ scale: 1 }}
            className="bg-white rounded-2xl max-w-2xl w-full max-h-[80vh] overflow-y-auto p-6" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-4">
              <div>
                <h2 className="text-lg font-bold">{selected.StationName}</h2>
                <p className="text-sm text-slate-500">{selected.StationCode}</p>
              </div>
              <StatusBadge status={selected.StationStatus} />
            </div>
            <div className="grid grid-cols-2 gap-4 mb-6">
              <div className="bg-slate-50 rounded-xl p-3 text-center">
                <p className="text-2xl font-bold text-emerald-600">{stationPoints.filter(p => p.PointStatus === 'Available').length}</p>
                <p className="text-xs text-slate-500">Sẵn sàng</p>
              </div>
              <div className="bg-slate-50 rounded-xl p-3 text-center">
                <p className="text-2xl font-bold text-amber-600">{stationPoints.filter(p => p.PointStatus === 'Busy').length}</p>
                <p className="text-xs text-slate-500">Đang sạc</p>
              </div>
            </div>
            <h3 className="font-semibold mb-3">Điểm sạc</h3>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
              {stationPoints.map(p => (
                <div key={p.PointID} className="bg-slate-50 rounded-xl p-3">
                  <div className="flex items-center justify-between mb-2">
                    <span className="font-semibold text-sm">{p.PointCode}</span>
                    <StatusBadge status={p.PointStatus} />
                  </div>
                  <p className="text-xs text-slate-500">{p.PowerKW} kW · {p.ConnectorType}</p>
                </div>
              ))}
            </div>
          </motion.div>
        </div>
      )}
    </div>
  );
}
