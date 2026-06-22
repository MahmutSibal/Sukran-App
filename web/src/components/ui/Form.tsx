"use client";

import { forwardRef, useState } from "react";
import { cn } from "@/lib/cn";

export function Field({
  label,
  hint,
  error,
  required,
  children,
  className,
}: {
  label?: string;
  hint?: string;
  error?: string;
  required?: boolean;
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <label className={cn("flex flex-col gap-1.5", className)}>
      {label && (
        <span className="text-sm font-medium text-content-muted">
          {label}
          {required && <span className="ml-0.5 text-coral">*</span>}
        </span>
      )}
      {children}
      {error ? (
        <span className="text-xs text-coral">{error}</span>
      ) : (
        hint && <span className="text-xs text-content-faint">{hint}</span>
      )}
    </label>
  );
}

const fieldBase =
  "focus-ring w-full rounded-xl border border-line bg-ink-900/70 px-3.5 py-2.5 text-sm text-content placeholder:text-content-faint transition-colors focus:border-gold/50";

export const TextInput = forwardRef<HTMLInputElement, React.InputHTMLAttributes<HTMLInputElement>>(
  function TextInput({ className, ...rest }, ref) {
    return <input ref={ref} className={cn(fieldBase, className)} {...rest} />;
  },
);

export const TextArea = forwardRef<HTMLTextAreaElement, React.TextareaHTMLAttributes<HTMLTextAreaElement>>(
  function TextArea({ className, ...rest }, ref) {
    return <textarea ref={ref} className={cn(fieldBase, "min-h-[88px] resize-y", className)} {...rest} />;
  },
);

export const Select = forwardRef<HTMLSelectElement, React.SelectHTMLAttributes<HTMLSelectElement>>(
  function Select({ className, children, ...rest }, ref) {
    return (
      <select ref={ref} className={cn(fieldBase, "appearance-none bg-[length:0]", className)} {...rest}>
        {children}
      </select>
    );
  },
);

export function Switch({
  checked,
  onChange,
  label,
}: {
  checked: boolean;
  onChange: (next: boolean) => void;
  label?: string;
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      onClick={() => onChange(!checked)}
      className="focus-ring inline-flex items-center gap-3"
    >
      <span
        className={cn(
          "relative h-6 w-11 rounded-full transition-colors",
          checked ? "bg-sage" : "bg-ink-600",
        )}
      >
        <span
          className={cn(
            "absolute top-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform",
            checked ? "translate-x-[22px]" : "translate-x-0.5",
          )}
        />
      </span>
      {label && <span className="text-sm text-content">{label}</span>}
    </button>
  );
}

/** Etiket/tag (chips) girişi — menü "içindekiler" alanı için. */
export function ChipsInput({
  values,
  onChange,
  placeholder = "Yaz ve Enter'a bas…",
}: {
  values: string[];
  onChange: (next: string[]) => void;
  placeholder?: string;
}) {
  const [draft, setDraft] = useState("");

  function commit() {
    const trimmed = draft.trim();
    if (trimmed && !values.includes(trimmed)) onChange([...values, trimmed]);
    setDraft("");
  }

  return (
    <div className={cn(fieldBase, "flex flex-wrap items-center gap-2")}>
      {values.map((value) => (
        <span
          key={value}
          className="inline-flex items-center gap-1.5 rounded-lg border border-gold/30 bg-gold/10 px-2 py-1 text-xs font-medium text-gold"
        >
          {value}
          <button
            type="button"
            onClick={() => onChange(values.filter((v) => v !== value))}
            className="text-gold/70 hover:text-gold"
            aria-label={`${value} kaldır`}
          >
            ×
          </button>
        </span>
      ))}
      <input
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === "Enter" || e.key === ",") {
            e.preventDefault();
            commit();
          } else if (e.key === "Backspace" && !draft && values.length) {
            onChange(values.slice(0, -1));
          }
        }}
        onBlur={commit}
        placeholder={values.length ? "" : placeholder}
        className="min-w-[120px] flex-1 bg-transparent text-sm text-content outline-none placeholder:text-content-faint"
      />
    </div>
  );
}
