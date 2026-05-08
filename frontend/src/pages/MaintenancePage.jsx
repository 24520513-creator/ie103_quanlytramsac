import React, { useEffect, useState } from 'react';
import api from '../api';

export default function MaintenancePage() {
  const [schedules, setSchedules] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({
    StationID: '', PointID: '', ScheduledDate: '', MaintenanceType: 'Routine',
    TechnicianName: '', TechnicianPhone: '', Description: '', Priority: 'Normal',
  });
  const [stations, setStations] = useState([]);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [sRes, stRes] = await Promise.all([api.get('/maintenance-schedules'), api.get('/stations')]);
        setSchedules(sRes.data.data || []);
        setStations(stRes.data.data || []);
      } catch (err) { console.error(err); } finally { setLoading(false); }
    };
    fetchData();
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await api.post('/maintenance-schedules', form);
      alert('Maintenance scheduled');
      setShowForm(false);
      const res = await api.get('/maintenance-schedules');
      setSchedules(res.data.data || []);
    } catch (err) { alert(err?.message || 'Failed to schedule'); }
  };

  const handleComplete = async (id) => {
    try {
      await api.put(`/maintenance-schedules/${id}`, { ScheduleStatus: 'Completed', CompletedDate: new Date().toISOString() });
      alert('Marked as completed');
      const res = await api.get('/maintenance-schedules');
      setSchedules(res.data.data || []);
    } catch (err) { alert(err?.message); }
  };

  if (loading) return <div className="loading">Loading maintenance schedules...</div>;

  return (
    <div>
      <div className="page-header">
        <h1>Maintenance Schedules</h1>
        <button className="btn btn-primary" onClick={() => setShowForm(!showForm)}>{showForm ? 'Cancel' : '+ Schedule Maintenance'}</button>
      </div>

      {showForm && (
        <div className="card" style={{ marginBottom: '25px' }}>
          <h3>New Maintenance Schedule</h3>
          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label>Station *</label>
              <select value={form.StationID} onChange={(e) => setForm({...form, StationID: e.target.value})} required>
                <option value="">Select...</option>
                {stations.map(s => <option key={s.StationID} value={s.StationID}>{s.StationName} ({s.StationCode})</option>)}
              </select>
            </div>
            <div className="form-row">
              <div className="form-group"><label>Type</label>
                <select value={form.MaintenanceType} onChange={(e) => setForm({...form, MaintenanceType: e.target.value})}>
                  <option value="Routine">Routine</option><option value="Repair">Repair</option>
                  <option value="Inspection">Inspection</option><option value="Upgrade">Upgrade</option>
                  <option value="Emergency">Emergency</option>
                </select>
              </div>
              <div className="form-group"><label>Priority</label>
                <select value={form.Priority} onChange={(e) => setForm({...form, Priority: e.target.value})}>
                  <option value="Low">Low</option><option value="Normal">Normal</option>
                  <option value="High">High</option><option value="Critical">Critical</option>
                </select>
              </div>
            </div>
            <div className="form-row">
              <div className="form-group"><label>Scheduled Date *</label><input type="datetime-local" value={form.ScheduledDate} onChange={(e) => setForm({...form, ScheduledDate: e.target.value})} required /></div>
              <div className="form-group"><label>Technician *</label><input value={form.TechnicianName} onChange={(e) => setForm({...form, TechnicianName: e.target.value})} required /></div>
            </div>
            <div className="form-group"><label>Description</label><textarea value={form.Description} onChange={(e) => setForm({...form, Description: e.target.value})} /></div>
            <button type="submit" className="btn btn-primary">Schedule</button>
          </form>
        </div>
      )}

      <div className="data-table">
        <table>
          <thead>
            <tr><th>ID</th><th>Station</th><th>Type</th><th>Technician</th><th>Scheduled</th><th>Status</th><th>Priority</th><th>Actions</th></tr>
          </thead>
          <tbody>
            {schedules.map((s) => (
              <tr key={s.ScheduleID}>
                <td>{s.ScheduleID}</td>
                <td>{s.StationID}</td>
                <td><span className="badge badge-info">{s.MaintenanceType}</span></td>
                <td>{s.TechnicianName}</td>
                <td>{s.ScheduledDate ? new Date(s.ScheduledDate).toLocaleString() : '-'}</td>
                <td><span className={`badge badge-${s.ScheduleStatus === 'Completed' ? 'success' : s.ScheduleStatus === 'InProgress' ? 'warning' : 'default'}`}>{s.ScheduleStatus}</span></td>
                <td><span className={`badge badge-${s.Priority === 'Critical' ? 'danger' : s.Priority === 'High' ? 'warning' : 'info'}`}>{s.Priority}</span></td>
                <td>
                  {s.ScheduleStatus !== 'Completed' && (
                    <button className="btn btn-success btn-sm" onClick={() => handleComplete(s.ScheduleID)}>Complete</button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
