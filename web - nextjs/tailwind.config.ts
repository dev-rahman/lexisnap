import type { Config } from "tailwindcss";

/** Design tokens live as CSS variables in src/styles/globals.css. */
const config: Config = {
  darkMode: ["class", '[data-theme="dark"]'],
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        ink: "rgb(var(--ink) / <alpha-value>)",
        "ink-muted": "rgb(var(--ink-muted) / <alpha-value>)",
        paper: "rgb(var(--paper) / <alpha-value>)",
        surface: "rgb(var(--surface) / <alpha-value>)",
        card: "rgb(var(--card) / <alpha-value>)",
        border: "rgb(var(--border) / <alpha-value>)",
        panel: "rgb(var(--panel) / <alpha-value>)",
        accent: "rgb(var(--accent) / <alpha-value>)",
        "accent-600": "rgb(var(--accent-600) / <alpha-value>)",
        success: "rgb(var(--success) / <alpha-value>)",
        error: "rgb(var(--error) / <alpha-value>)",
        alert: "rgb(var(--alert) / <alpha-value>)",
        confirm: "rgb(var(--confirm) / <alpha-value>)",
        caution: "rgb(var(--caution) / <alpha-value>)",
        notice: "rgb(var(--notice) / <alpha-value>)",
        "hue-teal": "rgb(var(--hue-teal) / <alpha-value>)",
        "hue-violet": "rgb(var(--hue-violet) / <alpha-value>)",
        "hue-amber": "rgb(var(--hue-amber) / <alpha-value>)",
        "hue-rose": "rgb(var(--hue-rose) / <alpha-value>)",
        "hue-sky": "rgb(var(--hue-sky) / <alpha-value>)",
        "hue-moss": "rgb(var(--hue-moss) / <alpha-value>)",
      },
      fontFamily: {
        display: ["var(--font-display)", "system-ui", "sans-serif"],
        sans: ["system-ui", "-apple-system", "Segoe UI", "Roboto", "sans-serif"],
      },
      borderRadius: {
        xl: "0.875rem",
        "2xl": "1.25rem",
        "3xl": "1.75rem",
      },
      maxWidth: {
        content: "60rem",
      },
    },
  },
  plugins: [],
};

export default config;
