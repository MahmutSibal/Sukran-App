"use client";

import { useEffect } from "react";
import { cn } from "@/lib/cn";

export function Modal({
  open,
  onClose,
  title,
  description,
  children,
  footer,
  size = "md",
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  description?: string;
  children: React.ReactNode;
  footer?: React.ReactNode;
  size?: "sm" | "md" | "lg";
}) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", onKey);
    document.body.style.overflow = "hidden";
    return () => {
      window.removeEventListener("keydown", onKey);
      document.body.style.overflow = "";
    };
  }, [open, onClose]);

  if (!open) return null;

  const widths = { sm: "max-w-md", md: "max-w-xl", lg: "max-w-3xl" } as const;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 animate-fade-in bg-black/65 backdrop-blur-sm" onClick={onClose} />
      <div
        role="dialog"
        aria-modal="true"
        className={cn(
          "surface-panel relative z-10 max-h-[90vh] w-full animate-pop-in overflow-hidden",
          widths[size],
        )}
      >
        <div className="flex items-start justify-between gap-4 border-b border-line px-6 py-5">
          <div>
            <h3 className="text-lg font-semibold text-content">{title}</h3>
            {description && <p className="mt-0.5 text-sm text-content-muted">{description}</p>}
          </div>
          <button
            onClick={onClose}
            className="focus-ring -mr-1 grid h-8 w-8 place-items-center rounded-lg text-content-muted hover:bg-white/5 hover:text-content"
            aria-label="Kapat"
          >
            ✕
          </button>
        </div>
        <div className="max-h-[calc(90vh-9rem)] overflow-y-auto px-6 py-5">{children}</div>
        {footer && (
          <div className="flex items-center justify-end gap-3 border-t border-line bg-ink-900/40 px-6 py-4">
            {footer}
          </div>
        )}
      </div>
    </div>
  );
}
