import React, { useState, useEffect } from 'react';
import { 
  LayoutDashboard, MapPin, Zap, History, Settings, Users, Building2,
  AlertTriangle, Wallet, Battery, LogOut, Menu, X, ChevronRight,
  CreditCard, BarChart3, PlugZap, UserCircle
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { cn } from './lib/utils';
import { UserRole } from './types';

import ClientDashboard from './components/Client/ClientDashboard';
import ManagerDashboard from './components/Manager/ManagerDashboard';
import AdminDashboard from './components/Admin/AdminDashboard';
import LoginPage from './components/Auth/LoginPage';
import RegisterPage from './components/Auth/RegisterPage';
import ForgotPasswordPage from './components/Auth/ForgotPasswordPage';
import ResetPasswordPage from './components/Auth/ResetPasswordPage';

type AuthView = 'login' | 'register' | 'forgot-password' | 'reset-password';

interface UserData {
  UserID: number;
  FullName: string;
  Email: string;
  Phone?: string;
  roles: string[];
  frontendRole: string;
}

export default function App() {
  const [user, setUser] = useState<UserData | null>(null);
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [activeTab, setActiveTab] = useState('dashboard');
  const [authView, setAuthView] = useState<AuthView>('login');
  const [resetToken, setResetToken] = useState('');

  useEffect(() => {
    const token = localStorage.getItem('token');
    const stored = localStorage.getItem('user');
    if (token && stored) {
      try {
        setUser(JSON.parse(stored));
      } catch { localStorage.clear(); }
    }
  }, []);

  const role: UserRole = (user?.frontendRole as UserRole) || 'client';

  const handleLogin = (userData: UserData, _token: string) => {
    localStorage.setItem('user', JSON.stringify(userData));
    setUser(userData);
    setActiveTab('dashboard');
  };

  const handleLogout = () => {
    localStorage.clear();
    setUser(null);
    setActiveTab('dashboard');
  };

  const navigation = {
    client: [
      { id: 'dashboard', name: 'Tổng quan', icon: LayoutDashboard },
      { id: 'map', name: 'Tìm trạm sạc', icon: MapPin },
      { id: 'vehicles', name: 'Quản lý xe', icon: Battery },
      { id: 'charging', name: 'Đang sạc', icon: Zap },
      { id: 'history', name: 'Lịch sử', icon: History },
      { id: 'wallet', name: 'Ví điện tử', icon: Wallet },
      { id: 'profile', name: 'Hồ sơ', icon: Users },
    ],
    manager: [
      { id: 'dashboard', name: 'Dashboard', icon: LayoutDashboard },
      { id: 'stations', name: 'Quản lý trạm', icon: Building2 },
      { id: 'sessions', name: 'Phiên sạc', icon: Zap },
      { id: 'errors', name: 'Lỗi hệ thống', icon: AlertTriangle },
      { id: 'revenue', name: 'Doanh thu', icon: BarChart3 },
    ],
    admin: [
      { id: 'dashboard', name: 'Toàn cảnh', icon: LayoutDashboard },
      { id: 'franchisees', name: 'Đối tác', icon: Building2 },
      { id: 'suppliers', name: 'Nhà cung cấp', icon: PlugZap },
      { id: 'pricing', name: 'Chính sách giá', icon: CreditCard },
      { id: 'users', name: 'Người dùng', icon: Users },
    ]
  };

  if (!user) {
    switch (authView) {
      case 'register':
        return <RegisterPage onSwitchToLogin={() => setAuthView('login')} />;
      case 'forgot-password':
        return <ForgotPasswordPage onSwitchToLogin={() => setAuthView('login')} onSwitchToReset={(t) => { setResetToken(t); setAuthView('reset-password'); }} />;
      case 'reset-password':
        return <ResetPasswordPage token={resetToken} onSwitchToLogin={() => setAuthView('login')} />;
      default:
        return <LoginPage onLogin={handleLogin} onSwitchToRegister={() => setAuthView('register')} onSwitchToForgotPassword={() => setAuthView('forgot-password')} />;
    }
  }

  const renderContent = () => {
    switch (role) {
      case 'client': return <ClientDashboard activeTab={activeTab} setActiveTab={setActiveTab} user={user} />;
      case 'manager': return <ManagerDashboard activeTab={activeTab} setActiveTab={setActiveTab} />;
      case 'admin': return <AdminDashboard activeTab={activeTab} setActiveTab={setActiveTab} />;
      default: return <ClientDashboard activeTab={activeTab} setActiveTab={setActiveTab} user={user} />;
    }
  };

  const initials = user.FullName?.split(' ').map((s: string) => s[0]).join('').slice(0, 2).toUpperCase() || 'U';

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
          {(navigation[role] || navigation.client).map((item) => (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              className={cn(
                "w-full flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all duration-200 group",
                activeTab === item.id 
                  ? "bg-blue-50 text-blue-600 shadow-sm" 
                  : "text-slate-500 hover:bg-slate-50 hover:text-slate-900"
              )}
            >
              <item.icon className={cn("w-5 h-5", activeTab === item.id ? "text-blue-600" : "text-slate-400 group-hover:text-slate-600")} />
              {isSidebarOpen && <span className="font-medium">{item.name}</span>}
              {activeTab === item.id && isSidebarOpen && (
                <motion.div layoutId="active-pill" className="ml-auto w-1.5 h-1.5 rounded-full bg-blue-600" />
              )}
            </button>
          ))}
        </nav>

        <div className="p-4 border-t border-slate-100">
          <button
            onClick={handleLogout}
            className="w-full flex items-center gap-3 px-3 py-2.5 text-red-500 hover:bg-red-50 rounded-lg transition-colors"
          >
            <LogOut className="w-5 h-5" />
            {isSidebarOpen && <span className="font-medium">Đăng xuất</span>}
          </button>
        </div>
      </motion.aside>

      <main className="flex-1 flex flex-col min-w-0 h-screen overflow-y-auto bg-slate-50">
        <header className="h-16 bg-white border-b border-slate-200 flex items-center justify-between px-8 sticky top-0 z-40 flex-shrink-0">
          <div className="flex items-center gap-4">
            <button 
              onClick={() => setIsSidebarOpen(!isSidebarOpen)}
              className="p-2 hover:bg-slate-100 rounded-lg text-slate-500"
            >
              {isSidebarOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>
            <h1 className="text-lg font-semibold text-slate-800 capitalize">
              {(navigation[role] || navigation.client).find(n => n.id === activeTab)?.name || 'Trang chủ'}
            </h1>
          </div>

          <div className="flex items-center gap-4">
            <div className="text-right hidden sm:block">
              <p className="text-sm font-semibold text-slate-900">{user.FullName || user.Email}</p>
              <p className="text-xs text-slate-500 capitalize">{role}</p>
            </div>
            <div className="w-10 h-10 rounded-full bg-blue-100 border-2 border-white shadow-sm flex items-center justify-center text-blue-700 font-bold">
              {initials}
            </div>
          </div>
        </header>

        <div className="p-8 max-w-7xl mx-auto w-full">
          <AnimatePresence mode="wait">
            <motion.div
              key={`${role}-${activeTab}`}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.2 }}
            >
              {renderContent()}
            </motion.div>
          </AnimatePresence>
        </div>
      </main>
    </div>
  );
}
