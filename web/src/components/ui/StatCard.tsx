import { cn } from "@/lib/cn";

type Accent = "gold" | "sage" | "coral" | "info";

const accents: Record<Accent, { ring: string; text: string; glow: string }> = {
  gold: { ring: "bg-gold/15", text: "text-gold", glow: "before:bg-gold/10" },
  sage: { ring: "bg-sage/15", text: "text-sage", glow: "before:bg-sage/10" },
  coral: { ring: "bg-coral/15", text: "text-coral", glow: "before:bg-coral/10" },
  info: { ring: "bg-sky-400/15", text: "text-sky-300", glow: "before:bg-sky-400/10" },
};

export function StatCard({
  label,
  value,
  hint,
  icon,
  accent = "gold",
  trend,
}: {
  label: string;
  value: string;
  hint?: string;
  icon?: React.ReactNode;
  accent?: Accent;
  trend?: { value: string; positive: boolean };
}) {
  const a = accents[accent];
  return (
    <div
      className={cn(
        "surface-card relative overflow-hidden p-5",
        "before:absolute before:-right-8 before:-top-10 before:h-28 before:w-28 before:rounded-full before:blur-2xl",
        a.glow,
      )}
    >
      <div className="flex items-start justify-between">
        <span className="text-sm font-medium text-content-muted">{label}</span>
        {icon && <div className={cn("grid h-10 w-10 place-items-center rounded-xl", a.ring, a.text)}>{icon}</div>}
      </div>
      <div className="mt-4 flex items-end gap-2">
        <span className="text-3xl font-bold tracking-tight text-content">{value}</span>
        {trend && (
          <span className={cn("mb-1 text-xs font-semibold", trend.positive ? "text-sage" : "text-coral")}>
            {trend.positive ? "▲" : "▼"} {trend.value}
          </span>
        )}
      </div>
      {hint && <p className="mt-1 text-xs text-content-faint">{hint}</p>}
    </div>
  );
}
