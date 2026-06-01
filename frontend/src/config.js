// API base URL lives in lib/api.js (single source of truth for the fetch layer).

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
