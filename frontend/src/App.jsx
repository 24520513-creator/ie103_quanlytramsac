import React, { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate, useNavigate } from 'react-router-dom';
import Sidebar from './components/Sidebar';
import LoginPage from './pages/LoginPage';
import Dashboard from './pages/Dashboard';
import StationList from './pages/StationList';
import StationDetail from './pages/StationDetail';
import StationFormPage from './pages/StationFormPage';
import BookingPage from './pages/BookingPage';
import UserProfile from './pages/UserProfile';
import WalletPage from './pages/WalletPage';
import MyVehicles from './pages/MyVehicles';
import TransactionsPage from './pages/TransactionsPage';
import AdminUsersPage from './pages/AdminUsersPage';
import AdminFranchisesPage from './pages/AdminFranchisesPage';
import PricingPoliciesPage from './pages/PricingPoliciesPage';
import MaintenancePage from './pages/MaintenancePage';
import AlertsPage from './pages/AlertsPage';
import './styles.css';

function AppContent() {
  const [user, setUser] = useState(() => JSON.parse(localStorage.getItem('user')));
  const navigate = useNavigate();

  useEffect(() => {
    if (!user) navigate('/login', { replace: true });
  }, []);

  const handleLogin = (userData) => {
    localStorage.setItem('user', JSON.stringify(userData));
    setUser(userData);
    navigate('/');
  };

  const handleLogout = () => {
    localStorage.clear();
    setUser(null);
    navigate('/login', { replace: true });
  };

  const isAdmin = user?.roles?.includes('SysAdmin');
  const isCustomer = user?.roles?.includes('CUSTOMER');

  return (
    <div className="app-layout">
      {user && <Sidebar user={user} onLogout={handleLogout} />}
      <main className="main-content">
        <Routes>
          <Route path="/login" element={user ? <Navigate to="/" /> : <LoginPage onLogin={handleLogin} />} />
          <Route path="/" element={user ? <Dashboard user={user} /> : <Navigate to="/login" />} />
          <Route path="/stations" element={user ? <StationList /> : <Navigate to="/login" />} />
          <Route path="/stations/new" element={user && isAdmin ? <StationFormPage /> : <Navigate to="/login" />} />
          <Route path="/stations/:id" element={user ? <StationDetail /> : <Navigate to="/login" />} />
          <Route path="/stations/:id/edit" element={user && isAdmin ? <StationFormPage /> : <Navigate to="/login" />} />
          <Route path="/bookings" element={user ? <BookingPage /> : <Navigate to="/login" />} />
          <Route path="/wallet" element={user ? <WalletPage /> : <Navigate to="/login" />} />
          <Route path="/profile" element={user ? <UserProfile /> : <Navigate to="/login" />} />
          <Route path="/vehicles" element={user ? <MyVehicles /> : <Navigate to="/login" />} />
          <Route path="/transactions" element={user ? <TransactionsPage /> : <Navigate to="/login" />} />
          {isAdmin && (
            <>
              <Route path="/admin/users" element={<AdminUsersPage />} />
              <Route path="/admin/franchises" element={<AdminFranchisesPage />} />
              <Route path="/admin/pricing" element={<PricingPoliciesPage />} />
              <Route path="/admin/maintenance" element={<MaintenancePage />} />
              <Route path="/admin/alerts" element={<AlertsPage />} />
            </>
          )}
        </Routes>
      </main>
    </div>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <AppContent />
    </BrowserRouter>
  );
}
