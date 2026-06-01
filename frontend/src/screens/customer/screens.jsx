import React, { useState } from 'react';
import { useActionData, useLookupOptions } from '../../lib/useAction';
import { formatVND, formatNumber, formatDate } from '../../lib/format';
import { DashboardStats, ActionModal, ConfirmAction, QuickReports } from '../common';
import { AreaTrend } from '../../components/charts';
import {
  Card, CardHeader, PageHeader, Button, Badge, EmptyState, Loader, SearchInput, ProgressRing
} from '../../components/ui';
import {
  MapPinIcon, CarIcon, CalendarIcon, ChargingIcon, PaymentIcon, BoltIcon, PlusIcon,
  DashboardIcon, ClockIcon, DownloadIcon, BatteryIcon, ChevronLeftIcon, ChevronRightIcon
} from '../../components/Icons';

/* ----------------------------------- Home ----------------------------------- */
export function CustomerHome({ ctx, h }) {
  const name = ctx.user.profile?.FullName || ctx.user.username;
  const summary = useActionData('myChargingSummary', { token: ctx.token, body: { pageSize: 24 } });
  const spendData = summary.rows
    .map((r) => ({ label: `${r.UsageMonth}/${r.UsageYear}`, TotalSpend: Number(r.TotalSpend) || 0 }))
    .reverse();
  return (
    <div className="ui-stack">
      <Card className="hero">
        <div className="hero-text">
          <span className="hero-eyebrow">Xin chào</span>
          <h1>{name} 👋</h1>
          <p>Tìm trạm sạc gần bạn, đặt chỗ trước và theo dõi phiên sạc — tất cả trong một nơi.</p>
        </div>
        <div className="hero-mark"><BoltIcon size={42} /></div>
      </Card>
      <DashboardStats actionId="customerDashboard" token={ctx.token} />
      {h.has('myChargingSummary') && (
        <Card>
          <CardHeader title="Chi tiêu sạc theo tháng" subtitle="VND" />
          {summary.loading ? <Loader /> : spendData.length === 0
            ? <EmptyState icon={<BoltIcon size={26} />} title="Chưa có dữ liệu sạc" message="Hoàn tất một phiên sạc để xem thống kê." />
            : <AreaTrend data={spendData} xKey="label" yKey="TotalSpend" height={260} />}
        </Card>
      )}
      <QuickReports h={h} token={ctx.token} onToast={ctx.onToast} reports={[
        { id: 'chargingHistory', label: 'Lịch sử phiên sạc', icon: <ChargingIcon size={16} /> },
        { id: 'invoiceDetail', label: 'Hoá đơn của tôi', icon: <PaymentIcon size={16} /> },
        { id: 'myChargingSummary', label: 'Tổng hợp sạc theo tháng', icon: <BoltIcon size={16} /> }
      ]} />
    </div>
  );
}

/* ------------------------------- Find stations ------------------------------- */
// Group available charging points by station. Users look for a *station* near
// them first, then pick a specific port — so the list shows one card per station
// with its available-port count, and drilling in reveals the individual ports.
function groupByStation(rows) {
  const map = new Map();
  for (const r of rows) {
    const key = r.StationID ?? `${r.StationName ?? ''}|${r.RegionName ?? ''}`;
    if (!map.has(key)) {
      map.set(key, { key, name: r.StationName || 'Trạm sạc', region: r.RegionName || '', points: [] });
    }
    map.get(key).points.push(r);
  }
  return [...map.values()].map((st) => {
    const powers = st.points.map((p) => Number(p.PowerKW)).filter((n) => Number.isFinite(n));
    const connectors = [...new Set(st.points.map((p) => p.ConnectorName).filter(Boolean))];
    return { ...st, minKW: powers.length ? Math.min(...powers) : 0, maxKW: powers.length ? Math.max(...powers) : 0, connectors };
  });
}

