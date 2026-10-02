import Image from "next/image";

interface HeroProps {
  apkUrl?: string;
  appVersion?: string;
  fileSize?: string;
  sha256?: string;
  releasedAt?: string;
}

export default function Hero({
  apkUrl = process.env.NEXT_PUBLIC_APK_URL || "/zeroscroll.apk",
  appVersion = process.env.NEXT_PUBLIC_APP_VERSION || "v1.0.0",
  fileSize,
  sha256,
  releasedAt,
}: HeroProps) {
  return (
    <section className="relative overflow-hidden pt-12 pb-12 sm:pt-20 sm:pb-16 text-center">
      <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
        {/* App Logo */}
        <div className="mb-6 flex justify-center">
          <div className="relative rounded-3xl p-1.5 shadow-xl shadow-teal-900/10 ring-1 ring-neutral-200/60 dark:ring-neutral-800 dark:shadow-teal-950/30">
            <Image
              src="/logo.png"
              alt="ZeroScroll App Icon"
              width={80}
              height={80}
              className="h-20 w-20 rounded-[22px] object-contain"
              priority
            />
          </div>
        </div>

        {/* Subtle pill badge */}
        <div className="inline-flex items-center gap-2 rounded-full border border-teal-200/60 bg-teal-50/70 px-3.5 py-1 text-xs font-medium text-teal-800 dark:border-teal-900/60 dark:bg-teal-950/50 dark:text-teal-300">
          <span className="flex h-1.5 w-1.5 rounded-full bg-teal-600 dark:bg-teal-400"></span>
          Pure focus for your messages
        </div>

        {/* Headline */}
        <h1 className="mt-6 text-4xl font-extrabold tracking-tight text-neutral-900 sm:text-5xl md:text-6xl dark:text-white">
          Your DMs. <span className="text-teal-700 dark:text-teal-400">Without the feed.</span>
        </h1>

        {/* One line of subtext */}
        <p className="mx-auto mt-5 max-w-2xl text-lg text-neutral-600 sm:text-xl dark:text-neutral-400">
          ZeroScroll is an Android app that shows only your Instagram DMs and notifications, with no feed, Search, Reels tab, or Stories.
        </p>

        {/* Large Download Button */}
        <div className="mt-8 flex flex-col items-center justify-center gap-3">
          <a
            href={apkUrl}
            download="zeroscroll.apk"
            className="group inline-flex items-center justify-center gap-3 rounded-2xl bg-teal-700 px-8 py-4 text-base font-semibold text-white shadow-lg shadow-teal-700/20 transition-all hover:bg-teal-800 hover:shadow-teal-700/30 focus:outline-none focus:ring-2 focus:ring-teal-700 focus:ring-offset-2 active:scale-95 sm:text-lg dark:bg-teal-600 dark:hover:bg-teal-500 dark:shadow-teal-950/50 dark:focus:ring-teal-500 dark:focus:ring-offset-neutral-950"
            aria-label={`Download ZeroScroll for Android version ${appVersion}`}
          >
            {/* Android robot icon */}
            <svg
              className="h-6 w-6 transition-transform group-hover:-translate-y-0.5"
              viewBox="0 0 24 24"
              fill="currentColor"
              aria-hidden="true"
            >
              <path d="M17.523 15.3414c-.5511 0-.9993-.4486-.9993-.9997s.4482-.9993.9993-.9993c.551 0 .9993.4482.9993.9993.0001.5511-.4483.9997-.9993.9997m-11.046 0c-.5511 0-.9993-.4486-.9993-.9997s.4482-.9993.9993-.9993c.5511 0 .9993.4482.9993.9993 0 .5511-.4482.9997-.9993.9997m11.4045-6.02l1.997-3.459a.416.416 0 00-.1521-.5676.416.416 0 00-.5676.1521l-2.0223 3.503C15.5837 8.4116 13.8517 8.125 12 8.125s-3.5837.2866-5.1365.8249L4.8412 5.4469a.4161.4161 0 00-.5677-.1521.4157.4157 0 00-.1521.5676l1.997 3.459C2.6889 11.1867.3432 14.6589 0 18.75h24c-.3432-4.0911-2.6889-7.5633-6.1185-9.4286" />
            </svg>
            <span>Download for Android</span>
            <span className="rounded-lg bg-teal-800/60 px-2 py-0.5 text-xs font-normal tracking-wide text-teal-100 dark:bg-teal-700/60">
              {appVersion}
            </span>
          </a>

          {/* Release metadata pill / info */}
          {fileSize && (
            <div className="flex flex-wrap items-center justify-center gap-2 text-xs text-neutral-500 dark:text-neutral-400">
              <span>{fileSize} APK</span>
              {sha256 && (
                <>
                  <span>•</span>
                  <span title={`SHA-256 Checksum: ${sha256}`} className="font-mono">
                    SHA-256: {sha256.substring(0, 8)}…
                  </span>
                </>
              )}
            </div>
          )}

          {/* Small note on how to allow installs from this source */}
          <p className="max-w-md text-xs leading-relaxed text-neutral-500 dark:text-neutral-500">
            Direct APK download. When prompted, enable <span className="font-medium text-neutral-700 dark:text-neutral-300">&ldquo;Allow from this source&rdquo;</span> in your Android Settings to install.
          </p>
        </div>
      </div>
    </section>
  );
}
