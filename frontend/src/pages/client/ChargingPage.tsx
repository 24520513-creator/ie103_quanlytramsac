import { useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { Zap, XCircle, Loader2, Battery, Clock, DollarSign } from 'lucide-react';
import { motion } from 'motion/react';
import { api } from '../../services/api';
import { useSocketEvent } from '../../lib/useSocket';
import { useMySessions, useStations, usePoints } from '../../lib/useApi';
import { queryKeys } from '../../lib/queryKeys';
import PageHeader from '../../components/ui/PageHeader';
import StatusBadge from '../../components/ui/StatusBadge';
import type { ChargingSession } from '../../types';

export default function ChargingPage() {
  const qc = useQueryClient();
  const { data: sessions = [], isLoading: sessionsLoading } = useMySessions();
  const { data: stations = [], isLoading: stationsLoading } = useStations();
  const { data: points = [], isLoading: pointsLoading } = usePoints();
  const [selectedStation, setSelectedStation] = useState<number | null>(null);
  const [selectedPoint, setSelectedPoint] = useState<number | null>(null);
  const [error, setError] = useState('');

  const active = sessions.filter(s => s.SessionStatus === 'Charging');

  useSocketEvent('session:started', () => {
    qc.invalidateQueries({ queryKey: queryKeys.sessions.my });
    qc.invalidateQueries({ queryKey: queryKeys.stations.points() });
  });

  useSocketEvent('session:ended', () => {
    qc.invalidateQueries({ queryKey: queryKeys.sessions.my });
    qc.invalidateQueries({ queryKey: queryKeys.stations.points() });
  });

  useSocketEvent('session:cancelled', (data: any) => {
    qc.invalidateQueries({ queryKey: queryKeys.sessions.my });
    qc.invalidateQueries({ queryKey: queryKeys.stations.points() });
  });

  const handleStart = async () => {
    if (!selectedPoint) return;
    setError('');
    try {
      await api.post('/sessions/start', { PointID: selectedPoint });
      setSelectedStation(null);
      setSelectedPoint(null);
      qc.invalidateQueries({ queryKey: queryKeys.sessions.my });
      qc.invalidateQueries({ queryKey: queryKeys.stations.points() });
    } catch (err: any) { setError(err.message); }
  };

  const handleStop = async (sessionId: number) => {
    try {
      await api.post(`/sessions/${sessionId}/end`, { StopReason: 'UserStopped' });
      qc.invalidateQueries({ queryKey: queryKeys.sessions.my });
      qc.invalidateQueries({ queryKey: queryKeys.stations.points() });
    } catch (err: any) { setError(err.message); }
  };

  if (sessionsLoading || stationsLoading || pointsLoading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;

  const availablePoints = points.filter(p =>
    p.PointStatus === 'Available' &&
    (selectedStation ? p.StationID === selectedStation : true)
  );
  const selectedStationPoints = selectedStation
    ? points.filter(p => p.StationID === selectedStation)
    : [];

  return (
    <div className="space-y-6">
      <PageHeader title="Sạc xe" subtitle={active.length > 0 ? `${active.length} phiên đang sạc` : 'Không có phiên nào'} />

      {error && <div className="bg-red-50 text-red-600 text-sm p-3 rounded-xl">{error}</div>}

      {active.length > 0 && (
        <div className="space-y-4">
          <h3 className="font-semibold text-slate-900">Phiên đang sạc</h3>
          {active.map(s => (
            <motion.div key={s.SessionID} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}
              className="bg-white rounded-2xl border border-slate-200 p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 bg-emerald-50 rounded-xl flex items-center justify-center">
                    <Battery className="w-6 h-6 text-emerald-600 fill-current" />
                  </div>
                  <div>
                    <p className="font-semibold text-slate-900">{s.StationName || `Trạm #${s.StationID}`}</p>
                    <p className="text-xs text-slate-500">Điểm sạc {s.PointCode}</p>
                  </div>
                </div>
                <StatusBadge status={s.SessionStatus} />
              </div>

              <div className="relative h-3 bg-slate-100 rounded-full mb-4 overflow-hidden">
                <motion.div initial={{ width: '0%' }}
                  animate={{ width: `${Math.min((s.TotalKWh || 0) / 60 * 100, 100)}%` }}
                  transition={{ duration: 2, ease: 'easeOut' }}
                  className="h-full bg-emerald-500 rounded-full" />
              </div>

              <div className="grid grid-cols-3 gap-4 text-center">
                <div className="bg-slate-50 rounded-xl p-3">
                  <Zap className="w-4 h-4 text-blue-600 mx-auto mb-1" />
                  <p className="text-sm font-bold">{s.TotalKWh?.toFixed(1) || '0'} kWh</p>
                  <p className="text-xs text-slate-500">Đã sạc</p>
                </div>
                <div className="bg-slate-50 rounded-xl p-3">
                  <Clock className="w-4 h-4 text-amber-600 mx-auto mb-1" />
                  <p className="text-sm font-bold">{s.ChargingDurationMinutes || 0} phút</p>
                  <p className="text-xs text-slate-500">Thời gian</p>
                </div>
                <div className="bg-slate-50 rounded-xl p-3">
                  <DollarSign className="w-4 h-4 text-emerald-600 mx-auto mb-1" />
                  <p className="text-sm font-bold">{s.CostTotal?.toLocaleString() || '0'} VND</p>
                  <p className="text-xs text-slate-500">Chi phí</p>
                </div>
              </div>

              <button onClick={() => handleStop(s.SessionID)}
                className="mt-4 w-full py-3 bg-red-500 text-white font-semibold rounded-xl hover:bg-red-600 transition-colors flex items-center justify-center gap-2">
                <XCircle className="w-5 h-5" /> Dừng sạc
              </button>
            </motion.div>
          ))}
        </div>
      )}

      {active.length === 0 && (
        <div className="bg-white rounded-2xl border border-slate-200 p-6">
          <h3 className="font-semibold text-slate-900 mb-4">Bắt đầu phiên sạc mới</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
            {stations.filter(s => s.IsActive !== false).slice(0, 6).map(st => (
              <button key={st.StationID} onClick={() => { setSelectedStation(st.StationID); setSelectedPoint(null); }}
                className={`p-4 rounded-xl border text-left transition-all ${
                  selectedStation === st.StationID
                    ? 'border-blue-500 bg-blue-50'
                    : 'border-slate-200 hover:border-blue-300 bg-white'
                }`}>
                <p className="font-semibold text-sm">{st.StationName}</p>
                <p className="text-xs text-slate-500">{points.filter(p => p.StationID === st.StationID && p.PointStatus === 'Available').length} điểm trống</p>
              </button>
            ))}
          </div>

          {selectedStation && (
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-4">
              {selectedStationPoints.map(p => (
                <button key={p.PointID} onClick={() => setSelectedPoint(p.PointID)}
                  disabled={p.PointStatus !== 'Available'}
                  className={`p-3 rounded-xl border text-center transition-all ${
                    selectedPoint === p.PointID
                      ? 'border-blue-500 bg-blue-50'
                      : p.PointStatus === 'Available'
                        ? 'border-slate-200 hover:border-blue-300 bg-white'
                        : 'border-slate-100 bg-slate-50 opacity-50 cursor-not-allowed'
                  }`}>
                  <p className="font-bold text-lg">{p.PointCode}</p>
                  <p className="text-xs text-slate-500">{p.PowerKW} kW</p>
                  <StatusBadge status={p.PointStatus} />
                </button>
              ))}
            </div>
          )}

          <button onClick={handleStart} disabled={!selectedPoint}
            className="w-full py-3 bg-blue-600 text-white font-bold rounded-xl hover:bg-blue-700 disabled:opacity-50 transition-colors flex items-center justify-center gap-2">
            <Zap className="w-5 h-5" /> Bắt đầu sạc
          </button>
        </div>
      )}
    </div>
  );
}
