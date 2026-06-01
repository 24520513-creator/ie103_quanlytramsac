import React, { useState } from 'react';
import { useActionData } from '../../lib/useAction';
import { formatNumber, formatDate } from '../../lib/format';
import { DashboardStats, ActionModal, ConfirmAction, ReportView, QuickReports } from '../common';
import { Bars } from '../../components/charts';
import {
  Card, CardHeader, PageHeader, Button, Badge, EmptyState, Loader, SearchInput, Tabs
} from '../../components/ui';
import { SQL_HINTS } from '../../lib/sqlHints';
import {
  OperationsIcon, MaintenanceIcon, ActivityIcon, AlertTriangleIcon, PlusIcon, MapPinIcon, BoltIcon
} from '../../components/Icons';

/* ------------------------------- Dashboard ------------------------------- */
export function OpsDashboard({ ctx, h }) {
  const { rows } = useActionData('stationStatus', { token: ctx.token, body: { pageSize: 12 } });
  const chartData = rows.slice(0, 8).map((r) => ({
    name: r.StationCode || r.StationName,
    'Khả dụng': Number(r.AvailablePoints) || 0,
    'Đang sạc': Number(r.ChargingPoints) || 0,
    'Sự cố': Number(r.ProblemPoints) || 0
  }));
  return (
    <div className="ui-stack">
      <PageHeader icon={<OperationsIcon size={22} />} title="Tổng quan vận hành" subtitle="Tình trạng trạm, cổng, phiên đang sạc và ticket bảo trì." />
      <DashboardStats actionId="operationsDashboard" token={ctx.token} accents={['brand', 'info', 'bad', 'warn']} />
      {chartData.length > 0 && (
        <Card>
          <CardHeader title="Tình trạng cổng theo trạm" subtitle="Top trạm" />
          <Bars data={chartData} xKey="name" yKeys={['Khả dụng', 'Đang sạc', 'Sự cố']} height={300} />
        </Card>
      )}
      <QuickReports h={h} token={ctx.token} onToast={ctx.onToast} reports={[
        { id: 'stationStatus', label: 'Trạng thái trạm & cổng', icon: <MapPinIcon size={16} /> },
        { id: 'maintenanceTickets', label: 'Ticket bảo trì', icon: <MaintenanceIcon size={16} /> },
        { id: 'maintenanceKpi', label: 'KPI bảo trì theo trạm', icon: <ActivityIcon size={16} /> },
        { id: 'errorLogActive', label: 'Lỗi thiết bị đang hoạt động', icon: <AlertTriangleIcon size={16} /> },
        { id: 'connectorUtilization', label: 'Hiệu suất theo đầu sạc', icon: <BoltIcon size={16} /> },
        { id: 'telemetryHealth', label: 'Telemetry cảnh báo', icon: <ActivityIcon size={16} /> }
      ]} />
    </div>
  );
}

/* ------------------------------- Reports ------------------------------- */
export function OpsReports({ ctx, h }) {
  const available = [
    { id: 'maintenanceKpi', label: 'KPI bảo trì', chart: (rows) => <Bars data={rows} xKey="StationName" yKeys={['OpenTicketCount', 'ActiveErrorCount']} height={320} /> },
    { id: 'connectorUtilization', label: 'Đầu sạc', chart: (rows) => <Bars data={rows} xKey="ConnectorName" yKeys={['TotalKWh']} height={300} /> },
    { id: 'errorLogActive', label: 'Lỗi đang hoạt động', chart: null },
    { id: 'stationStatus', label: 'Trạng thái trạm', chart: null },
    { id: 'maintenanceTickets', label: 'Ticket bảo trì', chart: null },
    { id: 'telemetryHealth', label: 'Telemetry', chart: null }
  ].filter((r) => h.has(r.id));
  const [active, setActive] = useState(available[0]?.id);
  const cfg = available.find((r) => r.id === active) || available[0];

  return (
    <div className="ui-stack">
      <PageHeader icon={<ActivityIcon size={22} />} title="Báo cáo vận hành" subtitle="Bảo trì, lỗi thiết bị và hiệu suất hạ tầng — xuất PDF/CSV." />
      <Tabs tabs={available.map((r) => ({ id: r.id, label: r.label }))} active={active} onChange={setActive} />
      {cfg && <ReportView key={cfg.id} action={h.get(cfg.id)} token={ctx.token} chart={cfg.chart} />}
    </div>
  );
}

