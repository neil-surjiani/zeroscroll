export default function WhatItDoes() {
  const features = [
    {
      title: "Messages only",
      description:
        "Read, compose, and reply to direct messages and group chats with zero algorithmic interruptions or suggestions.",
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
            d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
          />
        </svg>
      ),
    },
    {
      title: "Notifications only",
      description:
        "Stay updated on account activity, direct mentions, and replies without being redirected to an infinite feed.",
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
            d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"
          />
        </svg>
      ),
    },
    {
      title: "Reels from DMs play one at a time with no swiping",
      description:
        "Watch video clips your friends send you individually. When the video ends, playback stops—vertical swipe-up is completely disabled.",
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
            d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"
          />
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
          />
        </svg>
      ),
    },
    {
      title: "Daily reel budget and time limits",
      description:
        "Set custom daily budgets and viewing limits for reels sent in conversations to protect your attention and screen time.",
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
            d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
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
            Features
          </h2>
          <p className="mt-2 text-3xl font-bold tracking-tight text-neutral-900 sm:text-4xl dark:text-white">
            What it does
          </p>
          <p className="mx-auto mt-3 max-w-2xl text-base text-neutral-600 dark:text-neutral-400">
            Designed from the ground up for intentional communication without the addictive mechanisms.
          </p>
        </div>

        <div className="mt-12 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:gap-8">
          {features.map((feature, index) => (
            <div
              key={index}
              className="flex flex-col justify-between rounded-2xl border border-neutral-200/80 bg-white p-6 shadow-sm transition-all hover:border-teal-600/30 hover:shadow-md dark:border-neutral-800/80 dark:bg-neutral-900/60 dark:hover:border-teal-500/30"
            >
              <div>
                <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-teal-50 dark:bg-teal-950/60">
                  {feature.icon}
                </div>
                <h3 className="mt-5 text-lg font-bold text-neutral-900 dark:text-neutral-100">
                  {feature.title}
                </h3>
                <p className="mt-2 text-sm leading-relaxed text-neutral-600 dark:text-neutral-400">
                  {feature.description}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
