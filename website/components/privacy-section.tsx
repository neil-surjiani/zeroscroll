export default function PrivacySection() {
  const privacyPillars = [
    {
      title: "Messages never leave your phone",
      description:
        "All conversations, authentication cookies, and session data stay strictly on your local Android device. ZeroScroll operates no external servers or proxies.",
      icon: (
        <svg
          className="h-6 w-6 text-teal-700 dark:text-teal-400"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          strokeWidth="2"
          aria-hidden="true"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
          />
        </svg>
      ),
    },
    {
      title: "No ads & no sponsored content",
      description:
        "We do not inject ads, sponsored placements, or promotional banners. Your messaging interface remains completely unmonetized and uncluttered.",
      icon: (
        <svg
          className="h-6 w-6 text-teal-700 dark:text-teal-400"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          strokeWidth="2"
          aria-hidden="true"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"
          />
        </svg>
      ),
    },
    {
      title: "No tracking & no analytics",
      description:
        "Zero tracking cookies, zero analytics SDKs, and zero crash telemetries. We have no interest in observing how, when, or with whom you communicate.",
      icon: (
        <svg
          className="h-6 w-6 text-teal-700 dark:text-teal-400"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          strokeWidth="2"
          aria-hidden="true"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l18 18"
          />
        </svg>
      ),
    },
  ];

  return (
    <section className="py-16 sm:py-24">
      <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
        <div className="text-center">
          <h2 className="text-xs font-semibold uppercase tracking-wider text-teal-700 dark:text-teal-400">
            Security & Trust
          </h2>
          <p className="mt-2 text-3xl font-bold tracking-tight text-neutral-900 sm:text-4xl dark:text-white">
            Privacy
          </p>
          <p className="mx-auto mt-3 max-w-2xl text-base text-neutral-600 dark:text-neutral-400">
            Built on a simple principle: your private messages belong to you and stay on your device.
          </p>
        </div>

        <div className="mt-12 grid grid-cols-1 gap-6 sm:grid-cols-3">
          {privacyPillars.map((pillar, index) => (
            <div
              key={index}
              className="flex flex-col rounded-2xl border border-neutral-200/80 bg-white p-6 shadow-sm dark:border-neutral-800/80 dark:bg-neutral-900/60"
            >
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-teal-50 dark:bg-teal-950/60">
                {pillar.icon}
              </div>
              <h3 className="mt-5 text-base font-bold text-neutral-900 dark:text-neutral-100">
                {pillar.title}
              </h3>
              <p className="mt-2 text-sm leading-relaxed text-neutral-600 dark:text-neutral-400">
                {pillar.description}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
