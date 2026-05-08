import React, { useEffect, useState } from 'react';
import api from '../api';

export default function MyVehicles() {
  const [vehicles, setVehicles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({
    PlateNumber: '', Brand: '', Model: '', ModelYear: '',
    BatteryCapacityKWh: '', ConnectorType: 'Type 2', VIN: '',
  });

  const fetchVehicles = async () => {
    try {
      const res = await api.get('/vehicles');
      setVehicles(res.data.data || []);
    } catch (err) { console.error(err); } finally { setLoading(false); }
  };

  useEffect(() => { fetchVehicles(); }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await api.post('/vehicles', form);
      alert('Vehicle added');
      setShowForm(false);
      setForm({ PlateNumber: '', Brand: '', Model: '', ModelYear: '', BatteryCapacityKWh: '', ConnectorType: 'Type 2', VIN: '' });
      fetchVehicles();
    } catch (err) { alert(err?.message || 'Failed to add vehicle'); }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Remove this vehicle?')) return;
    try {
      await api.delete(`/vehicles/${id}`);
      fetchVehicles();
    } catch (err) { alert(err?.message || 'Delete failed'); }
  };

  if (loading) return <div className="loading">Loading vehicles...</div>;

  return (
    <div>
      <div className="page-header">
        <h1>My Vehicles</h1>
        <button className="btn btn-primary" onClick={() => setShowForm(!showForm)}>
          {showForm ? 'Cancel' : '+ Add Vehicle'}
        </button>
      </div>

      {showForm && (
        <div className="card" style={{ marginBottom: '25px' }}>
          <h3 style={{ marginBottom: '15px' }}>Add New Vehicle</h3>
          <form onSubmit={handleSubmit}>
            <div className="form-row">
              <div className="form-group">
                <label>Plate Number *</label>
                <input value={form.PlateNumber} onChange={(e) => setForm({ ...form, PlateNumber: e.target.value })} required />
              </div>
              <div className="form-group">
                <label>VIN</label>
                <input value={form.VIN} onChange={(e) => setForm({ ...form, VIN: e.target.value })} maxLength="17" />
              </div>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Brand</label>
                <input value={form.Brand} onChange={(e) => setForm({ ...form, Brand: e.target.value })} placeholder="e.g. Tesla, VinFast" />
              </div>
              <div className="form-group">
                <label>Model</label>
                <input value={form.Model} onChange={(e) => setForm({ ...form, Model: e.target.value })} placeholder="e.g. Model 3, VF8" />
              </div>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Year</label>
                <input type="number" value={form.ModelYear} onChange={(e) => setForm({ ...form, ModelYear: e.target.value })} min="2000" max="2030" />
              </div>
              <div className="form-group">
                <label>Battery Capacity (kWh)</label>
                <input type="number" step="0.1" value={form.BatteryCapacityKWh} onChange={(e) => setForm({ ...form, BatteryCapacityKWh: e.target.value })} />
              </div>
            </div>
            <div className="form-group">
              <label>Connector Type</label>
              <select value={form.ConnectorType} onChange={(e) => setForm({ ...form, ConnectorType: e.target.value })}>
                <option value="Type 1">Type 1</option>
                <option value="Type 2">Type 2</option>
                <option value="CCS">CCS</option>
                <option value="CHAdeMO">CHAdeMO</option>
                <option value="Tesla">Tesla</option>
              </select>
            </div>
            <button type="submit" className="btn btn-primary">Save Vehicle</button>
          </form>
        </div>
      )}

      {vehicles.length === 0 ? (
        <div className="empty-state"><h3>No vehicles yet</h3><p>Add a vehicle to start charging sessions.</p></div>
      ) : (
        <div className="data-table">
          <table>
            <thead>
              <tr><th>Plate Number</th><th>Brand</th><th>Model</th><th>Year</th><th>Connector</th><th>Battery</th><th>Actions</th></tr>
            </thead>
            <tbody>
              {vehicles.map((v) => (
                <tr key={v.VehicleID}>
                  <td><strong>{v.PlateNumber}</strong></td>
                  <td>{v.Brand || '-'}</td>
                  <td>{v.Model || '-'}</td>
                  <td>{v.ModelYear || '-'}</td>
                  <td><span className="badge badge-info">{v.ConnectorType || 'N/A'}</span></td>
                  <td>{v.BatteryCapacityKWh ? `${v.BatteryCapacityKWh} kWh` : '-'}</td>
                  <td><button className="btn btn-danger btn-sm" onClick={() => handleDelete(v.VehicleID)}>Remove</button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
