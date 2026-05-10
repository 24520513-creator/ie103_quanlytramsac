import React, { useState } from 'react';
import { Zap } from 'lucide-react';
import { api } from '../../services/api';

interface LoginPageProps {
  onLogin: (user: any, token: string) => void;
  onSwitchToRegister: () => void;
  onSwitchToForgotPassword: () => void;
}

export default function LoginPage({ onLogin, onSwitchToRegister, onSwitchToForgotPassword }: LoginPageProps) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const res = await api.post('/auth/login', { Email: email, Password: password });
      localStorage.setItem('token', res.data.token);
      onLogin(res.data.user, res.data.token);
    } catch (err: any) {
      setError(err.message || 'Login failed');
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
          <h1 className="text-2xl font-bold text-slate-900">EVCharge Pro</h1>
          <p className="text-slate-500 mt-1">Sign in to your account</p>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-100 text-red-600 text-sm p-3 rounded-xl mb-4">{error}</div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-bold text-slate-500 uppercase mb-1.5">Email or Username</label>
            <input
              type="text"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="Enter your email"
              required
              className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <div>
            <label className="block text-xs font-bold text-slate-500 uppercase mb-1.5">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Enter your password"
              required
              className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <div className="text-right">
            <button type="button" onClick={onSwitchToForgotPassword} className="text-sm text-blue-600 hover:underline font-medium">
              Forgot password?
            </button>
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 bg-blue-600 text-white font-bold rounded-xl hover:bg-blue-700 transition-all shadow-lg shadow-blue-200 disabled:opacity-50"
          >
            {loading ? 'Signing in...' : 'Sign In'}
          </button>
        </form>

        <div className="text-center mt-6">
          <p className="text-sm text-slate-500">
            Don't have an account?{' '}
            <button type="button" onClick={onSwitchToRegister} className="text-blue-600 font-bold hover:underline">
              Register
            </button>
          </p>
        </div>
      </div>
    </div>
  );
}
