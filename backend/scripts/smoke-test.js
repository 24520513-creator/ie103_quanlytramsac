const API_URL = process.env.API_URL || 'http://127.0.0.1:8000';

const users = [
  ['customer01', 'Customer', 'customerDashboard'],
  ['operator01', 'OperationsStaff', 'operationsDashboard'],
  ['business01', 'BusinessManager', 'businessDashboard'],
  ['franchise01', 'FranchisePartner', 'franchiseDashboard'],
  ['admin01', 'SystemAdmin', 'adminDashboard']
];

async function request(path, options = {}) {
  const res = await fetch(`${API_URL}${path}`, options);
  const contentType = res.headers.get('content-type') || '';
  const body = contentType.includes('application/json') ? await res.json() : await res.arrayBuffer();
  if (!res.ok) {
    const message = body?.message || `${res.status} ${res.statusText}`;
    throw new Error(`${path}: ${message}`);
  }
  return body;
}

async function requestBinary(path, options = {}, expectedType = '') {
  const res = await fetch(`${API_URL}${path}`, options);
  const contentType = res.headers.get('content-type') || '';
  const body = await res.arrayBuffer();
  if (!res.ok) {
    let message = `${res.status} ${res.statusText}`;
    try { message = JSON.parse(Buffer.from(body).toString('utf8')).message || message; } catch { /* ignore */ }
    throw new Error(`${path}: ${message}`);
  }
  if (expectedType && !contentType.includes(expectedType)) {
    throw new Error(`${path}: expected content-type ${expectedType}, got ${contentType}`);
  }
  return body;
}

async function login(username) {
  return request('/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password: 'password' })
  });
}

async function main() {
  const summary = [];
  for (const [username, expectedRole, dashboardAction] of users) {
    const auth = await login(username);
    if (auth.user.roleCode !== expectedRole) {
      throw new Error(`${username}: expected role ${expectedRole}, got ${auth.user.roleCode}`);
    }

    const headers = { Authorization: `Bearer ${auth.token}`, 'Content-Type': 'application/json' };
    const me = await request('/api/me', { headers });
    const catalog = await request('/api/actions', { headers });
    const dashboard = await request(`/api/actions/${dashboardAction}`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ page: 1, pageSize: 5 })
    });

    summary.push({
      username,
      role: expectedRole,
      fullName: me.user.profile?.FullName,
      actions: catalog.actions.length,
      dashboardRows: dashboard.summary.rowCount
    });
  }

  const customer = await login('customer01');
  const customerHeaders = { Authorization: `Bearer ${customer.token}`, 'Content-Type': 'application/json' };
  const forbidden = await fetch(`${API_URL}/api/actions/auditLog`, {
    method: 'POST',
    headers: customerHeaders,
    body: JSON.stringify({})
  });
  if (forbidden.status !== 403) throw new Error(`Expected customer auditLog to return 403, got ${forbidden.status}`);

  const business = await login('business01');
  const businessHeaders = { Authorization: `Bearer ${business.token}`, 'Content-Type': 'application/json' };
  const pdf = await requestBinary('/api/reports/regionRevenue/pdf', {
    method: 'POST',
    headers: businessHeaders,
    body: JSON.stringify({ pageSize: 5 })
  }, 'application/pdf');
  const csv = await request('/api/exports/regionRevenue/csv', {
    method: 'POST',
    headers: businessHeaders,
    body: JSON.stringify({ pageSize: 5 })
  });
  if (pdf.byteLength < 4000) throw new Error('PDF export returned too little data for a formatted report');
  if (csv.byteLength < 20) throw new Error('CSV export returned too little data');

  console.table(summary);
  console.log('Smoke test passed.');
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
