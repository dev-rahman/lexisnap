import type { Config } from "tailwindcss";

/**
 * Design tokens are defined as CSS custom properties in src/styles/globals.css
 * (light values on :root, dark values under the dark selector) so a single
 * token works in both themes. Tailwind references them through these names.
 * This mirrors lib/app/core/theme/app_colors.dart from the Flutter app.
 */
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
        border: "rgb(var(--border) / <alpha-value>)",
        panel: "rgb(var(--panel) / <alpha-value>)",
        // Coral — reserved for the single primary action on a screen.
        accent: "rgb(var(--accent) / <alpha-value>)",
        "accent-600": "rgb(var(--accent-600) / <alpha-value>)",
        // Flashcard review only.
        success: "rgb(var(--success) / <alpha-value>)",
        error: "rgb(var(--error) / <alpha-value>)",
        // Generic system toasts.
        alert: "rgb(var(--alert) / <alpha-value>)",
        confirm: "rgb(var(--confirm) / <alpha-value>)",
        caution: "rgb(var(--caution) / <alpha-value>)",
        notice: "rgb(var(--notice) / <alpha-value>)",
        // Additive hue palette (identity + data). Resolved per-theme in CSS.
        "hue-teal": "rgb(var(--hue-teal) / <alpha-value>)",
        "hue-violet": "rgb(var(--hue-violet) / <alpha-value>)",
        "hue-amber": "rgb(var(--hue-amber) / <alpha-value>)",
        "hue-rose": "rgb(var(--hue-rose) / <alpha-value>)",
        "hue-sky": "rgb(var(--hue-sky) / <alpha-value>)",
        "hue-moss": "rgb(var(--hue-moss) / <alpha-value>)",
      },
      fontFamily: {
        // Space Grotesk for display, system stack for body — matches Flutter.
        display: ["var(--font-display)", "system-ui", "sans-serif"],
        sans: [
          "system-ui",
          "-apple-system",
          "Segoe UI",
          "Roboto",
          "sans-serif",
        ],
      },
      borderRadius: {
        // app_radius.dart
        sm: "8px",
        DEFAULT: "12px",
        md: "16px",
        lg: "20px",
        xl: "28px",
      },
    },
  },
  plugins: [],
};

export default config;
