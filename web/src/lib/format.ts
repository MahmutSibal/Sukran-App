/** Biçimlendirme yardımcıları (TL para, mesafe, tarih). */

const tryFormatter = new Intl.NumberFormat("tr-TR", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

/** Backend `long` (kuruş) → "1.250,00 ₺". */
export function formatMinorAsTry(minor: number): string {
  return `${tryFormatter.format((minor ?? 0) / 100)} ₺`;
}

/** Kullanıcının girdiği TL metnini kuruşa çevirir ("1.250,50" → 125050). */
export function parseTryToMinor(text: string): number | null {
  const trimmed = text.trim();
  if (!trimmed) return null;
  const normalized = trimmed.replace(/\./g, "").replace(",", ".");
  const value = Number(normalized);
  if (!Number.isFinite(value) || value < 0) return null;
  return Math.round(value * 100);
}

/** Kuruş → düzenlenebilir TL metni (form alanı için). */
export function minorToTryInput(minor: number): string {
  return ((minor ?? 0) / 100).toFixed(2).replace(".", ",");
}

export function formatDistance(meters: number): string {
  if (meters >= 1000) return `${(meters / 1000).toFixed(1)} km`;
  return `${Math.round(meters)} m`;
}

export function initialsOf(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return "?";
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}
