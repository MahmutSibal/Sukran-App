"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/cn";
import { USER_ROLE_LABEL } from "@/lib/enums";
import { useAuth } from "@/context/AuthContext";
import { Icon } from "@/components/icons";
import { navItemsForRole } from "./navigation";

export function Sidebar({
  collapsed,
  onToggle,
}: {
  collapsed: boolean;
  onToggle: () => void;
}) {
  const pathname = usePathname();
  const { identity } = useAuth();
  if (!identity) return null;

  const items = navItemsForRole(identity.role);
  const sections = ["SuperAdmin", "Restoran"] as const;

  return (
    <aside
      className={cn(
        "sticky top-0 z-30 flex h-screen shrink-0 flex-col border-r border-line bg-ink-900/80 backdrop-blur-xl transition-[width] duration-300",
        collapsed ? "w-[76px]" : "w-64",
      )}
    >
      {/* Marka */}
      <div className="flex h-16 items-center gap-3 px-4">
        <div className="grid h-9 w-9 shrink-0 place-items-center rounded-xl btn-gold font-black">S</div>
        {!collapsed && (
          <div className="min-w-0">
            <p className="truncate text-sm font-bold tracking-tight text-content">AppSukran</p>
            <p className="truncate text-xs text-content-faint">Yönetim Paneli</p>
          </div>
        )}
      </div>

      <nav className="flex-1 space-y-6 overflow-y-auto px-3 py-4">
        {sections.map((section) => {
          const sectionItems = items.filter((i) => i.section === section);
          if (!sectionItems.length) return null;
          return (
            <div key={section}>
              {!collapsed && (
                <p className="px-3 pb-2 text-[10px] font-semibold uppercase tracking-[0.14em] text-content-faint">
                  {section}
                </p>
              )}
              <ul className="space-y-1">
                {sectionItems.map((item) => {
                  const active = pathname === item.href || pathname.startsWith(item.href + "/");
                  const ItemIcon = item.icon;
                  return (
                    <li key={item.href}>
                      <Link
                        href={item.href}
                        title={collapsed ? item.label : undefined}
                        className={cn(
                          "group relative flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors",
                          active
                            ? "bg-gold/15 text-gold"
                            : "text-content-muted hover:bg-white/5 hover:text-content",
                          collapsed && "justify-center",
                        )}
                      >
                        {active && (
                          <span className="absolute left-0 top-1/2 h-5 w-1 -translate-y-1/2 rounded-r-full bg-gold" />
                        )}
                        <ItemIcon size={20} />
                        {!collapsed && <span className="truncate">{item.label}</span>}
                      </Link>
                    </li>
                  );
                })}
              </ul>
            </div>
          );
        })}
      </nav>

      {/* Kullanıcı + daralt */}
      <div className="border-t border-line p-3">
        {!collapsed && (
          <div className="mb-2 rounded-xl bg-ink-800/70 px-3 py-2.5">
            <p className="truncate text-sm font-semibold text-content">{identity.name}</p>
            <p className="truncate text-xs text-gold">{USER_ROLE_LABEL[identity.role]}</p>
          </div>
        )}
        <button
          onClick={onToggle}
          className="focus-ring flex w-full items-center justify-center gap-2 rounded-xl px-3 py-2 text-xs font-medium text-content-muted hover:bg-white/5 hover:text-content"
        >
          {collapsed ? <Icon.ChevronRight size={18} /> : <><Icon.ChevronLeft size={18} /> Menüyü daralt</>}
        </button>
      </div>
    </aside>
  );
}
