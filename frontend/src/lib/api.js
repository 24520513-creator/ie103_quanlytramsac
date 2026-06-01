export const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

function authHeaders(token, base = {}) {
  const headers = { ...base };
  if (token) headers.Authorization = `Bearer ${token}`;
  return headers;
}

export async function apiGet(path, token) {
  const res = await fetch(`${API_URL}${path}`, { headers: authHeaders(token), credentials: 'include' });
  const json = await res.json();
  if (!res.ok) throw new Error(json.message || 'Không tải được dữ liệu.');
  return json;
}

export async function postJson(path, body, token) {
  const res = await fetch(`${API_URL}${path}`, {
    method: 'POST',
    headers: authHeaders(token, { 'Content-Type': 'application/json' }),
    credentials: 'include',
    body: JSON.stringify(body)
  });
  const json = await res.json();
  if (!res.ok) throw new Error(json.message || 'Không thực hiện được.');
  return json;
}

/** Run a catalog action by id and return its normalized result. */
export function runAction(actionId, body, token) {
  return postJson(`/api/actions/${actionId}`, body, token);
}

export function fetchLookup(key, body, token) {
  return postJson(`/api/lookups/${key}`, body, token);
}

export async function logoutRequest() {
  await fetch(`${API_URL}/api/auth/logout`, { method: 'POST', credentials: 'include' }).catch(() => {});
}

export async function downloadFile(path, filename, body, token) {
  const res = await fetch(`${API_URL}${path}`, {
    method: 'POST',
    headers: authHeaders(token, { 'Content-Type': 'application/json' }),
    credentials: 'include',
    body: JSON.stringify(body)
  });
  if (!res.ok) {
    let message = 'Không tải được tệp.';
    try { message = (await res.json()).message || message; } catch { /* ignore */ }
    throw new Error(message);
  }
  const blob = await res.blob();
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

export function downloadReportPdf(actionId, body, token) {
  return downloadFile(`/api/reports/${actionId}/pdf`, `${actionId}.pdf`, { ...body, pageSize: 80 }, token);
}

export function downloadCsv(actionId, body, token) {
  return downloadFile(`/api/exports/${actionId}/csv`, `${actionId}.csv`, { ...body, pageSize: 100 }, token);
}

export function importJson(actionId, rows, token) {
  return postJson(`/api/imports/${actionId}/json`, { rows }, token);
}
