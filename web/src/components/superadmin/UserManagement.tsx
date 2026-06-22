"use client";

import { useEffect, useState } from "react";
import { USER_ROLE_LABEL, UserRole } from "@/lib/enums";
import type { AppUser } from "@/lib/types";
import { userService } from "@/services/userService";
import { useToast } from "@/context/ToastContext";
import { useDisclosure } from "@/hooks/useDisclosure";
import { Card, PanelHeader } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { Badge } from "@/components/ui/Badge";
import { Modal } from "@/components/ui/Modal";
import { Field, Select, TextInput } from "@/components/ui/Form";
import { DataTable, TBody, TD, TH, THead, TR } from "@/components/ui/Table";
import { EmptyState, ErrorState, LoadingState } from "@/components/ui/Spinner";
import { Icon } from "@/components/icons";

// Panelden atanabilecek roller (SuperAdmin oluşturulamaz).
const ROLE_OPTIONS = [UserRole.RestaurantOwner, UserRole.WaiterCashier];

const roleTone: Record<number, "gold" | "sage" | "info" | "neutral"> = {
  [UserRole.SuperAdmin]: "gold",
  [UserRole.RestaurantOwner]: "sage",
  [UserRole.WaiterCashier]: "info",
  [UserRole.Customer]: "neutral",
};

export function UserManagement({
  users,
  loading,
  error,
  reload,
}: {
  users: AppUser[] | null;
  loading: boolean;
  error: string | null;
  reload: () => void;
}) {
  const toast = useToast();
  const roleModal = useDisclosure();
  const passwordModal = useDisclosure();
  const createModal = useDisclosure();
  const [active, setActive] = useState<AppUser | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  function openRole(user: AppUser) {
    setActive(user);
    roleModal.open();
  }
  function openPassword(user: AppUser) {
    setActive(user);
    passwordModal.open();
  }

  async function remove(user: AppUser) {
    if (!window.confirm(`"${user.name || user.email}" kullanıcısı silinsin mi?`)) return;
    setDeletingId(user.id);
    try {
      await userService.remove(user.id);
      toast.success("Kullanıcı silindi.");
      reload();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Kullanıcı silinemedi.");
    } finally {
      setDeletingId(null);
    }
  }

  return (
    <Card>
      <PanelHeader
        title="Kullanıcı Yönetimi"
        subtitle="Oluştur · rol ata · şifre değiştir · sil"
        icon={<Icon.Users size={18} />}
        actions={
          <Button size="sm" icon={<Icon.Plus size={16} />} onClick={createModal.open}>
            Kullanıcı Ekle
          </Button>
        }
      />

      {loading && !users ? (
        <LoadingState label="Kullanıcılar yükleniyor…" />
      ) : error && !users ? (
        <ErrorState message={error} onRetry={reload} />
      ) : (users ?? []).length === 0 ? (
        <EmptyState
          icon={<Icon.Users size={28} />}
          title="Henüz kullanıcı yok"
          description="Sağ üstten yeni kullanıcı oluşturun."
        />
      ) : (
        <DataTable>
          <THead>
            <TR>
              <TH>Kullanıcı</TH>
              <TH>Rol</TH>
              <TH>Restoran</TH>
              <TH className="text-right">Aksiyonlar</TH>
            </TR>
          </THead>
          <TBody>
            {(users ?? []).map((user) => (
              <TR key={user.id}>
                <TD>
                  <div>
                    <p className="font-medium text-content">{user.name || "—"}</p>
                    {user.email && <p className="text-xs text-content-faint">{user.email}</p>}
                  </div>
                </TD>
                <TD>
                  <Badge tone={roleTone[user.role] ?? "neutral"}>{USER_ROLE_LABEL[user.role]}</Badge>
                </TD>
                <TD className="font-mono text-xs text-content-muted">{user.restaurantId || "—"}</TD>
                <TD className="text-right">
                  <div className="flex justify-end gap-2">
                    <Button size="sm" variant="outline" onClick={() => openRole(user)}>
                      Rol
                    </Button>
                    <Button size="sm" variant="ghost" onClick={() => openPassword(user)}>
                      Şifre
                    </Button>
                    <button
                      onClick={() => remove(user)}
                      disabled={deletingId === user.id}
                      className="focus-ring grid h-9 w-9 place-items-center rounded-lg text-content-muted hover:bg-coral/10 hover:text-coral disabled:opacity-50"
                      aria-label="Sil"
                    >
                      <Icon.Trash size={16} />
                    </button>
                  </div>
                </TD>
              </TR>
            ))}
          </TBody>
        </DataTable>
      )}

      <CreateUserModal open={createModal.isOpen} onClose={createModal.close} onCreated={reload} />
      <RoleModal open={roleModal.isOpen} user={active} onClose={roleModal.close} onSaved={reload} />
      <PasswordModal open={passwordModal.isOpen} user={active} onClose={passwordModal.close} />
    </Card>
  );
}

