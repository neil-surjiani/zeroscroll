import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Terms of Service - ZeroScroll",
  description:
    "Terms of service for using the ZeroScroll application and website.",
};

export default function TermsPage() {
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
          Terms of Service
        </h1>
        <p className="mt-2 text-sm text-neutral-500 dark:text-neutral-400">
          Last updated: September 30, 2026
        </p>

        {/* Terms Content */}
        <div className="mt-8 space-y-8 text-base leading-relaxed text-neutral-700 dark:text-neutral-300">
          
          <section className="space-y-3">
            <h2 className="text-xl font-bold text-neutral-900 dark:text-neutral-100">
              1. Use at Your Own Risk
            </h2>
            <p>
              ZeroScroll is an experimental, independent utility created to assist users in managing digital distraction. You acknowledge and agree that your use of the ZeroScroll app and website is entirely at your own risk.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-neutral-900 dark:text-neutral-100">
              2. No Affiliation with Meta or Instagram
            </h2>
            <p>
              ZeroScroll is not affiliated with, sponsored by, authorized by, or endorsed by Meta Platforms, Inc. or Instagram. All product and company names are trademarks™ or registered® trademarks of their respective holders. Their descriptive use does not imply any affiliation with or endorsement by them.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-neutral-900 dark:text-neutral-100">
              3. User Responsibility & Compliance
            </h2>
            <p>
              You are solely responsible for ensuring that your access to and use of third-party platforms complies with Instagram&apos;s applicable Terms of Use, Community Guidelines, and policies. ZeroScroll assumes no responsibility or liability for any actions taken by third-party platforms with respect to your account.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-neutral-900 dark:text-neutral-100">
              4. Disclaimer of Warranty
            </h2>
            <p>
              ZeroScroll is provided on an &ldquo;AS IS&rdquo; and &ldquo;AS AVAILABLE&rdquo; basis, without warranties of any kind, whether express, implied, or statutory, including but not limited to warranties of merchantability, fitness for a particular purpose, or non-infringement.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-neutral-900 dark:text-neutral-100">
              5. Limitation of Liability
            </h2>
            <p>
              To the fullest extent permitted by applicable law, neither the developers, contributors, nor maintainers of ZeroScroll shall be liable for any direct, indirect, incidental, special, consequential, or punitive damages arising out of or related to your use of or inability to use the application or website.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-neutral-900 dark:text-neutral-100">
              6. Changes to These Terms
            </h2>
            <p>
              We reserve the right to revise or update these Terms of Service at any time. Any revisions will become effective immediately upon posting the updated terms on this website. Continued use of the application or website following any changes signifies your acceptance of the updated terms.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-neutral-900 dark:text-neutral-100">
              7. Governing Law
            </h2>
            <p>
              These Terms and any dispute or claim arising out of or in connection with them or their subject matter shall be governed by and construed in accordance with the laws of India, without regard to its conflict of law principles.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-neutral-900 dark:text-neutral-100">
              8. Contact
            </h2>
            <p>
              For inquiries regarding these Terms of Service, please reach out via email at:
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
