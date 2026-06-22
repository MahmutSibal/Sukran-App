/** Hafif inline SVG ikon seti (harici ikon paketi gerektirmez). */

type IconProps = Omit<React.SVGProps<SVGSVGElement>, "strokeWidth"> & { size?: number };

function base({ size = 20, strokeWidth = 1.8, children, ...rest }: IconProps & { children: React.ReactNode; strokeWidth?: number }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={strokeWidth}
      strokeLinecap="round"
      strokeLinejoin="round"
      {...rest}
    >
      {children}
    </svg>
  );
}

export const Icon = {
  Dashboard: (p: IconProps) =>
    base({ ...p, children: <><rect x="3" y="3" width="7" height="9" rx="1.5" /><rect x="14" y="3" width="7" height="5" rx="1.5" /><rect x="14" y="12" width="7" height="9" rx="1.5" /><rect x="3" y="16" width="7" height="5" rx="1.5" /></> }),
  Store: (p: IconProps) =>
    base({ ...p, children: <><path d="M3 9.5 4.5 4h15L21 9.5" /><path d="M4 9.5v9a1.5 1.5 0 0 0 1.5 1.5h13a1.5 1.5 0 0 0 1.5-1.5v-9" /><path d="M3 9.5a3 3 0 0 0 6 0 3 3 0 0 0 6 0 3 3 0 0 0 6 0" /></> }),
  Users: (p: IconProps) =>
    base({ ...p, children: <><circle cx="9" cy="8" r="3.2" /><path d="M3.5 19a5.5 5.5 0 0 1 11 0" /><path d="M16 6.2a3 3 0 0 1 0 5.6" /><path d="M17.5 14.5A5.5 5.5 0 0 1 20.5 19" /></> }),
  Fire: (p: IconProps) =>
    base({ ...p, children: <path d="M12 3c.5 3-2 4.5-2 7a2 2 0 0 0 4 0c0-.7-.2-1.2-.4-1.7C15.5 9.6 17 11.7 17 14a5 5 0 0 1-10 0c0-3.3 2.5-5.3 3.5-8 .4-1 1-2 1.5-3Z" /> }),
  Table: (p: IconProps) =>
    base({ ...p, children: <><rect x="3" y="4" width="18" height="16" rx="2" /><path d="M3 9h18M9 9v11M15 9V20" /></> }),
  Menu: (p: IconProps) =>
    base({ ...p, children: <><path d="M4 6h16M4 12h16M4 18h10" /><circle cx="19" cy="18" r="1.4" /></> }),
  Bell: (p: IconProps) =>
    base({ ...p, children: <><path d="M18 8a6 6 0 0 0-12 0c0 6-2 7-2 7h16s-2-1-2-7" /><path d="M10.5 19a1.7 1.7 0 0 0 3 0" /></> }),
  Logout: (p: IconProps) =>
    base({ ...p, children: <><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /><path d="M16 17l5-5-5-5M21 12H9" /></> }),
  Plus: (p: IconProps) => base({ ...p, children: <path d="M12 5v14M5 12h14" /> }),
  ChevronLeft: (p: IconProps) => base({ ...p, children: <path d="M15 6l-6 6 6 6" /> }),
  ChevronRight: (p: IconProps) => base({ ...p, children: <path d="M9 6l6 6-6 6" /> }),
  ArrowRight: (p: IconProps) => base({ ...p, children: <path d="M5 12h14M13 6l6 6-6 6" /> }),
  Wallet: (p: IconProps) =>
    base({ ...p, children: <><rect x="3" y="6" width="18" height="13" rx="2" /><path d="M3 10h18" /><circle cx="17" cy="14" r="1.2" /></> }),
  Heart: (p: IconProps) => base({ ...p, children: <path d="M12 20s-7-4.5-9.5-9A4.5 4.5 0 0 1 12 6a4.5 4.5 0 0 1 9.5 5c-2.5 4.5-9.5 9-9.5 9Z" /> }),
  Pencil: (p: IconProps) =>
    base({ ...p, children: <><path d="M4 20h4l10-10-4-4L4 16v4Z" /><path d="M13.5 6.5l4 4" /></> }),
  Trash: (p: IconProps) =>
    base({ ...p, children: <><path d="M4 7h16M9 7V5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2M6 7l1 13a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1l1-13" /></> }),
  Clock: (p: IconProps) => base({ ...p, children: <><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></> }),
  Check: (p: IconProps) => base({ ...p, children: <path d="M5 12l5 5L20 7" /> }),
  Search: (p: IconProps) => base({ ...p, children: <><circle cx="11" cy="11" r="7" /><path d="m20 20-3.2-3.2" /></> }),
  Pulse: (p: IconProps) => base({ ...p, children: <path d="M3 12h4l2-6 4 12 2-6h6" /> }),
};
