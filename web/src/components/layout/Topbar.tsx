"use client";

import { useState } from "react";
import { USER_ROLE_LABEL } from "@/lib/enums";
import { initialsOf } from "@/lib/format";
import { useAuth } from "@/context/AuthContext";
import { Icon } from "@/components/icons";

export function Topbar({ title, subtitle }: { title: string; subtitle?: string }) {
  const { identity, logout } = useAuth();
  const [menuOpen, setMenuOpen] = useState(false);
  if (!identity) return null;

  return (
    <header className="sticky top-0 z-20 flex h-16 items-center justify-between gap-4 border-b border-line bg-ink-950/70 px-6 backdrop-blur-xl">
      <div>
        <h1 className="text-base font-semibold tracking-tight text-content">{title}</h1>
        {subtitle && <p className="text-xs text-content-muted">{subtitle}</p>}
      </div>

      <div className="flex items-center gap-2">
        <button className="focus-ring relative grid h-10 w-10 place-items-center rounded-xl text-content-muted hover:bg-white/5 hover:text-content">
          <Icon.Bell size={20} />
          <span className="absolute right-2.5 top-2.5 h-2 w-2 rounded-full bg-coral ring-2 ring-ink-950" />
        </button>

        <div className="relative">
          <button
            onClick={() => setMenuOpen((v) => !v)}
            onBlur={() => setTimeout(() => setMenuOpen(false), 150)}
            className="focus-ring flex items-center gap-3 rounded-xl py-1.5 pl-1.5 pr-3 hover:bg-white/5"
          >
            <span className="grid h-9 w-9 place-items-center rounded-lg btn-gold text-sm font-bold">
              {initialsOf(identity.name)}
            </span>
            <span className="hidden text-left sm:block">
              <span className="block text-sm font-semibold leading-tight text-content">{identity.name}</span>
              <span className="block text-xs leading-tight text-content-faint">
                {USER_ROLE_LABEL[identity.role]}
              </span>
            </span>
          </button>

          {menuOpen && (
            <div className="absolute right-0 top-12 w-52 animate-pop-in rounded-card border border-line bg-ink-800 p-1.5 shadow-card">
              <div className="px-3 py-2">
                <p className="truncate text-sm font-semibold text-content">{identity.email || identity.name}</p>
                {identity.restaurantId && (
                  <p className="truncate text-xs text-content-faint">Restoran: {identity.restaurantId}</p>
                )}
              </div>
              <button
                onClick={() => logout()}
                className="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm font-medium text-coral hover:bg-coral/10"
              >
                <Icon.Logout size={18} /> Çıkış Yap
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
