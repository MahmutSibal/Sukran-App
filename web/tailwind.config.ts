import type { Config } from "tailwindcss";

/**
 * AppSukran Web — Premium Koyu Mod tasarım sistemi token'ları.
 * Mobil uygulamadaki altın/füme dilini web'e taşır.
 */
const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        // Arka plan / yüzey katmanları — mobil ile aynı: derin zümrüt yeşili füme.
        ink: {
          950: "#061A0C", // en derin zemin
          900: "#08210F", // degrade üst (BgTop)
          850: "#0E3320", // ara yüzey
          800: "#143A26", // kart/konteyner (Surface)
          700: "#1C4A31", // iç içe yüzey / divider (SurfaceHigh)
          600: "#245A3C", // hover
        },
        // Birincil vurgu — mat altın (mobil Accent / AccentBright).
        gold: {
          DEFAULT: "#DDA15E",
          soft: "#C98A4A",
          bright: "#E9C46A",
        },
        // Onay / aktif — mobil Success.
        sage: {
          DEFAULT: "#6FCF97",
          deep: "#4FB87B",
        },
        // İptal / kritik — mobil Danger.
        coral: {
          DEFAULT: "#FF8A80",
          deep: "#E0675C",
        },
        // Altın @ ~%18 ince kenarlık (mobil Hairline).
        line: "rgba(221,161,94,0.18)",
        "line-strong": "rgba(221,161,94,0.32)",
        content: {
          DEFAULT: "#F5EFE0", // sıcak fildişi (TextPrimary)
          muted: "#A9BCAD", // soluk adaçayı (TextSecondary)
          faint: "#7C9180",
        },
      },
      borderRadius: {
        card: "16px", // buton / input / küçük kart
        panel: "28px", // büyük yüzey / sheet (mobil modül radius)
      },
      boxShadow: {
        card: "0 18px 40px -20px rgba(0,0,0,0.55)",
        glow: "0 8px 18px -4px rgba(221,161,94,0.40)",
        drawer: "-24px 0 60px -20px rgba(0,0,0,0.7)",
      },
      fontFamily: {
        sans: ["var(--font-geist-sans)", "system-ui", "sans-serif"],
      },
      keyframes: {
        "fade-in": { from: { opacity: "0" }, to: { opacity: "1" } },
        "slide-in": {
          from: { transform: "translateX(100%)" },
          to: { transform: "translateX(0)" },
        },
        "pop-in": {
          from: { opacity: "0", transform: "scale(0.96) translateY(8px)" },
          to: { opacity: "1", transform: "scale(1) translateY(0)" },
        },
        pulseGlow: {
          "0%,100%": { boxShadow: "0 0 0 0 rgba(221,161,94,0.0)" },
          "50%": { boxShadow: "0 0 0 4px rgba(221,161,94,0.20)" },
        },
      },
      animation: {
        "fade-in": "fade-in 0.25s ease-out",
        "slide-in": "slide-in 0.28s cubic-bezier(0.22,1,0.36,1)",
        "pop-in": "pop-in 0.2s ease-out",
        "pulse-glow": "pulseGlow 2s ease-in-out infinite",
      },
    },
  },
  plugins: [],
};

export default config;
