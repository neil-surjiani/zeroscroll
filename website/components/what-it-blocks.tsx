export default function WhatItBlocks() {
  const blockedItems = [
    {
      title: "Home feed",
      detail: "No algorithmic feed, sponsored posts, or suggested accounts.",
    },
    {
      title: "Search / Explore",
      detail: "No discovery grid designed to hook your attention.",
    },
    {
      title: "Reels tab",
      detail: "No dedicated infinite-scroll short-form video tab.",
    },
    {
      title: "Stories",
      detail: "No top story tray or autoplaying ephemeral loops.",
    },
    {
      title: "Profile browsing",
      detail: "No rabbit holes wandering across strangers' profiles.",
    },
  ];

  return (
    <section className="border-y border-neutral-200/80 bg-neutral-100/50 py-16 sm:py-24 transition-colors dark:border-neutral-800/80 dark:bg-neutral-900/40">
      <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
        <div className="text-center">
          <h2 className="text-xs font-semibold uppercase tracking-wider text-teal-700 dark:text-teal-400">
            Distraction-Free
          </h2>
          <p className="mt-2 text-3xl font-bold tracking-tight text-neutral-900 sm:text-4xl dark:text-white">
            What it blocks
          </p>
          <p className="mx-auto mt-3 max-w-2xl text-base text-neutral-600 dark:text-neutral-400">
            Every engagement trap and continuous discovery loop is structurally filtered and removed.
          </p>
        </div>

        <div className="mt-12 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {blockedItems.map((item, index) => (
            <div
              key={index}
              className="flex items-start gap-3.5 rounded-2xl border border-neutral-200/60 bg-white p-5 shadow-sm transition-all hover:border-neutral-300 dark:border-neutral-800/60 dark:bg-neutral-900/60 dark:hover:border-neutral-700"
            >
              <div className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-xl bg-neutral-100 text-neutral-500 dark:bg-neutral-800 dark:text-neutral-400">
                {/* Blocked icon */}
                <svg
                  className="h-5 w-5 text-neutral-600 dark:text-neutral-300"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path
                    fillRule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zM6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z"
                    clipRule="evenodd"
                  />
                </svg>
              </div>
              <div className="min-w-0">
                <h3 className="text-base font-semibold text-neutral-900 dark:text-neutral-100">
                  {item.title}
                </h3>
                <p className="mt-1 text-xs leading-relaxed text-neutral-600 dark:text-neutral-400">
                  {item.detail}
                </p>
              </div>
            </div>
          ))}

          {/* Calm Guarantee Highlight Card */}
          <div className="flex flex-col justify-center rounded-2xl border border-teal-200/60 bg-teal-50/60 p-5 text-teal-900 dark:border-teal-900/60 dark:bg-teal-950/40 dark:text-teal-200 sm:col-span-2 lg:col-span-1">
            <div className="flex items-center gap-2">
              <span className="flex h-2 w-2 rounded-full bg-teal-600 dark:bg-teal-400"></span>
              <span className="text-xs font-bold uppercase tracking-wider text-teal-800 dark:text-teal-300">
                Zero Continuous Scrolling
              </span>
            </div>
            <p className="mt-2 text-xs leading-relaxed text-teal-800/90 dark:text-teal-200/90">
              When there are no new messages, the app has nothing left to show you. Put your phone down and live your life.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
