import React, { useEffect, useState } from 'react';
import api from '../api';

export default function AdminFranchisesPage() {
  const [franchises, setFranchises] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editItem, setEditItem] = useState(null);
  const [form, setForm] = useState({
    FranchiseCode: '', FranchiseName: '', TaxCode: '',
    ContactPerson: '', ContactPhone: '', ContactEmail: '',
    RevenueShareRate: '15', ContractSignedDate: '', FranchiseTier: 'Standard',
  });

  const fetchFranchises = async () => {
    try {
      const res = await api.get('/franchises');
      setFranchises(res.data.data || []);
    } catch (err) { console.error(err); } finally { setLoading(false); }
  };

  useEffect(() => { fetchFranchises(); }, []);

  const openEdit = (f) => {
    setEditItem(f);
    setForm({
      FranchiseCode: f.FranchiseCode, FranchiseName: f.FranchiseName, TaxCode: f.TaxCode,
      ContactPerson: f.ContactPerson || '', ContactPhone: f.ContactPhone || '',
      ContactEmail: f.ContactEmail || '', RevenueShareRate: f.RevenueShareRate,
      ContractSignedDate: f.ContractSignedDate ? f.ContractSignedDate.slice(0, 10) : '',
      FranchiseTier: f.FranchiseTier,
    });
    setShowForm(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      if (editItem) {
        await api.put(`/franchises/${editItem.FranchiseID}`, form);
        alert('Franchise updated');
      } else {
        await api.post('/franchises', form);
        alert('Franchise created');
      }
      setShowForm(false);
      setEditItem(null);
      fetchFranchises();
    } catch (err) { alert(err?.message || 'Save failed'); }
  };

  if (loading) return <div className="loading">Loading franchises...</div>;

  return (
    <div>
      <div className="page-header">
        <h1>Franchises</h1>
        <button className="btn btn-primary" onClick={() => { setEditItem(null); setForm({ FranchiseCode: '', FranchiseName: '', TaxCode: '', ContactPerson: '', ContactPhone: '', ContactEmail: '', RevenueShareRate: '15', ContractSignedDate: '', FranchiseTier: 'Standard' }); setShowForm(!showForm); }}>
          {showForm ? 'Cancel' : '+ New Franchise'}
        </button>
      </div>

      {showForm && (
        <div className="card" style={{ marginBottom: '25px' }}>
          <h3>{editItem ? 'Edit Franchise' : 'New Franchise'}</h3>
          <form onSubmit={handleSubmit}>
            <div className="form-row">
              <div className="form-group"><label>Code *</label><input value={form.FranchiseCode} onChange={(e) => setForm({...form, FranchiseCode: e.target.value})} required /></div>
              <div className="form-group"><label>Name *</label><input value={form.FranchiseName} onChange={(e) => setForm({...form, FranchiseName: e.target.value})} required /></div>
            </div>
            <div className="form-row">
              <div className="form-group"><label>Tax Code</label><input value={form.TaxCode} onChange={(e) => setForm({...form, TaxCode: e.target.value})} /></div>
              <div className="form-group"><label>Revenue Share (%)</label><input type="number" value={form.RevenueShareRate} onChange={(e) => setForm({...form, RevenueShareRate: e.target.value})} min="0" max="100" /></div>
            </div>
            <div className="form-row">
              <div className="form-group"><label>Contact Person</label><input value={form.ContactPerson} onChange={(e) => setForm({...form, ContactPerson: e.target.value})} /></div>
              <div className="form-group"><label>Contact Phone</label><input value={form.ContactPhone} onChange={(e) => setForm({...form, ContactPhone: e.target.value})} /></div>
            </div>
            <div className="form-row">
              <div className="form-group"><label>Contact Email</label><input type="email" value={form.ContactEmail} onChange={(e) => setForm({...form, ContactEmail: e.target.value})} /></div>
              <div className="form-group"><label>Contract Date</label><input type="date" value={form.ContractSignedDate} onChange={(e) => setForm({...form, ContractSignedDate: e.target.value})} /></div>
            </div>
            <div className="form-group">
              <label>Tier</label>
              <select value={form.FranchiseTier} onChange={(e) => setForm({...form, FranchiseTier: e.target.value})}>
                <option value="Bronze">Bronze</option><option value="Silver">Silver</option>
                <option value="Gold">Gold</option><option value="Platinum">Platinum</option>
                <option value="Standard">Standard</option>
              </select>
            </div>
            <button type="submit" className="btn btn-primary">{editItem ? 'Update' : 'Create'}</button>
          </form>
        </div>
      )}

      <div className="data-table">
        <table>
          <thead>
            <tr><th>Code</th><th>Name</th><th>Tax Code</th><th>Revenue Share</th><th>Tier</th><th>Contact</th><th>Actions</th></tr>
          </thead>
          <tbody>
            {franchises.map((f) => (
              <tr key={f.FranchiseID}>
                <td><strong>{f.FranchiseCode}</strong></td>
                <td>{f.FranchiseName}</td>
                <td>{f.TaxCode}</td>
                <td>{f.RevenueShareRate}%</td>
                <td><span className="badge badge-info">{f.FranchiseTier}</span></td>
                <td>{f.ContactPerson || '-'}</td>
                <td><button className="btn btn-outline btn-sm" onClick={() => openEdit(f)}>Edit</button></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
