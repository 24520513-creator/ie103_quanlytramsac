import { motion } from 'motion/react';
import { type ReactNode } from 'react';
import { cn } from '../../lib/utils';

interface StatCardProps {
  title: string;
  value: string | number;
  icon?: ReactNode;
  trend?: { value: number; isUp: boolean };
  color?: string;
  onClick?: () => void;
}

const colorMap: Record<string, string> = {
  blue: 'bg-blue-50 text-blue-600 border-blue-200',
  green: 'bg-emerald-50 text-emerald-600 border-emerald-200',
  orange: 'bg-orange-50 text-orange-600 border-orange-200',
  purple: 'bg-purple-50 text-purple-600 border-purple-200',
  red: 'bg-red-50 text-red-600 border-red-200',
  slate: 'bg-slate-50 text-slate-600 border-slate-200',
};

export default function StatCard({ title, value, icon, trend, color = 'blue', onClick }: StatCardProps) {
  return (
    <motion.div
      whileHover={{ y: -2 }}
      onClick={onClick}
      className={cn(
        'rounded-2xl border p-5 bg-white transition-shadow hover:shadow-lg cursor-pointer',
        colorMap[color]?.split(' ')[0] ? '' : ''
      )}
    >
      <div className="flex items-start justify-between">
        <div className="space-y-2">
          <p className="text-sm font-medium text-slate-500">{title}</p>
          <p className="text-2xl font-bold text-slate-900">{value}</p>
          {trend && (
            <p className={cn('text-xs font-medium flex items-center gap-1', trend.isUp ? 'text-emerald-600' : 'text-red-500')}>
              <span>{trend.isUp ? '↑' : '↓'}</span>
              <span>{Math.abs(trend.value)}% so với tháng trước</span>
            </p>
          )}
        </div>
        {icon && (
          <div className={cn('p-3 rounded-xl', colorMap[color] || 'bg-blue-50')}>
            {icon}
          </div>
        )}
      </div>
    </motion.div>
  );
}
