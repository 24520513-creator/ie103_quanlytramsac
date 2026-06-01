export const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

export const demoUsers = [
  ['customer01', 'Khách hàng'],
  ['operator01', 'Vận hành'],
  ['business01', 'Kinh doanh'],
  ['franchise01', 'Đối tác'],
  ['admin01', 'Quản trị']
];

export const roleLabels = {
  Customer: 'Khách hàng',
  OperationsStaff: 'Nhân viên vận hành',
  BusinessManager: 'Quản lý kinh doanh',
  FranchisePartner: 'Đối tác nhượng quyền',
  SystemAdmin: 'Quản trị hệ thống'
};
