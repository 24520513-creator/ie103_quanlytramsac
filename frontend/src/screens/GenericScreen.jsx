import React, { useEffect, useState } from 'react';
import { runAction, downloadReportPdf, downloadCsv, importJson } from '../lib/api';
import { formatValue, isStatusColumn } from '../lib/format';
import { friendlyError } from '../lib/errors';
import { Badge, Button, PageHeader, DataTable, StatTile, Modal } from '../components/ui';
import { Field } from '../components/ui/ActionForm';
import { getGroupIcon, DownloadIcon, UploadIcon, BoltIcon, RefreshIcon } from '../components/Icons';

/** Fallback renderer for any action without a bespoke screen. */
export function GenericScreen({ action, token, onToast }) {
  const [form, setForm] = useState(() => defaultForm(action));
  const [data, setData] = useState(null);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [importOpen, setImportOpen] = useState(false);
  const [importText, setImportText] = useState('[\n  {\n  }\n]');
  const [busy, setBusy] = useState(false);
  const [confirmState, setConfirmState] = useState(null); // { message, onConfirm }
  const isDashboard = action.group === 'dashboard';
  const isQuery = action.kind === 'query';

  useEffect(() => {
    setForm(defaultForm(action)); setData(null); setSearch(''); setPage(1); setImportOpen(false); setConfirmState(null);
  }, [action.id]);

  useEffect(() => {
    if (action.kind === 'query' || action.kind === 'static' || isDashboard || action.params.length === 0) {
      run({ silent: true });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [action.id, page]);

  async function run({ silent = false } = {}) {
    setBusy(true);
    try {
      const json = await runAction(action.id, { ...form, search, page, pageSize: action.pageSize || 25 }, token);
      setData(json);
      if (!silent) onToast(json.message || 'Thực hiện thành công.', 'success');
    } catch (error) {
      onToast(friendlyError(error), 'error');
    } finally {
      setBusy(false);
    }
  }

  // Confirm destructive/explicit actions via a styled modal instead of window.confirm.
  function requestRun() {
    if (action.confirm) {
      setConfirmState({
        message: `Xác nhận thực hiện: ${action.title}?`,
        confirmLabel: 'Thực hiện',
        onConfirm: () => { setConfirmState(null); run(); }
      });
    } else {
      run();
    }
  }

  async function exportFile(kind) {
    setBusy(true);
    try {
      if (kind === 'pdf') await downloadReportPdf(action.id, { ...form, search }, token);
      else await downloadCsv(action.id, { ...form, search }, token);
    } catch (error) { onToast(friendlyError(error), 'error'); } finally { setBusy(false); }
  }

  function requestImport() {
    setConfirmState({
      message: `Xác nhận import dữ liệu cho: ${action.title}?`,
      confirmLabel: 'Chạy import',
      onConfirm: () => { setConfirmState(null); doImport(); }
    });
  }

  async function doImport() {
    setBusy(true);
    try {
      setData(await importJson(action.id, JSON.parse(importText), token));
      onToast('Import đã xử lý xong.', 'success');
    } catch (error) { onToast(friendlyError(error), 'error'); } finally { setBusy(false); }
  }

  const columns = (action.columns?.length ? action.columns : data?.columns) || [];

  return (
    <div className="ui-stack">
      <PageHeader
        icon={getGroupIcon(action.group, { size: 22 })}
        title={action.title}
        subtitle={action.description}
        actions={(
          <>
            {action.importable && <Button variant="ghost" icon={<UploadIcon size={16} />} onClick={() => setImportOpen((v) => !v)} disabled={busy}>Import JSON</Button>}
            {action.exportable && <Button variant="ghost" icon={<DownloadIcon size={16} />} onClick={() => exportFile('csv')} disabled={busy}>Tải CSV</Button>}
            {action.report && <Button variant="secondary" icon={<DownloadIcon size={16} />} onClick={() => exportFile('pdf')} disabled={busy}>Tải PDF</Button>}
            <Button onClick={requestRun} disabled={busy} icon={isQuery ? <RefreshIcon size={16} /> : null}>
              {busy ? 'Đang xử lý...' : isQuery ? 'Làm mới' : 'Thực hiện'}
            </Button>
          </>
        )}
      />

      {importOpen && (
        <div className="importBox">
          <label>Danh sách bản ghi JSON<textarea value={importText} onChange={(e) => setImportText(e.target.value)} /></label>
          <button onClick={requestImport} disabled={busy}>Chạy import</button>
        </div>
      )}

      {isDashboard && data?.rows?.length > 0 && (
        <div className="ui-grid ui-grid-stats">
          {data.rows.map((row, i) => (
            <StatTile key={i} icon={<BoltIcon size={18} />} label={row.ChiSo || Object.values(row)[0]} value={formatValue(row.GiaTri ?? Object.values(row)[1])} unit={row.DonVi || ''} />
          ))}
        </div>
      )}

      {!isDashboard && (action.params.length > 0 || action.kind === 'query') && (
        <div className="toolbox">
          {action.kind === 'query' && (
            <label className="searchBox">Tìm kiếm
              <input value={search} onChange={(e) => setSearch(e.target.value)} onKeyDown={(e) => { if (e.key === 'Enter') { setPage(1); run(); } }} placeholder="Nhập từ khóa..." />
            </label>
          )}
          {action.params.length > 0 && (
            <div className="ui-form-grid cols-2">
              {action.params.map((p) => (
                <Field
                  key={p.name}
                  param={p}
                  value={form[p.name]}
                  values={form}
                  token={token}
                  onPatch={(patch) => setForm((prev) => ({ ...prev, ...patch }))}
                  onChange={(v) => setForm((prev) => ({ ...prev, [p.name]: v }))}
                />
              ))}
            </div>
          )}
        </div>
      )}

      {data && !isDashboard && (
        <DataTable
          columns={columns}
          rows={data.rows || []}
          page={data.summary?.page || page}
          totalPages={data.summary?.totalPages || 1}
          onPage={action.kind === 'query' ? setPage : undefined}
          renderCell={(c, v) => (isStatusColumn(c) && v != null ? <Badge value={v} /> : formatValue(v))}
          meta={{ left: `${data.summary?.totalRows ?? (data.rows?.length || 0)} dòng dữ liệu`, right: `Trang ${data.summary?.page || page} / ${data.summary?.totalPages || 1}` }}
        />
      )}

      <Modal
        open={Boolean(confirmState)}
        title="Xác nhận thao tác"
        onClose={() => setConfirmState(null)}
        footer={(
          <>
            <Button variant="ghost" onClick={() => setConfirmState(null)} disabled={busy}>Huỷ</Button>
            <Button onClick={() => confirmState?.onConfirm?.()} disabled={busy}>{confirmState?.confirmLabel || 'Xác nhận'}</Button>
          </>
        )}
      >
        <p style={{ fontSize: 14, lineHeight: 1.6, color: 'var(--text-main)' }}>{confirmState?.message}</p>
      </Modal>
    </div>
  );
}

function defaultForm(action) {
  return Object.fromEntries((action.params || []).map((p) => [p.name, p.defaultValue ?? '']));
}
