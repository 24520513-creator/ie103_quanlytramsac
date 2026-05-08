import React, { useEffect, useState } from 'react';
import api from '../api';

export default function AdminUsersPage() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [expanded, setExpanded] = useState(null);

  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const res = await api.get('/users');
        setUsers(res.data.data || []);
      } catch (err) { console.error(err); } finally { setLoading(false); }
    };
    fetchUsers();
  }, []);

  if (loading) return <div className="loading">Loading users...</div>;

  return (
    <div>
      <div className="page-header"><h1>User Management</h1></div>
      <div className="data-table">
        <table>
          <thead>
            <tr><th>ID</th><th>Username</th><th>Email</th><th>Status</th><th>Tier</th><th>Role</th><th>Last Login</th><th>Login Attempts</th></tr>
          </thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.UserID}>
                <td>{u.UserID}</td>
                <td><strong>{u.Username}</strong></td>
                <td style={{ color: '#555' }}>{u.Email}</td>
                <td><span className={`badge badge-${u.AccountStatus === 'Active' ? 'success' : u.AccountStatus === 'Suspended' ? 'danger' : 'warning'}`}>{u.AccountStatus}</span></td>
                <td><span className="badge badge-info">{u.AccountTier}</span></td>
                <td>-</td>
                <td>{u.LastLoginAt ? new Date(u.LastLoginAt).toLocaleDateString() : '-'}</td>
                <td>{u.FailedLoginAttempts}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
