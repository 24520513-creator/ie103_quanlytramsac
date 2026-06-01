import React from 'react';
import { AdminDashboard, UsersScreen, AuditFeed, AdminReports } from './screens';
import { GenericScreen } from '../GenericScreen';
import { ProfileScreen } from '../ProfileScreen';
import {
  DashboardIcon, AdminIcon, ActivityIcon, ReportIcon, ProfileIcon
} from '../../components/Icons';

export function adminSections(h) {
  const s = [];
  const add = (id, label, icon, group, Comp) => s.push({ id, label, icon, group, render: (ctx) => <Comp ctx={ctx} h={h} /> });

  add('admin-home', 'Tổng quan', <DashboardIcon size={18} />, 'Quản trị', AdminDashboard);
  if (h.has('accountsByRole') || h.has('auditLog')) add('admin-reports', 'Báo cáo', <ReportIcon size={18} />, 'Quản trị', AdminReports);
  if (h.has('userRoleSummary')) add('users', 'Người dùng', <AdminIcon size={18} />, 'Quản trị', UsersScreen);
  if (h.has('auditLog')) add('audit', 'Nhật ký kiểm toán', <ActivityIcon size={18} />, 'Quản trị', AuditFeed);
  if (h.has('backupRestoreGuide')) s.push({ id: 'backup', label: 'Backup / Restore', icon: <ReportIcon size={18} />, group: 'Hệ thống', render: (ctx) => <GenericScreen action={h.get('backupRestoreGuide')} token={ctx.token} user={ctx.user} onToast={ctx.onToast} /> });
  if (h.has('me')) s.push({ id: 'me', label: 'Hồ sơ', icon: <ProfileIcon size={18} />, group: 'Tài khoản', render: (ctx) => <ProfileScreen ctx={ctx} h={h} /> });
  return s;
}
