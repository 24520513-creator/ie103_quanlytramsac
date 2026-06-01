import React from 'react';
import { FranchiseDashboard, FranchiseProfile, makeReportScreen } from './screens';
import { ProfileScreen } from '../ProfileScreen';
import {
  DashboardIcon, ProfileIcon, MapPinIcon, ReportIcon, PaymentIcon, FranchiseIcon
} from '../../components/Icons';

export function franchiseSections(h) {
  const s = [];
  const add = (id, label, icon, group, Comp) => s.push({ id, label, icon, group, render: (ctx) => <Comp ctx={ctx} h={h} /> });

  add('fr-home', 'Tổng quan', <DashboardIcon size={18} />, 'Đối tác', FranchiseDashboard);
  if (h.has('myFranchiseProfile')) add('fr-profile', 'Hồ sơ đối tác', <ProfileIcon size={18} />, 'Đối tác', FranchiseProfile);
  if (h.has('myFranchiseStations')) add('fr-stations', 'Trạm của tôi', <MapPinIcon size={18} />, 'Đối tác', makeReportScreen('myFranchiseStations', <MapPinIcon size={22} />, 'Trạm của tôi', 'Các trạm thuộc đối tác của bạn.'));
  if (h.has('myFranchiseContracts')) add('fr-contracts', 'Hợp đồng', <ReportIcon size={18} />, 'Đối tác', makeReportScreen('myFranchiseContracts', <ReportIcon size={22} />, 'Hợp đồng', 'Hợp đồng nhượng quyền của bạn.'));
  if (h.has('myRevenueSharePolicies')) add('fr-policies', 'Chia doanh thu', <PaymentIcon size={18} />, 'Doanh thu', makeReportScreen('myRevenueSharePolicies', <PaymentIcon size={22} />, 'Chính sách chia doanh thu', 'Tỷ lệ chia doanh thu áp dụng cho bạn.'));
  if (h.has('myFranchiseSettlements')) add('fr-settle', 'Quyết toán', <FranchiseIcon size={18} />, 'Doanh thu', makeReportScreen('myFranchiseSettlements', <FranchiseIcon size={22} />, 'Quyết toán', 'Các kỳ quyết toán doanh thu của bạn.'));
  if (h.has('me')) s.push({ id: 'me', label: 'Hồ sơ', icon: <ProfileIcon size={18} />, group: 'Tài khoản', render: (ctx) => <ProfileScreen ctx={ctx} h={h} /> });
  return s;
}
