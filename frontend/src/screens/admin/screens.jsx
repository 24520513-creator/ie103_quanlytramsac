import React, { useState } from 'react';
import { useActionData } from '../../lib/useAction';
import { formatValue, formatDate, isStatusColumn } from '../../lib/format';
import { DashboardStats, ActionModal, ConfirmAction, ReportView, QuickReports } from '../common';
import { Donut } from '../../components/charts';
import {
  Card, CardHeader, PageHeader, Button, Badge, EmptyState, Loader, SearchInput, DataTable, Tabs
} from '../../components/ui';
import { SQL_HINTS } from '../../lib/sqlHints';
import {
  AdminIcon, ProfileIcon, LockIcon, UnlockIcon, ReportIcon, PlusIcon, ActivityIcon
} from '../../components/Icons';

function sumByKey(rows, nameKey, valKey) {
  const map = new Map();
  for (const r of rows) {
    const k = r[nameKey] ?? '—';
    map.set(k, (map.get(k) || 0) + (Number(r[valKey]) || 0));
  }
  return [...map.entries()].map(([name, value]) => ({ name, value }));
}

export function AdminDashboard({ ctx, h }) {
  const roles = useActionData('accountsByRole', { token: ctx.token, body: { pageSize: 50 } });
  const roleData = sumByKey(roles.rows, 'RoleCode', 'AccountCount');
  return (
    <div className="ui-stack">
      <PageHeader icon={<AdminIcon size={22} />} title="Tổng quan quản trị" subtitle="Tài khoản, vai trò và hoạt động hệ thống gần nhất." />
      <DashboardStats actionId="adminDashboard" token={ctx.token} accents={['brand', 'bad', 'info', 'warn']} />
      {h.has('accountsByRole') && (
        <Card>
          <CardHeader title="Tài khoản theo vai trò" subtitle="Số lượng tài khoản" />
          {roles.loading ? <Loader /> : roleData.length === 0
            ? <EmptyState icon={<ProfileIcon size={26} />} title="Chưa có dữ liệu tài khoản" />
            : <Donut data={roleData} nameKey="name" valueKey="value" height={300} />}
        </Card>
      )}
      <QuickReports h={h} token={ctx.token} onToast={ctx.onToast} reports={[
        { id: 'userRoleSummary', label: 'Tài khoản & vai trò', icon: <AdminIcon size={16} /> },
        { id: 'accountsByRole', label: 'Tài khoản theo vai trò', icon: <ProfileIcon size={16} /> },
        { id: 'auditLog', label: 'Nhật ký kiểm toán', icon: <ActivityIcon size={16} /> }
      ]} />
    </div>
  );
}

/* ------------------------------- Reports ------------------------------- */
export function AdminReports({ ctx, h }) {
  const available = [
    { id: 'accountsByRole', label: 'Theo vai trò', chart: (rows) => <Donut data={sumByKey(rows, 'RoleCode', 'AccountCount')} nameKey="name" valueKey="value" height={300} /> },
    { id: 'userRoleSummary', label: 'Danh sách tài khoản', chart: null },
    { id: 'auditLog', label: 'Nhật ký kiểm toán', chart: null }
  ].filter((r) => h.has(r.id));
  const [active, setActive] = useState(available[0]?.id);
  const cfg = available.find((r) => r.id === active) || available[0];

  return (
    <div className="ui-stack">
      <PageHeader icon={<ReportIcon size={22} />} title="Báo cáo quản trị" subtitle="Thống kê tài khoản, vai trò và kiểm toán — xuất PDF/CSV." />
      <Tabs tabs={available.map((r) => ({ id: r.id, label: r.label }))} active={active} onChange={setActive} />
      {cfg && <ReportView key={cfg.id} action={h.get(cfg.id)} token={ctx.token} chart={cfg.chart} />}
    </div>
  );
}

