import { Navigate, useLocation } from 'react-router-dom';
import { UserRole } from '../../types';

import { type ReactNode } from 'react';

interface ProtectedRouteProps {
  children: ReactNode;
  requiredRoles?: UserRole[];
}

export default function ProtectedRoute({ children, requiredRoles }: ProtectedRouteProps) {
  const location = useLocation();
  const token = localStorage.getItem('token');
  const userStr = localStorage.getItem('user');

  if (!token || !userStr) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  let user: any = null;
  try { user = JSON.parse(userStr); } catch { return <Navigate to="/login" replace />; }

  const roleMap: Record<string, UserRole> = {
    Customer: 'client',
    Manager: 'manager',
    Admin: 'admin',
    SysAdmin: 'admin',
    Operator: 'manager',
  };

  const frontendRole = roleMap[user.Role] || 'client';

  if (requiredRoles && !requiredRoles.includes(frontendRole)) {
    return <Navigate to={`/${frontendRole}/dashboard`} replace />;
  }

  return <>{children}</>;
}