export function FindStations({ ctx, h }) {
  const { rows, loading, reload } = useActionData('availablePoints', { token: ctx.token, body: { pageSize: 200 } });
  const [search, setSearch] = useState('');
  const [selectedKey, setSelectedKey] = useState(null);
  const [book, setBook] = useState(null);
  const [start, setStart] = useState(null);

  const stations = groupByStation(rows);
  const filtered = stations.filter((st) => {
    if (!search) return true;
    const q = search.toLowerCase();
    return st.name.toLowerCase().includes(q) || st.region.toLowerCase().includes(q)
      || st.connectors.some((c) => c.toLowerCase().includes(q));
  });
  const selected = stations.find((st) => st.key === selectedKey) || null;

  const bookingModal = h.has('createBooking') && (
    <ActionModal action={h.get('createBooking')} open={Boolean(book)} onClose={() => setBook(null)}
      initial={book ? { PointID: book.PointID } : {}} title={book ? `Đặt chỗ · ${book.StationName}` : 'Đặt chỗ'}
      token={ctx.token} onToast={ctx.onToast} onDone={reload} submitLabel="Xác nhận đặt chỗ" />
  );
  const startModal = h.has('startSession') && (
    <ActionModal action={h.get('startSession')} open={Boolean(start)} onClose={() => setStart(null)}
      initial={start ? { PointID: start.PointID } : {}} title={start ? `Bắt đầu sạc · ${start.StationName}` : 'Bắt đầu sạc'}
      token={ctx.token} onToast={ctx.onToast} onDone={reload} submitLabel="Bắt đầu" />
  );

  // Detail view: the ports of one station.
  if (selected) {
    return (
      <div className="ui-stack">
        <button className="ui-btn ui-btn-ghost ui-btn-sm station-back" onClick={() => setSelectedKey(null)}>
          <ChevronLeftIcon size={16} />Tất cả trạm
        </button>
        <PageHeader icon={<MapPinIcon size={22} />} title={selected.name}
          subtitle={`${selected.region} · ${selected.points.length} cổng sẵn sàng`} />
        <div className="ui-grid ui-grid-cards">
          {selected.points.map((p) => (
            <Card key={p.PointID} className="station-card">
              <div className="station-top">
                <div>
                  <strong className="u-truncate" title={p.PointCode}>{p.PointCode}</strong>
                  <span className="muted-line">{p.ConnectorName || 'Đầu sạc tiêu chuẩn'}</span>
                </div>
                <Badge value={p.PointStatus} />
              </div>
              <div className="station-specs">
                <span><BoltIcon size={14} />{formatNumber(p.PowerKW)} kW</span>
                <span><BatteryIcon size={14} />{p.ConnectorName || '—'}</span>
              </div>
              <div className="station-actions">
                <Button variant="ghost" className="ui-btn-sm" icon={<CalendarIcon size={15} />} onClick={() => setBook(p)}>Đặt chỗ</Button>
                <Button className="ui-btn-sm" icon={<ChargingIcon size={15} />} onClick={() => setStart(p)}>Bắt đầu sạc</Button>
              </div>
            </Card>
          ))}
        </div>
        {bookingModal}
        {startModal}
      </div>
    );
  }

  // List view: one card per station.
  return (
    <div className="ui-stack">
      <PageHeader icon={<MapPinIcon size={22} />} title="Tìm trạm & sạc"
        subtitle="Tìm trạm sạc gần bạn, xem số cổng đang sẵn sàng, rồi chọn cổng để đặt chỗ hoặc sạc." />
      <SearchInput value={search} onChange={setSearch} placeholder="Tìm theo trạm, khu vực, đầu sạc..." />

      {loading ? <Loader /> : filtered.length === 0 ? (
        <EmptyState icon={<MapPinIcon size={26} />} title="Không có trạm khả dụng" message="Hãy thử lại sau hoặc đổi từ khóa tìm kiếm." />
      ) : (
        <div className="ui-grid ui-grid-cards">
          {filtered.map((st) => (
            <Card key={st.key} className="ui-card-hover station-group" as="button" onClick={() => setSelectedKey(st.key)}>
              <div className="station-group-head">
                <div className="station-group-icon"><MapPinIcon size={20} /></div>
                <div className="station-group-info">
                  <strong className="u-truncate" title={st.name}>{st.name}</strong>
                  <span className="muted-line">{st.region || 'Khu vực chưa rõ'}</span>
                </div>
                <ChevronRightIcon size={18} className="station-group-chevron" />
              </div>
              <div className="station-group-meta">
                <span className="station-group-count"><ChargingIcon size={14} />{st.points.length} cổng sẵn sàng</span>
                <span><BoltIcon size={14} />{st.minKW === st.maxKW ? formatNumber(st.maxKW) : `${formatNumber(st.minKW)}–${formatNumber(st.maxKW)}`} kW</span>
              </div>
            </Card>
          ))}
        </div>
      )}
      {bookingModal}
      {startModal}
    </div>
  );
}

