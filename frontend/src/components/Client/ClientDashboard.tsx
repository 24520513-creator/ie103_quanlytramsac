import React, { useState, useEffect } from 'react';
import { 
  Wallet, 
  Zap, 
  History, 
  MapPin, 
  Navigation, 
  Battery, 
  Clock, 
  TrendingUp,
  ChevronRight,
  Search,
  Filter,
  CreditCard,
  PlugZap,
  Plus,
  Trash2,
  X,
  Download,
  Info,
  Settings,
  Calendar,
  DollarSign
} from 'lucide-react';
import { 
  AreaChart, 
  Area, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer 
} from 'recharts';
import { motion } from 'motion/react';
import { api } from '../../services/api';
import { cn } from '../../lib/utils';
import { ChargingSession, Vehicle, ChargingPoint, Customer, ChargingStation, Transaction } from '../../types';

const chartData = [
  { name: 'Thứ 2', kwh: 12 },
  { name: 'Thứ 3', kwh: 15 },
  { name: 'Thứ 4', kwh: 8 },
  { name: 'Thứ 5', kwh: 22 },
  { name: 'Thứ 6', kwh: 18 },
  { name: 'Thứ 7', kwh: 30 },
  { name: 'Chủ nhật', kwh: 25 },
];

export default function ClientDashboard({ 
  activeTab, 
  setActiveTab,
  user
}: { 
  activeTab: string;
  setActiveTab: (tab: string) => void;
  user?: any;
}) {
  const [selectedSession, setSelectedSession] = useState<ChargingSession | null>(null);
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [isAddVehicleModalOpen, setIsAddVehicleModalOpen] = useState(false);
  const [newVehicle, setNewVehicle] = useState({
    PlateNumber: '',
    Brand: '',
    Model: '',
    BatteryCapacity_kWh: 0,
    ConnectorType: 'CCS2'
  });

  const [isCharging, setIsCharging] = useState(true);
  const [isReporting, setIsReporting] = useState(false);
  const [reportSuccess, setReportSuccess] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterStatus, setFilterStatus] = useState('All');
  const [isTopUpSuccess, setIsTopUpSuccess] = useState(false);
  const [isTopUpModalOpen, setIsTopUpModalOpen] = useState(false);
  const [selectedPointForCharging, setSelectedPointForCharging] = useState<ChargingPoint | null>(null);
  const [showAllTransactions, setShowAllTransactions] = useState(false);
  const [isEditProfileModalOpen, setIsEditProfileModalOpen] = useState(false);
  const [loading, setLoading] = useState(true);

  // API data
  const [stations, setStations] = useState<ChargingStation[]>([]);
  const [points, setPoints] = useState<ChargingPoint[]>([]);
  const [sessions, setSessions] = useState<ChargingSession[]>([]);
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [profile, setProfile] = useState<Customer>({ UserID: 0, FullName: '', Email: '', Phone: '', Address: '', WalletBalance: 0, AccountStatus: 'Active' });
  const [walletBalance, setWalletBalance] = useState(0);
  const [totalKwh, setTotalKwh] = useState(0);
  const [totalSessions, setTotalSessions] = useState(0);
  const [profileDataInner, setProfileDataInner] = useState({ FullName: '', Email: '', Phone: '', Address: '' });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [profRes, statRes, sessRes, vehRes, tranRes] = await Promise.all([
        api.get('/auth/profile'),
        api.get('/stations'),
        api.get('/sessions'),
        api.get('/vehicles'),
        api.get('/transactions'),
      ]);
      setProfile(profRes.data);
      setWalletBalance(profRes.data.WalletBalance || 0);
      setStations(statRes.data || []);
      setSessions(sessRes.data || []);
      setVehicles(vehRes.data || []);
      setTransactions(tranRes.data || []);
      setTotalKwh((sessRes.data || []).reduce((s: number, x: any) => s + Number(x.Total_kWh || 0), 0));
      setTotalSessions((sessRes.data || []).length);
    } catch (err) { console.error('Failed to load data', err); }
    setLoading(false);
  };

  const handleStopCharging = () => {
    if (window.confirm('Bạn có chắc chắn muốn dừng phiên sạc này?')) {
      setIsCharging(false);
      setSelectedPointForCharging(null);
    }
  };

  const handleReportIssue = () => {
    setIsReporting(true);
    setTimeout(() => {
      setIsReporting(false);
      setReportSuccess(true);
      setTimeout(() => setReportSuccess(false), 3000);
    }, 1500);
  };

  const handleTopUp = async () => {
    try {
      await api.post('/wallet/topup', { Amount: 500000 });
      setIsTopUpSuccess(true);
      loadData();
      setTimeout(() => {
        setIsTopUpSuccess(false);
        setIsTopUpModalOpen(false);
      }, 2000);
    } catch (err) { console.error(err); }
  };

  const filteredSessions = [...sessions, ...sessions, ...sessions].filter(session => {
    const matchesSearch = session.SessionID.toString().includes(searchQuery) || 
                         'Trạm Landmark 81'.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesFilter = filterStatus === 'All' || session.Status === filterStatus;
    return matchesSearch && matchesFilter;
  });

  const handleAddVehicle = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await api.post('/vehicles', { ...newVehicle, BatteryCapacity_kWh: Number(newVehicle.BatteryCapacity_kWh) });
      setIsAddVehicleModalOpen(false);
      setNewVehicle({ PlateNumber: '', Brand: '', Model: '', BatteryCapacity_kWh: 0, ConnectorType: 'CCS2' });
      const res = await api.get('/vehicles');
      setVehicles(res.data || []);
    } catch (err) { console.error(err); }
  };

  const handleDeleteVehicle = async (id: number) => {
    try {
      await api.delete(`/vehicles/${id}`);
      setVehicles(vehicles.filter(v => v.VehicleID !== id));
    } catch (err) { console.error(err); }
  };

  const handleUpdateProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await api.put('/auth/profile', profileDataInner);
      setIsEditProfileModalOpen(false);
      loadData();
    } catch (err) { console.error(err); }
  };

  const handleTopUpAmount = async (amount: string) => {
    const numAmount = parseInt(amount.replace(/\./g, ''));
    if (!numAmount) return;
    try {
      await api.post('/wallet/topup', { Amount: numAmount });
      setIsTopUpSuccess(true);
      loadData();
      setTimeout(() => {
        setIsTopUpSuccess(false);
        setIsTopUpModalOpen(false);
      }, 2000);
    } catch (err) { console.error(err); }
  };

  useEffect(() => {
    if (profile?.FullName) setProfileDataInner({ FullName: profile.FullName, Email: profile.Email, Phone: profile.Phone || '', Address: profile.Address || '' });
  }, [profile]);

  const [selectedStation, setSelectedStation] = useState<any>(null);

  if (activeTab === 'dashboard') {
    return (
      <div className="space-y-8">
        {/* Top Stats */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <div className="p-2 bg-blue-50 rounded-lg">
                <Wallet className="w-6 h-6 text-blue-600" />
              </div>
              <span className="text-xs font-bold text-green-600 bg-green-50 px-2 py-1 rounded-full">+12%</span>
            </div>
            <p className="text-slate-500 text-sm font-medium">Số dư ví</p>
            <h3 className="text-2xl font-bold text-slate-900 mt-1">{walletBalance.toLocaleString()} VNĐ</h3>
          </div>

          <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <div className="p-2 bg-amber-50 rounded-lg">
                <Zap className="w-6 h-6 text-amber-600" />
              </div>
              <span className="text-xs font-bold text-amber-600 bg-amber-50 px-2 py-1 rounded-full">Đang sạc</span>
            </div>
            <p className="text-slate-500 text-sm font-medium">Điện năng tháng này</p>
            <h3 className="text-2xl font-bold text-slate-900 mt-1">145.8 kWh</h3>
          </div>

          <button 
            onClick={() => setActiveTab('history')}
            className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm text-left hover:border-blue-300 transition-all group"
          >
            <div className="flex items-center justify-between mb-4">
              <div className="p-2 bg-purple-50 rounded-lg group-hover:bg-purple-100 transition-colors">
                <History className="w-6 h-6 text-purple-600" />
              </div>
              <ChevronRight className="w-5 h-5 text-slate-300 group-hover:text-blue-500 group-hover:translate-x-1 transition-all" />
            </div>
            <p className="text-slate-500 text-sm font-medium">Tổng phiên sạc</p>
            <h3 className="text-2xl font-bold text-slate-900 mt-1">24 phiên</h3>
          </button>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Chart */}
          <div className="lg:col-span-2 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
            <div className="flex items-center justify-between mb-6">
              <h3 className="font-bold text-slate-900">Điện năng tiêu thụ (7 ngày qua)</h3>
              <select className="text-sm border-none bg-slate-50 rounded-lg px-3 py-1.5 font-medium focus:ring-0">
                <option>Tuần này</option>
                <option>Tuần trước</option>
              </select>
            </div>
            <div className="h-[300px] w-full">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={chartData}>
                  <defs>
                    <linearGradient id="colorKwh" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#2563eb" stopOpacity={0.1}/>
                      <stop offset="95%" stopColor="#2563eb" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                  <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill: '#64748b', fontSize: 12}} dy={10} />
                  <YAxis axisLine={false} tickLine={false} tick={{fill: '#64748b', fontSize: 12}} />
                  <Tooltip 
                    contentStyle={{ backgroundColor: '#fff', borderRadius: '12px', border: '1px solid #e2e8f0', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
                  />
                  <Area type="monotone" dataKey="kwh" stroke="#2563eb" strokeWidth={3} fillOpacity={1} fill="url(#colorKwh)" />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Vehicle Info */}
          <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm flex flex-col">
            <h3 className="font-bold text-slate-900 mb-6">Xe của tôi</h3>
            <div className="bg-slate-900 rounded-xl p-6 text-white relative overflow-hidden flex-1">
              <div className="relative z-10">
                <p className="text-slate-400 text-xs font-bold uppercase tracking-widest mb-1">{vehicles[0]?.Brand || 'Chưa có xe'}</p>
                <h4 className="text-xl font-bold mb-4">{vehicles[0]?.Model || 'Vui lòng thêm xe'}</h4>
                
                {vehicles[0] && (
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2 text-slate-400">
                        <CreditCard className="w-4 h-4" />
                        <span className="text-sm">Biển số</span>
                      </div>
                      <span className="font-mono font-bold">{vehicles[0].PlateNumber}</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2 text-slate-400">
                        <Battery className="w-4 h-4" />
                        <span className="text-sm">Dung lượng</span>
                      </div>
                      <span className="font-bold">{vehicles[0].BatteryCapacity_kWh} kWh</span>
                    </div>
                  </div>
                )}
              </div>
              <div className="absolute -right-10 -bottom-10 w-40 h-40 bg-blue-600/20 rounded-full blur-3xl" />
            </div>
            <button 
              onClick={() => setActiveTab('vehicles')}
              className="mt-6 w-full py-3 bg-slate-100 hover:bg-slate-200 text-slate-900 font-bold rounded-xl transition-colors flex items-center justify-center gap-2"
            >
              Quản lý xe <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Recent Sessions */}
        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="p-6 border-b border-slate-100 flex items-center justify-between">
            <h3 className="font-bold text-slate-900">Phiên sạc gần đây</h3>
            <button 
              onClick={() => setActiveTab('history')}
              className="text-blue-600 text-sm font-bold hover:underline"
            >
              Xem tất cả
            </button>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead>
                <tr className="bg-slate-50 text-slate-500 text-xs uppercase tracking-wider font-bold">
                  <th className="px-6 py-4">Thời gian</th>
                  <th className="px-6 py-4">Trạm sạc</th>
                  <th className="px-6 py-4">Điện năng</th>
                  <th className="px-6 py-4">Chi phí</th>
                  <th className="px-6 py-4">Trạng thái</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {sessions.slice(0, 5).map((session) => (
                  <tr 
                    key={session.SessionID} 
                    className="hover:bg-slate-50 transition-colors cursor-pointer"
                    onClick={() => setSelectedSession(session)}
                  >
                    <td className="px-6 py-4">
                      <p className="text-sm font-medium text-slate-900">{new Date(session.StartTime).toLocaleDateString('vi-VN')}</p>
                      <p className="text-xs text-slate-500">{new Date(session.StartTime).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}</p>
                    </td>
                    <td className="px-6 py-4">
                      <p className="text-sm font-medium text-slate-900">Trạm Landmark 81</p>
                      <p className="text-xs text-slate-500">Trụ #02 - CCS2</p>
                    </td>
                    <td className="px-6 py-4 text-sm font-bold text-slate-900">{session.Total_kWh} kWh</td>
                    <td className="px-6 py-4 text-sm font-bold text-blue-600">{session.Cost_Total.toLocaleString()} VNĐ</td>
                    <td className="px-6 py-4">
                      <span className="px-2 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider bg-green-50 text-green-600 border border-green-100">
                        {session.Status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Session Detail Modal */}
        {selectedSession && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
            <div className="bg-white w-full max-w-md rounded-3xl shadow-2xl overflow-hidden">
              <div className="p-6 bg-blue-600 text-white flex justify-between items-center">
                <h3 className="text-xl font-bold">Chi tiết hoá đơn</h3>
                <button onClick={() => setSelectedSession(null)} className="p-1 hover:bg-white/20 rounded-lg">
                  <X className="w-6 h-6" />
                </button>
              </div>
              <div className="p-8 space-y-6">
                <div className="text-center">
                  <div className="w-16 h-16 bg-blue-50 rounded-full flex items-center justify-center mx-auto mb-4">
                    <Zap className="w-8 h-8 text-blue-600" />
                  </div>
                  <h4 className="text-2xl font-bold text-slate-900">-{selectedSession.Cost_Total.toLocaleString()} VNĐ</h4>
                  <p className="text-slate-500 text-sm mt-1">Mã giao dịch: #CHG-{selectedSession.SessionID}</p>
                </div>

                <div className="space-y-4 border-t border-slate-100 pt-6">
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-500">Trạm sạc</span>
                    <span className="font-bold text-slate-900">Landmark 81</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-500">Thời gian bắt đầu</span>
                    <span className="font-bold text-slate-900">{new Date(selectedSession.StartTime).toLocaleString('vi-VN')}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-500">Thời gian kết thúc</span>
                    <span className="font-bold text-slate-900">{selectedSession.EndTime ? new Date(selectedSession.EndTime).toLocaleString('vi-VN') : 'N/A'}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-500">Tổng điện năng</span>
                    <span className="font-bold text-slate-900">{selectedSession.Total_kWh} kWh</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-500">Đơn giá cơ bản</span>
                    <span className="font-bold text-slate-900">3,500 VNĐ/kWh</span>
                  </div>
                </div>

                <div className="bg-slate-50 p-4 rounded-2xl flex items-start gap-3">
                  <Info className="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5" />
                  <p className="text-xs text-slate-600 leading-relaxed">
                    Hoá đơn này đã được thanh toán tự động qua ví điện tử của bạn. Nếu có thắc mắc, vui lòng liên hệ tổng đài 1900 1234.
                  </p>
                </div>

                <button className="w-full py-3 bg-slate-900 text-white font-bold rounded-xl hover:bg-slate-800 transition-colors flex items-center justify-center gap-2">
                  <Download className="w-4 h-4" /> Tải hoá đơn (PDF)
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    );
  }

  if (activeTab === 'history') {
    return (
      <div className="space-y-6">
        <div className="flex flex-col sm:flex-row justify-between items-center gap-4">
          <div className="relative w-full sm:w-96">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input 
              type="text" 
              placeholder="Tìm kiếm phiên sạc..." 
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" 
            />
          </div>
          <div className="flex gap-2 w-full sm:w-auto">
            <select 
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="flex-1 sm:flex-none px-4 py-2.5 bg-white border border-slate-200 rounded-xl text-sm font-bold text-slate-700 outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="All">Tất cả trạng thái</option>
              <option value="Completed">Hoàn thành</option>
              <option value="Charging">Đang sạc</option>
              <option value="Error">Lỗi</option>
            </select>
            <button className="flex-1 sm:flex-none px-4 py-2.5 bg-white border border-slate-200 rounded-xl text-sm font-bold text-slate-700 hover:bg-slate-50 flex items-center justify-center gap-2">
              <Download className="w-4 h-4" /> Xuất báo cáo
            </button>
          </div>
        </div>

        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead>
                <tr className="bg-slate-50 text-slate-500 text-xs uppercase tracking-wider font-bold">
                  <th className="px-6 py-4">Mã phiên</th>
                  <th className="px-6 py-4">Thời gian</th>
                  <th className="px-6 py-4">Trạm sạc</th>
                  <th className="px-6 py-4">Điện năng</th>
                  <th className="px-6 py-4">Chi phí</th>
                  <th className="px-6 py-4">Trạng thái</th>
                  <th className="px-6 py-4"></th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredSessions.map((session, idx) => (
                  <tr 
                    key={`${session.SessionID}-${idx}`} 
                    className="hover:bg-slate-50 transition-colors cursor-pointer"
                    onClick={() => setSelectedSession(session)}
                  >
                    <td className="px-6 py-4 text-sm font-mono font-bold text-slate-400">#CHG-{session.SessionID}</td>
                    <td className="px-6 py-4">
                      <p className="text-sm font-medium text-slate-900">{new Date(session.StartTime).toLocaleDateString('vi-VN')}</p>
                      <p className="text-xs text-slate-500">{new Date(session.StartTime).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}</p>
                    </td>
                    <td className="px-6 py-4">
                      <p className="text-sm font-medium text-slate-900">Trạm Landmark 81</p>
                      <p className="text-xs text-slate-500">Trụ #02</p>
                    </td>
                    <td className="px-6 py-4 text-sm font-bold text-slate-900">{session.Total_kWh} kWh</td>
                    <td className="px-6 py-4 text-sm font-bold text-blue-600">{session.Cost_Total.toLocaleString()} VNĐ</td>
                    <td className="px-6 py-4">
                      <span className="px-2 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider bg-green-50 text-green-600">
                        {session.Status}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <ChevronRight className="w-4 h-4 text-slate-300 inline" />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
        {/* Reuse the same modal from dashboard */}
        {selectedSession && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
            <div className="bg-white w-full max-w-md rounded-3xl shadow-2xl overflow-hidden">
              <div className="p-6 bg-blue-600 text-white flex justify-between items-center">
                <h3 className="text-xl font-bold">Chi tiết hoá đơn</h3>
                <button onClick={() => setSelectedSession(null)} className="p-1 hover:bg-white/20 rounded-lg">
                  <X className="w-6 h-6" />
                </button>
              </div>
              <div className="p-8 space-y-6">
                <div className="text-center">
                  <div className="w-16 h-16 bg-blue-50 rounded-full flex items-center justify-center mx-auto mb-4">
                    <Zap className="w-8 h-8 text-blue-600" />
                  </div>
                  <h4 className="text-2xl font-bold text-slate-900">-{selectedSession.Cost_Total.toLocaleString()} VNĐ</h4>
                  <p className="text-slate-500 text-sm mt-1">Mã giao dịch: #CHG-{selectedSession.SessionID}</p>
                </div>
                <div className="space-y-4 border-t border-slate-100 pt-6">
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-500">Trạm sạc</span>
                    <span className="font-bold text-slate-900">Landmark 81</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-500">Tổng điện năng</span>
                    <span className="font-bold text-slate-900">{selectedSession.Total_kWh} kWh</span>
                  </div>
                </div>
                <button className="w-full py-3 bg-slate-900 text-white font-bold rounded-xl hover:bg-slate-800 transition-colors flex items-center justify-center gap-2">
                  <Download className="w-4 h-4" /> Tải hoá đơn (PDF)
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    );
  }

  if (activeTab === 'vehicles') {
    return (
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h3 className="text-xl font-bold text-slate-900">Quản lý phương tiện</h3>
          <button 
            onClick={() => setIsAddVehicleModalOpen(true)}
            className="flex items-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 shadow-sm transition-all"
          >
            <Plus className="w-4 h-4" /> Thêm xe mới
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {vehicles.map((vehicle) => (
            <div key={vehicle.VehicleID} className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden group hover:border-blue-300 transition-all">
              <div className="p-6">
                <div className="flex justify-between items-start mb-6">
                  <div className="w-12 h-12 bg-slate-100 rounded-xl flex items-center justify-center text-slate-600">
                    <Battery className="w-6 h-6" />
                  </div>
                  <button 
                    onClick={() => handleDeleteVehicle(vehicle.VehicleID)}
                    className="p-2 text-slate-300 hover:text-red-500 hover:bg-red-50 rounded-lg transition-all"
                  >
                    <Trash2 className="w-5 h-5" />
                  </button>
                </div>
                
                <p className="text-xs font-bold text-blue-600 uppercase tracking-widest mb-1">{vehicle.Brand}</p>
                <h4 className="text-xl font-bold text-slate-900 mb-4">{vehicle.Model}</h4>
                
                <div className="space-y-3 pt-4 border-t border-slate-50">
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-slate-500">Biển số</span>
                    <span className="text-sm font-mono font-bold bg-slate-100 px-2 py-0.5 rounded">{vehicle.PlateNumber}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-slate-500">Dung lượng pin</span>
                    <span className="text-sm font-bold text-slate-900">{vehicle.BatteryCapacity_kWh} kWh</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-slate-500">Cổng sạc</span>
                    <span className="text-sm font-bold text-slate-900">{vehicle.ConnectorType}</span>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Add Vehicle Modal */}
        {isAddVehicleModalOpen && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
            <div className="bg-white w-full max-w-md rounded-3xl shadow-2xl overflow-hidden">
              <div className="p-6 border-b border-slate-100 flex justify-between items-center">
                <h3 className="text-xl font-bold text-slate-900">Thêm xe mới</h3>
                <button onClick={() => setIsAddVehicleModalOpen(false)} className="p-1 hover:bg-slate-100 rounded-lg">
                  <X className="w-6 h-6 text-slate-400" />
                </button>
              </div>
              <form onSubmit={handleAddVehicle} className="p-8 space-y-4">
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase mb-1.5">Hãng xe</label>
                  <input 
                    required
                    type="text" 
                    value={newVehicle.Brand}
                    onChange={(e) => setNewVehicle({...newVehicle, Brand: e.target.value})}
                    placeholder="VD: VinFast, Tesla..." 
                    className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase mb-1.5">Dòng xe</label>
                  <input 
                    required
                    type="text" 
                    value={newVehicle.Model}
                    onChange={(e) => setNewVehicle({...newVehicle, Model: e.target.value})}
                    placeholder="VD: VF8, Model 3..." 
                    className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase mb-1.5">Biển số</label>
                  <input 
                    required
                    type="text" 
                    value={newVehicle.PlateNumber}
                    onChange={(e) => setNewVehicle({...newVehicle, PlateNumber: e.target.value})}
                    placeholder="VD: 51G-123.45" 
                    className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none"
                  />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-bold text-slate-500 uppercase mb-1.5">Dung lượng (kWh)</label>
                    <input 
                      required
                      type="number" 
                      value={newVehicle.BatteryCapacity_kWh || ''}
                      onChange={(e) => setNewVehicle({...newVehicle, BatteryCapacity_kWh: Number(e.target.value)})}
                      placeholder="82" 
                      className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-slate-500 uppercase mb-1.5">Cổng sạc</label>
                    <select 
                      value={newVehicle.ConnectorType}
                      onChange={(e) => setNewVehicle({...newVehicle, ConnectorType: e.target.value})}
                      className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none"
                    >
                      <option value="CCS2">CCS2</option>
                      <option value="Type 2">Type 2</option>
                      <option value="CHAdeMO">CHAdeMO</option>
                    </select>
                  </div>
                </div>
                <button type="submit" className="w-full py-3 bg-blue-600 text-white font-bold rounded-xl hover:bg-blue-700 shadow-lg shadow-blue-200 transition-all mt-4">
                  Xác nhận thêm xe
                </button>
              </form>
            </div>
          </div>
        )}
      </div>
    );
  }

  if (activeTab === 'charging') {
    return (
      <div className="max-w-4xl mx-auto space-y-8">
        <div className="bg-white rounded-3xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="p-8 bg-slate-900 text-white relative overflow-hidden">
            <div className="relative z-10 flex flex-col items-center text-center">
              <div className={cn(
                "w-24 h-24 rounded-full flex items-center justify-center mb-6 shadow-lg transition-all duration-500",
                isCharging ? "bg-blue-600 shadow-blue-500/20 animate-pulse" : "bg-green-600 shadow-green-500/20"
              )}>
                <Zap className={cn("w-12 h-12 text-white fill-current", !isCharging && "text-green-100")} />
              </div>
              <h3 className="text-2xl font-bold mb-1">{isCharging ? "Đang sạc nhanh DC" : "Phiên sạc đã hoàn tất"}</h3>
              <p className="text-slate-400 text-sm">Trạm Landmark 81 - Trụ #02</p>
              
              <div className="mt-10 w-full max-w-md">
                <div className="flex justify-between items-end mb-2">
                  <span className="text-4xl font-black text-white">{isCharging ? '72' : '100'}<span className="text-xl font-bold text-slate-500 ml-1">%</span></span>
                  <span className="text-sm font-bold text-blue-400">{isCharging ? 'Đang nạp: 45.2 kW' : 'Đã ngắt kết nối'}</span>
                </div>
                <div className="w-full bg-slate-800 h-3 rounded-full overflow-hidden">
                  <motion.div 
                    initial={{ width: 0 }}
                    animate={{ width: isCharging ? '72%' : '100%' }}
                    className={cn("h-full transition-colors duration-500", isCharging ? "bg-blue-500 shadow-[0_0_15px_rgba(59,130,246,0.5)]" : "bg-green-500")}
                  />
                </div>
                <div className="flex justify-between mt-3 text-[10px] uppercase font-bold tracking-wider text-slate-500">
                  <span>0%</span>
                  <span>{isCharging ? 'Ước tính: 15 phút còn lại' : 'Hoàn thành lúc 10:45'}</span>
                  <span>100%</span>
                </div>
              </div>
            </div>
            <div className="absolute top-0 right-0 w-64 h-64 bg-blue-600/10 rounded-full blur-3xl -mr-32 -mt-32" />
          </div>

          <div className="p-8 grid grid-cols-2 md:grid-cols-4 gap-8">
            <div className="space-y-1">
              <p className="text-[10px] uppercase font-bold text-slate-400 tracking-wider">Điện năng đã nạp</p>
              <p className="text-xl font-bold text-slate-900">{isCharging ? '32.45' : '45.80'} kWh</p>
            </div>
            <div className="space-y-1">
              <p className="text-[10px] uppercase font-bold text-slate-400 tracking-wider">Chi phí hiện tại</p>
              <p className="text-xl font-bold text-blue-600">{isCharging ? '113,575' : '160,300'} VNĐ</p>
            </div>
            <div className="space-y-1">
              <p className="text-[10px] uppercase font-bold text-slate-400 tracking-wider">Điện áp</p>
              <p className="text-xl font-bold text-slate-900">{isCharging ? '398 V' : '0 V'}</p>
            </div>
            <div className="space-y-1">
              <p className="text-[10px] uppercase font-bold text-slate-400 tracking-wider">Dòng điện</p>
              <p className="text-xl font-bold text-slate-900">{isCharging ? '114 A' : '0 A'}</p>
            </div>
          </div>

          <div className="p-8 bg-slate-50 border-t border-slate-100 flex flex-col sm:flex-row gap-4">
            {isCharging ? (
              <button 
                onClick={handleStopCharging}
                className="flex-1 py-4 bg-red-500 hover:bg-red-600 text-white font-bold rounded-2xl transition-all shadow-lg shadow-red-200 flex items-center justify-center gap-2"
              >
                <X className="w-5 h-5" /> Dừng sạc ngay lập tức
              </button>
            ) : (
              <button 
                onClick={() => setActiveTab('history')}
                className="flex-1 py-4 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-2xl transition-all shadow-lg shadow-blue-200 flex items-center justify-center gap-2"
              >
                <History className="w-5 h-5" /> Xem lịch sử sạc
              </button>
            )}
            <button 
              onClick={handleReportIssue}
              disabled={isReporting || reportSuccess}
              className={cn(
                "flex-1 py-4 font-bold rounded-2xl transition-all flex items-center justify-center gap-2 border",
                reportSuccess 
                  ? "bg-green-50 border-green-200 text-green-600" 
                  : "bg-white border-slate-200 text-slate-700 hover:bg-slate-50"
              )}
            >
              {isReporting ? (
                <div className="w-5 h-5 border-2 border-slate-300 border-t-slate-600 rounded-full animate-spin" />
              ) : reportSuccess ? (
                <>Đã gửi báo cáo thành công</>
              ) : (
                <><Info className="w-5 h-5" /> Hỗ trợ kỹ thuật</>
              )}
            </button>
          </div>
        </div>

        <div className="bg-blue-50 border border-blue-100 rounded-2xl p-6 flex items-start gap-4">
          <div className="p-2 bg-blue-100 rounded-xl text-blue-600">
            <TrendingUp className="w-5 h-5" />
          </div>
          <div>
            <h4 className="font-bold text-blue-900">Mẹo tối ưu pin</h4>
            <p className="text-sm text-blue-700 mt-1 leading-relaxed">
              Sạc đến 80% giúp kéo dài tuổi thọ pin xe điện của bạn. Tốc độ sạc sẽ giảm dần sau khi đạt mức 80% để bảo vệ các cell pin.
            </p>
          </div>
        </div>
      </div>
    );
  }

  if (activeTab === 'wallet') {
    return (
      <div className="space-y-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-1 space-y-6">
            <div className="bg-gradient-to-br from-blue-600 to-blue-800 p-8 rounded-3xl text-white shadow-xl shadow-blue-200 relative overflow-hidden">
              <div className="relative z-10">
                <p className="text-blue-100 text-sm font-medium mb-2">Số dư khả dụng</p>
                <h3 className="text-3xl font-black mb-8">{walletBalance.toLocaleString()} VNĐ</h3>
                
                <div className="flex gap-3">
                  <button 
                    onClick={() => setIsTopUpModalOpen(true)}
                    disabled={isTopUpSuccess}
                    className={cn(
                      "flex-1 py-3 font-bold rounded-xl transition-all flex items-center justify-center gap-2",
                      isTopUpSuccess ? "bg-green-500 text-white" : "bg-white text-blue-600 hover:bg-blue-50"
                    )}
                  >
                    {isTopUpSuccess ? 'Đang xử lý...' : <><Plus className="w-4 h-4" /> Nạp tiền</>}
                  </button>
                  <button className="p-3 bg-blue-500/30 text-white rounded-xl hover:bg-blue-500/50 transition-all">
                    <Settings className="w-5 h-5" />
                  </button>
                </div>
              </div>
              <div className="absolute -right-10 -bottom-10 w-40 h-40 bg-white/10 rounded-full blur-3xl" />
            </div>

            <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
              <h4 className="font-bold text-slate-900 mb-4">Phương thức thanh toán</h4>
              <div className="space-y-3">
                <div className="flex items-center justify-between p-3 border border-slate-100 rounded-xl bg-slate-50">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-6 bg-slate-900 rounded flex items-center justify-center text-[8px] font-bold text-white">VISA</div>
                    <span className="text-sm font-medium text-slate-700">**** 4242</span>
                  </div>
                  <span className="text-[10px] font-bold text-slate-400 uppercase">Mặc định</span>
                </div>
                <button className="w-full py-3 border-2 border-dashed border-slate-200 text-slate-400 text-sm font-bold rounded-xl hover:border-blue-300 hover:text-blue-500 transition-all flex items-center justify-center gap-2">
                  <Plus className="w-4 h-4" /> Thêm thẻ mới
                </button>
              </div>
            </div>
          </div>

          <div className="lg:col-span-2 bg-white rounded-3xl border border-slate-200 shadow-sm overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex items-center justify-between">
              <h3 className="font-bold text-slate-900">Lịch sử giao dịch</h3>
              <div className="flex gap-2">
                <button className="p-2 hover:bg-slate-50 rounded-lg border border-slate-100"><Filter className="w-4 h-4 text-slate-400" /></button>
                <button className="p-2 hover:bg-slate-50 rounded-lg border border-slate-100"><Download className="w-4 h-4 text-slate-400" /></button>
              </div>
            </div>
            <div className="divide-y divide-slate-50">
              {transactions.slice(0, showAllTransactions ? undefined : 2).map((tx) => (
                <div key={tx.TransactionID} className="p-6 flex items-center justify-between hover:bg-slate-50 transition-colors">
                  <div className="flex items-center gap-4">
                    <div className={cn(
                      "w-12 h-12 rounded-2xl flex items-center justify-center",
                      tx.TransactionType === 'Top-up' ? "bg-green-50 text-green-600" : "bg-blue-50 text-blue-600"
                    )}>
                      {tx.TransactionType === 'Top-up' ? <TrendingUp className="w-6 h-6" /> : <Zap className="w-6 h-6" />}
                    </div>
                    <div>
                      <p className="font-bold text-slate-900">{tx.TransactionType === 'Top-up' ? 'Nạp tiền vào ví' : 'Thanh toán phiên sạc'}</p>
                      <p className="text-xs text-slate-500 mt-0.5">{new Date(tx.Timestamp).toLocaleString('vi-VN')}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className={cn(
                      "font-bold text-lg",
                      tx.Amount > 0 ? "text-green-600" : "text-slate-900"
                    )}>
                      {tx.Amount > 0 ? '+' : ''}{tx.Amount.toLocaleString()} VNĐ
                    </p>
                    <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Thành công</p>
                  </div>
                </div>
              ))}
            </div>
            {!showAllTransactions && (
              <button 
                onClick={() => setShowAllTransactions(true)}
                className="w-full py-4 text-sm font-bold text-slate-400 hover:text-slate-900 bg-slate-50/50 transition-colors"
              >
                Xem giao dịch cũ hơn
              </button>
            )}
          </div>
        </div>

        {/* Top-up Modal */}
        {isTopUpModalOpen && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
            <div className="bg-white w-full max-w-md rounded-3xl shadow-2xl overflow-hidden">
              <div className="p-6 border-b border-slate-100 flex justify-between items-center">
                <h3 className="text-xl font-bold text-slate-900">Nạp tiền vào ví</h3>
                <button onClick={() => setIsTopUpModalOpen(false)} className="p-1 hover:bg-slate-100 rounded-lg">
                  <X className="w-6 h-6 text-slate-400" />
                </button>
              </div>
              <div className="p-8 space-y-6">
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase mb-3">Chọn số tiền nạp</label>
                  <div className="grid grid-cols-3 gap-3">
                    {['100.000', '200.000', '500.000', '1.000.000', '2.000.000', 'Khác'].map((amount) => (
                      <button 
                        key={amount}
                        onClick={handleTopUp}
                        className={cn(
                          "py-3 text-sm font-bold rounded-xl border transition-all",
                          amount === '500.000' ? "bg-blue-600 border-blue-600 text-white shadow-lg shadow-blue-100" : "bg-white border-slate-200 text-slate-600 hover:border-blue-300"
                        )}
                      >
                        {amount}
                      </button>
                    ))}
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase mb-3">Phương thức thanh toán</label>
                  <div className="space-y-3">
                    <div className="flex items-center justify-between p-4 border-2 border-blue-600 rounded-2xl bg-blue-50/50">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-6 bg-slate-900 rounded flex items-center justify-center text-[8px] font-bold text-white">VISA</div>
                        <span className="text-sm font-bold text-slate-900">Thẻ Visa (**** 4242)</span>
                      </div>
                      <div className="w-5 h-5 rounded-full border-4 border-blue-600 bg-white" />
                    </div>
                    <div className="flex items-center justify-between p-4 border border-slate-100 rounded-2xl hover:bg-slate-50 transition-all cursor-pointer">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 bg-pink-50 rounded-xl flex items-center justify-center text-pink-600 font-bold text-xs">Momo</div>
                        <span className="text-sm font-medium text-slate-700">Ví MoMo</span>
                      </div>
                      <div className="w-5 h-5 rounded-full border-2 border-slate-200" />
                    </div>
                  </div>
                </div>

                <button 
                  onClick={handleTopUp}
                  className="w-full py-4 bg-blue-600 text-white font-bold rounded-2xl hover:bg-blue-700 shadow-lg shadow-blue-100 transition-all mt-4"
                >
                  Xác nhận nạp tiền
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    );
  }

  if (activeTab === 'profile') {
    return (
      <div className="max-w-4xl mx-auto space-y-8">
        <div className="bg-white rounded-3xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="h-32 bg-gradient-to-r from-blue-600 to-indigo-600" />
          <div className="px-8 pb-8">
            <div className="relative flex justify-between items-end -mt-12 mb-8">
              <div className="w-24 h-24 rounded-3xl bg-white p-1 shadow-xl">
                <div className="w-full h-full rounded-2xl bg-slate-100 flex items-center justify-center text-slate-400">
                  <img 
                    src="https://api.dicebear.com/7.x/avataaars/svg?seed=Felix" 
                    alt="Avatar" 
                    className="w-full h-full rounded-2xl object-cover"
                  />
                </div>
              </div>
              <button 
                onClick={() => setIsEditProfileModalOpen(true)}
                className="px-6 py-2.5 bg-blue-600 text-white font-bold rounded-xl hover:bg-blue-700 transition-all shadow-lg shadow-blue-100"
              >
                Chỉnh sửa hồ sơ
              </button>
            </div>
            
            <div className="space-y-1">
              <h3 className="text-2xl font-bold text-slate-900">{profileDataInner.FullName}</h3>
              <p className="text-slate-500 font-medium">{profileDataInner.Email}</p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mt-10">
              <div className="space-y-6">
                <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider">Thông tin cá nhân</h4>
                <div className="space-y-4">
                  <div className="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl border border-slate-100">
                    <div className="p-2 bg-white rounded-lg text-slate-400"><Search className="w-4 h-4" /></div>
                    <div>
                      <p className="text-[10px] font-bold text-slate-400 uppercase">Số điện thoại</p>
                      <p className="text-sm font-bold text-slate-900">{profileDataInner.Phone}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-4 p-4 bg-slate-50 rounded-2xl border border-slate-100">
                    <div className="p-2 bg-white rounded-lg text-slate-400"><MapPin className="w-4 h-4" /></div>
                    <div>
                      <p className="text-[10px] font-bold text-slate-400 uppercase">Địa chỉ</p>
                      <p className="text-sm font-bold text-slate-900">{profileDataInner.Address}</p>
                    </div>
                  </div>
                </div>
              </div>

              <div className="space-y-6">
                <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider">Cài đặt tài khoản</h4>
                <div className="space-y-3">
                  <button 
                    onClick={() => setActiveTab('wallet')}
                    className="w-full flex items-center justify-between p-4 hover:bg-slate-50 rounded-2xl transition-all group"
                  >
                    <div className="flex items-center gap-4">
                      <div className="p-2 bg-slate-100 rounded-lg text-slate-500 group-hover:bg-blue-50 group-hover:text-blue-600 transition-all"><CreditCard className="w-4 h-4" /></div>
                      <span className="text-sm font-bold text-slate-700">Quản lý thanh toán</span>
                    </div>
                    <ChevronRight className="w-4 h-4 text-slate-300" />
                  </button>
                  <button className="w-full flex items-center justify-between p-4 hover:bg-slate-50 rounded-2xl transition-all group">
                    <div className="flex items-center gap-4">
                      <div className="p-2 bg-slate-100 rounded-lg text-slate-500 group-hover:bg-blue-50 group-hover:text-blue-600 transition-all"><Settings className="w-4 h-4" /></div>
                      <span className="text-sm font-bold text-slate-700">Thông báo & Bảo mật</span>
                    </div>
                    <ChevronRight className="w-4 h-4 text-slate-300" />
                  </button>
                  <button className="w-full flex items-center justify-between p-4 hover:bg-red-50 rounded-2xl transition-all group">
                    <div className="flex items-center gap-4">
                      <div className="p-2 bg-red-50 rounded-lg text-red-400 group-hover:bg-red-100 group-hover:text-red-600 transition-all"><Trash2 className="w-4 h-4" /></div>
                      <span className="text-sm font-bold text-red-600">Đăng xuất</span>
                    </div>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (activeTab === 'map') {
    return (
      <div className="space-y-6">
        <div className="flex flex-col md:flex-row gap-4 items-center justify-between">
          <div className="relative w-full md:w-96">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input 
              type="text" 
              placeholder="Tìm trạm sạc, địa chỉ..." 
              className="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none transition-all"
            />
          </div>
          <div className="flex items-center gap-2 w-full md:w-auto">
            <button className="flex-1 md:flex-none flex items-center justify-center gap-2 px-4 py-2.5 bg-white border border-slate-200 rounded-xl text-sm font-bold text-slate-700 hover:bg-slate-50">
              <Filter className="w-4 h-4" /> Bộ lọc
            </button>
            <button className="flex-1 md:flex-none flex items-center justify-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-xl text-sm font-bold hover:bg-blue-700 shadow-sm">
              <Navigation className="w-4 h-4" /> Gần tôi
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2 space-y-4">
            {stations.map((station) => (
              <div 
                key={station.StationID} 
                onClick={() => setSelectedStation(station)}
                className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm hover:border-blue-300 transition-all group cursor-pointer"
              >
                <div className="flex justify-between items-start">
                  <div>
                    <h4 className="font-bold text-slate-900 group-hover:text-blue-600 transition-colors">{station.StationName}</h4>
                    <p className="text-sm text-slate-500 mt-1 flex items-center gap-1">
                      <MapPin className="w-3 h-3" /> {station.Address}
                    </p>
                  </div>
                  <span className="px-2 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider bg-green-50 text-green-600">
                    {station.Station_Status}
                  </span>
                </div>
                
                <div className="mt-6 grid grid-cols-2 sm:grid-cols-4 gap-4">
                  <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                    <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Trụ khả dụng</p>
                    <p className="text-lg font-bold text-slate-900">4/6</p>
                  </div>
                  <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                    <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Công suất</p>
                    <p className="text-lg font-bold text-slate-900">150kW</p>
                  </div>
                  <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                    <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Khoảng cách</p>
                    <p className="text-lg font-bold text-slate-900">2.4 km</p>
                  </div>
                  <div className="bg-slate-50 p-3 rounded-xl border border-slate-100">
                    <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Giá sạc</p>
                    <p className="text-lg font-bold text-blue-600">3.5k</p>
                  </div>
                </div>
              </div>
            ))}
          </div>

          <div className="bg-slate-200 rounded-2xl border border-slate-300 min-h-[400px] flex items-center justify-center relative overflow-hidden">
            <div className="absolute inset-0 bg-[url('https://picsum.photos/seed/map/800/800')] bg-cover bg-center opacity-50 grayscale" />
            <div className="relative z-10 bg-white/90 backdrop-blur-sm p-4 rounded-xl shadow-xl border border-white/50 text-center">
              <MapPin className="w-8 h-8 text-blue-600 mx-auto mb-2" />
              <p className="font-bold text-slate-900">Bản đồ tương tác</p>
              <p className="text-xs text-slate-500 mt-1">Đang tải dữ liệu vị trí...</p>
            </div>
          </div>
        </div>

        {/* Station Detail Modal */}
        {selectedStation && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
            <div className="bg-white w-full max-w-lg rounded-3xl shadow-2xl overflow-hidden">
              <div className="relative h-48 bg-slate-200">
                <img 
                  src={`https://picsum.photos/seed/${selectedStation.StationID}/800/400`} 
                  alt={selectedStation.StationName}
                  className="w-full h-full object-cover"
                  referrerPolicy="no-referrer"
                />
                <button 
                  onClick={() => setSelectedStation(null)}
                  className="absolute top-4 right-4 p-2 bg-white/80 backdrop-blur-sm rounded-full hover:bg-white transition-all"
                >
                  <X className="w-5 h-5 text-slate-900" />
                </button>
              </div>
              
              <div className="p-8">
                <div className="flex justify-between items-start mb-6">
                  <div>
                    <h3 className="text-2xl font-bold text-slate-900">{selectedStation.StationName}</h3>
                    <p className="text-slate-500 flex items-center gap-1 mt-1">
                      <MapPin className="w-4 h-4" /> {selectedStation.Address}
                    </p>
                  </div>
                  <span className="px-3 py-1 bg-green-50 text-green-600 text-xs font-bold rounded-full border border-green-100">
                    {selectedStation.Station_Status}
                  </span>
                </div>

                <div className="grid grid-cols-3 gap-4 mb-8">
                  <div className="p-4 bg-slate-50 rounded-2xl border border-slate-100 text-center">
                    <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Trụ khả dụng</p>
                    <p className="text-xl font-bold text-slate-900">4/6</p>
                  </div>
                  <div className="p-4 bg-slate-50 rounded-2xl border border-slate-100 text-center">
                    <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Công suất tối đa</p>
                    <p className="text-xl font-bold text-slate-900">150kW</p>
                  </div>
                  <div className="p-4 bg-slate-50 rounded-2xl border border-slate-100 text-center">
                    <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Giá sạc</p>
                    <p className="text-xl font-bold text-blue-600">3.5k</p>
                  </div>
                </div>

                <div className="space-y-4">
                  <h4 className="font-bold text-slate-900">Danh sách trụ sạc</h4>
                  <div className="space-y-2">
                    {points.filter(p => p.StationID === selectedStation.StationID).map(point => (
                      <div 
                        key={point.PointID} 
                        onClick={() => point.Point_Status === 'Available' && setSelectedPointForCharging(point)}
                        className={cn(
                          "flex items-center justify-between p-4 border rounded-2xl transition-all cursor-pointer",
                          selectedPointForCharging?.PointID === point.PointID ? "border-blue-600 bg-blue-50/50 shadow-sm" : "border-slate-100 bg-white hover:border-blue-200",
                          point.Point_Status !== 'Available' && "opacity-50 cursor-not-allowed"
                        )}
                      >
                        <div className="flex items-center gap-4">
                          <div className={cn(
                            "w-10 h-10 rounded-xl flex items-center justify-center",
                            point.Point_Status === 'Available' ? "bg-green-50 text-green-600" : "bg-slate-50 text-slate-400"
                          )}>
                            <Zap className="w-5 h-5" />
                          </div>
                          <div>
                            <p className="font-bold text-slate-900">Trụ #{point.PointID} - {point.Connector_Type}</p>
                            <p className="text-xs text-slate-500">{point.Power_kW} kW</p>
                          </div>
                        </div>
                        <span className={cn(
                          "text-xs font-bold px-2 py-1 rounded-lg",
                          point.Point_Status === 'Available' ? "text-green-600 bg-green-50" : "text-slate-400 bg-slate-100"
                        )}>
                          {point.Point_Status}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="mt-8 flex gap-4">
                  <button 
                    disabled={!selectedPointForCharging}
                    onClick={() => {
                      setIsCharging(true);
                      setSelectedStation(null);
                      setActiveTab('charging');
                    }}
                    className={cn(
                      "flex-1 py-4 font-bold rounded-2xl transition-all flex items-center justify-center gap-2",
                      selectedPointForCharging 
                        ? "bg-blue-600 text-white hover:bg-blue-700 shadow-lg shadow-blue-100" 
                        : "bg-slate-100 text-slate-400 cursor-not-allowed"
                    )}
                  >
                    <Zap className="w-5 h-5" /> Bắt đầu sạc
                  </button>
                  <button className="p-4 bg-slate-100 text-slate-700 rounded-2xl hover:bg-slate-200 transition-all">
                    <Navigation className="w-6 h-6" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Edit Profile Modal */}
        {isEditProfileModalOpen && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm">
            <div className="bg-white w-full max-w-md rounded-3xl shadow-2xl overflow-hidden">
              <div className="p-6 border-b border-slate-100 flex justify-between items-center">
                <h3 className="text-xl font-bold text-slate-900">Chỉnh sửa hồ sơ</h3>
                <button onClick={() => setIsEditProfileModalOpen(false)} className="p-1 hover:bg-slate-100 rounded-lg">
                  <X className="w-6 h-6 text-slate-400" />
                </button>
              </div>
              <form onSubmit={(e) => {
                e.preventDefault();
                setIsEditProfileModalOpen(false);
              }} className="p-8 space-y-4">
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase mb-2">Họ và tên</label>
                  <input 
                    type="text" 
                    value={profileDataInner.FullName}
                    onChange={(e) => setProfileDataInner({...profileDataInner, FullName: e.target.value})}
                    className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase mb-2">Email</label>
                  <input 
                    type="email" 
                    value={profileDataInner.Email}
                    onChange={(e) => setProfileDataInner({...profileDataInner, Email: e.target.value})}
                    className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase mb-2">Số điện thoại</label>
                  <input 
                    type="tel" 
                    value={profileDataInner.Phone}
                    onChange={(e) => setProfileDataInner({...profileDataInner, Phone: e.target.value})}
                    className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase mb-2">Địa chỉ</label>
                  <input 
                    type="text" 
                    value={profileDataInner.Address}
                    onChange={(e) => setProfileDataInner({...profileDataInner, Address: e.target.value})}
                    className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <button type="submit" className="w-full py-4 bg-blue-600 text-white font-bold rounded-2xl hover:bg-blue-700 shadow-lg shadow-blue-100 transition-all mt-4">
                  Lưu thay đổi
                </button>
              </form>
            </div>
          </div>
        )}
      </div>
    );
  }

  return (
    <div className="flex flex-col items-center justify-center py-20 text-center">
      <div className="w-20 h-20 bg-slate-100 rounded-full flex items-center justify-center mb-6">
        <Clock className="w-10 h-10 text-slate-400" />
      </div>
      <h2 className="text-2xl font-bold text-slate-900">Tính năng đang phát triển</h2>
      <p className="text-slate-500 mt-2 max-w-md">Chúng tôi đang nỗ lực hoàn thiện giao diện cho mục này. Vui lòng quay lại sau.</p>
    </div>
  );
}
