import type { Metadata } from "next";
import "./globals.css";
import Header from "@/components/header";
import Footer from "@/components/footer";

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || "https://zoomschool.app"),
  title: "ZeroScroll - DMs without the feed",
  description:
    "ZeroScroll is an Android app that shows only your Instagram DMs and notifications, with no feed, Search, Reels tab, or Stories.",
  icons: {
    icon: "/logo.png",
    shortcut: "/logo.png",
    apple: "/logo.png",
  },
  openGraph: {
    title: "ZeroScroll - DMs without the feed",
    description:
      "ZeroScroll is an Android app that shows only your Instagram DMs and notifications, with no feed, Search, Reels tab, or Stories.",
    url: process.env.NEXT_PUBLIC_SITE_URL || "https://zoomschool.app",
    siteName: "ZeroScroll",
    images: [
      {
        url: "/logo.png",
        width: 1024,
        height: 1024,
        alt: "ZeroScroll Logo",
      },
    ],
    type: "website",
    locale: "en_US",
  },
  twitter: {
    card: "summary",
    title: "ZeroScroll - DMs without the feed",
    description:
      "ZeroScroll is an Android app that shows only your Instagram DMs and notifications, with no feed, Search, Reels tab, or Stories.",
    images: ["/logo.png"],
  },
  robots: {
    index: true,
    follow: true,
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="flex min-h-screen flex-col bg-neutral-50 text-neutral-900 antialiased selection:bg-teal-700 selection:text-white dark:bg-neutral-950 dark:text-neutral-100">
        <Header />
        <main className="flex-1">{children}</main>
        <Footer />
      </body>
    </html>
  );
}
