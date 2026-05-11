import { useQuery } from '@tanstack/react-query';
import { api } from '../services/api';
import { queryKeys } from './queryKeys';
import type { Wallet, ChargingSession, Booking, ChargingStation, ChargingPoint, Transaction, Notification, Vehicle, ErrorLog, StationReview } from '../types';

export function useMyWallet() {
  return useQuery({
    queryKey: queryKeys.wallet.my,
    queryFn: () => api.get<Wallet>('/wallet/my').then(r => r.data),
  });
}

export function useMySessions() {
  return useQuery({
    queryKey: queryKeys.sessions.my,
    queryFn: () => api.get<ChargingSession[]>('/sessions/my').then(r =>
      Array.isArray(r.data) ? r.data : []),
  });
}

export function useActiveSessions() {
  return useQuery({
    queryKey: queryKeys.sessions.active,
    queryFn: () => api.get<ChargingSession[]>('/sessions').then(r =>
      Array.isArray(r.data) ? r.data : []),
  });
}

export function useSessionHistory() {
  return useQuery({
    queryKey: queryKeys.sessions.history,
    queryFn: () => api.get<ChargingSession[]>('/sessions/history').then(r =>
      Array.isArray(r.data) ? r.data : []),
  });
}

export function useMyTransactions() {
  return useQuery({
    queryKey: queryKeys.wallet.transactions(),
    queryFn: () => api.get<Transaction[]>('/transactions/my').then(r =>
      Array.isArray(r.data) ? r.data : []),
  });
}

export function useStations() {
  return useQuery({
    queryKey: queryKeys.stations.all,
    queryFn: () => api.get<ChargingStation[]>('/stations').then(r =>
      Array.isArray(r.data) ? r.data : []),
    staleTime: 60_000,
  });
}

export function usePoints() {
  return useQuery({
    queryKey: queryKeys.stations.points(),
    queryFn: () => api.get<ChargingPoint[]>('/points').then(r =>
      Array.isArray(r.data) ? r.data : []),
    staleTime: 30_000,
  });
}

export function useBookings() {
  return useQuery({
    queryKey: queryKeys.bookings.all(),
    queryFn: () => api.get<Booking[]>('/bookings').then(r =>
      Array.isArray(r.data) ? r.data : []),
  });
}

export function useNotifications(filters?: Record<string, string>) {
  return useQuery({
    queryKey: queryKeys.notifications.my(filters),
    queryFn: () => api.get<Notification[]>('/notifications/my', { params: filters }).then(r =>
      Array.isArray(r.data) ? r.data : []),
  });
}

export function useUnreadNotificationCount() {
  return useQuery({
    queryKey: queryKeys.notifications.unreadCount,
    queryFn: () => api.get<{ unreadCount: number }>('/notifications/unread-count').then(r => r.data),
    staleTime: 15_000,
  });
}

export function useMyVehicles() {
  return useQuery({
    queryKey: queryKeys.vehicles.all,
    queryFn: () => api.get<Vehicle[]>('/vehicles').then(r =>
      Array.isArray(r.data) ? r.data : []),
  });
}

export function useErrorLogs() {
  return useQuery({
    queryKey: queryKeys.errorLogs.all,
    queryFn: () => api.get<ErrorLog[]>('/error-logs').then(r =>
      Array.isArray(r.data) ? r.data : []),
  });
}

export function useStationReviews(filters?: Record<string, string>) {
  return useQuery({
    queryKey: queryKeys.reviews.all(filters),
    queryFn: () => api.get<StationReview[]>('/station-reviews', { params: filters }).then(r =>
      Array.isArray(r.data) ? r.data : []),
  });
}

export function useAdminDashboard() {
  return useQuery({
    queryKey: queryKeys.admin.dashboard,
    queryFn: () => api.get('/dashboard/admin').then(r => r.data),
  });
}

export function useFranchiseDashboard(id: string) {
  return useQuery({
    queryKey: queryKeys.manager.dashboard(id),
    queryFn: () => api.get(`/dashboard/franchise/${id}`).then(r => r.data),
    enabled: !!id,
  });
}
