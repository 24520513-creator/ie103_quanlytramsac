import { useState, useEffect } from 'react';
import { User, Mail, Phone, Edit3, Loader2 } from 'lucide-react';
import { api } from '../../services/api';
import PageHeader from '../../components/ui/PageHeader';
import Modal from '../../components/ui/Modal';
import StatusBadge from '../../components/ui/StatusBadge';
import type { User as UserType } from '../../types';

export default function ProfilePage() {
  const [profile, setProfile] = useState<UserType | null>(null);
  const [loading, setLoading] = useState(true);
  const [showEdit, setShowEdit] = useState(false);
  const [form, setForm] = useState({ FullName: '', Phone: '' });
  const [saving, setSaving] = useState(false);

  const load = () => {
    api.get('/auth/profile').then(r => {
      if (r.data) {
        setProfile(r.data);
        setForm({ FullName: r.data.FullName || '', Phone: r.data.Phone || '' });
      }
    }).finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  const handleSave = async () => {
    setSaving(true);
    try {
      await api.put('/auth/profile', form);
      setShowEdit(false);
      load();
    } catch (err: any) { alert(err.message); }
    finally { setSaving(false); }
  };

  if (loading) return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-blue-600" /></div>;
  if (!profile) return <div className="text-center py-20 text-slate-400">Không tìm thấy hồ sơ</div>;

  return (
    <div className="space-y-6">
      <PageHeader title="Hồ sơ cá nhân"
        actions={<button onClick={() => setShowEdit(true)}
          className="flex items-center gap-2 px-4 py-2.5 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 text-sm font-medium">
          <Edit3 className="w-4 h-4" /> Chỉnh sửa</button>} />

      <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden">
        <div className="h-32 bg-gradient-to-r from-blue-500 to-indigo-600" />
        <div className="px-6 pb-6">
          <div className="w-20 h-20 rounded-full bg-white border-4 border-white -mt-10 shadow-lg flex items-center justify-center text-blue-600 font-bold text-2xl">
            {profile.FullName?.split(' ').map(s => s[0]).join('').slice(0, 2).toUpperCase() || 'U'}
          </div>

          <div className="mt-4 grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <div className="mb-4">
                <p className="text-xs font-bold text-slate-500 uppercase mb-1">Họ tên</p>
                <p className="text-lg font-semibold text-slate-900">{profile.FullName}</p>
              </div>
              <div className="mb-4">
                <p className="text-xs font-bold text-slate-500 uppercase mb-1">Email</p>
                <p className="text-slate-700 flex items-center gap-2"><Mail className="w-4 h-4 text-slate-400" /> {profile.Email}</p>
              </div>
            </div>
            <div>
              <div className="mb-4">
                <p className="text-xs font-bold text-slate-500 uppercase mb-1">Số điện thoại</p>
                <p className="text-slate-700 flex items-center gap-2"><Phone className="w-4 h-4 text-slate-400" /> {profile.Phone || 'Chưa cập nhật'}</p>
              </div>
              <div className="mb-4">
                <p className="text-xs font-bold text-slate-500 uppercase mb-1">Vai trò</p>
                <StatusBadge status={profile.Role} />
              </div>
              <div>
                <p className="text-xs font-bold text-slate-500 uppercase mb-1">Trạng thái</p>
                <StatusBadge status={profile.AccountStatus} />
              </div>
            </div>
          </div>
        </div>
      </div>

      <Modal open={showEdit} onClose={() => setShowEdit(false)} title="Chỉnh sửa hồ sơ">
        <div className="space-y-4">
          <div>
            <label className="block text-xs font-bold text-slate-500 uppercase mb-1">Họ tên</label>
            <input type="text" value={form.FullName} onChange={e => setForm(p => ({...p, FullName: e.target.value}))}
              className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
          </div>
          <div>
            <label className="block text-xs font-bold text-slate-500 uppercase mb-1">Số điện thoại</label>
            <input type="tel" value={form.Phone} onChange={e => setForm(p => ({...p, Phone: e.target.value}))}
              className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl outline-none focus:ring-2 focus:ring-blue-500" />
          </div>
          <button onClick={handleSave} disabled={saving}
            className="w-full py-3 bg-blue-600 text-white font-bold rounded-xl hover:bg-blue-700 disabled:opacity-50">
            {saving ? 'Đang lưu...' : 'Lưu thay đổi'}
          </button>
        </div>
      </Modal>
    </div>
  );
}
