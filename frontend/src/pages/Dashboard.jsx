import React, { useEffect, useState } from 'react';
import api from '../api';

export default function Dashboard({ user }) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        if (user.roles.includes('SysAdmin')) {
          const res = await api.get('/dashboard/admin');
          setData(res.data);
        } else {
          const [walletRes, sessionsRes] = await Promise.all([
            api.get('/wallet/my'),
            api.get('/sessions/my'),
          ]);
          setData({ wallet: walletRes.data, sessions: sessionsRes.data });
        }
      } catch (err) {
        console.error('Dashboard fetch error:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, [user]);

  if (loading) return <div className="loading">Loading dashboard...</div>;

  if (user.roles.includes('SysAdmin')) {
    const c = data?.counts || {};
    const t = data?.totals || {};
    return (
      <div>
        <div className="page-header"><h1>Admin Dashboard</h1></div>
        <div className="card-grid">
          <div className="card stat-card"><h3>{c.users || 0}</h3><p>Total Users</p></div>
          <div className="card stat-card"><h3>{c.stations || 0}</h3><p>Charging Stations</p></div>
          <div className="card stat-card"><h3>{c.sessions || 0}</h3><p>Completed Sessions</p></div>
          <div className="card stat-card"><h3>{c.activeSessions || 0}</h3><p>Active Now</p></div>
          <div className="card stat-card"><h3>{c.franchises || 0}</h3><p>Franchises</p></div>
          <div className="card stat-card"><h3>{parseFloat(t.revenue || 0).toLocaleString()} VND</h3><p>Total Revenue</p></div>
          <div className="card stat-card"><h3>{parseFloat(t.kwh || 0).toFixed(1)}</h3><p>Total MWh Delivered</p></div>
          <div className="card stat-card"><h3>{c.activeAlerts || 0}</h3><p>Open Alerts</p></div>
        </div>

        {data?.topStations?.length > 0 && (
          <div className="card" style={{ padding: '0' }}>
            <div style={{ padding: '20px 20px 0' }}><h3>Top 10 Stations by Revenue</h3></div>
            <div className="data-table" style={{ boxShadow: 'none' }}>
              <table>
                <thead>
                  <tr><th>Station</th><th>Sessions</th><th>Energy (kWh)</th><th>Revenue</th></tr>
                </thead>
                <tbody>
                  {data.topStations.map((s, i) => (
                    <tr key={i}>
                      <td>{s.StationCode} - {s.StationName}</td>
                      <td>{s.Sessions}</td>
                      <td>{parseFloat(s.KWh).toFixed(1)}</td>
                      <td>{parseFloat(s.Revenue).toLocaleString()} VND</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {data?.revenueByDay?.length > 0 && (
          <div className="card" style={{ marginTop: '25px' }}>
            <h3>Daily Revenue (Last 30 Days)</h3>
            <div style={{ display: 'flex', gap: '2px', alignItems: 'flex-end', height: '120px', marginTop: '15px' }}>
              {data.revenueByDay.map((d, i) => {
                const maxRev = Math.max(...data.revenueByDay.map(x => parseFloat(x.Revenue)));
                const height = maxRev > 0 ? (parseFloat(d.Revenue) / maxRev) * 100 : 0;
                return (
                  <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                    <div style={{ width: '100%', height: `${height}%`, background: '#1a237e', borderRadius: '2px 2px 0 0', minHeight: height > 0 ? '2px' : '0' }} />
                    <span style={{ fontSize: '8px', marginTop: '4px', transform: 'rotate(-45deg)', whiteSpace: 'nowrap' }}>{d.Date?.slice(5)}</span>
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>
    );
  }

  return (
    <div>
      <div className="page-header"><h1>Welcome, {user.Username}</h1></div>
      <div className="card-grid">
        <div className="card stat-card">
          <h3>{data?.wallet?.Balance || 0}</h3>
          <p>Wallet Balance (VND)</p>
        </div>
        <div className="card stat-card">
          <h3>{data?.sessions?.length || 0}</h3>
          <p>My Sessions</p>
        </div>
      </div>
      <div className="card">
        <p style={{ marginBottom: '15px' }}>Ready to charge your vehicle?</p>
        <a href="/stations" className="btn btn-success">🔌 Find a Station</a>
      </div>
    </div>
  );
}
