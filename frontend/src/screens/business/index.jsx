import React from 'react';
import { BizDashboard, ReportsExplorer, PricingScreen, RefundsScreen, FranchiseMgmtScreen } from './screens';
import { ProfileScreen } from '../ProfileScreen';
import {
  DashboardIcon, ReportIcon, PaymentIcon, FranchiseIcon, ProfileIcon
} from '../../components/Icons';

export function businessSections(h) {
  const s = [];
  const add = (id, label, icon, group, Comp) => s.push({ id, label, icon, group, render: (ctx) => <Comp ctx={ctx} h={h} /> });

  add('biz-home', 'Tổng quan', <DashboardIcon size={18} />, 'Kinh doanh', BizDashboard);
  add('reports', 'Báo cáo & phân tích', <ReportIcon size={18} />, 'Kinh doanh', ReportsExplorer);
  if (h.has('pricingPolicies')) add('pricing', 'Chính sách giá', <PaymentIcon size={18} />, 'Kinh doanh', PricingScreen);
  if (h.has('refundablePayments')) add('refunds', 'Hoàn tiền', <PaymentIcon size={18} />, 'Thanh toán', RefundsScreen);
  if (h.has('profitSharing') || h.has('createRevenueSettlement')) add('franchise', 'Nhượng quyền', <FranchiseIcon size={18} />, 'Nhượng quyền', FranchiseMgmtScreen);
  if (h.has('me')) s.push({ id: 'me', label: 'Hồ sơ', icon: <ProfileIcon size={18} />, group: 'Tài khoản', render: (ctx) => <ProfileScreen ctx={ctx} h={h} /> });
  return s;
}
