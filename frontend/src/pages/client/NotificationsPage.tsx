import { useState, useEffect } from 'react';
import { Bell, CheckCheck, Loader2 } from 'lucide-react';
import { motion } from 'motion/react';
import { api } from '../../services/api';
import PageHeader from '../../components/ui/PageHeader';
import StatusBadge from '../../components/ui/StatusBadge';
import type { Notification } from '../../types';

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);

  const load = () => {
    api.get('/notifications/my').then(r => {
      setNotifications(Array.isArray(r.data) ? r.data : []);
    }).finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  const handleMarkRead = async (id: number) => {
    try {
      await api.post(`/notifications/${id}/read`);
      setNotifications(prev => prev.map(n => n.NotificationID === id ? { ...n, IsRead: true } : n));
    } catch {}
  };

  const unreadCount = notifications.filter(n => !n.IsRead).length;

  if (loading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;

  return (
    <div className="space-y-6">
      <PageHeader title="Thông báo" subtitle={unreadCount > 0 ? `${unreadCount} chưa đọc` : 'Đã đọc tất cả'} />

      {notifications.length === 0 ? (
        <div className="text-center py-16 text-slate-400">
          <Bell className="w-16 h-16 mx-auto mb-4 opacity-50" />
          <p>Không có thông báo</p>
        </div>
      ) : (
        <div className="space-y-3">
          {notifications.map(n => (
            <motion.div key={n.NotificationID} whileHover={{ y: -1 }}
              onClick={() => !n.IsRead && handleMarkRead(n.NotificationID)}
              className={`bg-white rounded-2xl border p-5 cursor-pointer transition-all ${
                n.IsRead ? 'border-slate-200' : 'border-blue-200 shadow-sm'
              }`}>
              <div className="flex items-start justify-between">
                <div className="flex items-start gap-3 flex-1">
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${
                    n.IsRead ? 'bg-slate-50' : 'bg-blue-50'
                  }`}>
                    <Bell className={`w-5 h-5 ${n.IsRead ? 'text-slate-400' : 'text-blue-600'}`} />
                  </div>
                  <div className="flex-1">
                    <p className={`font-medium ${n.IsRead ? 'text-slate-700' : 'text-slate-900'}`}>{n.Title}</p>
                    <p className="text-sm text-slate-500 mt-1">{n.Message}</p>
                    <p className="text-xs text-slate-400 mt-2">{new Date(n.CreatedAt || '').toLocaleString('vi-VN')}</p>
                  </div>
                </div>
                <div className="flex items-center gap-2 ml-4">
                  <StatusBadge status={n.NotificationType} />
                  {!n.IsRead && <CheckCheck className="w-4 h-4 text-blue-600" />}
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      )}
    </div>
  );
}
