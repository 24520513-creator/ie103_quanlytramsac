import React, { useState } from 'react';
import { Zap } from 'lucide-react';
import { api } from '../../services/api';

interface ResetPasswordPageProps {
  token: string;
  onSwitchToLogin: () => void;
}

export default function ResetPasswordPage({ token, onSwitchToLogin }: ResetPasswordPageProps) {
  const [form, setForm] = useState({ Password: '', ConfirmPassword: '' });
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [loading, setLoading] = useState(false);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => setForm({ ...form, [e.target.name]: e.target.value });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    if (!token) { setError('Missing reset token'); return; }
    if (form.Password !== form.ConfirmPassword) { setError('Passwords do not match'); return; }
    setLoading(true);
    try {
      await api.post('/auth/reset-password', { Token: token, Password: form.Password });
      setSuccess('Password has been reset successfully!');
    } catch (err: any) {
      setError(err.message || 'Failed to reset password');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-600 to-indigo-800 flex items-center justify-center p-4">
      <div className="bg-white rounded-3xl shadow-2xl w-full max-w-md p-8">
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-blue-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <Zap className="w-8 h-8 text-blue-600 fill-current" />
          </div>
          <h1 className="text-2xl font-bold text-slate-900">Reset Password</h1>
          <p className="text-slate-500 mt-1">Enter your new password</p>
        </div>

        {error && <div className="bg-red-50 border border-red-100 text-red-600 text-sm p-3 rounded-xl mb-4">{error}</div>}
        {success && <div className="bg-green-50 border border-green-100 text-green-600 text-sm p-3 rounded-xl mb-4">{success}</div>}

        {!success && (
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-xs font-bold text-slate-500 uppercase mb-1.5">New Password</label>
              <input type="password" name="Password" value={form.Password} onChange={handleChange} placeholder="Enter new password" required minLength={6} className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-500 uppercase mb-1.5">Confirm Password</label>
              <input type="password" name="ConfirmPassword" value={form.ConfirmPassword} onChange={handleChange} placeholder="Confirm new password" required minLength={6} className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <button type="submit" disabled={loading} className="w-full py-3 bg-blue-600 text-white font-bold rounded-xl hover:bg-blue-700 transition-all shadow-lg shadow-blue-200 disabled:opacity-50">
              {loading ? 'Resetting...' : 'Reset Password'}
            </button>
          </form>
        )}

        <div className="text-center mt-6">
          <button type="button" onClick={onSwitchToLogin} className="text-sm text-blue-600 font-bold hover:underline">
            Back to Sign in
          </button>
        </div>
      </div>
    </div>
  );
}
