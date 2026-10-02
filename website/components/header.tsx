import Link from "next/link";
import Image from "next/image";

interface HeaderProps {
  apkUrl?: string;
  appVersion?: string;
}

export default function Header({
  apkUrl = process.env.NEXT_PUBLIC_APK_URL || "/zeroscroll.apk",
  appVersion = process.env.NEXT_PUBLIC_APP_VERSION || "v1.0.0",
}: HeaderProps) {
  return (
    <header className="sticky top-0 z-50 w-full border-b border-neutral-200/80 bg-neutral-50/80 backdrop-blur-md transition-colors dark:border-neutral-800/80 dark:bg-neutral-950/80">
      <div className="mx-auto flex h-16 max-w-5xl items-center justify-between px-4 sm:px-6 lg:px-8">
        {/* Wordmark with Logo */}
        <Link
          href="/"
          className="group flex items-center gap-2.5 text-neutral-900 transition-opacity hover:opacity-90 dark:text-white"
          aria-label="ZeroScroll Home"
        >
          <Image
            src="/logo.png"
            alt="ZeroScroll App Logo"
            width={32}
            height={32}
            className="h-8 w-8 rounded-lg object-contain shadow-xs"
            priority
          />
          <span className="text-lg font-bold tracking-tight text-neutral-900 dark:text-neutral-50">
            ZeroScroll
          </span>
        </Link>

        {/* Navigation & Small Download Button */}
        <div className="flex items-center gap-4">
          <a
            href={apkUrl}
            download="zeroscroll.apk"
            className="inline-flex items-center gap-1.5 rounded-full bg-teal-700 px-4 py-1.5 text-xs font-semibold text-white shadow-sm transition-all hover:bg-teal-800 focus:outline-none focus:ring-2 focus:ring-teal-700 focus:ring-offset-2 active:scale-95 dark:bg-teal-600 dark:hover:bg-teal-500 dark:focus:ring-teal-500 dark:focus:ring-offset-neutral-950"
            title={`Download ZeroScroll ${appVersion} APK`}
          >
            <svg
              className="h-3.5 w-3.5"
              viewBox="0 0 20 20"
              fill="currentColor"
              aria-hidden="true"
            >
              <path
                fillRule="evenodd"
                d="M10 3a.75.75 0 01.75.75v8.19l2.72-2.72a.75.75 0 111.06 1.06l-4 4a.75.75 0 01-1.06 0l-4-4a.75.75 0 111.06-1.06l2.72 2.72V3.75A.75.75 0 0110 3z"
                clipRule="evenodd"
              />
              <path
                fillRule="evenodd"
                d="M3.75 14a.75.75 0 01.75.75v1.5c0 .414.336.75.75.75h9.5a.75.75 0 00.75-.75v-1.5a.75.75 0 011.5 0v1.5A2.25 2.25 0 0114.75 18H5.25A2.25 2.25 0 013 15.75v-1.5a.75.75 0 01.75-.75z"
                clipRule="evenodd"
              />
            </svg>
            <span>Download</span>
          </a>
        </div>
      </div>
    </header>
  );
}
