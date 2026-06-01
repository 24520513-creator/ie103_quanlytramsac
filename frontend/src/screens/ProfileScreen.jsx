import React from 'react';
import { useActionData } from '../lib/useAction';
import { formatDate, getInitials } from '../lib/format';
import { Card, PageHeader, Badge, Loader, EmptyState } from '../components/ui';
import { ProfileIcon } from '../components/Icons';

function roleLabel(value) {
  const labels = {
    Customer: 'Khách hàng',
    OperationsStaff: 'Nhân viên vận hành',
    BusinessManager: 'Quản lý kinh doanh',
    FranchisePartner: 'Đối tác nhượng quyền',
    SystemAdmin: 'Quản trị hệ thống'
  };
  return labels[value] || value;
}

function splitRoles(row, user) {
  const raw = row.RoleCodes || user?.roles?.join(',') || user?.roleCode || '';
  return String(raw).split(',').map((item) => item.trim()).filter(Boolean);
}

export function ProfileScreen({ ctx }) {
  const { rows, loading, error } = useActionData('me', { token: ctx.token });
  const row = rows[0] || ctx.user.profile || ctx.user || {};
  const roles = splitRoles(row, ctx.user);

  return (
    <div className="ui-stack">
      <PageHeader icon={<ProfileIcon size={22} />} title="Hồ sơ" subtitle="Thông tin tài khoản, vai trò và trạng thái sử dụng hệ thống." />
      {loading ? <Loader /> : error ? <EmptyState title="Không tải được hồ sơ" message={error} /> : (
        <>
          <Card className="profileHero">
            <div className="profileAvatar">{getInitials(row.FullName || row.Username || ctx.user.username)}</div>
            <div className="profileHeroMain">
              <span className="muted-line">{row.Username || ctx.user.username}</span>
              <h2>{row.FullName || ctx.user.fullName || ctx.user.username}</h2>
              <div className="profileBadges">
                <Badge value={row.AccountStatus || ctx.user.accountStatus || 'Active'} />
                {roles.map((role) => <span key={role} className="pill">{roleLabel(role)}</span>)}
              </div>
            </div>
          </Card>

          <div className="profilePanel">
            <div><span>Email</span><strong>{row.Email || ctx.user.email || 'Chưa có'}</strong></div>
            <div><span>Số điện thoại</span><strong>{row.Phone || ctx.user.phone || 'Chưa có'}</strong></div>
            <div><span>Đăng nhập gần nhất</span><strong>{row.LastLoginAt ? formatDate(row.LastLoginAt) : 'Chưa ghi nhận'}</strong></div>
            <div><span>Ngày tạo tài khoản</span><strong>{row.CreatedAt ? formatDate(row.CreatedAt, false) : 'Chưa ghi nhận'}</strong></div>
          </div>
        </>
      )}
    </div>
  );
}
