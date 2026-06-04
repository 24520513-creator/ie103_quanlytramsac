import React, { useMemo, useState } from 'react';
import { CircleMarker, MapContainer, Popup, TileLayer, Tooltip } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import { useActionData } from '../../lib/useAction';
import { formatVND, formatNumber, formatDate } from '../../lib/format';
import { DashboardStats, DashboardHeader, TrendPanel, ActionModal, ConfirmAction, ReportView, QuickReports } from '../common';
import { Bars, AreaTrend, Donut } from '../../components/charts';
import {
  Card, CardHeader, PageHeader, Button, Badge, EmptyState, Loader, Tabs
} from '../../components/ui';
import { SQL_HINTS } from '../../lib/sqlHints';
import {
  BusinessIcon, ReportIcon, PaymentIcon, FranchiseIcon, PlusIcon, ProfileIcon, BoltIcon
} from '../../components/Icons';

function aggregateSum(rows, nameKey, valKey) {
  const map = new Map();
  for (const r of rows) {
    const k = r[nameKey] ?? '—';
    map.set(k, (map.get(k) || 0) + (Number(r[valKey]) || 0));
  }
  return [...map.entries()].map(([name, value]) => ({ name, value }));
}

function isValidCoordinate(lat, lng) {
  return Number.isFinite(lat) && Number.isFinite(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
}

function stationMarkerRadius(revenue, maxRevenue) {
  if (!maxRevenue) return 4;
  return Math.max(3, Math.min(11, 3 + Math.sqrt(Math.max(revenue, 0) / maxRevenue) * 8));
}

function StationRevenueMap({ rows, loading, error }) {
  const stations = useMemo(() => rows
    .map((row) => ({
      ...row,
      Latitude: Number(row.Latitude),
      Longitude: Number(row.Longitude),
      CompletedSessions: Number(row.CompletedSessions) || 0,
      TotalKWh: Number(row.TotalKWh) || 0,
      RevenueTotal: Number(row.RevenueTotal) || 0
    }))
    .filter((row) => isValidCoordinate(row.Latitude, row.Longitude)), [rows]);
  const maxRevenue = Math.max(0, ...stations.map((s) => s.RevenueTotal));
  const activeStations = stations.filter((s) => s.StationStatus === 'Active').length;

  return (
    <Card className="station-map-card">
      <CardHeader
        title="Bản đồ doanh thu trạm sạc"
        subtitle="Chấm tròn theo tọa độ trạm, kích thước phản ánh doanh thu"
        action={!loading && <span className="station-map-count">{formatNumber(stations.length)} trạm · {formatNumber(activeStations)} active</span>}
      />
      {loading ? <Loader /> : error ? (
        <EmptyState title="Không tải được dữ liệu bản đồ" message={error} />
      ) : stations.length === 0 ? (
        <EmptyState title="Chưa có tọa độ trạm" message="Không tìm thấy trạm có kinh độ, vĩ độ hợp lệ trong dữ liệu hiện tại." />
      ) : (
        <div className="station-map-wrap">
          <MapContainer className="station-map" center={[16.2, 107.8]} zoom={5} minZoom={5} maxZoom={15} scrollWheelZoom>
            <TileLayer
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
              crossOrigin="anonymous"
            />
            {stations.map((station) => {
              const radius = stationMarkerRadius(station.RevenueTotal, maxRevenue);
              const isEarning = station.RevenueTotal > 0;
              return (
                <CircleMarker
                  key={station.StationID}
                  center={[station.Latitude, station.Longitude]}
                  radius={radius}
                  pathOptions={{
                    color: '#ffffff',
                    fillColor: isEarning ? '#10b981' : '#94a3b8',
                    fillOpacity: isEarning ? 0.85 : 0.55,
                    opacity: 1,
                    weight: 1
                  }}
                >
                  <Tooltip direction="top" offset={[0, -4]} opacity={1} className="station-map-tooltip">
                    <strong>{station.StationName}</strong>
                    <span>{station.StationCode} · {formatVND(station.RevenueTotal)}</span>
                  </Tooltip>
                  <Popup className="station-map-popup">
                    <div>
                      <strong>{station.StationName}</strong>
                      <span>{station.StationCode} · {station.RegionName || 'Chưa có khu vực'}</span>
                    </div>
                    <dl>
                      <dt>Doanh thu</dt><dd>{formatVND(station.RevenueTotal)}</dd>
                      <dt>Phiên hoàn tất</dt><dd>{formatNumber(station.CompletedSessions)}</dd>
                      <dt>Sản lượng</dt><dd>{formatNumber(station.TotalKWh)} kWh</dd>
                      <dt>Trạng thái</dt><dd>{station.StationStatus}</dd>
                    </dl>
                  </Popup>
                </CircleMarker>
              );
            })}
          </MapContainer>
        </div>
      )}
    </Card>
  );
}

/* ------------------------------- Dashboard ------------------------------- */
export function BizDashboard({ ctx, h }) {
  const [range, setRange] = useState({});
  const body = useMemo(() => ({ ...range }), [range]);
  const revenue = useActionData('stationRevenueTrend', { token: ctx.token, body: { ...body, pageSize: 5000 }, auto: h.has('stationRevenueTrend') });
  const map = useActionData('stationRevenueMap', { token: ctx.token, body: { ...body, pageSize: 5000 }, auto: h.has('stationRevenueMap') });
  const region = useActionData('regionRevenue', { token: ctx.token, body: { ...body, pageSize: 20 } });
  const sessions = useActionData('sessionStatistics', { token: ctx.token, body: { ...body, pageSize: 5000 } });

  const sessionData = aggregateSum(sessions.rows, 'SessionStatus', 'SessionCount');

  return (
    <div className="ui-stack">
      <DashboardHeader icon={<BusinessIcon size={22} />} title="Tổng quan kinh doanh" subtitle="Doanh thu, tăng trưởng khách hàng và hiệu suất phiên sạc." range={range} onRangeChange={setRange} onToast={ctx.onToast} />
      <DashboardStats actionId="businessDashboard" token={ctx.token} accents={['brand', 'info', 'warn', 'brand']} range={range} />
      <div className={`ui-grid${h.has('stationRevenueMap') ? ' dash-split' : ''}`}>
        {h.has('stationRevenueTrend') && (
          <TrendPanel
            title="Doanh thu hệ thống"
            subtitle="Tổng doanh thu theo khoảng thời gian đã chọn (VND)"
            rows={revenue.rows}
            loading={revenue.loading}
            dateKey="RevenueDate"
            valueKey="RevenueTotal"
            range={range}
            format={formatVND}
            height={400}
          />
        )}
        {h.has('stationRevenueMap') && <StationRevenueMap rows={map.rows} loading={map.loading} error={map.error} />}
      </div>
      <div className="ui-grid ui-grid-2">
        <Card>
          <CardHeader title="Doanh thu theo khu vực" subtitle="Top khu vực theo doanh thu (VND)" />
          {region.loading ? <Loader /> : <Bars data={region.rows.slice(0, 8)} xKey="RegionName" yKeys={['RevenueTotal']} height={300} horizontal />}
        </Card>
        <Card>
          <CardHeader title="Phân bố phiên sạc theo trạng thái" subtitle="Trong khoảng thời gian đã chọn" />
          {sessions.loading ? <Loader /> : <Donut data={sessionData} nameKey="name" valueKey="value" height={280} />}
        </Card>
      </div>
      <QuickReports h={h} token={ctx.token} onToast={ctx.onToast} reports={BIZ_QUICK_REPORTS} />
    </div>
  );
}

const BIZ_QUICK_REPORTS = [
  { id: 'stationRevenueByYear', label: 'Doanh thu theo trạm theo năm', icon: <BusinessIcon size={16} /> },
  { id: 'regionRevenue', label: 'Doanh thu theo khu vực', icon: <ReportIcon size={16} /> },
  { id: 'topRevenueStations', label: 'Top trạm doanh thu', icon: <ReportIcon size={16} /> },
  { id: 'paymentSummary', label: 'Tổng hợp thanh toán', icon: <PaymentIcon size={16} /> },
  { id: 'stationRevenueDaily', label: 'Doanh thu trạm theo ngày', icon: <ReportIcon size={16} /> },
  { id: 'connectorUtilization', label: 'Hiệu suất theo đầu sạc', icon: <BoltIcon size={16} /> }
];

/* ------------------------------- Reports explorer ------------------------------- */
const REPORTS = [
  { id: 'stationRevenueByYear', label: 'Doanh thu theo năm', chart: (rows) => <Bars data={aggregateSum(rows, 'RevenueYear', 'RevenueTotal').map((r) => ({ RevenueYear: r.name, RevenueTotal: r.value }))} xKey="RevenueYear" yKeys={['RevenueTotal']} height={300} /> },
  { id: 'regionRevenue', label: 'Theo khu vực', chart: (rows) => <Bars data={rows} xKey="RegionName" yKeys={['RevenueTotal']} height={300} /> },
  { id: 'connectorUtilization', label: 'Theo đầu sạc', chart: (rows) => <Bars data={rows} xKey="ConnectorName" yKeys={['TotalRevenue']} height={300} /> },
  { id: 'stationRevenueDaily', label: 'Doanh thu theo ngày', chart: null, chartActionId: 'stationRevenueTrend' },
  { id: 'topRevenueStations', label: 'Top trạm', chart: (rows) => <Bars data={rows} xKey="StationName" yKeys={['RevenueTotal']} height={320} horizontal /> },
  { id: 'peakHours', label: 'Giờ cao điểm', chart: (rows) => <Bars data={[...rows].sort((a, b) => a.StartHour - b.StartHour)} xKey="StartHour" yKeys={['SessionCount']} height={300} /> },
  { id: 'customerGrowth', label: 'Tăng trưởng KH', chart: (rows) => <AreaTrend data={rows.map((r) => ({ label: `${r.CreatedMonth}/${r.CreatedYear}`, NewCustomers: Number(r.NewCustomers) || 0 })).reverse()} xKey="label" yKey="NewCustomers" height={300} /> },
  { id: 'sessionStatistics', label: 'Thống kê phiên', chart: (rows) => <Donut data={aggregateSum(rows, 'SessionStatus', 'SessionCount')} nameKey="name" valueKey="value" height={300} /> },
  { id: 'topCustomerUsage', label: 'Top khách hàng', chart: (rows) => <Bars data={rows} xKey="FullName" yKeys={['TotalSpend']} height={320} horizontal /> },
  { id: 'stationRevenue', label: 'Doanh thu trạm', chart: null },
  { id: 'paymentSummary', label: 'Thanh toán', chart: (rows) => <Donut data={autoDonut(rows)} nameKey="name" valueKey="value" height={300} /> },
  { id: 'systemKpi', label: 'KPI hệ thống', chart: null }
];

function autoDonut(rows) {
  if (!rows.length) return [];
  const keys = Object.keys(rows[0]);
  const nameKey = keys.find((k) => typeof rows[0][k] === 'string') || keys[0];
  const valKey = keys.find((k) => typeof rows[0][k] === 'number') || keys[1];
  return aggregateSum(rows, nameKey, valKey);
}

export function ReportsExplorer({ ctx, h }) {
  const available = REPORTS.filter((r) => h.has(r.id));
  const [active, setActive] = useState(available[0]?.id);
  const cfg = available.find((r) => r.id === active) || available[0];

  return (
    <div className="ui-stack">
      <PageHeader icon={<ReportIcon size={22} />} title="Báo cáo & phân tích" subtitle="Trực quan hóa dữ liệu kinh doanh và xuất PDF/CSV." />
      <Tabs tabs={available.map((r) => ({ id: r.id, label: r.label }))} active={active} onChange={setActive} />
      {cfg && <ReportView key={cfg.id} action={h.get(cfg.id)} token={ctx.token} chart={cfg.chart} chartActionId={cfg.chartActionId} />}
    </div>
  );
}

/* ------------------------------- Pricing ------------------------------- */
export function PricingScreen({ ctx, h }) {
  const { rows, loading, reload } = useActionData('pricingPolicies', { token: ctx.token, body: { pageSize: 60 } });
  const [add, setAdd] = useState(false);
  const [off, setOff] = useState(null);
  const [on, setOn] = useState(null);

  return (
    <div className="ui-stack">
      <PageHeader icon={<PaymentIcon size={22} />} title="Chính sách giá" subtitle="Quản lý biểu giá theo kWh và hệ số cao điểm."
        actions={h.has('createPricingPolicy') && <Button icon={<PlusIcon size={16} />} sqlHint={SQL_HINTS.createPricingPolicy} onClick={() => setAdd(true)}>Tạo chính sách</Button>} />

      {loading ? <Loader /> : rows.length === 0 ? <EmptyState title="Chưa có chính sách giá" /> : (
        <div className="ui-grid ui-grid-cards">
          {rows.map((p) => (
            <Card key={p.PolicyID} className="ui-card-hover">
              <div className="station-top">
                <div><strong>{p.PolicyName}</strong><span className="muted-line">{p.PolicyCode}</span></div>
                <Badge value={p.IsActive ? 'Active' : 'Inactive'} />
              </div>
              <div className="price-figure">{formatVND(p.BasePricePerKWh)}<em>/kWh</em></div>
              <div className="receipt-rows">
                <div><span>Hệ số cao điểm</span><b>×{formatNumber(p.PeakMultiplier)}</b></div>
                <div><span>Áp dụng từ</span><b>{formatDate(p.AppliedFrom, false)}</b></div>
                <div><span>Đến</span><b>{p.AppliedTo ? formatDate(p.AppliedTo, false) : '—'}</b></div>
              </div>
              <div className="ui-row-actions">
                {h.has('deactivatePricingPolicy') && p.IsActive && (
                  <Button variant="danger" className="ui-btn-sm" sqlHint={SQL_HINTS.deactivatePricingPolicy} onClick={() => setOff(p)}>Vô hiệu hóa</Button>
                )}
                {h.has('activatePricingPolicy') && !p.IsActive && (
                  <Button className="ui-btn-sm" sqlHint={SQL_HINTS.activatePricingPolicy} onClick={() => setOn(p)}>Kích hoạt</Button>
                )}
              </div>
            </Card>
          ))}
        </div>
      )}

      {h.has('createPricingPolicy') && <ActionModal action={h.get('createPricingPolicy')} open={add} onClose={() => setAdd(false)} token={ctx.token} onToast={ctx.onToast} onDone={reload} submitLabel="Tạo chính sách" columns={2} />}
      {h.has('deactivatePricingPolicy') && <ConfirmAction action={h.get('deactivatePricingPolicy')} open={Boolean(off)} onClose={() => setOff(null)} params={off ? { PolicyID: off.PolicyID } : {}} danger title="Vô hiệu hóa chính sách" message={off ? `Tắt chính sách ${off.PolicyName}?` : ''} token={ctx.token} onToast={ctx.onToast} onDone={reload} />}
      {h.has('activatePricingPolicy') && <ConfirmAction action={h.get('activatePricingPolicy')} open={Boolean(on)} onClose={() => setOn(null)} params={on ? { PolicyID: on.PolicyID } : {}} title="Kích hoạt chính sách" message={on ? `Kích hoạt lại chính sách ${on.PolicyName}?` : ''} token={ctx.token} onToast={ctx.onToast} onDone={reload} />}
    </div>
  );
}

/* ------------------------------- Refunds ------------------------------- */
export function RefundsScreen({ ctx, h }) {
  const { rows, loading, reload } = useActionData('refundablePayments', { token: ctx.token, body: { pageSize: 60 } });
  const [refund, setRefund] = useState(null);

  return (
    <div className="ui-stack">
      <PageHeader icon={<PaymentIcon size={22} />} title="Hoàn tiền" subtitle="Các giao dịch đã thanh toán có thể hoàn tiền." />
      {loading ? <Loader /> : rows.length === 0 ? <EmptyState title="Không có giao dịch cần hoàn tiền" /> : (
        <div className="ui-grid ui-grid-cards">
          {rows.map((p) => (
            <Card key={p.TransactionID} className="ui-card-hover">
              <div className="station-top">
                <div><strong>{p.TransactionCode}</strong><span className="muted-line">{p.FullName}</span></div>
                <Badge value={p.TransactionStatus} />
              </div>
              <div className="price-figure">{formatVND(p.Amount)}</div>
              <div className="receipt-rows">
                <div><span>Phương thức</span><b>{p.PaymentMethod}</b></div>
                <div><span>Trạm</span><b>{p.StationName}</b></div>
                <div><span>Thanh toán</span><b>{formatDate(p.PaidAt)}</b></div>
              </div>
              {h.has('refundPayment') && <Button variant="danger" className="ui-btn-sm" sqlHint={SQL_HINTS.refundPayment} onClick={() => setRefund(p)}>Hoàn tiền</Button>}
            </Card>
          ))}
        </div>
      )}
      {h.has('refundPayment') && <ActionModal action={h.get('refundPayment')} open={Boolean(refund)} onClose={() => setRefund(null)} initial={refund ? { TransactionID: refund.TransactionID } : {}} title={refund ? `Hoàn tiền · ${refund.TransactionCode}` : 'Hoàn tiền'} token={ctx.token} onToast={ctx.onToast} onDone={reload} submitLabel="Xác nhận hoàn tiền" />}
    </div>
  );
}

/* ------------------------------- Franchise mgmt ------------------------------- */
export function FranchiseMgmtScreen({ ctx, h }) {
  const [settle, setSettle] = useState(false);
  const [policy, setPolicy] = useState(false);
  return (
    <div className="ui-stack">
      <PageHeader icon={<FranchiseIcon size={22} />} title="Nhượng quyền" subtitle="Chia lợi nhuận, điều chỉnh tỷ lệ và tạo quyết toán cho đối tác."
        actions={(
          <>
            {h.has('updateRevenueSharePolicy') && <Button variant="ghost" sqlHint={SQL_HINTS.updateRevenueSharePolicy} onClick={() => setPolicy(true)}>Cập nhật tỷ lệ chia</Button>}
            {h.has('createRevenueSettlement') && <Button icon={<PlusIcon size={16} />} sqlHint={SQL_HINTS.createRevenueSettlement} onClick={() => setSettle(true)}>Tạo quyết toán</Button>}
          </>
        )} />
      {h.has('profitSharing') && <ReportView action={h.get('profitSharing')} token={ctx.token} />}

      {h.has('updateRevenueSharePolicy') && <ActionModal action={h.get('updateRevenueSharePolicy')} open={policy} onClose={() => setPolicy(false)} token={ctx.token} onToast={ctx.onToast} submitLabel="Cập nhật" />}
      {h.has('createRevenueSettlement') && <ActionModal action={h.get('createRevenueSettlement')} open={settle} onClose={() => setSettle(false)} token={ctx.token} onToast={ctx.onToast} submitLabel="Tạo quyết toán" />}
    </div>
  );
}
