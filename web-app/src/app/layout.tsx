import type { Metadata, Viewport } from "next";
import { Space_Grotesk } from "next/font/google";

import { Providers } from "@/components/providers/Providers";
import "@/styles/globals.css";

const spaceGrotesk = Space_Grotesk({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  variable: "--font-display",
  display: "swap",
});

export const metadata: Metadata = {
  title: "LexiSnap",
  description: "AI flashcards from anything you scan.",
  manifest: "/manifest.webmanifest",
  appleWebApp: { capable: true, title: "LexiSnap", statusBarStyle: "default" },
};

export const viewport: Viewport = {
  themeColor: "#1C2541",
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning className={spaceGrotesk.variable}>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
