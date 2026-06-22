import { cn } from "@/lib/cn";

type Tone = "gold" | "sage" | "coral" | "neutral" | "info";

const tones: Record<Tone, string> = {
  gold: "border-gold/40 bg-gold/15 text-gold",
  sage: "border-sage/40 bg-sage/15 text-sage",
  coral: "border-coral/40 bg-coral/15 text-coral",
  neutral: "border-line bg-white/5 text-content-muted",
  info: "border-sky-400/30 bg-sky-400/10 text-sky-300",
};

export function Badge({
  tone = "neutral",
  children,
  className,
  dot,
}: {
  tone?: Tone;
  children: React.ReactNode;
  className?: string;
  dot?: boolean;
}) {
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs font-semibold",
        tones[tone],
        className,
      )}
    >
      {dot && <span className="h-1.5 w-1.5 rounded-full bg-current" />}
      {children}
    </span>
  );
}
