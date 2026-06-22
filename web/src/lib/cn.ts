import clsx, { type ClassValue } from "clsx";

/** Koşullu sınıf birleştirme yardımcısı. */
export function cn(...inputs: ClassValue[]): string {
  return clsx(inputs);
}
