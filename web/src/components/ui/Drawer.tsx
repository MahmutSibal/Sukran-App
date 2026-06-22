"use client";

import { useEffect } from "react";

/** Sağdan açılan yan panel (masa adisyon detayı için). */
export function Drawer({
  open,
  onClose,
  title,
  subtitle,
  children,
  footer,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  subtitle?: string;
  children: React.ReactNode;
  footer?: React.ReactNode;
}) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50">
      <div className="absolute inset-0 animate-fade-in bg-black/55 backdrop-blur-sm" onClick={onClose} />
      <aside className="absolute right-0 top-0 flex h-full w-full max-w-md animate-slide-in flex-col border-l border-line bg-ink-850 shadow-drawer">
        <header className="flex items-start justify-between gap-4 border-b border-line px-6 py-5">
          <div>
            <h3 className="text-lg font-semibold text-content">{title}</h3>
            {subtitle && <p className="mt-0.5 text-sm text-content-muted">{subtitle}</p>}
          </div>
          <button
            onClick={onClose}
            className="focus-ring grid h-8 w-8 place-items-center rounded-lg text-content-muted hover:bg-white/5 hover:text-content"
            aria-label="Kapat"
          >
            ✕
          </button>
        </header>
        <div className="flex-1 overflow-y-auto px-6 py-5">{children}</div>
        {footer && <footer className="border-t border-line bg-ink-900/40 px-6 py-4">{footer}</footer>}
      </aside>
    </div>
  );
}
