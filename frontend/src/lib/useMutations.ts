import { useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../services/api';
import { queryKeys } from './queryKeys';

export function useTopUpWallet() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (body: { amount: number; paymentMethod?: string }) =>
      api.post('/wallet/topup', body),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: queryKeys.wallet.my });
      qc.invalidateQueries({ queryKey: queryKeys.wallet.transactions() });
    },
  });
}

export function useCreatePayment() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (body: { SessionID: string }) =>
      api.post('/payments/create', body),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: queryKeys.wallet.my });
      qc.invalidateQueries({ queryKey: queryKeys.wallet.transactions() });
    },
  });
}

export function useStartSession() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (body: { PointID: string; VehicleID?: string }) =>
      api.post('/sessions/start', body),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: queryKeys.sessions.active });
      qc.invalidateQueries({ queryKey: queryKeys.sessions.my });
    },
  });
}

export function useEndSession() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, ...body }: { id: string; TotalKWh?: number; CostTotal?: number }) =>
      api.post(`/sessions/${id}/end`, body),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: queryKeys.sessions.active });
      qc.invalidateQueries({ queryKey: queryKeys.sessions.my });
      qc.invalidateQueries({ queryKey: queryKeys.sessions.history });
    },
  });
}

export function useCancelSession() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, reason }: { id: string; reason?: string }) =>
      api.post(`/sessions/${id}/cancel`, { reason }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: queryKeys.sessions.active });
      qc.invalidateQueries({ queryKey: queryKeys.sessions.my });
      qc.invalidateQueries({ queryKey: queryKeys.sessions.history });
    },
  });
}

export function useCreateBooking() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (body: {
      PointID: string; StationID: string; VehicleID?: string;
      BookedFrom: string; BookedTo: string;
    }) => api.post('/bookings', body),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: queryKeys.bookings.all() });
    },
  });
}

export function useConfirmBooking() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.post(`/bookings/${id}/confirm`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: queryKeys.bookings.all() });
    },
  });
}

export function useCancelBooking() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, reason }: { id: string; reason?: string }) =>
      api.post(`/bookings/${id}/cancel`, { reason }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: queryKeys.bookings.all() });
    },
  });
}

export function useMarkNotificationRead() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.post(`/notifications/${id}/read`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: queryKeys.notifications.my() });
      qc.invalidateQueries({ queryKey: queryKeys.notifications.unreadCount });
    },
  });
}

export function useResolveError() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.post(`/errors/${id}/resolve`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: queryKeys.errorLogs.all });
    },
  });
}
