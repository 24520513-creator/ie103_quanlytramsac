import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { login, registerCustomer, requestPasswordReset, requireAuth, resetPassword, verifyEmail } from './auth.js';
import { actions, publicCatalogFor } from './catalog.js';
import { runAction } from './actionRunner.js';
import { getLookupOptions } from './lookups.js';
import { buildReportPdf } from './pdf.js';
import { buildCsvExport } from './csv.js';
import { config } from './config.js';
import { withSession } from './db.js';

const app = express();
const authBuckets = new Map();

app.use(helmet());
app.use(cors({
  origin: [config.frontendUrl, 'http://127.0.0.1:3000', 'http://localhost:3000'],
  credentials: true
}));
app.use(express.json({ limit: '1mb' }));

function authRateLimit(req, res, next) {
  const key = `${req.ip}:${req.body?.username || req.body?.identifier || req.body?.email || ''}`;
  const now = Date.now();
  const windowMs = 15 * 60 * 1000;
  const maxAttempts = 20;
  const bucket = authBuckets.get(key) || { count: 0, resetAt: now + windowMs };
  if (bucket.resetAt < now) {
    bucket.count = 0;
    bucket.resetAt = now + windowMs;
  }
  bucket.count += 1;
  authBuckets.set(key, bucket);
  if (bucket.count > maxAttempts) return res.status(429).json({ message: 'Bạn thao tác quá nhanh. Vui lòng thử lại sau.' });
  next();
}

function setAuthCookie(res, token) {
  res.cookie(config.auth.cookieName, token, {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    maxAge: config.auth.cookieMaxAgeMs
  });
}

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', service: 'ev-charging-backend' });
});

app.post('/api/auth/login', authRateLimit, async (req, res, next) => {
  try {
    const { username, identifier, password } = req.body;
    const result = await login(identifier || username, password);
    setAuthCookie(res, result.token);
    res.json(result);
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/register', authRateLimit, async (req, res, next) => {
  try {
    res.status(201).json(await registerCustomer(req.body));
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/logout', (req, res) => {
  res.clearCookie(config.auth.cookieName, {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production'
  });
  res.json({ message: 'Đã đăng xuất.' });
});

app.post('/api/auth/forgot-password', authRateLimit, async (req, res, next) => {
  try {
    res.json(await requestPasswordReset(req.body.identifier || req.body.email || req.body.username));
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/reset-password', authRateLimit, async (req, res, next) => {
  try {
    res.json(await resetPassword(req.body.token, req.body.password));
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/verify-email', authRateLimit, async (req, res, next) => {
  try {
    res.json(await verifyEmail(req.body.token));
  } catch (error) {
    next(error);
  }
});

app.get('/api/me', requireAuth, async (req, res, next) => {
  try {
    const data = await runAction('me', req.user, {});
    res.json({
      user: {
        ...req.user,
        profile: data.rows[0] || null
      }
    });
  } catch (error) {
    next(error);
  }
});

app.get('/api/actions', requireAuth, (req, res) => {
  res.json({ actions: publicCatalogFor(req.user.roleCode), user: req.user });
});

app.post('/api/lookups/:key', requireAuth, async (req, res, next) => {
  try {
    const data = await withSession(req.user, (transaction) => (
      getLookupOptions(req.params.key, req.user, req.body || {}, transaction)
    ));
    res.json(data);
  } catch (error) {
    next(error);
  }
});

app.post('/api/actions/:id', requireAuth, async (req, res, next) => {
  try {
    res.json(await runAction(req.params.id, req.user, req.body));
  } catch (error) {
    next(error);
  }
});

app.post('/api/reports/:id/pdf', requireAuth, async (req, res, next) => {
  try {
    const pdf = await buildReportPdf(req.params.id, req.user, req.body);
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="${req.params.id}.pdf"`);
    res.send(pdf);
  } catch (error) {
    next(error);
  }
});

app.post('/api/exports/:id/csv', requireAuth, async (req, res, next) => {
  try {
    const csv = await buildCsvExport(req.params.id, req.user, req.body);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${req.params.id}.csv"`);
    res.send(csv);
  } catch (error) {
    next(error);
  }
});

app.post('/api/imports/:id/json', requireAuth, async (req, res, next) => {
  try {
    const action = actions[req.params.id];
    if (!action?.importable || action.kind !== 'procedure') {
      const error = new Error('Chức năng này không hỗ trợ import hàng loạt.');
      error.statusCode = 400;
      throw error;
    }

    const rows = Array.isArray(req.body?.rows) ? req.body.rows.slice(0, 100) : [];
    if (rows.length === 0) throw new Error('Dữ liệu import phải có mảng rows.');

    const results = [];
    for (let index = 0; index < rows.length; index += 1) {
      try {
        await runAction(req.params.id, req.user, rows[index]);
        results.push({ rowIndex: index, status: 'ok', message: 'Thành công' });
      } catch (error) {
        results.push({ rowIndex: index, status: 'error', message: error.originalError?.info?.message || error.message });
      }
    }

    res.json({
      columns: ['rowIndex', 'status', 'message'],
      rows: results,
      summary: {
        rowCount: results.length,
        successCount: results.filter((item) => item.status === 'ok').length,
        errorCount: results.filter((item) => item.status === 'error').length
      },
      message: 'Import đã xử lý xong.'
    });
  } catch (error) {
    next(error);
  }
});

app.use((error, req, res, next) => {
  const statusCode = error.statusCode || 400;
  res.status(statusCode).json({
    message: error.originalError?.info?.message || error.message || 'Có lỗi xảy ra.'
  });
});

app.listen(config.port, () => {
  console.log(`Backend listening on port ${config.port}`);
});
