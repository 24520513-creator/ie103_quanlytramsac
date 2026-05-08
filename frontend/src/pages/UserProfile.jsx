import React, { useEffect, useState } from 'react';
import api from '../api';

export default function UserProfile() {
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [editMode, setEditMode] = useState(false);
  const [form, setForm] = useState({});

  useEffect(() => {
    const fetchProfile = async () => {
      try {
        const res = await api.get('/auth/profile');
        setProfile(res.data);
        setForm({
          FullName: res.data.FullName || '',
          DisplayName: res.data.DisplayName || '',
          PreferredLanguage: res.data.PreferredLanguage || 'vi',
          DateOfBirth: res.data.DateOfBirth ? res.data.DateOfBirth.slice(0, 10) : '',
        });
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };
    fetchProfile();
  }, []);

  const handleSave = async () => {
    try {
      await api.put('/auth/profile', form);
      alert('Profile updated');
      setEditMode(false);
      const res = await api.get('/auth/profile');
      setProfile(res.data);
    } catch (err) {
      alert(err?.message || 'Update failed');
    }
  };

  if (loading) return <div className="loading">Loading profile...</div>;
  if (!profile) return <div className="empty-state"><h3>Profile not found</h3></div>;

  return (
    <div style={{ maxWidth: '700px' }}>
      <div className="page-header">
        <h1>My Profile</h1>
        <button className="btn btn-outline" onClick={() => setEditMode(!editMode)}>
          {editMode ? 'Cancel' : 'Edit Profile'}
        </button>
      </div>

      <div className="card" style={{ marginBottom: '25px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '20px', marginBottom: '20px' }}>
          <div style={{ width: '60px', height: '60px', borderRadius: '50%', background: '#1a237e', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '24px', fontWeight: 'bold' }}>
            {profile.Username?.charAt(0).toUpperCase()}
          </div>
          <div>
            <h2>{profile.FullName || profile.Username}</h2>
            <span className={`badge badge-${profile.AccountStatus === 'Active' ? 'success' : 'warning'}`}>{profile.AccountStatus}</span>
            <span style={{ marginLeft: '8px' }} className="badge badge-info">{profile.AccountTier}</span>
          </div>
        </div>
      </div>

      <div className="card">
        {editMode ? (
          <div>
            <div className="form-group">
              <label>Full Name</label>
              <input value={form.FullName} onChange={(e) => setForm({ ...form, FullName: e.target.value })} />
            </div>
            <div className="form-group">
              <label>Display Name</label>
              <input value={form.DisplayName} onChange={(e) => setForm({ ...form, DisplayName: e.target.value })} />
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Date of Birth</label>
                <input type="date" value={form.DateOfBirth} onChange={(e) => setForm({ ...form, DateOfBirth: e.target.value })} />
              </div>
              <div className="form-group">
                <label>Language</label>
                <select value={form.PreferredLanguage} onChange={(e) => setForm({ ...form, PreferredLanguage: e.target.value })}>
                  <option value="vi">Vietnamese</option>
                  <option value="en">English</option>
                </select>
              </div>
            </div>
            <button className="btn btn-primary" onClick={handleSave}>Save Changes</button>
          </div>
        ) : (
          <div>
            <div className="detail-row"><span className="detail-label">Username</span><span className="detail-value">{profile.Username}</span></div>
            <div className="detail-row"><span className="detail-label">Email</span><span className="detail-value">{profile.Email}</span></div>
            <div className="detail-row"><span className="detail-label">Phone</span><span className="detail-value">{profile.Phone || 'N/A'}</span></div>
            <div className="detail-row"><span className="detail-label">Full Name</span><span className="detail-value">{profile.FullName || 'N/A'}</span></div>
            <div className="detail-row"><span className="detail-label">Account Tier</span><span className="detail-value">{profile.AccountTier}</span></div>
            <div className="detail-row"><span className="detail-label">Last Login</span><span className="detail-value">{profile.LastLoginAt ? new Date(profile.LastLoginAt).toLocaleString() : 'N/A'}</span></div>
            <div className="detail-row"><span className="detail-label">Member Since</span><span className="detail-value">{new Date(profile.CreatedAt).toLocaleDateString()}</span></div>
            <div className="detail-row"><span className="detail-label">Login Attempts</span><span className="detail-value">{profile.FailedLoginAttempts || 0}</span></div>
          </div>
        )}
      </div>
    </div>
  );
}
