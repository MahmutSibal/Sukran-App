"use client";

import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

const GOLD = "#E5BA73";
const SAGE = "#A3B18A";

const axisStyle = { fill: "#6B6B73", fontSize: 12 };
const gridStroke = "rgba(255,255,255,0.06)";

function ChartTooltip({ active, payload, label, suffix }: {
  active?: boolean;
  payload?: { value: number; name: string }[];
  label?: string;
  suffix?: string;
}) {
  if (!active || !payload?.length) return null;
  return (
    <div className="rounded-lg border border-line bg-ink-800 px-3 py-2 text-xs shadow-card">
      <p className="mb-1 font-semibold text-content">{label}</p>
      {payload.map((p) => (
        <p key={p.name} className="text-content-muted">
          {p.name}: <span className="font-semibold text-gold">{p.value.toLocaleString("tr-TR")}{suffix}</span>
        </p>
      ))}
    </div>
  );
}

export interface RestaurantRevenuePoint {
  name: string;
  revenue: number;
}

/** Restoran bazlı ciro karşılaştırma (bar). */
export function RestaurantRevenueBar({ data }: { data: RestaurantRevenuePoint[] }) {
  return (
    <ResponsiveContainer width="100%" height={260}>
      <BarChart data={data} margin={{ top: 8, right: 8, left: -12, bottom: 0 }}>
        <CartesianGrid vertical={false} stroke={gridStroke} />
        <XAxis dataKey="name" tick={axisStyle} tickLine={false} axisLine={false} />
        <YAxis tick={axisStyle} tickLine={false} axisLine={false} />
        <Tooltip cursor={{ fill: "rgba(255,255,255,0.03)" }} content={<ChartTooltip suffix=" ₺" />} />
        <Bar dataKey="revenue" radius={[8, 8, 0, 0]} maxBarSize={46}>
          {data.map((entry, index) => (
            <Cell key={entry.name} fill={index % 2 === 0 ? GOLD : SAGE} fillOpacity={0.9} />
          ))}
        </Bar>
      </BarChart>
    </ResponsiveContainer>
  );
}

export interface DailyRevenuePoint {
  day: string;
  revenue: number;
}

/** Günlük ciro trendi (alan/çizgi). */
export function DailyRevenueArea({ data }: { data: DailyRevenuePoint[] }) {
  return (
    <ResponsiveContainer width="100%" height={260}>
      <AreaChart data={data} margin={{ top: 8, right: 8, left: -12, bottom: 0 }}>
        <defs>
          <linearGradient id="goldFill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={GOLD} stopOpacity={0.4} />
            <stop offset="100%" stopColor={GOLD} stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid vertical={false} stroke={gridStroke} />
        <XAxis dataKey="day" tick={axisStyle} tickLine={false} axisLine={false} />
        <YAxis tick={axisStyle} tickLine={false} axisLine={false} />
        <Tooltip cursor={{ stroke: GOLD, strokeOpacity: 0.3 }} content={<ChartTooltip suffix=" ₺" />} />
        <Area
          type="monotone"
          dataKey="revenue"
          stroke={GOLD}
          strokeWidth={2.5}
          fill="url(#goldFill)"
          dot={{ r: 3, fill: GOLD }}
          activeDot={{ r: 5 }}
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}
