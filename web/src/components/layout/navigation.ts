import { UserRole } from "@/lib/enums";
import { Icon } from "@/components/icons";

export interface NavItem {
  label: string;
  href: string;
  icon: (typeof Icon)[keyof typeof Icon];
  roles: UserRole[];
  section: "SuperAdmin" | "Restoran";
}

export const NAV_ITEMS: NavItem[] = [
  {
    label: "Sistem Paneli",
    href: "/superadmin",
    icon: Icon.Dashboard,
    roles: [UserRole.SuperAdmin],
    section: "SuperAdmin",
  },
  {
    label: "Restoran & Kullanıcı",
    href: "/superadmin/management",
    icon: Icon.Store,
    roles: [UserRole.SuperAdmin],
    section: "SuperAdmin",
  },
  {
    label: "Canlı Mutfak",
    href: "/owner/kitchen",
    icon: Icon.Fire,
    roles: [UserRole.SuperAdmin, UserRole.RestaurantOwner, UserRole.WaiterCashier],
    section: "Restoran",
  },
  {
    label: "Masalar & Hesaplar",
    href: "/owner/tables",
    icon: Icon.Table,
    roles: [UserRole.SuperAdmin, UserRole.RestaurantOwner, UserRole.WaiterCashier],
    section: "Restoran",
  },
  {
    label: "Menü Yönetimi",
    href: "/owner/menu",
    icon: Icon.Menu,
    roles: [UserRole.SuperAdmin, UserRole.RestaurantOwner],
    section: "Restoran",
  },
];

export function navItemsForRole(role: UserRole): NavItem[] {
  return NAV_ITEMS.filter((item) => item.roles.includes(role));
}
