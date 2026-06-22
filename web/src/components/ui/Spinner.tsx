import { cn } from "@/lib/cn";

export function Spinner({ size = 18, className }: { size?: number; className?: string }) {
  return (
    <span
      role="status"
      aria-label="Yükleniyor"
      className={cn("inline-block animate-spin rounded-full border-2 border-current border-t-transparent", className)}
      style={{ width: size, height: size }}
    />
  );
}

export function LoadingState({ label = "Yükleniyor…" }: { label?: string }) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 py-16 text-content-muted">
      <Spinner size={26} className="text-gold" />
      <span className="text-sm">{label}</span>
    </div>
  );
}

export function EmptyState({
  icon,
  title,
  description,
  action,
}: {
  icon?: React.ReactNode;
  title: string;
  description?: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 py-16 text-center">
      {icon && <div className="text-3xl text-gold">{icon}</div>}
      <h3 className="text-base font-semibold text-content">{title}</h3>
      {description && <p className="max-w-sm text-sm text-content-muted">{description}</p>}
      {action}
    </div>
  );
}

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 py-16 text-center">
      <h3 className="text-base font-semibold text-coral">Bir şeyler ters gitti</h3>
      <p className="max-w-md text-sm text-content-muted">{message}</p>
      {onRetry && (
        <button onClick={onRetry} className="text-sm font-semibold text-gold hover:underline">
          Tekrar dene
        </button>
      )}
    </div>
  );
}
