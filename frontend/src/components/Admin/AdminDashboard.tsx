import React from 'react';
import { 
  Users, 
  Building2, 
  PlugZap, 
  CreditCard, 
  TrendingUp, 
  ShieldCheck, 
  Globe, 
  AlertCircle,
  Plus,
  Search,
  Filter,
  ArrowUpRight,
  ArrowDownRight,
  Zap
} from 'lucide-react';
import { 
  PieChart, 
  Pie, 
  Cell, 
  ResponsiveContainer, 
  Tooltip,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid
} from 'recharts';
import { api } from '../../services/api';

const COLORS = ['#2563eb', '#10b981', '#f59e0b', '#6366f1'];

export default function AdminDashboard({ 
  activeTab, 
  setActiveTab 
}: { 
  activeTab: string;
  setActiveTab: (tab: string) => void;
}) {
  const [dashboardData, setDashboardData] = React.useState<any>(null);
  const [franchisees, setFranchisees] = React.useState<any[]>([]);
  const [suppliers, setSuppliers] = React.useState<any[]>([]);
  const [users, setUsers] = React.useState<any[]>([]);
  const [pricing, setPricing] = React.useState<any[]>([]);
  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {
    loadData();
  }, [activeTab]);

  async function loadData() {
    setLoading(true);
    try {
      if (activeTab === 'dashboard') {
        const res = await api.get('/dashboard/admin');
        if (res.success) setDashboardData(res.data);
      } else if (activeTab === 'franchisees') {
        const res = await api.get('/franchisees');
        if (res.success) setFranchisees(res.data);
      } else if (activeTab === 'suppliers') {
        const res = await api.get('/suppliers');
        if (res.success) setSuppliers(res.data);
      } else if (activeTab === 'users') {
        const res = await api.get('/users');
        if (res.success) setUsers(res.data);
      } else if (activeTab === 'pricing') {
        const res = await api.get('/pricing');
        if (res.success) setPricing(res.data);
      }
    } catch (err) {
      console.error('Admin loadData error:', err);
    } finally {
      setLoading(false);
    }
  }

  if (activeTab === 'dashboard') {
    const counts = dashboardData?.counts || {};
    const totals = dashboardData?.totals || {};
    const revenueByDay: { Date: string; Revenue: number }[] = dashboardData?.revenueByDay || [];
    const topStations: { StationName: string; Sessions: number; KWh: number; Revenue: number }[] = dashboardData?.topStations || [];

    const totalRevenue = totals.revenue || 0;
    const totalUsers = counts.users || 0;
    const totalFranchises = counts.franchises || 0;
    const totalStations = counts.stations || 0;
    const uptime = totalStations > 0 ? ((totalStations - (counts.activeAlerts || 0)) / totalStations * 100).toFixed(1) : 'N/A';

    return (
      <div className="space-y-8">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
            <p className="text-slate-500 text-sm font-medium">Tổng doanh thu hệ thống</p>
            <div className="flex items-center gap-2 mt-1">
              <h3 className="text-2xl font-bold text-slate-900">{(totalRevenue / 1e6).toFixed(1)}M VNĐ</h3>
            </div>
            <p className="text-[10px] text-slate-400 mt-2 font-bold uppercase tracking-wider">Từ tất cả giao dịch</p>
          </div>

          <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
            <p className="text-slate-500 text-sm font-medium">Tổng số người dùng</p>
            <div className="flex items-center gap-2 mt-1">
              <h3 className="text-2xl font-bold text-slate-900">{totalUsers.toLocaleString()}</h3>
            </div>
            <p className="text-[10px] text-slate-400 mt-2 font-bold uppercase tracking-wider">Người dùng đã đăng ký</p>
          </div>

          <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
            <p className="text-slate-500 text-sm font-medium">Đối tác nhượng quyền</p>
            <div className="flex items-center gap-2 mt-1">
              <h3 className="text-2xl font-bold text-slate-900">{totalFranchises}</h3>
            </div>
            <p className="text-[10px] text-slate-400 mt-2 font-bold uppercase tracking-wider">Trên toàn hệ thống</p>
          </div>

          <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
            <p className="text-slate-500 text-sm font-medium">Tỷ lệ uptime trụ sạc</p>
            <div className="flex items-center gap-2 mt-1">
              <h3 className="text-2xl font-bold text-slate-900">{uptime}%</h3>
            </div>
            <p className="text-[10px] text-slate-400 mt-2 font-bold uppercase tracking-wider">{counts.activeAlerts || 0} cảnh báo đang mở</p>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
            <h3 className="font-bold text-slate-900 mb-6">Tăng trưởng doanh thu (VNĐ)</h3>
            {revenueByDay.length > 0 ? (
              <div className="h-[300px] w-full">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={revenueByDay.map(d => ({ ...d, date: new Date(d.Date).toLocaleDateString('vi-VN', { month: 'short', day: 'numeric' }) }))}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                    <XAxis dataKey="date" axisLine={false} tickLine={false} tick={{fill: '#64748b', fontSize: 12}} dy={10} />
                    <YAxis axisLine={false} tickLine={false} tick={{fill: '#64748b', fontSize: 12}} />
                    <Tooltip contentStyle={{ borderRadius: '12px', border: '1px solid #e2e8f0' }} />
                    <Line type="monotone" dataKey="Revenue" stroke="#2563eb" strokeWidth={3} dot={{ r: 4, fill: '#2563eb' }} activeDot={{ r: 6 }} />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            ) : (
              <div className="h-[300px] flex items-center justify-center text-slate-400">Chưa có dữ liệu doanh thu</div>
            )}
          </div>

          <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
            <h3 className="font-bold text-slate-900 mb-6">Top trạm sạc</h3>
            {topStations.length > 0 ? (
              <div className="space-y-4">
                {topStations.map((s, i) => (
                  <div key={i} className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <div className="w-2 h-2 rounded-full" style={{ backgroundColor: COLORS[i % COLORS.length] }} />
                      <span className="text-sm text-slate-600 truncate max-w-[140px]">{s.StationName}</span>
                    </div>
                    <span className="text-sm font-bold text-slate-900">{(s.Revenue || 0).toLocaleString()} VNĐ</span>
                  </div>
                ))}
              </div>
            ) : (
              <div className="h-[250px] flex items-center justify-center text-slate-400">Chưa có dữ liệu</div>
            )}
          </div>
        </div>
      </div>
    );
  }

  if (activeTab === 'franchisees') {
    return (
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <div className="relative w-96">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input type="text" placeholder="Tìm đối tác..." className="w-full pl-10 pr-4 py-2 bg-white border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
          </div>
          <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 transition-all">
            <Plus className="w-4 h-4" /> Thêm đối tác
          </button>
        </div>

        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-slate-50 text-slate-500 text-xs uppercase font-bold tracking-wider">
                <th className="px-6 py-4">Đối tác</th>
                <th className="px-6 py-4">Mã số thuế</th>
                <th className="px-6 py-4">Người đại diện</th>
                <th className="px-6 py-4">Tỷ lệ chia sẻ</th>
                <th className="px-6 py-4">Ngày hợp đồng</th>
                <th className="px-6 py-4">Trạng thái</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {franchisees.map((f: any) => (
                <tr key={f.FranchiseID} className="hover:bg-slate-50 transition-colors">
                  <td className="px-6 py-4">
                    <p className="font-bold text-slate-900">{f.FranchiseName}</p>
                    <p className="text-xs text-slate-500">{f.Email}</p>
                  </td>
                  <td className="px-6 py-4 text-sm font-mono">{f.TaxCode}</td>
                  <td className="px-6 py-4 text-sm">{f.ContactPerson}</td>
                  <td className="px-6 py-4 text-sm font-bold text-blue-600">{f.RevenueShareRate}%</td>
                  <td className="px-6 py-4 text-sm text-slate-600">{new Date(f.ContractDate).toLocaleDateString('vi-VN')}</td>
                  <td className="px-6 py-4">
                    <span className="px-2 py-1 rounded-full text-[10px] font-bold uppercase bg-green-50 text-green-600">Active</span>
                  </td>
                </tr>
              ))}
              {franchisees.length === 0 && !loading && (
                <tr><td colSpan={6} className="px-6 py-12 text-center text-slate-400">Chưa có đối tác nào</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    );
  }

  if (activeTab === 'pricing') {
    return (
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h2 className="text-2xl font-bold text-slate-900">Chính sách giá</h2>
          <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 transition-all">
            <Plus className="w-4 h-4" /> Thêm chính sách
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {pricing.map((p: any) => (
            <div key={p.PolicyID} className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
              <div className="flex items-center gap-3 mb-4">
                <div className="p-2 bg-blue-50 rounded-lg text-blue-600"><Zap className="w-5 h-5" /></div>
                <h4 className="font-bold text-slate-900">{p.PolicyName}</h4>
              </div>
              <p className="text-3xl font-bold text-slate-900">{p.BasePrice_kWh.toLocaleString()} <span className="text-sm font-medium text-slate-400">VNĐ/kWh</span></p>
              <div className="mt-4 pt-4 border-t border-slate-50 space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-slate-500">Giờ cao điểm</span>
                  <span className="font-bold text-amber-600">+{(p.PeakHourMultiplier - 1) * 100}%</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-slate-500">Áp dụng từ</span>
                  <span className="font-bold text-slate-900">{new Date(p.AppliedFrom).toLocaleDateString('vi-VN')}</span>
                </div>
              </div>
            </div>
          ))}
          {pricing.length === 0 && !loading && (
            <div className="col-span-3 text-center text-slate-400 py-12">Chưa có chính sách giá nào</div>
          )}
        </div>
      </div>
    );
  }

  if (activeTab === 'suppliers') {
    return (
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h2 className="text-2xl font-bold text-slate-900">Nhà cung cấp điện</h2>
          <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 transition-all">
            <Plus className="w-4 h-4" /> Thêm nhà cung cấp
          </button>
        </div>

        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-slate-50 text-slate-500 text-xs uppercase font-bold tracking-wider">
                <th className="px-6 py-4">Nhà cung cấp</th>
                <th className="px-6 py-4">Khu vực</th>
                <th className="px-6 py-4">Đơn giá (kWh)</th>
                <th className="px-6 py-4">Liên hệ</th>
                <th className="px-6 py-4">Trạng thái</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {suppliers.map((s: any) => (
                <tr key={s.SupplierID} className="hover:bg-slate-50 transition-colors">
                  <td className="px-6 py-4">
                    <p className="font-bold text-slate-900">{s.SupplierName}</p>
                  </td>
                  <td className="px-6 py-4 text-sm text-slate-600">{s.Region}</td>
                  <td className="px-6 py-4 text-sm font-bold text-slate-900">{s.UnitPrice_kWh.toLocaleString()} VNĐ</td>
                  <td className="px-6 py-4 text-sm text-slate-500">{s.ContactInfo}</td>
                  <td className="px-6 py-4">
                    <span className="px-2 py-1 rounded-full text-[10px] font-bold uppercase bg-green-50 text-green-600">Hợp tác</span>
                  </td>
                </tr>
              ))}
              {suppliers.length === 0 && !loading && (
                <tr><td colSpan={5} className="px-6 py-12 text-center text-slate-400">Chưa có nhà cung cấp nào</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    );
  }

  if (activeTab === 'users') {
    return (
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <div className="relative w-96">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input type="text" placeholder="Tìm người dùng..." className="w-full pl-10 pr-4 py-2 bg-white border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
          </div>
          <div className="flex gap-2">
            <button className="flex items-center gap-2 px-4 py-2 bg-white border border-slate-200 rounded-xl text-sm font-bold text-slate-600 hover:bg-slate-50">
              <Filter className="w-4 h-4" /> Lọc
            </button>
            <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 transition-all">
              <Plus className="w-4 h-4" /> Thêm người dùng
            </button>
          </div>
        </div>

        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-slate-50 text-slate-500 text-xs uppercase font-bold tracking-wider">
                <th className="px-6 py-4">Người dùng</th>
                <th className="px-6 py-4">Số điện thoại</th>
                <th className="px-6 py-4">Số dư ví</th>
                <th className="px-6 py-4">Ngày tham gia</th>
                <th className="px-6 py-4">Trạng thái</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {users.map((c: any) => (
                <tr key={c.UserID} className="hover:bg-slate-50 transition-colors">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-slate-400">
                        <Users className="w-4 h-4" />
                      </div>
                      <div>
                        <p className="font-bold text-slate-900">{c.FullName}</p>
                        <p className="text-xs text-slate-500">{c.Email}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm text-slate-600">{c.Phone}</td>
                  <td className="px-6 py-4 text-sm font-bold text-blue-600">{c.WalletBalance.toLocaleString()} VNĐ</td>
                  <td className="px-6 py-4 text-sm text-slate-500">{new Date(c.CreatedAt).toLocaleDateString('vi-VN')}</td>
                  <td className="px-6 py-4">
                    <span className="px-2 py-1 rounded-full text-[10px] font-bold uppercase bg-green-50 text-green-600">{(c.AccountStatus || 'Active').toUpperCase()}</span>
                  </td>
                </tr>
              ))}
              {users.length === 0 && !loading && (
                <tr><td colSpan={5} className="px-6 py-12 text-center text-slate-400">Chưa có người dùng nào</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col items-center justify-center py-20 text-center">
      <ShieldCheck className="w-16 h-16 text-slate-200 mb-6" />
      <h2 className="text-2xl font-bold text-slate-900">Hệ thống quản trị Admin</h2>
      <p className="text-slate-500 mt-2">Vui lòng chọn các mục quản lý từ menu bên trái.</p>
    </div>
  );
}
