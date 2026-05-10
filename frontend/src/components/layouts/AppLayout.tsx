import { useState } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import {
  LayoutDashboard, MapPin, Zap, History, Settings, Users, Building2,
  AlertTriangle, Wallet, Battery, LogOut, Menu, X, BarChart3,
  PlugZap, CreditCard, UserCircle, Bell, Calendar, Star,
  Navigation,
} from 'lucide-react';
import { motion } from 'motion/react';
import { cn } from '../../lib/utils';

const clientNav = [
  { id: 'dashboard', name: 'Tổng quan', icon: LayoutDashboard, path: '/client/dashboard' },
  { id: 'map', name: 'Tìm trạm sạc', icon: Navigation, path: '/client/map' },
  { id: 'vehicles', name: 'Quản lý xe', icon: Battery, path: '/client/vehicles' },
  { id: 'charging', name: 'Đang sạc', icon: Zap, path: '/client/charging' },
  { id: 'bookings', name: 'Đặt lịch', icon: Calendar, path: '/client/bookings' },
  { id: 'history', name: 'Lịch sử', icon: History, path: '/client/history' },
  { id: 'wallet', name: 'Ví điện tử', icon: Wallet, path: '/client/wallet' },
  { id: 'reviews', name: 'Đánh giá', icon: Star, path: '/client/reviews' },
  { id: 'notifications', name: 'Thông báo', icon: Bell, path: '/client/notifications' },
  { id: 'profile', name: 'Hồ sơ', icon: UserCircle, path: '/client/profile' },
];

const managerNav = [
  { id: 'dashboard', name: 'Dashboard', icon: LayoutDashboard, path: '/manager/dashboard' },
  { id: 'stations', name: 'Quản lý trạm', icon: Building2, path: '/manager/stations' },
  { id: 'sessions', name: 'Phiên sạc', icon: Zap, path: '/manager/sessions' },
  { id: 'errors', name: 'Lỗi hệ thống', icon: AlertTriangle, path: '/manager/errors' },
  { id: 'revenue', name: 'Doanh thu', icon: BarChart3, path: '/manager/revenue' },
];

const adminNav = [
  { id: 'dashboard', name: 'Toàn cảnh', icon: LayoutDashboard, path: '/admin/dashboard' },
  { id: 'franchises', name: 'Đối tác', icon: Building2, path: '/admin/franchises' },
  { id: 'suppliers', name: 'Nhà cung cấp', icon: PlugZap, path: '/admin/suppliers' },
  { id: 'pricing', name: 'Chính sách giá', icon: CreditCard, path: '/admin/pricing' },
  { id: 'users', name: 'Người dùng', icon: Users, path: '/admin/users' },
];

const roleNavMap: Record<string, { id: string; name: string; icon: any; path: string }[]> = {
  client: clientNav, manager: managerNav, admin: adminNav,
};

export default function AppLayout() {
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const navigate = useNavigate();
  const location = useLocation();

  const userStr = localStorage.getItem('user');
  let user: any = null;
  try { user = JSON.parse(userStr || '{}'); } catch {}

  const roleMap: Record<string, string> = {
    Customer: 'client', Manager: 'manager', Admin: 'admin',
    SysAdmin: 'admin', Operator: 'manager',
  };
  const frontendRole = roleMap[user?.Role] || 'client';
  const nav = roleNavMap[frontendRole] || clientNav;

  const handleLogout = () => {
    localStorage.clear();
    navigate('/login');
  };

  const initials = user?.FullName?.split(' ').map((s: string) => s[0]).join('').slice(0, 2).toUpperCase() || 'U';
  const currentTab = nav.find(n => location.pathname.startsWith(n.path))?.id || 'dashboard';
  const currentName = nav.find(n => location.pathname.startsWith(n.path))?.name || 'Trang chủ';

  return (
    <div className="min-h-screen bg-slate-50 flex text-slate-900 font-sans">
      <motion.aside
        initial={false}
        animate={{ width: isSidebarOpen ? 260 : 80 }}
        className="bg-white border-r border-slate-200 flex flex-col sticky top-0 h-screen z-50 overflow-hidden"
      >
        <div className="p-6 flex items-center gap-3 flex-shrink-0">
          <div className="w-10 h-10 bg-blue-600 rounded-xl flex items-center justify-center flex-shrink-0">
            <Zap className="text-white w-6 h-6 fill-current" />
          </div>
          {isSidebarOpen && (
            <span className="font-bold text-xl tracking-tight text-blue-900">EVCharge Pro</span>
          )}
        </div>

        <nav className="flex-1 px-4 space-y-1 mt-4 overflow-y-auto custom-scrollbar">
          {nav.map((item) => (
            <button
              key={item.id}
              onClick={() => navigate(item.path)}
              className={cn(
                "w-full flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all duration-200 group",
                currentTab === item.id
                  ? "bg-blue-50 text-blue-600 shadow-sm"
                  : "text-slate-500 hover:bg-slate-50 hover:text-slate-900"
              )}
            >
              <item.icon className={cn("w-5 h-5", currentTab === item.id ? "text-blue-600" : "text-slate-400 group-hover:text-slate-600")} />
              {isSidebarOpen && <span className="font-medium">{item.name}</span>}
              {currentTab === item.id && isSidebarOpen && (
                <motion.div layoutId="active-pill" className="ml-auto w-1.5 h-1.5 rounded-full bg-blue-600" />
              )}
            </button>
          ))}
        </nav>

        <div className="p-4 border-t border-slate-100">
          <button onClick={handleLogout}
            className="w-full flex items-center gap-3 px-3 py-2.5 text-red-500 hover:bg-red-50 rounded-lg transition-colors">
            <LogOut className="w-5 h-5" />
            {isSidebarOpen && <span className="font-medium">Đăng xuất</span>}
          </button>
        </div>
      </motion.aside>

      <main className="flex-1 flex flex-col min-w-0 h-screen overflow-y-auto bg-slate-50">
        <header className="h-16 bg-white border-b border-slate-200 flex items-center justify-between px-8 sticky top-0 z-40 flex-shrink-0">
          <div className="flex items-center gap-4">
            <button onClick={() => setIsSidebarOpen(!isSidebarOpen)}
              className="p-2 hover:bg-slate-100 rounded-lg text-slate-500">
              {isSidebarOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>
            <h1 className="text-lg font-semibold text-slate-800">{currentName}</h1>
          </div>

          <div className="flex items-center gap-4">
            <div className="text-right hidden sm:block">
              <p className="text-sm font-semibold text-slate-900">{user?.FullName || user?.Email}</p>
              <p className="text-xs text-slate-500 capitalize">{frontendRole}</p>
            </div>
            <div className="w-10 h-10 rounded-full bg-blue-100 border-2 border-white shadow-sm flex items-center justify-center text-blue-700 font-bold">
              {initials}
            </div>
          </div>
        </header>

        <div className="p-8 max-w-7xl mx-auto w-full">
          <Outlet />
        </div>
      </main>
    </div>
  );
}
