import React from 'react';
import { NavLink } from 'react-router-dom';

export default function Sidebar({ user, onLogout }) {
  const isAdmin = user?.roles?.includes('SysAdmin');
  const isCustomer = user?.roles?.includes('CUSTOMER');

  return (
    <aside className="sidebar">
      <div className="sidebar-brand">
        <h2>⚡ EV Charge</h2>
        <span>Management System v2.0</span>
      </div>
      <nav className="sidebar-nav">
        <div className="sidebar-section">Overview</div>
        <NavLink to="/" className={({ isActive }) => isActive ? 'sidebar-item active' : 'sidebar-item'}>
          📊 Dashboard
        </NavLink>

        <div className="sidebar-section">Infrastructure</div>
        <NavLink to="/stations" className={({ isActive }) => isActive ? 'sidebar-item active' : 'sidebar-item'}>
          🔌 Charging Stations
        </NavLink>

        {isAdmin && (
          <>
            <NavLink to="/admin/franchises" className={({ isActive }) => isActive ? 'sidebar-item active' : 'sidebar-item'}>
              🏢 Franchises
            </NavLink>
            <NavLink to="/admin/pricing" className={({ isActive }) => isActive ? 'sidebar-item active' : 'sidebar-item'}>
              💰 Pricing Policies
            </NavLink>
            <NavLink to="/admin/maintenance" className={({ isActive }) => isActive ? 'sidebar-item active' : 'sidebar-item'}>
              🔧 Maintenance
            </NavLink>
            <NavLink to="/admin/alerts" className={({ isActive }) => isActive ? 'sidebar-item active' : 'sidebar-item'}>
              🚨 Alerts
            </NavLink>
            <NavLink to="/admin/users" className={({ isActive }) => isActive ? 'sidebar-item active' : 'sidebar-item'}>
              👥 User Management
            </NavLink>
          </>
        )}

        {isCustomer && (
          <>
            <div className="sidebar-section">My Account</div>
            <NavLink to="/bookings" className={({ isActive }) => isActive ? 'sidebar-item active' : 'sidebar-item'}>
              📋 My Sessions
            </NavLink>
            <NavLink to="/transactions" className={({ isActive }) => isActive ? 'sidebar-item active' : 'sidebar-item'}>
              💳 Transactions
            </NavLink>
            <NavLink to="/wallet" className={({ isActive }) => isActive ? 'sidebar-item active' : 'sidebar-item'}>
              👛 My Wallet
            </NavLink>
            <NavLink to="/vehicles" className={({ isActive }) => isActive ? 'sidebar-item active' : 'sidebar-item'}>
              🚗 My Vehicles
            </NavLink>
          </>
        )}

        <div className="sidebar-section">Settings</div>
        <NavLink to="/profile" className={({ isActive }) => isActive ? 'sidebar-item active' : 'sidebar-item'}>
          👤 Profile
        </NavLink>
      </nav>
      <div className="sidebar-footer">
        <div style={{ marginBottom: '8px' }}>
          {user?.Username}
          <span style={{ display: 'block', fontSize: '11px', opacity: 0.6 }}>{user?.roles?.join(', ')}</span>
        </div>
        <div className="sidebar-item" onClick={onLogout}>🚪 Logout</div>
      </div>
    </aside>
  );
}
