import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import api from '../api';

export default function StationList() {
  const [stations, setStations] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    const fetchStations = async () => {
      try {
        const res = await api.get('/stations');
        setStations(res.data.data || []);
      } catch (err) {
        console.error('Fetch stations error:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchStations();
  }, []);

  const filtered = stations.filter(s =>
    !search || s.StationName?.toLowerCase().includes(search.toLowerCase()) ||
    s.StationCode?.toLowerCase().includes(search.toLowerCase())
  );

  if (loading) return <div className="loading">Loading stations...</div>;

  const user = JSON.parse(localStorage.getItem('user'));
  const isAdmin = user?.roles?.includes('SysAdmin');

  return (
    <div>
      <div className="page-header">
        <h1>Charging Stations</h1>
        <div style={{ display: 'flex', gap: '10px' }}>
          <input
            type="text"
            placeholder="Search stations..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            style={{ padding: '8px 12px', border: '1px solid #ddd', borderRadius: '6px', width: '250px' }}
          />
          {isAdmin && <Link to="/stations/new" className="btn btn-primary">+ New Station</Link>}
        </div>
      </div>

      <div className="station-grid">
        {filtered.length === 0 && <div className="empty-state"><h3>No stations found</h3></div>}
        {filtered.map((s) => (
          <div key={s.StationID} className="station-card">
            <div className="station-card-body">
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
                <div>
                  <h3>{s.StationName}</h3>
                  <span className="station-code">{s.StationCode}</span>
                </div>
                <span className={`badge badge-${s.StationStatus === 'Active' ? 'success' : s.StationStatus === 'UnderMaintenance' ? 'warning' : 'default'}`}>
                  {s.StationStatus}
                </span>
              </div>
              <div className="station-stats">
                <span>⚡ {s.MaxCapacityKW || 0} KW</span>
                <span>🅿️ {s.ParkingSpots || 0} spots</span>
                <span>📶 {s.NetworkStatus || 'Unknown'}</span>
              </div>
              <Link to={`/stations/${s.StationID}`} className="btn btn-outline btn-sm">View Details</Link>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
