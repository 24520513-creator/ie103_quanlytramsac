import React, { useState } from 'react';
import { 
  Building2, 
  Zap, 
  AlertTriangle, 
  TrendingUp, 
  Plus, 
  MoreVertical,
  Activity,
  BatteryCharging,
  Settings,
  Search,
  MapPin,
  ChevronRight,
  ArrowLeft,
  Filter,
  Download,
  Calendar,
  Clock,
  User,
  CreditCard,
  CheckCircle2,
  XCircle,
  AlertCircle
} from 'lucide-react';
import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  Cell,
  LineChart,
  Line,
  AreaChart,
  Area
} from 'recharts';
import { mockStations, mockPoints, mockErrorLogs, mockSessions, mockCustomers } from '../../mockData';
import { cn } from '../../lib/utils';
import { ChargingStation, ChargingPoint, ChargingSession, ErrorLog } from '../../types';

const revenueData = [
  { name: 'Trạm Landmark', value: 4500000 },
  { name: 'Trạm Vincom', value: 3200000 },
  { name: 'Trạm Aeon', value: 5100000 },
  { name: 'Trạm Gigamall', value: 2800000 },
];

const COLORS = ['#2563eb', '#3b82f6', '#60a5fa', '#93c5fd'];

export default function ManagerDashboard({ 
  activeTab, 
  setActiveTab 
}: { 
  activeTab: string;
  setActiveTab: (tab: string) => void;
}) {
  const [selectedStation, setSelectedStation] = useState<ChargingStation | null>(null);
  const [selectedPoint, setSelectedPoint] = useState<ChargingPoint | null>(null);
  const [searchQuery, setSearchQuery] = useState('');

  // Reset drill-down when tab changes
  React.useEffect(() => {
    setSelectedStation(null);
    setSelectedPoint(null);
  }, [activeTab]);

  if (activeTab === 'dashboard') {
    const totalStations = mockStations.length;
    const chargingPoints = mockPoints.filter(p => p.Point_Status === 'Charging').length;
    const totalPoints = mockPoints.length;
    const activeErrors = mockErrorLogs.length;
    const totalRevenue = mockSessions.reduce((sum, s) => sum + s.Cost_Total, 0);

    return (
      <div className="space-y-8">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
            <div className="flex items-center gap-4 mb-4">
              <div className="p-2 bg-blue-50 rounded-lg text-blue-600">
                <Building2 className="w-5 h-5" />
              </div>
              <p className="text-slate-500 text-sm font-medium">Tổng số trạm</p>
            </div>
            <h3 className="text-2xl font-bold text-slate-900">{totalStations} Trạm</h3>
            <p className="text-xs text-green-600 font-bold mt-2 flex items-center gap-1">
              <TrendingUp className="w-3 h-3" /> +2 trạm mới
            </p>
          </div>

          <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
            <div className="flex items-center gap-4 mb-4">
              <div className="p-2 bg-amber-50 rounded-lg text-amber-600">
                <Zap className="w-5 h-5" />
              </div>
              <p className="text-slate-500 text-sm font-medium">Trụ đang sạc</p>
            </div>
            <h3 className="text-2xl font-bold text-slate-900">{chargingPoints}/{totalPoints} Trụ</h3>
            <div className="mt-3 w-full bg-slate-100 h-1.5 rounded-full overflow-hidden">
              <div className="bg-amber-500 h-full" style={{ width: `${(chargingPoints/totalPoints) * 100}%` }} />
            </div>
          </div>

          <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
            <div className="flex items-center gap-4 mb-4">
              <div className="p-2 bg-red-50 rounded-lg text-red-600">
                <AlertTriangle className="w-5 h-5" />
              </div>
              <p className="text-slate-500 text-sm font-medium">Lỗi hệ thống</p>
            </div>
            <h3 className="text-2xl font-bold text-slate-900">{activeErrors} Lỗi</h3>
            <p className="text-xs text-red-600 font-bold mt-2">Cần xử lý ngay</p>
          </div>

          <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
            <div className="flex items-center gap-4 mb-4">
              <div className="p-2 bg-green-50 rounded-lg text-green-600">
                <TrendingUp className="w-5 h-5" />
              </div>
              <p className="text-slate-500 text-sm font-medium">Doanh thu tổng</p>
            </div>
            <h3 className="text-2xl font-bold text-slate-900">{(totalRevenue / 1000000).toFixed(1)}M VNĐ</h3>
            <p className="text-xs text-slate-400 mt-2">Cập nhật 5 phút trước</p>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
            <h3 className="font-bold text-slate-900 mb-8">Doanh thu theo trạm</h3>
            <div className="h-[300px] w-full">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={revenueData}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                  <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill: '#64748b', fontSize: 12}} dy={10} />
                  <YAxis axisLine={false} tickLine={false} tick={{fill: '#64748b', fontSize: 12}} />
                  <Tooltip cursor={{fill: '#f8fafc'}} contentStyle={{ backgroundColor: '#fff', borderRadius: '12px', border: '1px solid #e2e8f0' }} />
                  <Bar dataKey="value" radius={[6, 6, 0, 0]}>
                    {revenueData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

          <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
            <div className="flex items-center justify-between mb-6">
              <h3 className="font-bold text-slate-900">Phiên đang hoạt động</h3>
              <span className="px-2 py-1 rounded-full text-[10px] font-bold bg-blue-50 text-blue-600">LIVE</span>
            </div>
            <div className="space-y-4">
              {[1, 2, 3].map((i) => (
                <div key={i} className="flex items-center gap-4 p-4 rounded-xl border border-slate-100 hover:bg-slate-50 transition-colors">
                  <div className="w-12 h-12 bg-blue-50 rounded-full flex items-center justify-center text-blue-600">
                    <BatteryCharging className="w-6 h-6 animate-pulse" />
                  </div>
                  <div className="flex-1">
                    <div className="flex justify-between">
                      <p className="text-sm font-bold text-slate-900">Trạm Landmark 81 - Trụ #0{i}</p>
                      <p className="text-xs font-bold text-blue-600">72%</p>
                    </div>
                    <div className="mt-2 w-full bg-slate-100 h-1.5 rounded-full overflow-hidden">
                      <div className="bg-blue-500 h-full" style={{ width: `${60 + i * 10}%` }} />
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (activeTab === 'stations') {
    if (selectedPoint) {
      const pointSessions = mockSessions.filter(s => s.PointID === selectedPoint.PointID);
      return (
        <div className="space-y-6">
          <div className="flex items-center gap-4">
            <button 
              onClick={() => setSelectedPoint(null)}
              className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
            >
              <ArrowLeft className="w-5 h-5 text-slate-600" />
            </button>
            <div>
              <h2 className="text-xl font-bold text-slate-900">Trụ sạc #{selectedPoint.PointID}</h2>
              <p className="text-sm text-slate-500">{selectedStation?.StationName}</p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
              <p className="text-slate-500 text-sm font-medium">Công suất</p>
              <h3 className="text-2xl font-bold text-slate-900 mt-1">{selectedPoint.Power_kW} kW</h3>
            </div>
            <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
              <p className="text-slate-500 text-sm font-medium">Loại cổng</p>
              <h3 className="text-2xl font-bold text-slate-900 mt-1">{selectedPoint.Connector_Type}</h3>
            </div>
            <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
              <p className="text-slate-500 text-sm font-medium">Trạng thái</p>
              <span className={cn(
                "inline-block px-2 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider mt-2",
                selectedPoint.Point_Status === 'Available' ? "bg-green-50 text-green-600" :
                selectedPoint.Point_Status === 'Charging' ? "bg-blue-50 text-blue-600" :
                "bg-amber-50 text-amber-600"
              )}>
                {selectedPoint.Point_Status}
              </span>
            </div>
          </div>

          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center">
              <h3 className="font-bold text-slate-900">Lịch sử phiên sạc của trụ</h3>
              <button className="text-sm text-blue-600 font-bold hover:underline">Xem tất cả</button>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left">
                <thead>
                  <tr className="bg-slate-50 text-slate-400 text-[10px] font-bold uppercase tracking-wider">
                    <th className="px-6 py-4">ID Phiên</th>
                    <th className="px-6 py-4">Khách hàng</th>
                    <th className="px-6 py-4">Thời gian</th>
                    <th className="px-6 py-4">Năng lượng</th>
                    <th className="px-6 py-4">Chi phí</th>
                    <th className="px-6 py-4">Trạng thái</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {pointSessions.map((session) => {
                    const customer = mockCustomers.find(c => c.UserID === session.UserID);
                    return (
                      <tr key={session.SessionID} className="hover:bg-slate-50 transition-colors">
                        <td className="px-6 py-4 text-sm font-bold text-slate-900">#{session.SessionID}</td>
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-3">
                            <div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-slate-400">
                              <User className="w-4 h-4" />
                            </div>
                            <span className="text-sm font-medium text-slate-700">{customer?.FullName}</span>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="space-y-1">
                            <p className="text-xs font-medium text-slate-900">{new Date(session.StartTime).toLocaleDateString('vi-VN')}</p>
                            <p className="text-[10px] text-slate-400">{new Date(session.StartTime).toLocaleTimeString('vi-VN')}</p>
                          </div>
                        </td>
                        <td className="px-6 py-4 text-sm font-medium text-slate-600">{session.Total_kWh} kWh</td>
                        <td className="px-6 py-4 text-sm font-bold text-slate-900">{session.Cost_Total.toLocaleString()} VNĐ</td>
                        <td className="px-6 py-4">
                          <span className={cn(
                            "px-2 py-1 rounded-full text-[10px] font-bold",
                            session.Status === 'Completed' ? "bg-green-50 text-green-600" : "bg-blue-50 text-blue-600"
                          )}>
                            {session.Status}
                          </span>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      );
    }

    if (selectedStation) {
      const stationPoints = mockPoints.filter(p => p.StationID === selectedStation.StationID);
      return (
        <div className="space-y-6">
          <div className="flex items-center gap-4">
            <button 
              onClick={() => setSelectedStation(null)}
              className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
            >
              <ArrowLeft className="w-5 h-5 text-slate-600" />
            </button>
            <div>
              <h2 className="text-xl font-bold text-slate-900">{selectedStation.StationName}</h2>
              <p className="text-sm text-slate-500">{selectedStation.Address}</p>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {stationPoints.map((point) => (
              <div 
                key={point.PointID} 
                className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm hover:border-blue-300 transition-all cursor-pointer group"
                onClick={() => setSelectedPoint(point)}
              >
                <div className="flex justify-between items-start mb-4">
                  <div className={cn(
                    "p-3 rounded-xl",
                    point.Point_Status === 'Available' ? "bg-green-50 text-green-600" :
                    point.Point_Status === 'Charging' ? "bg-blue-50 text-blue-600" :
                    "bg-amber-50 text-amber-600"
                  )}>
                    <Zap className="w-6 h-6" />
                  </div>
                  <button className="p-1 text-slate-400 hover:text-slate-600"><MoreVertical className="w-4 h-4" /></button>
                </div>
                <h4 className="font-bold text-slate-900">Trụ sạc #{point.PointID}</h4>
                <p className="text-xs text-slate-500 mt-1">{point.Connector_Type} • {point.Power_kW}kW</p>
                <div className="mt-6 flex items-center justify-between">
                  <span className={cn(
                    "px-2 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider",
                    point.Point_Status === 'Available' ? "bg-green-50 text-green-600" :
                    point.Point_Status === 'Charging' ? "bg-blue-50 text-blue-600" :
                    "bg-amber-50 text-amber-600"
                  )}>
                    {point.Point_Status}
                  </span>
                  <ChevronRight className="w-4 h-4 text-slate-300 group-hover:text-blue-500 transition-colors" />
                </div>
              </div>
            ))}
            <button className="border-2 border-dashed border-slate-200 rounded-2xl p-6 flex flex-col items-center justify-center text-slate-400 hover:border-blue-300 hover:text-blue-500 transition-all">
              <Plus className="w-8 h-8 mb-2" />
              <span className="text-sm font-bold">Thêm trụ mới</span>
            </button>
          </div>
        </div>
      );
    }

    return (
      <div className="space-y-6">
        <div className="flex flex-col sm:flex-row justify-between items-center gap-4">
          <div className="relative w-full sm:w-96">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input 
              type="text" 
              placeholder="Tìm trạm sạc..." 
              className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
          <button className="w-full sm:w-auto flex items-center justify-center gap-2 px-6 py-2.5 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 shadow-sm transition-all">
            <Plus className="w-5 h-5" /> Thêm trạm mới
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
          {mockStations.filter(s => s.StationName.toLowerCase().includes(searchQuery.toLowerCase())).map((station) => (
            <div key={station.StationID} className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden group">
              <div className="h-32 bg-slate-100 relative overflow-hidden">
                <img src={`https://picsum.photos/seed/station-${station.StationID}/600/300`} alt={station.StationName} className="w-full h-full object-cover opacity-80 group-hover:scale-105 transition-transform duration-500" referrerPolicy="no-referrer" />
                <div className="absolute top-4 right-4">
                  <span className="px-2 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider bg-white/90 backdrop-blur-sm text-green-600 shadow-sm">{station.Station_Status}</span>
                </div>
              </div>
              <div className="p-6">
                <h4 className="font-bold text-slate-900 text-lg">{station.StationName}</h4>
                <p className="text-sm text-slate-500 mt-1 flex items-center gap-1"><MapPin className="w-3 h-3" /> {station.Address}</p>
                <div className="mt-6 flex gap-2">
                  <button 
                    onClick={() => setSelectedStation(station)}
                    className="flex-1 py-2.5 bg-slate-900 text-white text-sm font-bold rounded-xl hover:bg-slate-800 transition-colors"
                  >
                    Quản lý trụ
                  </button>
                  <button className="p-2.5 bg-slate-100 text-slate-600 rounded-xl hover:bg-slate-200 transition-colors"><Settings className="w-5 h-5" /></button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  if (activeTab === 'sessions') {
    return (
      <div className="space-y-6">
        <div className="flex flex-col sm:flex-row justify-between items-center gap-4">
          <h2 className="text-2xl font-bold text-slate-900">Quản lý phiên sạc</h2>
          <div className="flex items-center gap-2 w-full sm:w-auto">
            <button className="flex-1 sm:flex-none flex items-center justify-center gap-2 px-4 py-2 bg-white border border-slate-200 rounded-xl text-sm font-bold text-slate-600 hover:bg-slate-50">
              <Filter className="w-4 h-4" /> Lọc
            </button>
            <button className="flex-1 sm:flex-none flex items-center justify-center gap-2 px-4 py-2 bg-white border border-slate-200 rounded-xl text-sm font-bold text-slate-600 hover:bg-slate-50">
              <Download className="w-4 h-4" /> Xuất báo cáo
            </button>
          </div>
        </div>

        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead>
                <tr className="bg-slate-50 text-slate-400 text-[10px] font-bold uppercase tracking-wider">
                  <th className="px-6 py-4">ID Phiên</th>
                  <th className="px-6 py-4">Khách hàng</th>
                  <th className="px-6 py-4">Trạm & Trụ</th>
                  <th className="px-6 py-4">Thời gian</th>
                  <th className="px-6 py-4">Năng lượng</th>
                  <th className="px-6 py-4">Chi phí</th>
                  <th className="px-6 py-4">Trạng thái</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {mockSessions.map((session) => {
                  const customer = mockCustomers.find(c => c.UserID === session.UserID);
                  const point = mockPoints.find(p => p.PointID === session.PointID);
                  const station = mockStations.find(s => s.StationID === point?.StationID);
                  return (
                    <tr key={session.SessionID} className="hover:bg-slate-50 transition-colors">
                      <td className="px-6 py-4 text-sm font-bold text-slate-900">#{session.SessionID}</td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-slate-400">
                            <User className="w-4 h-4" />
                          </div>
                          <span className="text-sm font-medium text-slate-700">{customer?.FullName}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="space-y-1">
                          <p className="text-xs font-bold text-slate-900">{station?.StationName}</p>
                          <p className="text-[10px] text-slate-400">Trụ #{point?.PointID}</p>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="space-y-1">
                          <p className="text-xs font-medium text-slate-900">{new Date(session.StartTime).toLocaleDateString('vi-VN')}</p>
                          <p className="text-[10px] text-slate-400">{new Date(session.StartTime).toLocaleTimeString('vi-VN')}</p>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-sm font-medium text-slate-600">{session.Total_kWh} kWh</td>
                      <td className="px-6 py-4 text-sm font-bold text-slate-900">{session.Cost_Total.toLocaleString()} VNĐ</td>
                      <td className="px-6 py-4">
                        <span className={cn(
                          "px-2 py-1 rounded-full text-[10px] font-bold",
                          session.Status === 'Completed' ? "bg-green-50 text-green-600" : "bg-blue-50 text-blue-600"
                        )}>
                          {session.Status}
                        </span>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    );
  }

  if (activeTab === 'errors') {
    return (
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h2 className="text-2xl font-bold text-slate-900">Lỗi hệ thống</h2>
          <span className="px-3 py-1 bg-red-50 text-red-600 text-xs font-bold rounded-full">3 Lỗi chưa xử lý</span>
        </div>

        <div className="grid grid-cols-1 gap-4">
          {mockErrorLogs.map((log) => {
            const point = mockPoints.find(p => p.PointID === log.PointID);
            const station = mockStations.find(s => s.StationID === point?.StationID);
            return (
              <div key={log.ErrorID} className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row gap-6 items-start md:items-center">
                <div className={cn(
                  "p-3 rounded-xl",
                  log.Severity === 'High' ? "bg-red-50 text-red-600" : "bg-amber-50 text-amber-600"
                )}>
                  <AlertCircle className="w-6 h-6" />
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <span className={cn(
                      "text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full",
                      log.Severity === 'High' ? "bg-red-50 text-red-600" : "bg-amber-50 text-amber-600"
                    )}>
                      {log.Severity} Priority
                    </span>
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">{log.ErrorCode}</span>
                  </div>
                  <h4 className="font-bold text-slate-900">{log.Description}</h4>
                  <p className="text-sm text-slate-500 mt-1">
                    {station?.StationName} • Trụ #{point?.PointID}
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-sm font-medium text-slate-900">{new Date(log.OccurredAt).toLocaleDateString('vi-VN')}</p>
                  <p className="text-xs text-slate-400">{new Date(log.OccurredAt).toLocaleTimeString('vi-VN')}</p>
                </div>
                <div className="flex gap-2 w-full md:w-auto">
                  <button className="flex-1 md:flex-none px-4 py-2 bg-blue-600 text-white text-sm font-bold rounded-xl hover:bg-blue-700 transition-colors">Xử lý</button>
                  <button className="flex-1 md:flex-none px-4 py-2 bg-slate-100 text-slate-600 text-sm font-bold rounded-xl hover:bg-slate-200 transition-colors">Chi tiết</button>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    );
  }

  if (activeTab === 'revenue') {
    return (
      <div className="space-y-8">
        <div className="flex justify-between items-center">
          <h2 className="text-2xl font-bold text-slate-900">Báo cáo doanh thu</h2>
          <div className="flex items-center gap-2">
            <button className="px-4 py-2 bg-white border border-slate-200 rounded-xl text-sm font-bold text-slate-600 hover:bg-slate-50 flex items-center gap-2">
              <Calendar className="w-4 h-4" /> Tháng này
            </button>
            <button className="px-4 py-2 bg-blue-600 text-white rounded-xl text-sm font-bold hover:bg-blue-700 flex items-center gap-2 shadow-lg shadow-blue-100">
              <Download className="w-4 h-4" /> Xuất PDF
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
            <p className="text-slate-500 text-sm font-medium">Tổng doanh thu</p>
            <h3 className="text-3xl font-bold text-slate-900 mt-1">156.4M VNĐ</h3>
            <p className="text-xs text-green-600 font-bold mt-2 flex items-center gap-1">
              <TrendingUp className="w-3 h-3" /> +15.4% so với tháng trước
            </p>
          </div>
          <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
            <p className="text-slate-500 text-sm font-medium">Lợi nhuận ước tính</p>
            <h3 className="text-3xl font-bold text-slate-900 mt-1">42.8M VNĐ</h3>
            <p className="text-xs text-green-600 font-bold mt-2 flex items-center gap-1">
              <TrendingUp className="w-3 h-3" /> +8.2% so với tháng trước
            </p>
          </div>
          <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
            <p className="text-slate-500 text-sm font-medium">Số phiên sạc</p>
            <h3 className="text-3xl font-bold text-slate-900 mt-1">1,245</h3>
            <p className="text-xs text-blue-600 font-bold mt-2 flex items-center gap-1">
              <Zap className="w-3 h-3" /> Trung bình 42 phiên/ngày
            </p>
          </div>
        </div>

        <div className="bg-white p-8 rounded-3xl border border-slate-200 shadow-sm">
          <h3 className="font-bold text-slate-900 mb-8">Biểu đồ doanh thu theo ngày</h3>
          <div className="h-[400px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={[
                { date: '01/03', value: 4200000 },
                { date: '05/03', value: 5800000 },
                { date: '10/03', value: 4900000 },
                { date: '15/03', value: 7200000 },
                { date: '20/03', value: 6500000 },
                { date: '25/03', value: 8900000 },
                { date: '30/03', value: 9500000 },
              ]}>
                <defs>
                  <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#2563eb" stopOpacity={0.1}/>
                    <stop offset="95%" stopColor="#2563eb" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                <XAxis dataKey="date" axisLine={false} tickLine={false} tick={{fill: '#64748b', fontSize: 12}} dy={10} />
                <YAxis axisLine={false} tickLine={false} tick={{fill: '#64748b', fontSize: 12}} />
                <Tooltip contentStyle={{ backgroundColor: '#fff', borderRadius: '12px', border: '1px solid #e2e8f0' }} />
                <Area type="monotone" dataKey="value" stroke="#2563eb" strokeWidth={3} fillOpacity={1} fill="url(#colorRevenue)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col items-center justify-center py-20 text-center">
      <Activity className="w-16 h-16 text-slate-200 mb-6" />
      <h2 className="text-2xl font-bold text-slate-900">Module đang được xây dựng</h2>
      <p className="text-slate-500 mt-2">Dữ liệu quản lý đang được đồng bộ hóa.</p>
    </div>
  );
}