/* ------------------------------- Users ------------------------------- */
export function UsersScreen({ ctx, h }) {
  const { rows, loading, reload, summary } = useActionData('userRoleSummary', { token: ctx.token, body: { pageSize: 25 } });
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [create, setCreate] = useState(false);
  const [lock, setLock] = useState(null);
  const [unlock, setUnlock] = useState(null);
  const [reset, setReset] = useState(null);
  const [assign, setAssign] = useState(null);
  const [remove, setRemove] = useState(null);

  const baseCols = ['Username', 'FullName', 'Email', 'AccountStatus', 'RoleCodes'];
  const columns = [...baseCols, 'Thao tác'];

  function doSearch() { setPage(1); reload({ search, page: 1 }); }
  function go(p) { setPage(p); reload({ search, page: p }); }

  const isLocked = (s) => /locked|suspended/i.test(String(s));

  function renderCell(col, value, row) {
    if (col === 'Thao tác') {
      return (
        <div className="row-actions">
          {h.has('lockUser') && !isLocked(row.AccountStatus) && <Button variant="ghost" className="ui-btn-sm" icon={<LockIcon size={13} />} sqlHint={SQL_HINTS.lockUser} onClick={() => setLock(row)}>Khoá</Button>}
          {h.has('unlockUser') && isLocked(row.AccountStatus) && <Button variant="soft" className="ui-btn-sm" icon={<UnlockIcon size={13} />} sqlHint={SQL_HINTS.unlockUser} onClick={() => setUnlock(row)}>Mở</Button>}
          {h.has('resetPassword') && <Button variant="ghost" className="ui-btn-sm" sqlHint={SQL_HINTS.adminResetPassword} onClick={() => setReset(row)}>Reset</Button>}
          {h.has('assignRole') && <Button variant="ghost" className="ui-btn-sm" sqlHint={SQL_HINTS.assignRole} onClick={() => setAssign(row)}>+Vai trò</Button>}
          {h.has('removeRole') && <Button variant="ghost" className="ui-btn-sm" sqlHint={SQL_HINTS.removeRole} onClick={() => setRemove(row)}>−Vai trò</Button>}
        </div>
      );
    }
    if (isStatusColumn(col) && value != null) return <Badge value={value} />;
    return formatValue(value);
  }

  return (
    <div className="ui-stack">
      <PageHeader icon={<AdminIcon size={22} />} title="Quản lý người dùng" subtitle="Tài khoản, trạng thái và vai trò. Thao tác trực tiếp trên từng dòng."
        actions={h.has('createUser') && <Button icon={<PlusIcon size={16} />} sqlHint={SQL_HINTS.createUser} onClick={() => setCreate(true)}>Tạo tài khoản</Button>} />
      <div className="ui-toolbar">
        <SearchInput value={search} onChange={setSearch} onSubmit={doSearch} placeholder="Tìm theo tên, email, vai trò..." />
      </div>

      {loading ? <Loader /> : rows.length === 0 ? <EmptyState title="Không có người dùng" /> : (
        <DataTable
          columns={columns}
          rows={rows}
          renderCell={renderCell}
          page={summary.page || page}
          totalPages={summary.totalPages || 1}
          onPage={go}
          meta={{ left: `${summary.totalRows ?? rows.length} tài khoản`, right: `Trang ${summary.page || page} / ${summary.totalPages || 1}` }}
        />
      )}

      {h.has('createUser') && <ActionModal action={h.get('createUser')} open={create} onClose={() => setCreate(false)} token={ctx.token} onToast={ctx.onToast} onDone={() => go(page)} submitLabel="Tạo tài khoản" columns={2} />}
      {h.has('lockUser') && <ConfirmAction action={h.get('lockUser')} open={Boolean(lock)} onClose={() => setLock(null)} params={lock ? { UserID: lock.UserID } : {}} danger title="Khoá tài khoản" message={lock ? `Khoá tài khoản ${lock.Username}?` : ''} token={ctx.token} onToast={ctx.onToast} onDone={() => go(page)} />}
      {h.has('unlockUser') && <ConfirmAction action={h.get('unlockUser')} open={Boolean(unlock)} onClose={() => setUnlock(null)} params={unlock ? { UserID: unlock.UserID } : {}} title="Mở khoá tài khoản" message={unlock ? `Mở khoá tài khoản ${unlock.Username}?` : ''} token={ctx.token} onToast={ctx.onToast} onDone={() => go(page)} />}
      {h.has('resetPassword') && <ActionModal action={h.get('resetPassword')} open={Boolean(reset)} onClose={() => setReset(null)} initial={reset ? { UserID: reset.UserID } : {}} title={reset ? `Reset mật khẩu · ${reset.Username}` : 'Reset mật khẩu'} token={ctx.token} onToast={ctx.onToast} onDone={() => go(page)} submitLabel="Cập nhật mật khẩu" />}
      {h.has('assignRole') && <ActionModal action={h.get('assignRole')} open={Boolean(assign)} onClose={() => setAssign(null)} initial={assign ? { UserID: assign.UserID } : {}} title={assign ? `Gán vai trò · ${assign.Username}` : 'Gán vai trò'} token={ctx.token} onToast={ctx.onToast} onDone={() => go(page)} submitLabel="Gán vai trò" />}
      {h.has('removeRole') && <ActionModal action={h.get('removeRole')} open={Boolean(remove)} onClose={() => setRemove(null)} initial={remove ? { UserID: remove.UserID } : {}} title={remove ? `Gỡ vai trò · ${remove.Username}` : 'Gỡ vai trò'} token={ctx.token} onToast={ctx.onToast} onDone={() => go(page)} submitLabel="Gỡ vai trò" />}
    </div>
  );
}

/* ------------------------------- Audit feed ------------------------------- */
export function AuditFeed({ ctx }) {
  const { rows, loading } = useActionData('auditLog', { token: ctx.token, body: { pageSize: 40 } });
  return (
    <div className="ui-stack">
      <PageHeader icon={<ActivityIcon size={22} />} title="Nhật ký kiểm toán" subtitle="Lịch sử thay đổi dữ liệu và thao tác bảo mật gần nhất." />
      {loading ? <Loader /> : rows.length === 0 ? <EmptyState title="Chưa có nhật ký" /> : (
        <div className="feed">
          {rows.map((r) => (
            <Card key={r.AuditID} className="feed-item">
              <div className="feed-dot"><Badge value={r.ActionType} /></div>
              <div className="feed-main">
                <strong>{r.SchemaName}.{r.TableName} <span className="muted-line" style={{ display: 'inline' }}>#{r.RecordID}</span></strong>
                <span className="muted-line">Bởi {r.ChangedBy} · {formatDate(r.ChangedAt)}</span>
              </div>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
