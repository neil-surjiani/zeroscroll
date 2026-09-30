import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Privacy Policy - ZeroScroll",
  description:
    "Plain-language privacy policy for the ZeroScroll application and website. Zero tracking, zero data collection.",
};

export default function PrivacyPage() {
  return (
    <div className="py-16 sm:py-24">
      <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
        
        {/* Back Link */}
        <Link
          href="/"
          className="inline-flex items-center gap-1.5 text-sm font-medium text-teal-700 hover:underline dark:text-teal-400"
        >
          <svg
            className="h-4 w-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth="2"
          >
            <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
          </svg>
          Back to Home
        </Link>

        {/* Heading */}
        <h1 className="mt-6 text-3xl font-extrabold tracking-tight text-neutral-900 sm:text-4xl dark:text-white">
          Privacy Policy
        </h1>
        <p className="mt-2 text-sm text-neutral-500 dark:text-neutral-400">
          Last updated: September 30, 2026
        </p>

        {/* Policy Content */}
        <div className="mt-8 space-y-8 text-base leading-relaxed text-neutral-700 dark:text-neutral-300">
          
          <section className="space-y-3">
            <h2 className="text-xl font-bold text-neutral-900 dark:text-neutral-100">
              1. Our Privacy Philosophy
            </h2>
            <p>
              ZeroScroll was built to protect your focus and your privacy. We believe that tools designed to help you avoid algorithmic rabbit holes should never spy on you or monetize your attention.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-neutral-900 dark:text-neutral-100">
              2. What the App Does Not Collect
            </h2>
            <p>
              The ZeroScroll Android app does not collect, upload, store, or share:
            </p>
            <ul className="list-disc space-y-1.5 pl-6 text-neutral-600 dark:text-neutral-300">
              <li>Your message text, media, or direct conversations</li>
              <li>Your login credentials, passwords, or authentication keys</li>
              <li>Your notification content, sender details, or activity logs</li>
              <li>Your device identifiers, IP addresses, or location data</li>
            </ul>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-neutral-900 dark:text-neutral-100">
              3. All Data Stays on Your Device
            </h2>
            <p>
              ZeroScroll operates entirely on your physical phone. When you sign in, authentication happens strictly inside an isolated Android WebView container directly connecting to Instagram&apos;s servers.
            </p>
            <p>
              All local settings (such as reel budgets or screen limits) are saved exclusively in your device&apos;s local sandboxed SQLite storage. We do not operate any backend servers, relays, or cloud databases.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-neutral-900 dark:text-neutral-100">
              4. Website Privacy
            </h2>
            <p>
              This website (<span className="font-mono text-sm">zoomschool.app</span>) uses:
            </p>
            <ul className="list-disc space-y-1.5 pl-6 text-neutral-600 dark:text-neutral-300">
              <li>No cookies of any kind</li>
              <li>No analytics trackers (no Google Analytics, no telemetry scripts)</li>
              <li>No third-party marketing tags, pixels, or profiling scripts</li>
            </ul>
            <p>
              We do not track your visits, IP addresses, or browsing history when you view this landing page.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-neutral-900 dark:text-neutral-100">
              5. Contact Us
            </h2>
            <p>
              If you have any questions or concerns regarding our privacy practices, please contact us at:
            </p>
            <p className="font-medium text-teal-700 dark:text-teal-400">
              <a href="mailto:contact@zoomschool.app">contact@zoomschool.app</a>
            </p>
          </section>

        </div>
      </div>
    </div>
  );
}
