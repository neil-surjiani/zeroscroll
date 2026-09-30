export default function FAQ() {
  const faqs = [
    {
      question: "Is it free?",
      answer:
        "Yes, ZeroScroll is completely free. There are no subscriptions, paywalls, in-app purchases, or hidden costs.",
    },
    {
      question: "Is it safe to log in?",
      answer:
        "Yes. Your login happens directly within a secure, sandboxed on-device WebView that communicates exclusively with the official service. ZeroScroll operates no external servers, collects no credentials, and never transmits your password or session cookies anywhere.",
    },
    {
      question: "Does it work on iPhone (not yet)?",
      answer:
        "Not yet. ZeroScroll is currently developed specifically for Android due to the system-level flexibility required to control web container boundaries and provide a dedicated APK. An iOS version may be considered in the future.",
    },
    {
      question: "How do I install the APK?",
      answer:
        "Tap the 'Download for Android' button above to download the .apk file directly to your phone. When opened, Android will prompt you with a standard security warning about unknown apps. Tap 'Settings', toggle 'Allow from this source' for your browser or file manager, and then tap 'Install'.",
    },
  ];

  return (
    <section className="border-t border-neutral-200/80 bg-neutral-100/50 py-16 sm:py-24 transition-colors dark:border-neutral-800/80 dark:bg-neutral-900/40">
      <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
        <div className="text-center">
          <h2 className="text-xs font-semibold uppercase tracking-wider text-teal-700 dark:text-teal-400">
            Questions
          </h2>
          <p className="mt-2 text-3xl font-bold tracking-tight text-neutral-900 sm:text-4xl dark:text-white">
            Frequently Asked Questions
          </p>
        </div>

        <div className="mt-12 space-y-6">
          {faqs.map((faq, index) => (
            <div
              key={index}
              className="rounded-2xl border border-neutral-200/70 bg-white p-6 shadow-sm transition-colors dark:border-neutral-800/70 dark:bg-neutral-900/60"
            >
              <h3 className="text-base font-bold text-neutral-900 dark:text-neutral-100">
                {faq.question}
              </h3>
              <p className="mt-2.5 text-sm leading-relaxed text-neutral-600 dark:text-neutral-400">
                {faq.answer}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
