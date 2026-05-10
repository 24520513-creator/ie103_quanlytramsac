import React, { useState } from 'react';
import { Zap } from 'lucide-react';
import { api } from '../../services/api';

interface ForgotPasswordPageProps {
  onSwitchToLogin: () => void;
  onSwitchToReset: (token: string) => void;
}

export default function ForgotPasswordPage({ onSwitchToLogin, onSwitchToReset }: ForgotPasswordPageProps) {
  const [email, setEmail] = useState('');
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [resetToken, setResetToken] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setMessage('');
    setResetToken('');
    setLoading(true);
    try {
      const res = await api.post('/auth/forgot-password', { Email: email });
      setMessage(res.data.message);
      if (res.data.resetToken) {
        setResetToken(res.data.resetToken);
      }
    } catch (err: any) {
      setError(err.message || 'Failed to send reset email.');
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
          <h1 className="text-2xl font-bold text-slate-900">Forgot Password</h1>
          <p className="text-slate-500 mt-1">Enter your email to receive a reset link</p>
        </div>

        {error && <div className="bg-red-50 border border-red-100 text-red-600 text-sm p-3 rounded-xl mb-4">{error}</div>}
        {message && <div className="bg-green-50 border border-green-100 text-green-600 text-sm p-3 rounded-xl mb-4">{message}</div>}

        {resetToken && (
          <div className="bg-blue-50 border border-blue-100 text-blue-700 text-sm p-4 rounded-xl mb-4 break-all">
            <strong>Reset token (dev mode):</strong><br />
            <button type="button" onClick={() => onSwitchToReset(resetToken)} className="text-blue-600 font-bold hover:underline mt-1 block">
              Click here to reset your password
            </button>
          </div>
        )}

        {!message && (
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-xs font-bold text-slate-500 uppercase mb-1.5">Email</label>
              <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="Enter your email" required className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <button type="submit" disabled={loading} className="w-full py-3 bg-blue-600 text-white font-bold rounded-xl hover:bg-blue-700 transition-all shadow-lg shadow-blue-200 disabled:opacity-50">
              {loading ? 'Sending...' : 'Send Reset Link'}
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
