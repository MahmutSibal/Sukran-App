"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { roleHome, useAuth } from "@/context/AuthContext";
import { useToast } from "@/context/ToastContext";
import { Button } from "@/components/ui/Button";
import { Field, TextInput } from "@/components/ui/Form";
import { Icon } from "@/components/icons";

export default function LoginPage() {
  const { login, identity, isReady } = useAuth();
  const router = useRouter();
  const toast = useToast();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);

  // Zaten oturum açıksa panele gönder.
  useEffect(() => {
    if (isReady && identity) router.replace(roleHome(identity.role));
  }, [isReady, identity, router]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    try {
      const next = await login(email.trim(), password);
      router.replace(roleHome(next.role));
      toast.success("Hoş geldiniz.");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Giriş başarısız.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="grid min-h-screen place-items-center px-4">
      <div className="w-full max-w-md">
        <div className="mb-8 flex flex-col items-center text-center">
          <div className="mb-4 grid h-14 w-14 place-items-center rounded-2xl btn-gold text-2xl font-black shadow-glow">
            S
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-content">AppSukran Yönetim</h1>
          <p className="mt-1 text-sm text-content-muted">SuperAdmin &amp; Restoran Sahibi paneli</p>
        </div>

        <form onSubmit={handleSubmit} className="surface-panel space-y-4 p-6">
          <Field label="E-posta" required>
            <TextInput
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="yonetici@sukran.com"
              autoComplete="username"
              required
            />
          </Field>
          <Field label="Parola" required>
            <TextInput
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              autoComplete="current-password"
              required
            />
          </Field>

          <Button type="submit" size="lg" loading={loading} className="w-full" icon={<Icon.ArrowRight size={18} />}>
            Panele Giriş
          </Button>
        </form>
      </div>
    </div>
  );
}
