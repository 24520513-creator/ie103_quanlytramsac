import React from 'react';
import {
  ResponsiveContainer, AreaChart, Area, BarChart as ReBarChart, Bar,
  PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend
} from 'recharts';

const PALETTE = ['#10b981', '#06b6d4', '#6366f1', '#f59e0b', '#ef4444', '#8b5cf6', '#14b8a6', '#ec4899'];
const axisStyle = { fontSize: 11, fill: '#64748b' };
const gridStroke = '#e6ebf2';

const tooltipStyle = {
  borderRadius: 12,
  border: '1px solid #e6ebf2',
  boxShadow: '0 8px 24px rgba(15,23,42,0.12)',
  fontSize: 12
};

function shorten(n) {
  const v = Number(n);
  if (!Number.isFinite(v)) return n;
  if (Math.abs(v) >= 1e9) return `${(v / 1e9).toFixed(1)}B`;
  if (Math.abs(v) >= 1e6) return `${(v / 1e6).toFixed(1)}M`;
  if (Math.abs(v) >= 1e3) return `${(v / 1e3).toFixed(1)}K`;
  return v;
}

export function AreaTrend({ data, xKey, yKey, height = 260, color = '#10b981' }) {
  return (
    <ResponsiveContainer width="100%" height={height}>
      <AreaChart data={data} margin={{ top: 8, right: 12, left: 4, bottom: 4 }}>
        <defs>
          <linearGradient id={`area-${yKey}`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={color} stopOpacity={0.35} />
            <stop offset="100%" stopColor={color} stopOpacity={0.02} />
          </linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" stroke={gridStroke} vertical={false} />
        <XAxis dataKey={xKey} tick={axisStyle} tickLine={false} axisLine={{ stroke: gridStroke }} />
        <YAxis tickFormatter={shorten} tick={axisStyle} tickLine={false} axisLine={false} width={44} />
        <Tooltip contentStyle={tooltipStyle} formatter={(v) => new Intl.NumberFormat('vi-VN').format(v)} />
        <Area type="monotone" dataKey={yKey} stroke={color} strokeWidth={2.5} fill={`url(#area-${yKey})`} isAnimationActive={false} />
      </AreaChart>
    </ResponsiveContainer>
  );
}

export function Bars({ data, xKey, yKeys = [], height = 260, horizontal = false }) {
  const keys = Array.isArray(yKeys) ? yKeys : [yKeys];
  return (
    <ResponsiveContainer width="100%" height={height}>
      <ReBarChart data={data} layout={horizontal ? 'vertical' : 'horizontal'} margin={{ top: 8, right: 12, left: 4, bottom: 4 }}>
        <CartesianGrid strokeDasharray="3 3" stroke={gridStroke} vertical={!horizontal} horizontal={horizontal} />
        {horizontal ? (
          <>
            <XAxis type="number" tickFormatter={shorten} tick={axisStyle} tickLine={false} axisLine={false} />
            <YAxis type="category" dataKey={xKey} tick={axisStyle} tickLine={false} axisLine={{ stroke: gridStroke }} width={120} />
          </>
        ) : (
          <>
            <XAxis dataKey={xKey} tick={axisStyle} tickLine={false} axisLine={{ stroke: gridStroke }} />
            <YAxis tickFormatter={shorten} tick={axisStyle} tickLine={false} axisLine={false} width={44} />
          </>
        )}
        <Tooltip contentStyle={tooltipStyle} formatter={(v) => new Intl.NumberFormat('vi-VN').format(v)} cursor={{ fill: 'rgba(16,185,129,0.06)' }} />
        {keys.length > 1 && <Legend wrapperStyle={{ fontSize: 12 }} />}
        {keys.map((k, i) => (
          <Bar key={k} dataKey={k} fill={PALETTE[i % PALETTE.length]} radius={horizontal ? [0, 6, 6, 0] : [6, 6, 0, 0]} maxBarSize={46} isAnimationActive={false} />
        ))}
      </ReBarChart>
    </ResponsiveContainer>
  );
}

export function Donut({ data, nameKey, valueKey, height = 260 }) {
  return (
    <ResponsiveContainer width="100%" height={height}>
      <PieChart>
        <Pie data={data} dataKey={valueKey} nameKey={nameKey} cx="50%" cy="50%" innerRadius={58} outerRadius={88} paddingAngle={3} isAnimationActive={false}>
          {data.map((_, i) => <Cell key={i} fill={PALETTE[i % PALETTE.length]} />)}
        </Pie>
        <Tooltip contentStyle={tooltipStyle} formatter={(v) => new Intl.NumberFormat('vi-VN').format(v)} />
        <Legend wrapperStyle={{ fontSize: 12 }} />
      </PieChart>
    </ResponsiveContainer>
  );
}

export function Sparkline({ data, yKey, height = 48, color = '#10b981' }) {
  return (
    <ResponsiveContainer width="100%" height={height}>
      <AreaChart data={data} margin={{ top: 4, right: 0, left: 0, bottom: 0 }}>
        <defs>
          <linearGradient id={`spark-${yKey}`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={color} stopOpacity={0.4} />
            <stop offset="100%" stopColor={color} stopOpacity={0} />
          </linearGradient>
        </defs>
        <Area type="monotone" dataKey={yKey} stroke={color} strokeWidth={2} fill={`url(#spark-${yKey})`} isAnimationActive={false} />
      </AreaChart>
    </ResponsiveContainer>
  );
}

export { PALETTE };