/* -------------------------------- My vehicles -------------------------------- */
export function MyVehicles({ ctx, h }) {
  const { rows, loading, reload } = useActionData('myVehicles', { token: ctx.token, body: { pageSize: 60 } });
  const [add, setAdd] = useState(false);
  const [edit, setEdit] = useState(null);

  return (
    <div className="ui-stack">
      <PageHeader icon={<CarIcon size={22} />} title="Xe của tôi" subtitle="Quản lý phương tiện dùng để đặt chỗ và sạc."
        actions={h.has('createVehicle') && <Button icon={<PlusIcon size={16} />} onClick={() => setAdd(true)}>Thêm xe</Button>} />

      {loading ? <Loader /> : rows.length === 0 ? (
        <EmptyState icon={<CarIcon size={26} />} title="Chưa có xe nào" message="Thêm phương tiện đầu tiên để bắt đầu đặt chỗ và sạc." />
      ) : (
        <div className="ui-grid ui-grid-cards">
          {rows.map((v) => (
            <Card key={v.VehicleID} className="ui-card-hover vehicle-card">
              <div className="vehicle-icon"><CarIcon size={22} /></div>
              <div className="vehicle-body">
                <strong>{v.Brand} {v.Model}</strong>
                <span className="plate">{v.PlateNumber}</span>
                <div className="vehicle-meta">
                  <span>{formatNumber(v.BatteryCapacityKWh)} kWh</span>
                  <span>·</span>
                  <span>{v.ConnectorName || 'Chưa đặt đầu sạc'}</span>
                </div>
              </div>
              <div className="vehicle-foot">
                <Badge value={v.IsActive ? 'Active' : 'Inactive'} />
                {h.has('updateVehicle') && <Button variant="ghost" className="ui-btn-sm" onClick={() => setEdit(v)}>Sửa</Button>}
              </div>
            </Card>
          ))}
        </div>
      )}

      {h.has('createVehicle') && (
        <ActionModal action={h.get('createVehicle')} open={add} onClose={() => setAdd(false)}
          token={ctx.token} onToast={ctx.onToast} onDone={reload} submitLabel="Thêm xe" />
      )}
      {h.has('updateVehicle') && (
        <ActionModal action={h.get('updateVehicle')} open={Boolean(edit)} onClose={() => setEdit(null)}
          initial={edit ? { VehicleID: edit.VehicleID, PlateNumber: edit.PlateNumber, Brand: edit.Brand, Model: edit.Model, BatteryCapacityKWh: edit.BatteryCapacityKWh, IsActive: edit.IsActive } : {}}
          title="Cập nhật xe" token={ctx.token} onToast={ctx.onToast} onDone={reload} submitLabel="Lưu thay đổi" />
      )}
    </div>
  );
}