function CreateUserModal({
  open,
  onClose,
  onCreated,
}: {
  open: boolean;
  onClose: () => void;
  onCreated: () => void;
}) {
  const toast = useToast();
  const [form, setForm] = useState({ name: "", email: "", password: "", role: UserRole.RestaurantOwner });
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (open) setForm({ name: "", email: "", password: "", role: UserRole.RestaurantOwner });
  }, [open]);

  async function save() {
    if (!form.name.trim() || !form.email.trim()) {
      toast.error("Ad ve e-posta zorunlu.");
      return;
    }
    if (form.password.length < 8) {
      toast.error("Şifre en az 8 karakter olmalı.");
      return;
    }
    setSaving(true);
    try {
      // restaurantId opsiyonel: sahip ataması restoran oluşturulurken yapılır.
      await userService.create({
        name: form.name.trim(),
        email: form.email.trim(),
        password: form.password,
        role: form.role,
      });
      toast.success("Kullanıcı oluşturuldu.");
      onCreated();
      onClose();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Kullanıcı oluşturulamadı.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Yeni Kullanıcı"
      description="POST /api/users"
      size="sm"
      footer={
        <>
          <Button variant="ghost" onClick={onClose}>
            Vazgeç
          </Button>
          <Button loading={saving} onClick={save} icon={<Icon.Check size={18} />}>
            Oluştur
          </Button>
        </>
      }
    >
      <div className="space-y-4">
        <Field label="Ad" required>
          <TextInput value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="Ahmet Yılmaz" />
        </Field>
        <Field label="E-posta" required>
          <TextInput
            type="email"
            value={form.email}
            onChange={(e) => setForm({ ...form, email: e.target.value })}
            placeholder="ahmet@sukran.com"
          />
        </Field>
        <Field label="Şifre" required hint="En az 8 karakter">
          <TextInput
            type="password"
            value={form.password}
            onChange={(e) => setForm({ ...form, password: e.target.value })}
            placeholder="••••••••"
            autoComplete="new-password"
          />
        </Field>
        <Field label="Rol" required>
          <Select value={form.role} onChange={(e) => setForm({ ...form, role: Number(e.target.value) as UserRole })}>
            {ROLE_OPTIONS.map((r) => (
              <option key={r} value={r}>
                {USER_ROLE_LABEL[r]}
              </option>
            ))}
          </Select>
        </Field>
      </div>
    </Modal>
  );
}

function RoleModal({
  open,
  user,
  onClose,
  onSaved,
}: {
  open: boolean;
  user: AppUser | null;
  onClose: () => void;
  onSaved: () => void;
}) {
  const toast = useToast();
  const [role, setRole] = useState<UserRole>(UserRole.RestaurantOwner);
  const [restaurantId, setRestaurantId] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (user) {
      setRole(user.role === UserRole.SuperAdmin ? UserRole.RestaurantOwner : user.role);
      setRestaurantId(user.restaurantId ?? "");
    }
  }, [user]);

  const requiresRestaurant = role === UserRole.RestaurantOwner || role === UserRole.WaiterCashier;

  async function save() {
    if (!user) return;
    if (requiresRestaurant && !restaurantId.trim()) {
      toast.error("Bu rol için restaurantId zorunlu.");
      return;
    }
    setSaving(true);
    try {
      await userService.updateRole(user.id, role, requiresRestaurant ? restaurantId.trim() : null);
      toast.success("Kullanıcı rolü güncellendi.");
      onSaved();
      onClose();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Rol güncellenemedi.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Rolü Değiştir"
      description={user ? user.name || user.email : undefined}
      size="sm"
      footer={
        <>
          <Button variant="ghost" onClick={onClose}>
            Vazgeç
          </Button>
          <Button loading={saving} onClick={save} icon={<Icon.Check size={18} />}>
            Kaydet
          </Button>
        </>
      }
    >
      <div className="space-y-4">
        <Field label="Yeni rol (UserRole)" required>
          <Select value={role} onChange={(e) => setRole(Number(e.target.value) as UserRole)}>
            {ROLE_OPTIONS.map((r) => (
              <option key={r} value={r}>
                {USER_ROLE_LABEL[r]}
              </option>
            ))}
          </Select>
        </Field>
        {requiresRestaurant && (
          <Field label="Restoran ID" required hint="RestaurantOwner / Garson-Kasa için zorunlu">
            <TextInput
              value={restaurantId}
              onChange={(e) => setRestaurantId(e.target.value)}
              className="font-mono"
              placeholder="restaurant-..."
            />
          </Field>
        )}
      </div>
    </Modal>
  );
}

function PasswordModal({ open, user, onClose }: { open: boolean; user: AppUser | null; onClose: () => void }) {
  const toast = useToast();
  const [password, setPassword] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (open) setPassword("");
  }, [open]);

  async function save() {
    if (!user) return;
    if (password.length < 8) {
      toast.error("Şifre en az 8 karakter olmalı.");
      return;
    }
    setSaving(true);
    try {
      await userService.resetPassword(user.id, password);
      toast.success("Şifre güncellendi.");
      onClose();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Şifre güncellenemedi.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Şifre Değiştir"
      description={user ? user.name || user.email : undefined}
      size="sm"
      footer={
        <>
          <Button variant="ghost" onClick={onClose}>
            Vazgeç
          </Button>
          <Button loading={saving} onClick={save} icon={<Icon.Check size={18} />}>
            Güncelle
          </Button>
        </>
      }
    >
      <Field label="Yeni şifre" required hint="En az 8 karakter">
        <TextInput
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          placeholder="••••••••"
          autoComplete="new-password"
        />
      </Field>
    </Modal>
  );
}
