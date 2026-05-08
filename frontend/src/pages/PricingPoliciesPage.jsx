import React, { useEffect, useState } from 'react';
import api from '../api';

export default function PricingPoliciesPage() {
  const [policies, setPolicies] = useState([]);
  const [rules, setRules] = useState([]);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState('policies');
  const [showPolicyForm, setShowPolicyForm] = useState(false);
  const [policyForm, setPolicyForm] = useState({
    PolicyCode: '', PolicyName: '', PolicyType: 'Standard', BasePricePerKWh: '',
    MinChargeFee: '0', ParkingFeePerMin: '0', AppliedFrom: '', Priority: '0',
  });

  const fetchData = async () => {
    try {
      const [pRes, rRes] = await Promise.all([api.get('/pricing-policies'), api.get('/pricing-rules')]);
      setPolicies(pRes.data.data || []);
      setRules(rRes.data.data || []);
    } catch (err) { console.error(err); } finally { setLoading(false); }
  };

  useEffect(() => { fetchData(); }, []);

  const handleCreatePolicy = async (e) => {
    e.preventDefault();
    try {
      await api.post('/pricing-policies', { ...policyForm, BasePricePerKWh: parseFloat(policyForm.BasePricePerKWh), AppliedFrom: new Date().toISOString() });
      alert('Policy created');
      setShowPolicyForm(false);
      setPolicyForm({ PolicyCode: '', PolicyName: '', PolicyType: 'Standard', BasePricePerKWh: '', MinChargeFee: '0', ParkingFeePerMin: '0', AppliedFrom: '', Priority: '0' });
      fetchData();
    } catch (err) { alert(err?.message || 'Create failed'); }
  };

  if (loading) return <div className="loading">Loading pricing data...</div>;

  return (
    <div>
      <div className="page-header">
        <h1>Pricing Management</h1>
        <button className="btn btn-primary" onClick={() => setShowPolicyForm(!showPolicyForm)}>
          {showPolicyForm ? 'Cancel' : '+ New Policy'}
        </button>
      </div>

      <div className="tabs">
        <div className={`tab ${tab === 'policies' ? 'active' : ''}`} onClick={() => setTab('policies')}>Policies ({policies.length})</div>
        <div className={`tab ${tab === 'rules' ? 'active' : ''}`} onClick={() => setTab('rules')}>Rules ({rules.length})</div>
      </div>

      {showPolicyForm && (
        <div className="card" style={{ marginBottom: '25px' }}>
          <h3>New Pricing Policy</h3>
          <form onSubmit={handleCreatePolicy}>
            <div className="form-row">
              <div className="form-group"><label>Code *</label><input value={policyForm.PolicyCode} onChange={(e) => setPolicyForm({...policyForm, PolicyCode: e.target.value})} required /></div>
              <div className="form-group"><label>Name</label><input value={policyForm.PolicyName} onChange={(e) => setPolicyForm({...policyForm, PolicyName: e.target.value})} /></div>
            </div>
            <div className="form-row">
              <div className="form-group"><label>Type</label>
                <select value={policyForm.PolicyType} onChange={(e) => setPolicyForm({...policyForm, PolicyType: e.target.value})}>
                  <option value="Standard">Standard</option><option value="PeakHour">Peak Hour</option>
                  <option value="OffPeak">Off Peak</option><option value="Holiday">Holiday</option>
                  <option value="Promotional">Promotional</option><option value="Membership">Membership</option>
                </select>
              </div>
              <div className="form-group"><label>Base Price (per kWh)</label><input type="number" step="0.01" value={policyForm.BasePricePerKWh} onChange={(e) => setPolicyForm({...policyForm, BasePricePerKWh: e.target.value})} /></div>
            </div>
            <div className="form-row">
              <div className="form-group"><label>Min Fee</label><input type="number" value={policyForm.MinChargeFee} onChange={(e) => setPolicyForm({...policyForm, MinChargeFee: e.target.value})} /></div>
              <div className="form-group"><label>Parking Fee/min</label><input type="number" step="0.01" value={policyForm.ParkingFeePerMin} onChange={(e) => setPolicyForm({...policyForm, ParkingFeePerMin: e.target.value})} /></div>
            </div>
            <div className="form-group"><label>Priority</label><input type="number" value={policyForm.Priority} onChange={(e) => setPolicyForm({...policyForm, Priority: e.target.value})} /></div>
            <button type="submit" className="btn btn-primary">Create Policy</button>
          </form>
        </div>
      )}

      {tab === 'policies' && (
        <div className="data-table">
          <table>
            <thead>
              <tr><th>Code</th><th>Name</th><th>Type</th><th>Base Price/kWh</th><th>Min Fee</th><th>Parking Fee</th><th>Priority</th><th>Active</th></tr>
            </thead>
            <tbody>
              {policies.map((p) => (
                <tr key={p.PolicyID}>
                  <td><strong>{p.PolicyCode}</strong></td>
                  <td>{p.PolicyName}</td>
                  <td><span className="badge badge-info">{p.PolicyType}</span></td>
                  <td>{parseFloat(p.BasePricePerKWh).toLocaleString()} VND</td>
                  <td>{p.MinChargeFee ? `${parseFloat(p.MinChargeFee).toLocaleString()} VND` : '-'}</td>
                  <td>{p.ParkingFeePerMin ? `${p.ParkingFeePerMin}/min` : '-'}</td>
                  <td>{p.Priority}</td>
                  <td><span className={`badge ${p.IsActive ? 'badge-success' : 'badge-default'}`}>{p.IsActive ? 'Active' : 'Inactive'}</span></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {tab === 'rules' && (
        <div className="data-table">
          <table>
            <thead>
              <tr><th>Rule</th><th>Type</th><th>Adjustment</th><th>Value</th><th>Priority</th><th>Active</th></tr>
            </thead>
            <tbody>
              {rules.map((r) => (
                <tr key={r.PricingRuleID}>
                  <td>{r.RuleName}</td>
                  <td><span className="badge badge-info">{r.RuleType}</span></td>
                  <td>{r.AdjustmentType}</td>
                  <td>{r.AdjustmentValue}</td>
                  <td>{r.Priority}</td>
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