/* ------------------------------- Stations ------------------------------- */
export function StationsScreen({ ctx, h }) {
  const { rows, loading, reload } = useActionData('stationStatus', { token: ctx.token, body: { pageSize: 60 } });
  const [search, setSearch] = useState('');
  const [editStation, setEditStation] = useState(null);
  const [editPoint, setEditPoint] = useState(false);

  const filtered = rows.filter((r) => !search || JSON.stringify(r).toLowerCase().includes(search.toLowerCase()));

  return (
    <div className="ui-stack">
      <PageHeader icon={<MapPinIcon size={22} />} title="Trạm & cổng sạc" subtitle="Theo dõi và điều chỉnh trạng thái vận hành."
        actions={h.has('updatePointStatus') && <Button variant="ghost" sqlHint={SQL_HINTS.updatePointStatus} onClick={() => setEditPoint(true)}>Cập nhật cổng</Button>} />
      <SearchInput value={search} onChange={setSearch} placeholder="Tìm trạm..." />

      {loading ? <Loader /> : filtered.length === 0 ? <EmptyState title="Không có trạm" /> : (
        <div className="ui-grid ui-grid-cards">
          {filtered.map((s) => (
            <Card key={s.StationID} className="ui-card-hover">
              <div className="station-top">
                <div><strong>{s.StationName}</strong><span className="muted-line">{s.StationCode}</span></div>
                <Badge value={s.StationStatus} />
              </div>
              <div className="metric-row">
                <div className="metric"><b>{formatNumber(s.TotalPoints)}</b><span>Tổng cổng</span></div>
                <div className="metric ok"><b>{formatNumber(s.AvailablePoints)}</b><span>Khả dụng</span></div>
                <div className="metric info"><b>{formatNumber(s.ChargingPoints)}</b><span>Đang sạc</span></div>
                <div className="metric bad"><b>{formatNumber(s.ProblemPoints)}</b><span>Sự cố</span></div>
              </div>
              {h.has('updateStationStatus') && (
                <Button variant="ghost" className="ui-btn-sm" sqlHint={SQL_HINTS.updateStationStatus} onClick={() => setEditStation(s)}>Đổi trạng thái trạm</Button>
              )}
            </Card>
          ))}
        </div>
      )}

      {h.has('updateStationStatus') && (
        <ActionModal action={h.get('updateStationStatus')} open={Boolean(editStation)} onClose={() => setEditStation(null)}
          initial={editStation ? { StationID: editStation.StationID, StationStatus: editStation.StationStatus } : {}}
          title={editStation ? `Trạng thái · ${editStation.StationName}` : 'Cập nhật trạng thái trạm'}
          token={ctx.token} onToast={ctx.onToast} onDone={reload} submitLabel="Cập nhật" />
      )}
      {h.has('updatePointStatus') && (
        <ActionModal action={h.get('updatePointStatus')} open={editPoint} onClose={() => setEditPoint(false)}
          token={ctx.token} onToast={ctx.onToast} onDone={reload} submitLabel="Cập nhật cổng" />
      )}
    </div>
  );
}

/* ------------------------------- Active sessions ------------------------------- */
export function ActiveSessionsScreen({ ctx, h }) {
  const { rows, loading, reload } = useActionData('activeSessions', { token: ctx.token, body: { pageSize: 60 } });
  const [fail, setFail] = useState(null);

  return (
    <div className="ui-stack">
      <PageHeader icon={<ActivityIcon size={22} />} title="Phiên đang sạc" subtitle="Giám sát phiên sạc hiện hành và xử lý sự cố." />
      {loading ? <Loader /> : rows.length === 0 ? <EmptyState icon={<ActivityIcon size={26} />} title="Không có phiên đang sạc" /> : (
        <div className="ui-grid ui-grid-cards">
          {rows.map((s) => (
            <Card key={s.SessionID} className="ui-card-hover">
              <div className="station-top">
                <div><strong>{s.SessionCode}</strong><span className="muted-line">{s.FullName}</span></div>
                <Badge value={s.SessionStatus} />
              </div>
              <div className="station-specs">
                <span><MapPinIcon size={14} />{s.StationCode} · {s.PointCode}</span>
                <span><BoltIcon size={14} />{formatNumber(s.TotalKWh)} kWh</span>
              </div>
              <span className="muted-line">Bắt đầu {formatDate(s.StartTime)}</span>
              {h.has('markSessionFailed') && <Button variant="danger" className="ui-btn-sm" icon={<AlertTriangleIcon size={14} />} sqlHint={SQL_HINTS.markSessionFailed} onClick={() => setFail(s)}>Đánh dấu lỗi</Button>}
            </Card>
          ))}
        </div>
      )}
      {h.has('markSessionFailed') && (
        <ActionModal action={h.get('markSessionFailed')} open={Boolean(fail)} onClose={() => setFail(null)}
          initial={fail ? { SessionID: fail.SessionID } : {}} title="Đánh dấu phiên lỗi"
          token={ctx.token} onToast={ctx.onToast} onDone={reload} submitLabel="Xác nhận" />
      )}
    </div>
  );
}

