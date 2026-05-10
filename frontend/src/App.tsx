import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import ErrorBoundary from './components/ui/ErrorBoundary';
import LoginPage from './components/Auth/LoginPage';
import RegisterPage from './components/Auth/RegisterPage';
import ForgotPasswordPage from './components/Auth/ForgotPasswordPage';
import ResetPasswordPage from './components/Auth/ResetPasswordPage';
import AppLayout from './components/layouts/AppLayout';
import ProtectedRoute from './components/layouts/ProtectedRoute';

import ClientDashboard from './pages/client/DashboardPage';
import ClientMap from './pages/client/MapPage';
import ClientVehicles from './pages/client/VehiclesPage';
import ClientCharging from './pages/client/ChargingPage';
import ClientHistory from './pages/client/HistoryPage';
import ClientWallet from './pages/client/WalletPage';
import ClientProfile from './pages/client/ProfilePage';
import ClientBookings from './pages/client/BookingsPage';
import ClientNotifications from './pages/client/NotificationsPage';
import ClientReviews from './pages/client/StationReviewPage';

import ManagerDashboard from './pages/manager/DashboardPage';
import ManagerStations from './pages/manager/StationsPage';
import ManagerSessions from './pages/manager/SessionsPage';
import ManagerErrors from './pages/manager/ErrorsPage';
import ManagerRevenue from './pages/manager/RevenuePage';

import AdminDashboard from './pages/admin/DashboardPage';
import AdminFranchises from './pages/admin/FranchisesPage';
import AdminSuppliers from './pages/admin/SuppliersPage';
import AdminUsers from './pages/admin/UsersPage';
import AdminPricing from './pages/admin/PricingPage';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />
        <Route path="/forgot-password" element={<ForgotPasswordPage />} />
        <Route path="/reset-password" element={<ResetPasswordPage />} />

        <Route path="/client" element={<ProtectedRoute><ErrorBoundary><AppLayout /></ErrorBoundary></ProtectedRoute>}>
          <Route index element={<Navigate to="dashboard" replace />} />
          <Route path="dashboard" element={<ClientDashboard />} />
          <Route path="map" element={<ClientMap />} />
          <Route path="vehicles" element={<ClientVehicles />} />
          <Route path="charging" element={<ClientCharging />} />
          <Route path="history" element={<ClientHistory />} />
          <Route path="wallet" element={<ClientWallet />} />
          <Route path="profile" element={<ClientProfile />} />
          <Route path="bookings" element={<ClientBookings />} />
          <Route path="notifications" element={<ClientNotifications />} />
          <Route path="reviews" element={<ClientReviews />} />
        </Route>

        <Route path="/manager" element={<ProtectedRoute><ErrorBoundary><AppLayout /></ErrorBoundary></ProtectedRoute>}>
          <Route index element={<Navigate to="dashboard" replace />} />
          <Route path="dashboard" element={<ManagerDashboard />} />
          <Route path="stations" element={<ManagerStations />} />
          <Route path="sessions" element={<ManagerSessions />} />
          <Route path="errors" element={<ManagerErrors />} />
          <Route path="revenue" element={<ManagerRevenue />} />
        </Route>

        <Route path="/admin" element={<ProtectedRoute><ErrorBoundary><AppLayout /></ErrorBoundary></ProtectedRoute>}>
          <Route index element={<Navigate to="dashboard" replace />} />
          <Route path="dashboard" element={<AdminDashboard />} />
          <Route path="franchises" element={<AdminFranchises />} />
          <Route path="suppliers" element={<AdminSuppliers />} />
          <Route path="users" element={<AdminUsers />} />
          <Route path="pricing" element={<AdminPricing />} />
        </Route>

        <Route path="/" element={localStorage.getItem('token') ? <Navigate to="/client/dashboard" /> : <Navigate to="/login" />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
