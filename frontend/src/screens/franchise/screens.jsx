import React, { useState, useMemo } from 'react';
import { useActionData } from '../../lib/useAction';
import { formatValue, formatVND } from '../../lib/format';
import { DashboardStats, DashboardHeader, TrendPanel, ReportView, QuickReports } from '../common';
import { Card, PageHeader, Loader, EmptyState } from '../../components/ui';
import { FranchiseIcon, ProfileIcon, MapPinIcon, ReportIcon, PaymentIcon } from '../../components/Icons';

function withinRange(value, range) {
  if (!value) return false;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return false;
  if (range.FromDate && date < new Date(range.FromDate)) return false;
  if (range.ToDate) { const end = new Date(range.ToDate); end.setDate(end.getDate() + 1); if (date >= end) return false; }
  return true;
}

export function FranchiseDashboard({ ctx, h }) {
  const [range, setRange] = useState({});
  const settlements = useActionData('myFranchiseSettlements', { token: ctx.token, body: { pageSize: 5000 }, auto: h.has('myFranchiseSettlements') });
  // Settlements come from a stored procedure (no server-side date param), so the
  // timeframe picker filters the periods client-side before they reach the chart.
  const settlementRows = useMemo(
    () => ((range.FromDate || range.ToDate) ? settlements.rows.filter((r) => withinRange(r.PeriodEnd, range)) : settlements.rows),
    [settlements.rows, range]
  );
  return (
    <div className="ui-stack">
      <DashboardHeader icon={<FranchiseIcon size={22} />} title="Tổng quan đối tác" subtitle="Trạm, hợp đồng, chính sách chia doanh thu và quyết toán của bạn." range={range} onRangeChange={setRange} onToast={ctx.onToast} />
      <DashboardStats actionId="franchiseDashboard" token={ctx.token} accents={['brand', 'info', 'warn', 'brand']} range={range} />
      {h.has('myFranchiseSettlements') && (
        <TrendPanel
          title="Doanh thu quyết toán"
          subtitle="Tổng doanh thu gộp theo kỳ quyết toán (VND)"
          rows={settlementRows}
          loading={settlements.loading}
          dateKey="PeriodEnd"
          valueKey="GrossRevenue"
          range={range}
          format={formatVND}
          height={300}
        />
      )}
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
