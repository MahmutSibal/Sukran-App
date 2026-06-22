"use client";

import { useEffect, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { roleHome, useAuth } from "@/context/AuthContext";
import { UserRole } from "@/lib/enums";
import { LoadingState } from "@/components/ui/Spinner";
import { Sidebar } from "./Sidebar";

export function DashboardShell({ children }: { children: React.ReactNode }) {
  const { isReady, isAuthenticated, identity } = useAuth();
  const router = useRouter();
  const pathname = usePathname();
  const [collapsed, setCollapsed] = useState(false);

  // /superadmin alanı yalnızca SuperAdmin'e açıktır (backend de 403 ile korur;
  // bu istemci tarafı guard yetkisiz UI'ın hiç render olmamasını sağlar).
  const isAllowed =
    !pathname.startsWith("/superadmin") || identity?.role === UserRole.SuperAdmin;

  useEffect(() => {
    if (!isReady) return;
    if (!isAuthenticated) {
      router.replace("/login");
    } else if (!isAllowed && identity) {
      router.replace(roleHome(identity.role));
    }
  }, [isReady, isAuthenticated, isAllowed, identity, router]);

  if (!isReady) {
    return (
      <div className="grid min-h-screen place-items-center">
        <LoadingState label="Oturum doğrulanıyor…" />
      </div>
    );
  }

  if (!isAuthenticated || !isAllowed) return null;

  return (
    <div className="flex min-h-screen">
      <Sidebar collapsed={collapsed} onToggle={() => setCollapsed((v) => !v)} />
      <div className="flex min-w-0 flex-1 flex-col">{children}</div>
    </div>
  );
}
