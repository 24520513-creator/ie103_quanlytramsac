import React from 'react';
import { useActionData } from '../../lib/useAction';
import { formatValue } from '../../lib/format';
import { DashboardStats, ReportView, QuickReports } from '../common';
import { Card, PageHeader, Loader, EmptyState } from '../../components/ui';
import { FranchiseIcon, ProfileIcon, MapPinIcon, ReportIcon, PaymentIcon } from '../../components/Icons';

export function FranchiseDashboard({ ctx, h }) {
  return (
    <div className="ui-stack">
      <PageHeader icon={<FranchiseIcon size={22} />} title="Tổng quan đối tác" subtitle="Trạm, hợp đồng, chính sách chia doanh thu và quyết toán của bạn." />
      <DashboardStats actionId="franchiseDashboard" token={ctx.token} accents={['brand', 'info', 'warn', 'brand']} />
      <QuickReports h={h} token={ctx.token} onToast={ctx.onToast} reports={[
        { id: 'myFranchiseStations', label: 'Trạm thuộc franchise', icon: <MapPinIcon size={16} /> },
        { id: 'myFranchiseContracts', label: 'Hợp đồng nhượng quyền', icon: <ReportIcon size={16} /> },
        { id: 'myRevenueSharePolicies', label: 'Chính sách chia doanh thu', icon: <PaymentIcon size={16} /> },
        { id: 'myFranchiseSettlements', label: 'Quyết toán doanh thu', icon: <FranchiseIcon size={16} /> }
      ]} />
    </div>
  );
}

export function FranchiseProfile({ ctx, h }) {
  const { rows, loading } = useActionData('myFranchiseProfile', { token: ctx.token });
  const row = rows[0] || {};
  return (
    <div className="ui-stack">
      <PageHeader icon={<ProfileIcon size={22} />} title="Hồ sơ đối tác" subtitle="Thông tin đối tác nhượng quyền của bạn." />
      {loading ? <Loader /> : Object.keys(row).length === 0 ? <EmptyState title="Chưa có hồ sơ" /> : (
        <div className="profilePanel">
          {Object.entries(row).map(([k, v]) => (
            <div key={k}><span>{k}</span><strong>{formatValue(v) || '—'}</strong></div>
          ))}
        </div>
      )}
    </div>
  );
}

export function makeReportScreen(actionId, icon, title, subtitle) {
  return function FranchiseReport({ ctx, h }) {
    return (
      <div className="ui-stack">
        <PageHeader icon={icon} title={title} subtitle={subtitle} />
        <ReportView action={h.get(actionId)} token={ctx.token} />
      </div>
    );
  };
}
