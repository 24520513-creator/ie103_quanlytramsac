import React, { useEffect, useState } from 'react';
import api from '../api';

export default function BookingPage() {
  const [sessions, setSessions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState('active');

  const fetchSessions = async () => {
    try {
      const res = await api.get('/sessions/my');
      setSessions(res.data.data || []);
    } catch (err) {
      console.error('Fetch sessions error:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchSessions(); }, []);

  const handleStopSession = async (id) => {
    if (!window.confirm('Stop this charging session?')) return;
    try {
      await api.post(`/sessions/${id}/end`, { StopReason: 'UserStopped' });
      alert('Session ended successfully');
      fetchSessions();
    } catch (err) {
      alert(err?.message || 'Failed to stop session');
    }
  };

  const handleCancelSession = async (id) => {
    if (!window.confirm('Cancel this charging session?')) return;
    try {
      await api.post(`/sessions/${id}/cancel`, { reason: 'CancelledByUser' });
      alert('Session cancelled');
      fetchSessions();
    } catch (err) {
      alert(err?.message || 'Failed to cancel session');
    }
  };

  if (loading) return <div className="loading">Loading sessions...</div>;

  const activeSessions = sessions.filter(s => s.SessionStatus === 'Charging');
  const completedSessions = sessions.filter(s => s.SessionStatus === 'Completed' || s.SessionStatus === 'Cancelled');

  const displaySessions = tab === 'active' ? activeSessions : completedSessions;

  return (
    <div>
      <div className="page-header"><h1>My Charging Sessions</h1></div>

      {activeSessions.length > 0 && (
        <div className="alert alert-info" style={{ marginBottom: '20px' }}>
          ⚡ You have <strong>{activeSessions.length}</strong> active charging session{activeSessions.length > 1 ? 's' : ''}!
        </div>
      )}

      <div className="tabs">
        <div className={`tab ${tab === 'active' ? 'active' : ''}`} onClick={() => setTab('active')}>
          Active ({activeSessions.length})
        </div>
        <div className={`tab ${tab === 'completed' ? 'active' : ''}`} onClick={() => setTab('completed')}>
          History ({completedSessions.length})
        </div>
      </div>

      {displaySessions.length === 0 ? (
        <div className="empty-state">
          <h3>{tab === 'active' ? 'No active sessions' : 'No session history'}</h3>
          {tab === 'active' && <p>Go to <a href="/stations">stations</a> to start charging.</p>}
        </div>
      ) : (
        <div className="data-table">
          <table>
            <thead>
              <tr>
                <th>Session Code</th>
                <th>Station</th>
                <th>Started</th>
                <th>Duration</th>
                <th>Energy</th>
                <th>Cost</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {displaySessions.map((s) => (
                <tr key={s.SessionID}>
                  <td style={{ fontFamily: 'monospace', fontSize: '12px' }}>{s.SessionCode}</td>
                  <td>{s.StationName || s.SessionCode}</td>
                  <td>{s.StartTime ? new Date(s.StartTime).toLocaleString() : '-'}</td>
                  <td>{s.ChargingDurationMinutes ? `${s.ChargingDurationMinutes} min` : '-'}</td>
                  <td>{s.TotalKWh ? `${parseFloat(s.TotalKWh).toFixed(2)} kWh` : '-'}</td>
                  <td>{s.CostTotal ? `${parseFloat(s.CostTotal).toLocaleString()} VND` : '-'}</td>
                  <td>
                    <span className={`badge badge-${s.SessionStatus === 'Charging' ? 'success' : s.SessionStatus === 'Completed' ? 'info' : 'default'}`}>
                      {s.SessionStatus}
                    </span>
                  </td>
                  <td>
                    {s.SessionStatus === 'Charging' && (
                      <div style={{ display: 'flex', gap: '5px' }}>
                        <button className="btn btn-success btn-sm" onClick={() => handleStopSession(s.SessionID)}>Stop</button>
                        <button className="btn btn-danger btn-sm" onClick={() => handleCancelSession(s.SessionID)}>Cancel</button>
                      </div>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
