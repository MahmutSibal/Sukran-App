"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { roleHome, useAuth } from "@/context/AuthContext";
import { LoadingState } from "@/components/ui/Spinner";

export default function RootRedirect() {
  const { isReady, identity } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!isReady) return;
    router.replace(identity ? roleHome(identity.role) : "/login");
  }, [isReady, identity, router]);

  return (
    <div className="grid min-h-screen place-items-center">
      <LoadingState label="Yönlendiriliyor…" />
    </div>
  );
}
