import React, { useMemo, useState } from 'react';
import { API_URL } from '../../lib/api';
import { demoUsers } from '../../config';
import { passwordStrength, validateRegister } from '../../lib/auth';
import { EyeIcon, EyeOffIcon } from '../../components/Icons';
import { SqlTooltip } from '../../components/SqlTooltip';
import { SQL_HINTS } from '../../lib/sqlHints';

const REMEMBER_KEY = 'evcharge:rememberedIdentifier';

async function authPost(path, body) {
  const res = await fetch(`${API_URL}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    credentials: 'include',
    body: JSON.stringify(body)
  });
  const json = await res.json();
  if (!res.ok) throw new Error(json.message || 'Có lỗi xảy ra.');
  return json;
}

export function AuthPage({ onLogin }) {
  const resetToken = useMemo(() => new URLSearchParams(window.location.search).get('token') || '', []);
  const [mode, setMode] = useState(resetToken ? 'reset' : 'login');

  return (
    <main className="login">
      <section className="loginBox authBox">
        <div className="authHeader">
          <div className="brandMark">EV</div>
          <div>
            <h1>EVCharge Pro</h1>
            <p>Đăng nhập hoặc tạo tài khoản khách hàng để sử dụng dịch vụ sạc điện.</p>
          </div>
        </div>

        {mode !== 'reset' && (
          <div className="authTabs">
            <button type="button" className={mode === 'login' ? 'active' : ''} onClick={() => setMode('login')}>Đăng nhập</button>
            <button type="button" className={mode === 'register' ? 'active' : ''} onClick={() => setMode('register')}>Đăng kí</button>
          </div>
        )}

        {mode === 'login' && <LoginForm onLogin={onLogin} onForgot={() => setMode('forgot')} />}
        {mode === 'register' && <RegisterForm onDone={() => setMode('login')} />}
        {mode === 'forgot' && <ForgotPasswordForm onBack={() => setMode('login')} />}
        {mode === 'reset' && <ResetPasswordForm token={resetToken} onDone={() => setMode('login')} />}
      </section>
    </main>
  );
}

function LoginForm({ onLogin, onForgot }) {
  const remembered = useMemo(() => {
    try { return localStorage.getItem(REMEMBER_KEY) || ''; } catch { return ''; }
  }, []);
  const [form, setForm] = useState({ identifier: remembered, password: '' });
  const [remember, setRemember] = useState(Boolean(remembered));
  const [showPassword, setShowPassword] = useState(false);
  const [message, setMessage] = useState('');
  const [busy, setBusy] = useState(false);

  async function submit(event) {
    event.preventDefault();
    setMessage('');
    if (!form.identifier.trim() || !form.password) {
      setMessage('Vui lòng nhập đầy đủ thông tin đăng nhập.');
      return;
    }
    setBusy(true);
    try {
      const result = await authPost('/api/auth/login', form);
      try {
        if (remember) localStorage.setItem(REMEMBER_KEY, form.identifier.trim());
        else localStorage.removeItem(REMEMBER_KEY);
      } catch { /* storage may be unavailable */ }
      onLogin(result);
    } catch (error) {
      setMessage(error.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit} className="authForm">
      <label>Tên đăng nhập, email hoặc số điện thoại
        <input autoComplete="username" value={form.identifier} onChange={(e) => setForm({ ...form, identifier: e.target.value })} />
      </label>
      <label>Mật khẩu
        <div className="passwordField">
          <input type={showPassword ? 'text' : 'password'} autoComplete="current-password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} />
          <button type="button" onClick={() => setShowPassword((v) => !v)} aria-label="Hiện/ẩn mật khẩu">{showPassword ? <EyeOffIcon size={16} /> : <EyeIcon size={16} />}</button>
        </div>
      </label>
      <div className="authActions">
        <label className="checkLabel"><input type="checkbox" checked={remember} onChange={(e) => setRemember(e.target.checked)} />Ghi nhớ tài khoản trên thiết bị này</label>
        <button type="button" className="linkButton" onClick={onForgot}>Quên mật khẩu?</button>
      </div>
      <SqlTooltip hint={SQL_HINTS.login}><button className="primaryButton" disabled={busy}>{busy ? 'Đang đăng nhập...' : 'Đăng nhập'}</button></SqlTooltip>
      {import.meta.env.DEV && (
        <div className="demoGrid">
          {demoUsers.map(([username, label]) => (
            <button type="button" key={username} onClick={() => setForm({ identifier: username, password: 'password' })}>{label}</button>
          ))}
        </div>
      )}
      {message && <p className="error">{message}</p>}
    </form>
  );
}

function RegisterForm({ onDone }) {
  const [form, setForm] = useState({ fullName: '', username: '', email: '', phone: '', password: '', confirmPassword: '', acceptedTerms: false });
  const [showPassword, setShowPassword] = useState(false);
  const [message, setMessage] = useState('');
  const [busy, setBusy] = useState(false);
  const strength = passwordStrength(form.password);

  async function submit(event) {
    event.preventDefault();
    setMessage('');
    const error = validateRegister(form);
    if (error) { setMessage(error); return; }
    setBusy(true);
    try {
      const json = await authPost('/api/auth/register', form);
      setMessage(json.message || 'Đăng kí thành công.');
      setTimeout(onDone, 700);
    } catch (error) {
      setMessage(error.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit} className="authForm">
      <div className="formGrid two">
        <label>Họ và tên *<input value={form.fullName} onChange={(e) => setForm({ ...form, fullName: e.target.value })} /></label>
        <label>Tên đăng nhập *<input autoComplete="username" value={form.username} onChange={(e) => setForm({ ...form, username: e.target.value })} /></label>
        <label>Email *<input type="email" autoComplete="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} /></label>
        <label>Số điện thoại<input autoComplete="tel" value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} /></label>
      </div>
      <label>Mật khẩu *
        <div className="passwordField">
          <input type={showPassword ? 'text' : 'password'} autoComplete="new-password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} />
          <button type="button" onClick={() => setShowPassword((v) => !v)} aria-label="Hiện/ẩn mật khẩu">{showPassword ? <EyeOffIcon size={16} /> : <EyeIcon size={16} />}</button>
        </div>
      </label>
      <PasswordMeter score={strength.score} label={strength.label} />
      <label>Nhập lại mật khẩu *<input type={showPassword ? 'text' : 'password'} autoComplete="new-password" value={form.confirmPassword} onChange={(e) => setForm({ ...form, confirmPassword: e.target.value })} /></label>
      <label className="checkLabel"><input type="checkbox" checked={form.acceptedTerms} onChange={(e) => setForm({ ...form, acceptedTerms: e.target.checked })} />Tôi đồng ý với điều khoản sử dụng dịch vụ.</label>
      <SqlTooltip hint={SQL_HINTS.register}><button className="primaryButton" disabled={busy}>{busy ? 'Đang tạo tài khoản...' : 'Tạo tài khoản khách hàng'}</button></SqlTooltip>
      {message && <p className={message.includes('thành công') ? 'success' : 'error'}>{message}</p>}
    </form>
  );
}

function ForgotPasswordForm({ onBack }) {
  const [identifier, setIdentifier] = useState('');
  const [message, setMessage] = useState('');
  const [busy, setBusy] = useState(false);

  async function submit(event) {
    event.preventDefault();
    setBusy(true);
    setMessage('');
    try {
      const json = await authPost('/api/auth/forgot-password', { identifier });
      setMessage(json.devResetToken ? `${json.message} Token dev: ${json.devResetToken}` : json.message);
    } catch (error) {
      setMessage(error.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit} className="authForm">
      <p>Nhập email, số điện thoại hoặc tên đăng nhập. Hệ thống sẽ gửi hướng dẫn đặt lại mật khẩu nếu thông tin hợp lệ.</p>
      <label>Thông tin tài khoản<input value={identifier} onChange={(e) => setIdentifier(e.target.value)} /></label>
      <SqlTooltip hint={SQL_HINTS.forgotPassword}><button className="primaryButton" disabled={busy}>{busy ? 'Đang gửi...' : 'Gửi hướng dẫn'}</button></SqlTooltip>
      <button type="button" className="linkButton left" onClick={onBack}>Quay lại đăng nhập</button>
      {message && <p className="success">{message}</p>}
    </form>
  );
}

function ResetPasswordForm({ token, onDone }) {
  const [form, setForm] = useState({ password: '', confirmPassword: '' });
  const [message, setMessage] = useState('');
  const [busy, setBusy] = useState(false);
  const strength = passwordStrength(form.password);

  async function submit(event) {
    event.preventDefault();
    setMessage('');
    if (!token) { setMessage('Token đặt lại mật khẩu không hợp lệ.'); return; }
    if (form.password !== form.confirmPassword) { setMessage('Mật khẩu nhập lại không khớp.'); return; }
    if (strength.score < 2) { setMessage('Mật khẩu chưa đạt yêu cầu bảo mật.'); return; }
    setBusy(true);
    try {
      const json = await authPost('/api/auth/reset-password', { token, password: form.password });
      setMessage(json.message);
      window.history.replaceState({}, '', window.location.pathname);
      setTimeout(onDone, 700);
    } catch (error) {
      setMessage(error.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit} className="authForm">
      <label>Mật khẩu mới<input type="password" autoComplete="new-password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} /></label>
      <PasswordMeter score={strength.score} label={strength.label} />
      <label>Nhập lại mật khẩu mới<input type="password" autoComplete="new-password" value={form.confirmPassword} onChange={(e) => setForm({ ...form, confirmPassword: e.target.value })} /></label>
      <SqlTooltip hint={SQL_HINTS.resetPassword}><button className="primaryButton" disabled={busy}>{busy ? 'Đang cập nhật...' : 'Cập nhật mật khẩu'}</button></SqlTooltip>
      {message && <p className={message.includes('cập nhật') ? 'success' : 'error'}>{message}</p>}
    </form>
  );
}

function PasswordMeter({ score, label }) {
  return (
    <div className="passwordMeter" data-score={score}>
      <span><i /></span>
      <strong>{label}</strong>
    </div>
  );
}
