import React, { useState } from 'react';
import { Zap } from 'lucide-react';
import { api } from '../../services/api';

interface RegisterPageProps {
  onSwitchToLogin: () => void;
}

const ROLES = [
  { code: 'CUSTOMER', label: 'Customer', desc: 'End-user who charges vehicles' },
  { code: 'Operator', label: 'Operator', desc: 'Manages daily operations & sessions' },
  { code: 'Technician', label: 'Technician', desc: 'Handles maintenance & repairs' },
  { code: 'FranchiseOwner', label: 'Franchise Owner', desc: 'Views own franchise data & revenue' },
  { code: 'ReadOnly', label: 'Read-Only Auditor', desc: 'Read-only access for auditors' },
];

export default function RegisterPage({ onSwitchToLogin }: RegisterPageProps) {
  const [form, setForm] = useState({ Username: '', Email: '', FullName: '', Phone: '', Password: '', ConfirmPassword: '', RoleCode: 'CUSTOMER' });
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [loading, setLoading] = useState(false);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => setForm({ ...form, [e.target.name]: e.target.value });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    if (form.Password !== form.ConfirmPassword) {
      setError('Passwords do not match');
      return;
    }
    setLoading(true);
    try {
      await api.post('/auth/register', {
        Username: form.Username,
        Email: form.Email,
        FullName: form.FullName,
        Phone: form.Phone || undefined,
        Password: form.Password,
        RoleCode: form.RoleCode,
      });
      setSuccess(`Registration successful! You can now sign in.`);
      setForm({ Username: '', Email: '', FullName: '', Phone: '', Password: '', ConfirmPassword: '', RoleCode: 'CUSTOMER' });
    } catch (err: any) {
      setError(err.message || 'Registration failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-600 to-indigo-800 flex items-center justify-center p-4">
      <div className="bg-white rounded-3xl shadow-2xl w-full max-w-lg p-8">
        <div className="text-center mb-6">
          <div className="w-16 h-16 bg-blue-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <Zap className="w-8 h-8 text-blue-600 fill-current" />
          </div>
          <h1 className="text-2xl font-bold text-slate-900">Create Account</h1>
          <p className="text-slate-500 mt-1">Register for EVCharge Pro</p>
        </div>

        {error && <div className="bg-red-50 border border-red-100 text-red-600 text-sm p-3 rounded-xl mb-4">{error}</div>}
        {success && <div className="bg-green-50 border border-green-100 text-green-600 text-sm p-3 rounded-xl mb-4">{success}</div>}

        {!success && (
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-bold text-slate-500 uppercase mb-1.5">Username *</label>
                <input type="text" name="Username" value={form.Username} onChange={handleChange} placeholder="Username" required className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-500 uppercase mb-1.5">Full Name *</label>
                <input type="text" name="FullName" value={form.FullName} onChange={handleChange} placeholder="Your name" required className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
              </div>
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-500 uppercase mb-1.5">Email *</label>
              <input type="email" name="Email" value={form.Email} onChange={handleChange} placeholder="your@email.com" required className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-500 uppercase mb-1.5">Phone</label>
              <input type="tel" name="Phone" value={form.Phone} onChange={handleChange} placeholder="Optional" className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-500 uppercase mb-1.5">Role *</label>
              <select name="RoleCode" value={form.RoleCode} onChange={handleChange} className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500 text-slate-900">
                {ROLES.map(r => (
                  <option key={r.code} value={r.code} title={r.desc}>{r.label}</option>
                ))}
              </select>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-bold text-slate-500 uppercase mb-1.5">Password *</label>
                <input type="password" name="Password" value={form.Password} onChange={handleChange} placeholder="Min 6 chars" required minLength={6} className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-500 uppercase mb-1.5">Confirm *</label>
                <input type="password" name="ConfirmPassword" value={form.ConfirmPassword} onChange={handleChange} placeholder="Repeat password" required minLength={6} className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
              </div>
            </div>
            <button type="submit" disabled={loading} className="w-full py-3 bg-blue-600 text-white font-bold rounded-xl hover:bg-blue-700 transition-all shadow-lg shadow-blue-200 disabled:opacity-50">
              {loading ? 'Creating account...' : 'Register'}
            </button>
          </form>
        )}

        <div className="text-center mt-6">
          <p className="text-sm text-slate-500">
            Already have an account?{' '}
            <button type="button" onClick={onSwitchToLogin} className="text-blue-600 font-bold hover:underline">Sign in</button>
          </p>
        </div>
      </div>
    </div>
  );
}
