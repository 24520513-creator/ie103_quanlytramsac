import { useState, useEffect } from 'react';
import { Search, MapPin, Zap, Navigation, Loader2, Wifi, WifiOff } from 'lucide-react';
import { motion } from 'motion/react';
import { useNavigate } from 'react-router-dom';
import { api } from '../../services/api';
import PageHeader from '../../components/ui/PageHeader';
import StatusBadge from '../../components/ui/StatusBadge';
import type { ChargingStation, ChargingPoint } from '../../types';

export default function MapPage() {
  const navigate = useNavigate();
  const [stations, setStations] = useState<ChargingStation[]>([]);
  const [points, setPoints] = useState<ChargingPoint[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<ChargingStation | null>(null);

  useEffect(() => {
    Promise.all([
      api.get('/stations').catch(() => ({ data: [] as ChargingStation[] })),
      api.get('/points').catch(() => ({ data: [] as ChargingPoint[] })),
    ]).then(([sRes, pRes]) => {
      setStations(Array.isArray(sRes.data) ? sRes.data : []);
      setPoints(Array.isArray(pRes.data) ? pRes.data : []);
    }).finally(() => setLoading(false));
  }, []);

  const filtered = stations.filter(s =>
    s.StationName?.toLowerCase().includes(search.toLowerCase()) &&
    s.IsActive !== false
  );

  const getPointCount = (stationId: number, status: string) =>
    points.filter(p => p.StationID === stationId && p.PointStatus === status).length;

  if (loading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;

  return (
    <div className="space-y-6">
      <PageHeader title="Tìm trạm sạc" subtitle={`${filtered.length} trạm sạc khả dụng`} />

      <div className="relative">
        <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
        <input type="text" value={search} onChange={e => setSearch(e.target.value)}
          placeholder="Tìm kiếm trạm sạc..."
          className="w-full pl-12 pr-4 py-3 bg-white border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
        {filtered.map(station => {
          const available = getPointCount(station.StationID, 'Available');
          const busy = getPointCount(station.StationID, 'Busy');
          const total = points.filter(p => p.StationID === station.StationID).length;

          return (
            <motion.div key={station.StationID} whileHover={{ y: -2 }}
              onClick={() => setSelected(station)}
              className="bg-white rounded-2xl border border-slate-200 p-5 cursor-pointer hover:shadow-lg transition-shadow">
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-2">
                  <MapPin className="w-5 h-5 text-blue-600" />
                  <h3 className="font-semibold text-slate-900">{station.StationName}</h3>
                </div>
                <StatusBadge status={station.StationStatus} />
              </div>
              {station.Address && <p className="text-sm text-slate-500 mb-3">{station.Address}</p>}
              <div className="flex items-center gap-4 text-sm text-slate-600">
                <span className="flex items-center gap-1"><Zap className="w-4 h-4" />{station.MaxPowerKW || '?'} kW</span>
                <span className="flex items-center gap-1 text-emerald-600">
                  <Wifi className="w-4 h-4" /> {available}/{total} sẵn sàng
                </span>
                <span className="flex items-center gap-1 text-amber-600">
                  <Zap className="w-4 h-4" /> {busy} đang sạc
                </span>
              </div>
            </motion.div>
          );
        })}
      </div>

      {selected && (
        <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm flex items-center justify-center"
          onClick={() => setSelected(null)}>
          <motion.div initial={{ scale: 0.9 }} animate={{ scale: 1 }}
            className="bg-white rounded-2xl max-w-lg w-full mx-4 p-6" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-bold">{selected.StationName}</h2>
              <StatusBadge status={selected.StationStatus} />
            </div>
            <p className="text-sm text-slate-500 mb-4">{selected.Address || `Mã trạm: ${selected.StationCode}`}</p>
            <div className="grid grid-cols-2 gap-3 mb-6">
              <div className="bg-slate-50 rounded-xl p-3 text-center">
                <p className="text-2xl font-bold text-emerald-600">{getPointCount(selected.StationID, 'Available')}</p>
                <p className="text-xs text-slate-500">Sẵn sàng</p>
              </div>
              <div className="bg-slate-50 rounded-xl p-3 text-center">
                <p className="text-2xl font-bold text-amber-600">{getPointCount(selected.StationID, 'Busy')}</p>
                <p className="text-xs text-slate-500">Đang sạc</p>
              </div>
            </div>
            <button onClick={() => { setSelected(null); navigate('/client/vehicles'); }}
              className="w-full py-3 bg-blue-600 text-white font-semibold rounded-xl hover:bg-blue-700 transition-colors flex items-center justify-center gap-2">
              <Navigation className="w-5 h-5" /> Bắt đầu sạc
            </button>
          </motion.div>
        </div>
      )}
    </div>
  );
}
