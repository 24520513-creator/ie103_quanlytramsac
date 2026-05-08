import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import api from '../api';

export default function StationFormPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const isEdit = !!id;
  const [loading, setLoading] = useState(false);
  const [franchises, setFranchises] = useState([]);
  const [models, setModels] = useState([]);
  const [suppliers, setSuppliers] = useState([]);
  const [form, setForm] = useState({
    StationCode: '', StationName: '', FranchiseID: '', StationModelID: '',
    AddressID: '', SupplierID: '', MaxCapacityKW: '', ParkingSpots: '',
    Latitude: '', Longitude: '', StationStatus: 'Active', NetworkStatus: 'Online',
    InstallationDate: '', HasGenerator: false, HasSolarPanels: false,
  });

  useEffect(() => {
    const fetchRefs = async () => {
      try {
        const [fRes, mRes, sRes] = await Promise.all([
          api.get('/franchises'),
          api.get('/station-models'),
          api.get('/suppliers'),
        ]);
        setFranchises(fRes.data.data || []);
        setModels(mRes.data.data || []);
        setSuppliers(sRes.data.data || []);
      } catch (err) { console.error(err); }
    };
    fetchRefs();

    if (isEdit) {
      api.get(`/stations/${id}`).then(res => {
        const s = res.data;
        setForm({
          StationCode: s.StationCode || '', StationName: s.StationName || '',
          FranchiseID: s.FranchiseID || '', StationModelID: s.StationModelID || '',
          AddressID: s.AddressID || '', SupplierID: s.SupplierID || '',
          MaxCapacityKW: s.MaxCapacityKW || '', ParkingSpots: s.ParkingSpots || '',
          Latitude: s.Latitude || '', Longitude: s.Longitude || '',
          StationStatus: s.StationStatus || 'Active', NetworkStatus: s.NetworkStatus || 'Online',
          InstallationDate: s.InstallationDate ? s.InstallationDate.slice(0, 10) : '',
          HasGenerator: s.HasGenerator || false, HasSolarPanels: s.HasSolarPanels || false,
        });
      }).catch(() => navigate('/stations'));
    }
  }, [id]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      if (isEdit) {
        await api.put(`/stations/${id}`, form);
        alert('Station updated successfully!');
      } else {
        await api.post('/stations', form);
        alert('Station created successfully!');
      }
      navigate('/stations');
    } catch (err) {
      alert(err?.message || 'Failed to save station');
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setForm({ ...form, [name]: type === 'checkbox' ? checked : value });
  };

  return (
    <div>
      <div className="page-header"><h1>{isEdit ? 'Edit Station' : 'New Station'}</h1></div>
      <form onSubmit={handleSubmit} className="form-card">
        <div className="form-row">
          <div className="form-group">
            <label>Station Code *</label>
            <input name="StationCode" value={form.StationCode} onChange={handleChange} required />
          </div>
          <div className="form-group">
            <label>Station Name *</label>
            <input name="StationName" value={form.StationName} onChange={handleChange} required />
          </div>
        </div>
        <div className="form-row">
          <div className="form-group">
            <label>Franchise *</label>
            <select name="FranchiseID" value={form.FranchiseID} onChange={handleChange} required>
              <option value="">Select...</option>
              {franchises.map(f => <option key={f.FranchiseID} value={f.FranchiseID}>{f.FranchiseName}</option>)}
            </select>
          </div>
          <div className="form-group">
            <label>Station Model</label>
            <select name="StationModelID" value={form.StationModelID} onChange={handleChange}>
              <option value="">Select...</option>
              {models.map(m => <option key={m.StationModelID} value={m.StationModelID}>{m.ModelName} ({m.Manufacturer})</option>)}
            </select>
          </div>
        </div>
        <div className="form-row">
          <div className="form-group">
            <label>Capacity (KW)</label>
            <input name="MaxCapacityKW" type="number" value={form.MaxCapacityKW} onChange={handleChange} />
          </div>
          <div className="form-group">
            <label>Parking Spots</label>
            <input name="ParkingSpots" type="number" value={form.ParkingSpots} onChange={handleChange} />
          </div>
        </div>
        <div className="form-row">
          <div className="form-group">
            <label>Latitude</label>
            <input name="Latitude" type="number" step="any" value={form.Latitude} onChange={handleChange} />
          </div>
          <div className="form-group">
            <label>Longitude</label>
            <input name="Longitude" type="number" step="any" value={form.Longitude} onChange={handleChange} />
          </div>
        </div>
        <div className="form-row">
          <div className="form-group">
            <label>Status</label>
            <select name="StationStatus" value={form.StationStatus} onChange={handleChange}>
              <option value="Active">Active</option>
              <option value="Inactive">Inactive</option>
              <option value="UnderMaintenance">Under Maintenance</option>
              <option value="Retired">Retired</option>
            </select>
          </div>
          <div className="form-group">
            <label>Network Status</label>
            <select name="NetworkStatus" value={form.NetworkStatus} onChange={handleChange}>
              <option value="Online">Online</option>
              <option value="Offline">Offline</option>
              <option value="Degraded">Degraded</option>
              <option value="Unknown">Unknown</option>
            </select>
          </div>
        </div>
        <div className="form-group">
          <label>Installation Date</label>
          <input name="InstallationDate" type="date" value={form.InstallationDate} onChange={handleChange} />
        </div>
        <div className="form-row">
          <div className="form-group" style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <label style={{ margin: 0 }}>Has Generator</label>
            <input name="HasGenerator" type="checkbox" checked={form.HasGenerator} onChange={handleChange} />
          </div>
          <div className="form-group" style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <label style={{ margin: 0 }}>Has Solar Panels</label>
            <input name="HasSolarPanels" type="checkbox" checked={form.HasSolarPanels} onChange={handleChange} />
          </div>
        </div>
        <div style={{ display: 'flex', gap: '10px', marginTop: '10px' }}>
          <button type="submit" className="btn btn-primary" disabled={loading}>
            {loading ? 'Saving...' : isEdit ? 'Update Station' : 'Create Station'}
          </button>
          <button type="button" className="btn btn-outline" onClick={() => navigate('/stations')}>Cancel</button>
        </div>
      </form>
    </div>
  );
}