/* --------------------------------- Bookings --------------------------------- */
export function Bookings({ ctx, h }) {
  const { rows, loading, reload } = useActionData('bookingHistory', { token: ctx.token, body: { pageSize: 50 } });
  const [create, setCreate] = useState(false);
  const [cancel, setCancel] = useState(null);
  const canCancel = (s) => /pending|reserved|confirmed|booked/i.test(String(s));

  return (
    <div className="ui-stack">
      <PageHeader icon={<CalendarIcon size={22} />} title="Đặt chỗ của tôi" subtitle="Lịch sử đặt chỗ cổng sạc và trạng thái."
        actions={h.has('createBooking') && <Button icon={<PlusIcon size={16} />} onClick={() => setCreate(true)}>Tạo đặt chỗ</Button>} />

      {loading ? <Loader /> : rows.length === 0 ? (
        <EmptyState icon={<CalendarIcon size={26} />} title="Chưa có đặt chỗ" message="Đặt chỗ một cổng sạc từ màn hình Tìm trạm & sạc." />
      ) : (
        <div className="timeline">
          {rows.map((b) => (
            <Card key={b.BookingID} className="timeline-item">
              <div className="timeline-dot"><CalendarIcon size={16} /></div>
              <div className="timeline-main">
                <div className="timeline-head">
                  <strong>{b.BookingCode}</strong>
                  <Badge value={b.BookingStatus} />
                </div>
                <span className="muted-line">{b.StationName} · {b.PointCode} · {b.PlateNumber}</span>
                <div className="timeline-time"><ClockIcon size={14} />{formatDate(b.BookedFrom)} → {formatDate(b.BookedTo)}</div>
              </div>
              {h.has('cancelBooking') && canCancel(b.BookingStatus) && (
                <Button variant="danger" className="ui-btn-sm" onClick={() => setCancel(b)}>Huỷ</Button>
              )}
            </Card>
          ))}
        </div>
      )}

      {h.has('createBooking') && (
        <ActionModal action={h.get('createBooking')} open={create} onClose={() => setCreate(false)}
          token={ctx.token} onToast={ctx.onToast} onDone={reload} submitLabel="Xác nhận đặt chỗ" />
      )}
      {h.has('cancelBooking') && (
        <ConfirmAction action={h.get('cancelBooking')} open={Boolean(cancel)} onClose={() => setCancel(null)}
          params={cancel ? { BookingID: cancel.BookingID } : {}} danger
          title="Huỷ đặt chỗ" message={cancel ? `Huỷ đặt chỗ ${cancel.BookingCode}? Thao tác không thể hoàn tác.` : ''}
          token={ctx.token} onToast={ctx.onToast} onDone={reload} />
      )}
    </div>
  );
}

