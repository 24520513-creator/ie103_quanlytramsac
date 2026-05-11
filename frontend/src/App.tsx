import React, { lazy, Suspense } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import ErrorBoundary from './components/ui/ErrorBoundary';
import AppLayout from './components/layouts/AppLayout';
import ProtectedRoute from './components/layouts/ProtectedRoute';
import LoadingSpinner from './components/ui/LoadingSpinner';

const LoginPage = lazy(() => import('./components/Auth/LoginPage'));
const RegisterPage = lazy(() => import('./components/Auth/RegisterPage'));
const ForgotPasswordPage = lazy(() => import('./components/Auth/ForgotPasswordPage'));
const ResetPasswordPage = lazy(() => import('./components/Auth/ResetPasswordPage'));

const ClientDashboard = lazy(() => import('./pages/client/DashboardPage'));
const ClientMap = lazy(() => import('./pages/client/MapPage'));
const ClientVehicles = lazy(() => import('./pages/client/VehiclesPage'));
const ClientCharging = lazy(() => import('./pages/client/ChargingPage'));
const ClientHistory = lazy(() => import('./pages/client/HistoryPage'));
const ClientWallet = lazy(() => import('./pages/client/WalletPage'));
const ClientProfile = lazy(() => import('./pages/client/ProfilePage'));
const ClientBookings = lazy(() => import('./pages/client/BookingsPage'));
const ClientNotifications = lazy(() => import('./pages/client/NotificationsPage'));
const ClientReviews = lazy(() => import('./pages/client/StationReviewPage'));

const ManagerDashboard = lazy(() => import('./pages/manager/DashboardPage'));
const ManagerStations = lazy(() => import('./pages/manager/StationsPage'));
const ManagerSessions = lazy(() => import('./pages/manager/SessionsPage'));
const ManagerErrors = lazy(() => import('./pages/manager/ErrorsPage'));
const ManagerRevenue = lazy(() => import('./pages/manager/RevenuePage'));

const AdminDashboard = lazy(() => import('./pages/admin/DashboardPage'));
const AdminFranchises = lazy(() => import('./pages/admin/FranchisesPage'));
const AdminSuppliers = lazy(() => import('./pages/admin/SuppliersPage'));
const AdminUsers = lazy(() => import('./pages/admin/UsersPage'));
const AdminPricing = lazy(() => import('./pages/admin/PricingPage'));

function Lazy({ children }: { children: React.ReactNode }) {
  return <Suspense fallback={<LoadingSpinner message="Loading..." />}>{children}</Suspense>;
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Lazy><LoginPage /></Lazy>} />
        <Route path="/register" element={<Lazy><RegisterPage /></Lazy>} />
        <Route path="/forgot-password" element={<Lazy><ForgotPasswordPage /></Lazy>} />
        <Route path="/reset-password" element={<Lazy><ResetPasswordPage /></Lazy>} />

        <Route path="/client" element={<ProtectedRoute><ErrorBoundary><AppLayout /></ErrorBoundary></ProtectedRoute>}>
          <Route index element={<Navigate to="dashboard" replace />} />
          <Route path="dashboard" element={<Lazy><ClientDashboard /></Lazy>} />
          <Route path="map" element={<Lazy><ClientMap /></Lazy>} />
          <Route path="vehicles" element={<Lazy><ClientVehicles /></Lazy>} />
          <Route path="charging" element={<Lazy><ClientCharging /></Lazy>} />
          <Route path="history" element={<Lazy><ClientHistory /></Lazy>} />
          <Route path="wallet" element={<Lazy><ClientWallet /></Lazy>} />
          <Route path="profile" element={<Lazy><ClientProfile /></Lazy>} />
          <Route path="bookings" element={<Lazy><ClientBookings /></Lazy>} />
          <Route path="notifications" element={<Lazy><ClientNotifications /></Lazy>} />
          <Route path="reviews" element={<Lazy><ClientReviews /></Lazy>} />
        </Route>

        <Route path="/manager" element={<ProtectedRoute><ErrorBoundary><AppLayout /></ErrorBoundary></ProtectedRoute>}>
          <Route index element={<Navigate to="dashboard" replace />} />
          <Route path="dashboard" element={<Lazy><ManagerDashboard /></Lazy>} />
          <Route path="stations" element={<Lazy><ManagerStations /></Lazy>} />
          <Route path="sessions" element={<Lazy><ManagerSessions /></Lazy>} />
          <Route path="errors" element={<Lazy><ManagerErrors /></Lazy>} />
          <Route path="revenue" element={<Lazy><ManagerRevenue /></Lazy>} />
        </Route>

        <Route path="/admin" element={<ProtectedRoute><ErrorBoundary><AppLayout /></ErrorBoundary></ProtectedRoute>}>
          <Route index element={<Navigate to="dashboard" replace />} />
          <Route path="dashboard" element={<Lazy><AdminDashboard /></Lazy>} />
          <Route path="franchises" element={<Lazy><AdminFranchises /></Lazy>} />
          <Route path="suppliers" element={<Lazy><AdminSuppliers /></Lazy>} />
          <Route path="users" element={<Lazy><AdminUsers /></Lazy>} />
          <Route path="pricing" element={<Lazy><AdminPricing /></Lazy>} />
        </Route>

        <Route path="/" element={localStorage.getItem('token') ? <Navigate to="/client/dashboard" /> : <Navigate to="/login" />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
