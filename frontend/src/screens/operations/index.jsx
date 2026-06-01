import React from 'react';
import { OpsDashboard, StationsScreen, ActiveSessionsScreen, MaintenanceScreen, TelemetryScreen, OpsReports } from './screens';
import { ProfileScreen } from '../ProfileScreen';
import {
  DashboardIcon, MapPinIcon, ActivityIcon, MaintenanceIcon, ProfileIcon, ReportIcon
} from '../../components/Icons';

export function operationsSections(h) {
  const s = [];
  const add = (id, label, icon, group, Comp) => s.push({ id, label, icon, group, render: (ctx) => <Comp ctx={ctx} h={h} /> });

  add('ops-home', 'Tổng quan', <DashboardIcon size={18} />, 'Vận hành', OpsDashboard);
  if (h.has('stationStatus')) add('stations', 'Trạm & cổng', <MapPinIcon size={18} />, 'Vận hành', StationsScreen);
  if (h.has('activeSessions')) add('active', 'Phiên đang sạc', <ActivityIcon size={18} />, 'Vận hành', ActiveSessionsScreen);
  if (h.has('maintenanceTickets')) add('maint', 'Bảo trì', <MaintenanceIcon size={18} />, 'Bảo trì', MaintenanceScreen);
  if (h.has('telemetryHealth')) add('telemetry', 'Telemetry', <ActivityIcon size={18} />, 'Bảo trì', TelemetryScreen);
  if (h.has('maintenanceKpi') || h.has('errorLogActive')) add('ops-reports', 'Báo cáo', <ReportIcon size={18} />, 'Báo cáo', OpsReports);
  if (h.has('me')) s.push({ id: 'me', label: 'Hồ sơ', icon: <ProfileIcon size={18} />, group: 'Tài khoản', render: (ctx) => <ProfileScreen ctx={ctx} h={h} /> });
  return s;
}
