export const queryKeys = {
  auth: {
    profile: ['auth', 'profile'] as const,
  },
  wallet: {
    my: ['wallet', 'my'] as const,
    transactions: (filters?: Record<string, string>) => ['wallet', 'transactions', filters] as const,
  },
  sessions: {
    my: ['sessions', 'my'] as const,
    active: ['sessions', 'active'] as const,
    history: ['sessions', 'history'] as const,
    byId: (id: string) => ['sessions', id] as const,
  },
  bookings: {
    all: (filters?: Record<string, string>) => ['bookings', 'all', filters] as const,
    availability: (pointId: string, startTime: string, endTime: string) =>
      ['bookings', 'availability', pointId, startTime, endTime] as const,
  },
  stations: {
    all: ['stations', 'all'] as const,
    points: (stationId?: string) => ['stations', 'points', stationId] as const,
  },
  vehicles: {
    all: ['vehicles', 'all'] as const,
  },
  notifications: {
    my: (filters?: Record<string, string>) => ['notifications', 'my', filters] as const,
    unreadCount: ['notifications', 'unread-count'] as const,
  },
  errorLogs: {
    all: ['error-logs', 'all'] as const,
  },
  reviews: {
    all: (filters?: Record<string, string>) => ['station-reviews', 'all', filters] as const,
  },
  admin: {
    dashboard: ['dashboard', 'admin'] as const,
    franchises: ['franchises'] as const,
    users: ['users'] as const,
    suppliers: ['electricity-suppliers'] as const,
    pricingPolicies: ['pricing-policies'] as const,
  },
  manager: {
    dashboard: (id: string) => ['dashboard', 'franchise', id] as const,
    stations: ['stations', 'all'] as const,
  },
};