/* --------------------------------- Sessions --------------------------------- */
export function Sessions({ ctx, h }) {
  const { rows, loading, reload } = useActionData('chargingHistory', { token: ctx.token, body: { pageSize: 50 } });
  const payable = useLookupOptions('customerPayableSessions', { token: ctx.token });
  const invoiceable = useLookupOptions('customerInvoiceableSessions', { token: ctx.token });
  const [start, setStart] = useState(false);
  const [end, setEnd] = useState(null);
  const [pay, setPay] = useState(null);
  const [invoice, setInvoice] = useState(null);
  const isActive = (s) => /charging|inprogress|started/i.test(String(s));
  const payableIds = new Set(payable.options.map((item) => String(item.value)));
  const invoiceableIds = new Set(invoiceable.options.map((item) => String(item.value)));
  const afterMutation = () => {
    reload();
    payable.reload().catch(() => {});
    invoiceable.reload().catch(() => {});
  };

  return (
    <div className="ui-stack">
      <PageHeader icon={<ChargingIcon size={22} />} title="Phiên sạc" subtitle="Theo dõi phiên đang sạc, hoàn tất thanh toán và xem lịch sử."
        actions={h.has('startSession') && <Button icon={<BoltIcon size={16} />} onClick={() => setStart(true)}>Bắt đầu phiên</Button>} />

      {loading ? <Loader /> : rows.length === 0 ? (
        <EmptyState icon={<ChargingIcon size={26} />} title="Chưa có phiên sạc" message="Bắt đầu một phiên sạc từ màn hình Tìm trạm & sạc." />
      ) : (
        <div className="ui-grid ui-grid-2">
          {rows.map((s) => {
            const active = isActive(s.SessionStatus);
            return (
              <Card key={s.SessionID} className={`session-card ${active ? 'session-active' : ''}`}>
                <div className="session-ring">
                  <ProgressRing value={Number(s.TotalKWh) || 0} max={Math.max(Number(s.TotalKWh) || 0, 60)}
                    label={`${formatNumber(s.TotalKWh || 0)}`} sub="kWh" size={120} />
                </div>
                <div className="session-info">
                  <div className="session-head">
                    <strong>{s.SessionCode}</strong>
                    <Badge value={s.SessionStatus} />
                  </div>
                  <span className="muted-line">{s.StationName} · {s.PointCode} · {s.PlateNumber}</span>
                  <div className="session-figures">
                    <div><span>Bắt đầu</span><b>{formatDate(s.StartTime)}</b></div>
                    <div><span>Chi phí</span><b>{formatVND(s.CostTotal)}</b></div>
                  </div>
                  <div className="session-actions">
                    {active && h.has('endSession') && <Button className="ui-btn-sm" onClick={() => setEnd(s)}>Kết thúc</Button>}
                    {payableIds.has(String(s.SessionID)) && h.has('createPayment') && <Button variant="ghost" className="ui-btn-sm" icon={<PaymentIcon size={14} />} onClick={() => setPay(s)}>Thanh toán</Button>}
                    {invoiceableIds.has(String(s.SessionID)) && h.has('createInvoice') && <Button variant="ghost" className="ui-btn-sm" onClick={() => setInvoice(s)}>Lập hoá đơn</Button>}
                  </div>
                </div>
              </Card>
            );
          })}
        </div>
      )}

      {h.has('startSession') && <ActionModal action={h.get('startSession')} open={start} onClose={() => setStart(false)} token={ctx.token} onToast={ctx.onToast} onDone={afterMutation} submitLabel="Bắt đầu" />}
      {h.has('endSession') && <ActionModal action={h.get('endSession')} open={Boolean(end)} onClose={() => setEnd(null)} initial={end ? { SessionID: end.SessionID } : {}} title="Kết thúc phiên sạc" token={ctx.token} onToast={ctx.onToast} onDone={afterMutation} submitLabel="Kết thúc phiên" />}
      {h.has('createPayment') && <ActionModal action={h.get('createPayment')} open={Boolean(pay)} onClose={() => setPay(null)} initial={pay ? { SessionID: pay.SessionID } : {}} title="Tạo thanh toán" token={ctx.token} onToast={ctx.onToast} onDone={afterMutation} submitLabel="Thanh toán" />}
      {h.has('createInvoice') && <ActionModal action={h.get('createInvoice')} open={Boolean(invoice)} onClose={() => setInvoice(null)} initial={invoice ? { SessionID: invoice.SessionID } : {}} title="Lập hoá đơn" token={ctx.token} onToast={ctx.onToast} onDone={afterMutation} submitLabel="Phát hành hoá đơn" />}
    </div>
  );
}

/* --------------------------------- Invoices --------------------------------- */
export function Invoices({ ctx, h }) {
  const { rows, loading } = useActionData('invoiceDetail', { token: ctx.token, body: { pageSize: 50 } });
  const action = h.get('invoiceDetail');

  return (
    <div className="ui-stack">
      <PageHeader icon={<PaymentIcon size={22} />} title="Hoá đơn của tôi" subtitle="Hoá đơn điện tử cho các phiên sạc đã thanh toán." />

      {loading ? <Loader /> : rows.length === 0 ? (
        <EmptyState icon={<PaymentIcon size={26} />} title="Chưa có hoá đơn" message="Hoá đơn sẽ xuất hiện sau khi bạn thanh toán phiên sạc." />
      ) : (
        <div className="ui-grid ui-grid-cards">
          {rows.map((inv) => (
            <Card key={inv.InvoiceID} className="receipt">
              <div className="receipt-top">
                <div>
                  <span className="muted-line">Hoá đơn</span>
                  <strong>{inv.InvoiceCode}</strong>
                </div>
                <Badge value={inv.InvoiceStatus} />
              </div>
              <div className="receipt-amount">{formatVND(inv.TotalAmount)}</div>
              <div className="receipt-rows">
                <div><span>Trạm</span><b>{inv.StationName}</b></div>
                <div><span>Phương thức</span><b>{inv.PaymentMethod}</b></div>
                <div><span>Giao dịch</span><b>{inv.TransactionCode}</b></div>
                <div><span>Ngày phát hành</span><b>{formatDate(inv.IssuedAt)}</b></div>
              </div>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
