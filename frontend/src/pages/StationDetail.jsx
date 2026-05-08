import React, { useEffect, useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import api from '../api';

export default function StationDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [station, setStation] = useState(null);
  const [points, setPoints] = useState([]);
  const [loading, setLoading] = useState(true);

  const user = JSON.parse(localStorage.getItem('user'));
  const isAdmin = user?.roles?.includes('SysAdmin');

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [stationRes, pointsRes] = await Promise.all([
          api.get(`/stations/${id}`),
          api.get(`/points?stationId=${id}`),
        ]);
        setStation(stationRes.data);
        setPoints(pointsRes.data.data || []);
      } catch (err) {
        console.error('Fetch station detail error:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, [id]);

  const handleStartSession = async (pointId) => {
    try {
      const res = await api.post('/sessions/start', {
        PointID: parseInt(pointId),
        SessionSource: 'WebPortal',
        SessionType: 'Public',
      });
      alert(`Session ${res.data.SessionCode} started!`);
      navigate('/bookings');
    } catch (err) {
      alert(err?.message || 'Failed to start session');
    }
  };

  if (loading) return <div className="loading">Loading station details...</div>;
  if (!station) return <div className="empty-state"><h3>Station not found</h3></div>;

  return (
    <div>
      <div className="page-header">
        <div>
          <Link to="/stations" style={{ fontSize: '13px', color: '#1a237e', textDecoration: 'none' }}>&larr; Back to Stations</Link>
          <h1 style={{ marginTop: '5px' }}>{station.StationName}</h1>
        </div>
        {isAdmin && <Link to={`/stations/${id}/edit`} className="btn btn-primary">Edit Station</Link>}
      </div>

      <div className="detail-grid">
        <div>
          <div className="card detail-section">
            <h3>Station Information</h3>
            <div className="detail-row"><span className="detail-label">Code</span><span className="detail-value">{station.StationCode}</span></div>
            <div className="detail-row"><span className="detail-label">Status</span><span className="detail-value"><span className={`badge badge-${station.StationStatus === 'Active' ? 'success' : 'warning'}`}>{station.StationStatus}</span></span></div>
            <div className="detail-row"><span className="detail-label">Network</span><span className="detail-value"><span className={`badge badge-${station.NetworkStatus === 'Online' ? 'success' : 'danger'}`}>{station.NetworkStatus}</span></span></div>
            <div className="detail-row"><span className="detail-label">Capacity</span><span className="detail-value">{station.MaxCapacityKW} KW</span></div>
            <div className="detail-row"><span className="detail-label">Parking Spots</span><span className="detail-value">{station.ParkingSpots || 0}</span></div>
            <div className="detail-row"><span className="detail-label">Installation Date</span><span className="detail-value">{station.InstallationDate ? new Date(station.InstallationDate).toLocaleDateString() : 'N/A'}</span></div>
            <div className="detail-row"><span className="detail-label">Firmware</span><span className="detail-value">{station.FirmwareVersion || 'N/A'}</span></div>
            {station.HasGenerator && <div className="detail-row"><span className="detail-label">Generator</span><span className="detail-value">✅ Installed</span></div>}
            {station.HasSolarPanels && <div className="detail-row"><span className="detail-label">Solar Panels</span><span className="detail-value">✅ Installed</span></div>}
          </div>

          <div className="card detail-section">
            <h3>Charging Points ({points.length})</h3>
            <div className="point-grid">
              {points.map((p) => (
                <div key={p.PointID} className="point-card" style={{ borderColor: p.PointStatus === 'Available' ? '#2e7d32' : p.PointStatus === 'Busy' ? '#1565c0' : '#ddd' }}>
                  <h4>{p.PointCode}</h4>
                  <div className="power">{p.PowerKW} <span style={{ fontSize: '12px', fontWeight: 'normal' }}>kW</span></div>
                  <div className="connector">{p.ConnectorType}</div>
                  <div style={{ margin: '8px 0' }}>
                    <span className={`badge badge-${p.PointStatus === 'Available' ? 'success' : p.PointStatus === 'Busy' ? 'info' : 'default'}`}>
                      {p.PointStatus}
                    </span>
                  </div>
                  {p.PointStatus === 'Available' && (
                    <button className="btn btn-success btn-sm" onClick={() => handleStartSession(p.PointID)}>
                      Start Charging
                    </button>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>

        <div>
          <div className="card detail-section">
            <h3>Location</h3>
            {station.Latitude && station.Longitude ? (
              <div style={{ aspectRatio: '4/3', background: '#f0f0f0', borderRadius: '8px', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '13px', color: '#888' }}>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: '24px', marginBottom: '8px' }}>📍</div>
                  {station.Latitude?.toFixed(4)}, {station.Longitude?.toFixed(4)}
                </div>
              </div>
            ) : (
              <div style={{ color: '#888', padding: '20px', textAlign: 'center' }}>No coordinates available</div>
            )}
          </div>

          {station.OperatingHoursJson && (
            <div className="card detail-section">
              <h3>Operating Hours</h3>
              <pre style={{ fontSize: '12px', whiteSpace: 'pre-wrap', background: '#f9f9f9', padding: '10px', borderRadius: '4px' }}>{station.OperatingHoursJson}</pre>
            </div>
          )}

          {station.Notes && (
            <div className="card detail-section">
              <h3>Notes</h3>
              <p style={{ fontSize: '13px' }}>{station.Notes}</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
