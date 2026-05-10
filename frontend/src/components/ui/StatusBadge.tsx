import { cn } from '../../lib/utils';

interface StatusBadgeProps {
  status: string;
  mapping?: Record<string, string>;
}

const defaultMapping: Record<string, string> = {
  active: 'bg-emerald-50 text-emerald-700 border-emerald-200',
  inactive: 'bg-slate-50 text-slate-600 border-slate-200',
  available: 'bg-emerald-50 text-emerald-700 border-emerald-200',
  busy: 'bg-amber-50 text-amber-700 border-amber-200',
  charging: 'bg-blue-50 text-blue-700 border-blue-200',
  completed: 'bg-emerald-50 text-emerald-700 border-emerald-200',
  cancelled: 'bg-slate-50 text-slate-500 border-slate-200',
  pending: 'bg-amber-50 text-amber-700 border-amber-200',
  confirmed: 'bg-blue-50 text-blue-700 border-blue-200',
  scheduled: 'bg-purple-50 text-purple-700 border-purple-200',
  inprogress: 'bg-blue-50 text-blue-700 border-blue-200',
  error: 'bg-red-50 text-red-700 border-red-200',
  offline: 'bg-slate-100 text-slate-500 border-slate-200',
  maintenance: 'bg-orange-50 text-orange-700 border-orange-200',
  retired: 'bg-red-50 text-red-600 border-red-200',
  resolved: 'bg-emerald-50 text-emerald-700 border-emerald-200',
  high: 'bg-red-50 text-red-700 border-red-200',
  medium: 'bg-amber-50 text-amber-700 border-amber-200',
  low: 'bg-slate-50 text-slate-600 border-slate-200',
  critical: 'bg-red-100 text-red-800 border-red-300',
  true: 'bg-emerald-50 text-emerald-700 border-emerald-200',
  false: 'bg-slate-50 text-slate-500 border-slate-200',
};

export default function StatusBadge({ status, mapping }: StatusBadgeProps) {
  const key = (status || '').toLowerCase().replace(/\s+/g, '');
  const colorClass = (mapping || defaultMapping)[key] || 'bg-slate-50 text-slate-600 border-slate-200';
  return (
    <span className={cn('inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border', colorClass)}>
      {status || 'Unknown'}
    </span>
  );
}
