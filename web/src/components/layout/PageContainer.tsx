"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { UserRole } from "@/lib/enums";
import { roleHome, useAuth } from "@/context/AuthContext";
import { EmptyState } from "@/components/ui/Spinner";
import { Topbar } from "./Topbar";

/**
 * Sayfa kabuğu: üstte Topbar, ortada içerik. `allow` verilirse rol bazlı
 * koruma uygular (yetkisiz kullanıcıyı kendi ana sayfasına yönlendirir).
 */
export function PageContainer({
  title,
  subtitle,
  allow,
  children,
}: {
  title: string;
  subtitle?: string;
  allow?: UserRole[];
  children: React.ReactNode;
}) {
  const { identity } = useAuth();
  const router = useRouter();

  const authorized = !allow || (identity ? allow.includes(identity.role) : false);

  useEffect(() => {
    if (identity && !authorized) {
      router.replace(roleHome(identity.role));
    }
  }, [identity, authorized, router]);

  return (
    <>
      <Topbar title={title} subtitle={subtitle} />
      <main className="flex-1 px-6 py-6">
        {authorized ? (
          children
        ) : (
          <EmptyState title="Erişim yetkiniz yok" description="Bu ekran yalnızca yetkili roller için görünür." />
        )}
      </main>
    </>
  );
}
