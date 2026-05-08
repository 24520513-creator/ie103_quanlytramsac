import React, { useEffect, useState } from 'react';
import api from '../api';

export default function AlertsPage() {
  const [alerts, setAlerts] = useState([]);
  const [rules, setRules] = useState([]);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState('alerts');

  const fetchData = async () => {
    try {
      const [aRes, rRes] = await Promise.all([api.get('/alerts'), api.get('/alert-rules')]);
      setAlerts(aRes.data.data || []);
      setRules(rRes.data.data || []);
    } catch (err) { console.error(err); } finally { setLoading(false); }
  };

  useEffect(() => { fetchData(); }, []);

  const handleAcknowledge = async (id) => {
    try {
      await api.put(`/alerts/${id}`, { AlertStatus: 'Acknowledged' });
      fetchData();
    } catch (err) { alert(err?.message); }
  };

  const handleResolve = async (id) => {
    try {
      await api.put(`/alerts/${id}`, { AlertStatus: 'Resolved', ResolvedAt: new Date().toISOString() });
      fetchData();
    } catch (err) { alert(err?.message); }
  };

  if (loading) return <div className="loading">Loading alerts...</div>;

  return (
    <div>
      <div className="page-header"><h1>Alerts & Monitoring</h1></div>

      <div className="tabs">
        <div className={`tab ${tab === 'alerts' ? 'active' : ''}`} onClick={() => setTab('alerts')}>Active Alerts ({alerts.filter(a => a.AlertStatus !== 'Resolved').length})</div>
        <div className={`tab ${tab === 'rules' ? 'active' : ''}`} onClick={() => setTab('rules')}>Alert Rules ({rules.length})</div>
      </div>

      {tab === 'alerts' && (
        <>
          {alerts.filter(a => a.AlertStatus === 'Open').length > 0 && (
            <div className="alert alert-error" style={{ marginBottom: '20px' }}>
              🚨 {alerts.filter(a => a.AlertStatus === 'Open').length} open alerts require attention!
            </div>
          )}
          <div className="data-table">
            <table>
              <thead>
                <tr><th>Title</th><th>Severity</th><th>Status</th><th>Station</th><th>Created</th><th>Actions</th></tr>
              </thead>
              <tbody>
                {alerts.map((a) => (
                  <tr key={a.AlertID}>
                    <td><strong>{a.AlertTitle}</strong></td>
                    <td>
                      <span className={`badge badge-${a.Severity === 'Critical' ? 'danger' : a.Severity === 'High' ? 'warning' : a.Severity === 'Medium' ? 'info' : 'default'}`}>
                        {a.Severity}
                      </span>
                    </td>
                    <td><span className={`badge badge-${a.AlertStatus === 'Open' ? 'danger' : a.AlertStatus === 'Acknowledged' ? 'warning' : 'success'}`}>{a.AlertStatus}</span></td>
                    <td>{a.StationID || '-'}</td>
                    <td>{a.CreatedAt ? new Date(a.CreatedAt).toLocaleString() : '-'}</td>
                    <td>
                      {a.AlertStatus === 'Open' && <button className="btn btn-warning btn-sm" onClick={() => handleAcknowledge(a.AlertID)} style={{ marginRight: '5px' }}>Acknowledge</button>}
                      {a.AlertStatus !== 'Resolved' && <button className="btn btn-success btn-sm" onClick={() => handleResolve(a.AlertID)}>Resolve</button>}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}

      {tab === 'rules' && (
        <div className="data-table">
          <table>
            <thead>
              <tr><th>Rule Name</th><th>Category</th><th>Metric</th><th>Condition</th><th>Threshold</th><th>Severity</th><th>Active</th></tr>
            </thead>
            <tbody>
              {rules.map((r) => (
                <tr key={r.AlertRuleID}>
                  <td>{r.RuleName}</td>
                  <td><span className="badge badge-info">{r.RuleCategory}</span></td>
                  <td>{r.MetricName}</td>
                  <td>{r.Condition}</td>
                  <td>{r.ThresholdValue}</td>
                  <td><span className={`badge badge-${r.Severity === 'Critical' ? 'danger' : r.Severity === 'High' ? 'warning' : 'info'}`}>{r.Severity}</span></td>
                  <td><span className={`badge ${r.IsActive ? 'badge-success' : 'badge-default'}`}>{r.IsActive ? 'Active' : 'Inactive'}</span></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