/* ------------------------------- Maintenance kanban ------------------------------- */
const COLUMNS = [
  { key: 'Open', label: 'Mở', match: /open/i },
  { key: 'Assigned', label: 'Đã phân công', match: /assigned/i },
  { key: 'InProgress', label: 'Đang xử lý', match: /progress/i },
  { key: 'Closed', label: 'Đã đóng', match: /closed|resolved/i }
];

export function MaintenanceScreen({ ctx, h }) {
  const { rows, loading, reload } = useActionData('maintenanceTickets', { token: ctx.token, body: { pageSize: 100 } });
  const [report, setReport] = useState(false);
  const [schedule, setSchedule] = useState(false);
  const [assign, setAssign] = useState(null);
  const [close, setClose] = useState(null);

  const columns = COLUMNS.map((col) => ({
    ...col,
    items: rows.filter((t) => col.match.test(String(t.TicketStatus)))
  }));
  const other = rows.filter((t) => !COLUMNS.some((c) => c.match.test(String(t.TicketStatus))));
  if (other.length) columns[0].items = [...columns[0].items, ...other];

  return (
    <div className="ui-stack">
      <PageHeader icon={<MaintenanceIcon size={22} />} title="Bảo trì" subtitle="Quản lý ticket sự cố và bảo trì theo trạng thái."
        actions={(
          <>
            {h.has('reportError') && <Button variant="ghost" icon={<AlertTriangleIcon size={16} />} sqlHint={SQL_HINTS.reportError} onClick={() => setReport(true)}>Ghi nhận lỗi</Button>}
            {h.has('scheduleMaintenance') && <Button icon={<PlusIcon size={16} />} sqlHint={SQL_HINTS.scheduleMaintenance} onClick={() => setSchedule(true)}>Lập lịch bảo trì</Button>}
          </>
        )} />

      {loading ? <Loader /> : (
        <div className="kanban">
          {columns.map((col) => (
            <div key={col.key} className="kanban-col">
              <div className="kanban-head"><span>{col.label}</span><small>{col.items.length}</small></div>
              <div className="kanban-body">
                {col.items.length === 0 ? <div className="kanban-empty">—</div> : col.items.map((t) => (
                  <Card key={t.TicketID} className="ticket">
                    <div className="ticket-top"><Badge value={t.Priority} /><span className="ticket-code">{t.TicketCode}</span></div>
                    <strong className="ticket-title">{t.Title}</strong>
                    <span className="muted-line">{t.StationCode}{t.PointCode ? ` · ${t.PointCode}` : ''}</span>
                    {t.AssignedToFullName && <span className="muted-line">👤 {t.AssignedToFullName}</span>}
                    <div className="ticket-actions">
                      {h.has('assignTicket') && !/closed/i.test(t.TicketStatus) && <Button variant="ghost" className="ui-btn-sm" sqlHint={SQL_HINTS.assignTicket} onClick={() => setAssign(t)}>Phân công</Button>}
                      {h.has('closeTicket') && !/closed/i.test(t.TicketStatus) && <Button variant="soft" className="ui-btn-sm" sqlHint={SQL_HINTS.closeTicket} onClick={() => setClose(t)}>Đóng</Button>}
                    </div>
                  </Card>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}

      {h.has('reportError') && <ActionModal action={h.get('reportError')} open={report} onClose={() => setReport(false)} token={ctx.token} onToast={ctx.onToast} onDone={reload} submitLabel="Ghi nhận" />}
      {h.has('scheduleMaintenance') && <ActionModal action={h.get('scheduleMaintenance')} open={schedule} onClose={() => setSchedule(false)} token={ctx.token} onToast={ctx.onToast} onDone={reload} submitLabel="Tạo ticket" />}
      {h.has('assignTicket') && <ActionModal action={h.get('assignTicket')} open={Boolean(assign)} onClose={() => setAssign(null)} initial={assign ? { TicketID: assign.TicketID } : {}} title={assign ? `Phân công · ${assign.TicketCode}` : 'Phân công'} token={ctx.token} onToast={ctx.onToast} onDone={reload} submitLabel="Phân công" />}
      {h.has('closeTicket') && <ConfirmAction action={h.get('closeTicket')} open={Boolean(close)} onClose={() => setClose(null)} params={close ? { TicketID: close.TicketID } : {}} title="Đóng ticket" message={close ? `Đóng ticket ${close.TicketCode}?` : ''} token={ctx.token} onToast={ctx.onToast} onDone={reload} />}
    </div>
  );
}

/* ------------------------------- Telemetry ------------------------------- */
export function TelemetryScreen({ ctx, h }) {
  return (
    <div className="ui-stack">
      <PageHeader icon={<ActivityIcon size={22} />} title="Telemetry cảnh báo" subtitle="Các cổng có mẫu Warning, Critical hoặc Offline." />
      <ReportView action={h.get('telemetryHealth')} token={ctx.token} />
    </div>
  );
}
