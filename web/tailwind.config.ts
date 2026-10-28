import type { Config } from "tailwindcss";

/** Design tokens live as CSS variables in src/styles/globals.css. */
const config: Config = {
  darkMode: ["class", '[data-theme="dark"]'],
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        ink: "rgb(var(--ink) / <alpha-value>)",
        "ink-muted": "rgb(var(--ink-muted) / <alpha-value>)",
        "ink-soft": "rgb(var(--ink-soft) / <alpha-value>)",
        paper: "rgb(var(--paper) / <alpha-value>)",
        surface: "rgb(var(--surface) / <alpha-value>)",
        card: "rgb(var(--card) / <alpha-value>)",
        border: "rgb(var(--border) / <alpha-value>)",
        panel: "rgb(var(--panel) / <alpha-value>)",
        coral: "rgb(var(--coral) / <alpha-value>)",
        "coral-dark": "rgb(var(--coral-dark) / <alpha-value>)",
        "coral-soft": "rgb(var(--coral-soft) / <alpha-value>)",
        flame: "rgb(var(--flame) / <alpha-value>)",
        "flame-dark": "rgb(var(--flame-dark) / <alpha-value>)",
        success: "rgb(var(--success) / <alpha-value>)",
        "success-dark": "rgb(var(--success-dark) / <alpha-value>)",
        error: "rgb(var(--error) / <alpha-value>)",
        "error-dark": "rgb(var(--error-dark) / <alpha-value>)",
        "hue-teal": "rgb(var(--hue-teal) / <alpha-value>)",
        "hue-violet": "rgb(var(--hue-violet) / <alpha-value>)",
        "hue-amber": "rgb(var(--hue-amber) / <alpha-value>)",
        "hue-rose": "rgb(var(--hue-rose) / <alpha-value>)",
        "hue-sky": "rgb(var(--hue-sky) / <alpha-value>)",
        "hue-moss": "rgb(var(--hue-moss) / <alpha-value>)",
      },
      fontFamily: {
        display: ['"Baloo 2"', "system-ui", "sans-serif"],
        sans: ['"Plus Jakarta Sans"', "system-ui", "-apple-system", "sans-serif"],
      },
      borderRadius: {
        xl: "0.875rem",
        "2xl": "1.25rem",
        "3xl": "1.75rem",
        "4xl": "2.25rem",
      },
      spacing: {
        13: "3.25rem",
      },
      maxWidth: {
        content: "66rem",
        wide: "78rem",
        focus: "40rem",
      },
      boxShadow: {
        soft: "0 1px 2px rgb(27 32 56 / 0.04), 0 6px 16px -10px rgb(27 32 56 / 0.14)",
        card: "0 1px 2px rgb(27 32 56 / 0.04), 0 8px 20px -12px rgb(27 32 56 / 0.16)",
        "card-lift":
          "0 2px 4px rgb(27 32 56 / 0.05), 0 16px 34px -16px rgb(27 32 56 / 0.22)",
        pop: "0 8px 24px -10px rgb(241 90 50 / 0.4)",
      },
      keyframes: {
        "pop-in": {
          "0%": { transform: "scale(0.9)", opacity: "0" },
          "60%": { transform: "scale(1.03)" },
          "100%": { transform: "scale(1)", opacity: "1" },
        },
        "rise-in": {
          "0%": { transform: "translateY(10px)", opacity: "0" },
          "100%": { transform: "translateY(0)", opacity: "1" },
        },
        shake: {
          "0%,100%": { transform: "translateX(0)" },
          "20%,60%": { transform: "translateX(-7px)" },
          "40%,80%": { transform: "translateX(7px)" },
        },
        "flame-flicker": {
          "0%,100%": { transform: "scale(1) rotate(-2deg)" },
          "50%": { transform: "scale(1.08) rotate(2deg)" },
        },
        "ring-fill": { "0%": { strokeDashoffset: "var(--dash)" } },
        confetti: {
          "0%": { transform: "translateY(0) rotate(0)", opacity: "1" },
          "100%": { transform: "translateY(110vh) rotate(680deg)", opacity: "0" },
        },
        float: {
          "0%,100%": { transform: "translateY(0)" },
          "50%": { transform: "translateY(-8px)" },
        },
        shimmer: {
          "0%": { backgroundPosition: "200% 0" },
          "100%": { backgroundPosition: "-200% 0" },
        },
      },
      animation: {
        "pop-in": "pop-in 0.3s cubic-bezier(0.34,1.56,0.64,1) both",
        "rise-in": "rise-in 0.4s ease-out both",
        shake: "shake 0.4s ease-in-out",
        "flame-flicker": "flame-flicker 1.6s ease-in-out infinite",
        float: "float 3.5s ease-in-out infinite",
        shimmer: "shimmer 1.6s ease-in-out infinite",
      },
    },
  },
  plugins: [],
};

export default config;
