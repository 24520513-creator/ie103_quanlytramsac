import { useState, type FormEvent } from 'react';
import { useSearchParams, Link } from 'react-router-dom';
import { Zap, ArrowLeft } from 'lucide-react';
import { api } from '../../services/api';

export default function ResetPasswordPage() {
  const [searchParams] = useSearchParams();
  const token = searchParams.get('token') || '';
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    if (password !== confirm) { setError('Passwords do not match'); return; }
    if (!token) { setError('Invalid reset token'); return; }
    setLoading(true);
    try {
      await api.post('/auth/reset-password', { Token: token, Password: password });
      setSuccess('Password reset successful! You can now login.');
    } catch (err: any) {
      setError(err.message || 'Reset failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-600 to-indigo-800 flex items-center justify-center p-4">
      <div className="bg-white rounded-3xl shadow-2xl w-full max-w-md p-8">
        <div className="text-center mb-6">
          <div className="w-14 h-14 bg-blue-100 rounded-2xl flex items-center justify-center mx-auto mb-3">
            <Zap className="w-7 h-7 text-blue-600 fill-current" />
          </div>
          <h1 className="text-xl font-bold text-slate-900">Reset Password</h1>
        </div>
        {error && <div className="bg-red-50 border border-red-100 text-red-600 text-sm p-3 rounded-xl mb-3">{error}</div>}
        {success && <div className="bg-emerald-50 border border-emerald-100 text-emerald-600 text-sm p-3 rounded-xl mb-3">{success}</div>}
        {!success && (
          <form onSubmit={handleSubmit} className="space-y-4">
            <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="New password" required
              className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
            <input type="password" value={confirm} onChange={e => setConfirm(e.target.value)} placeholder="Confirm password" required
              className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
            <button type="submit" disabled={loading}
              className="w-full py-3 bg-blue-600 text-white font-bold rounded-xl hover:bg-blue-700 transition-all shadow-lg shadow-blue-200 disabled:opacity-50">
              {loading ? 'Resetting...' : 'Reset Password'}
            </button>
          </form>
        )}
        <div className="text-center mt-4">
          <Link to="/login" className="text-sm text-blue-600 hover:underline font-medium inline-flex items-center gap-1">
            <ArrowLeft className="w-4 h-4" /> Back to Login
          </Link>
        </div>
      </div>
    </div>
  );
}
