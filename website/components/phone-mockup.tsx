import Image from "next/image";

export default function PhoneMockup() {
  return (
    <section className="py-12 sm:py-16">
      <div className="mx-auto max-w-sm sm:max-w-md px-4">
        {/* Outer Phone Shell */}
        <div className="relative mx-auto w-full max-w-[340px] rounded-[48px] border-[10px] border-neutral-800 bg-neutral-900 p-2 shadow-2xl shadow-neutral-900/40 ring-1 ring-neutral-700/50 sm:max-w-[360px] dark:border-neutral-800 dark:bg-neutral-950 dark:shadow-teal-950/20">
          
          {/* Top Speaker / Camera Notch */}
          <div className="absolute top-4 left-1/2 -translate-x-1/2 z-20 flex h-4 w-28 items-center justify-center rounded-full bg-neutral-800">
            <div className="h-2 w-2 rounded-full bg-neutral-950 ring-1 ring-neutral-700/60"></div>
          </div>

          {/* Screen Container */}
          <div className="relative flex flex-col h-[580px] w-full overflow-hidden rounded-[38px] bg-white text-neutral-900 dark:bg-neutral-900 dark:text-neutral-100">
            
            {/* Screen Status Bar */}
            <div className="flex h-11 items-center justify-between px-6 pt-3 text-[11px] font-semibold text-neutral-800 dark:text-neutral-300">
              <span>9:41</span>
              <div className="flex items-center gap-1.5">
                {/* Cellular */}
                <svg className="h-3 w-3" fill="currentColor" viewBox="0 0 16 16">
                  <path d="M0 12h2v4H0zm3-3h2v7H3zm3-3h2v10H6zm3-3h2v13H9zm3-3h2v16h-2z" />
                </svg>
                {/* Wifi */}
                <svg className="h-3 w-3" fill="currentColor" viewBox="0 0 16 16">
                  <path fillRule="evenodd" d="M8 3.5a10.95 10.95 0 00-6.708 2.292.75.75 0 00.958 1.152A9.45 9.45 0 018 5a9.45 9.45 0 015.75 1.944.75.75 0 00.958-1.152A10.95 10.95 0 008 3.5zm-4.25 4.5a6.45 6.45 0 014.25-1.5c1.55 0 2.97.55 4.25 1.5a.75.75 0 10.96-1.15A7.95 7.95 0 008 5.5a7.95 7.95 0 00-5.21 1.85.75.75 0 10.96 1.15zm2.25 3a3.45 3.45 0 012-.625c.74 0 1.43.23 2 .625a.75.75 0 10.92-1.18A4.95 4.95 0 008 8.5a4.95 4.95 0 00-2.92 1.32.75.75 0 00.92 1.18zM8 12.5a1.25 1.25 0 100 2.5 1.25 1.25 0 000-2.5z" />
                </svg>
                {/* Battery */}
                <div className="h-2.5 w-5 rounded-sm border border-current p-0.5">
                  <div className="h-full w-full rounded-[1px] bg-current"></div>
                </div>
              </div>
            </div>

            {/* In-App App Bar */}
            <div className="flex items-center justify-between border-b border-neutral-100 px-5 py-3 dark:border-neutral-800">
              <div className="flex items-center gap-2">
                <Image
                  src="/logo.png"
                  alt="ZeroScroll logo"
                  width={22}
                  height={22}
                  className="h-5.5 w-5.5 rounded-md object-contain"
                />
                <span className="text-lg font-bold tracking-tight text-neutral-900 dark:text-white">
                  Messages
                </span>
                <span className="flex h-5 items-center justify-center rounded-full bg-teal-100 px-1.5 text-[10px] font-bold text-teal-800 dark:bg-teal-950 dark:text-teal-300">
                  3 new
                </span>
              </div>
              <div className="flex items-center gap-3 text-neutral-500 dark:text-neutral-400">
                {/* Compose icon */}
                <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                </svg>
              </div>
            </div>

            {/* Message Inbox List */}
            <div className="flex-1 divide-y divide-neutral-100 overflow-hidden dark:divide-neutral-800/60">
              
              {/* Item 1 */}
              <div className="flex items-center gap-3.5 px-5 py-3 transition-colors hover:bg-neutral-50 dark:hover:bg-neutral-800/40">
                <div className="relative flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-full bg-teal-600 text-xs font-semibold text-white">
                  MC
                  <span className="absolute bottom-0 right-0 h-3 w-3 rounded-full border-2 border-white bg-emerald-500 dark:border-neutral-900"></span>
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between">
                    <p className="truncate text-xs font-bold text-neutral-900 dark:text-neutral-100">
                      Maya Chen
                    </p>
                    <span className="text-[10px] font-medium text-teal-600 dark:text-teal-400">
                      2m ago
                    </span>
                  </div>
                  <p className="truncate text-xs font-medium text-neutral-800 dark:text-neutral-200">
                    Shared 1 video · No feed swiping
                  </p>
                </div>
                <div className="h-2 w-2 rounded-full bg-teal-600"></div>
              </div>

              {/* Item 2 */}
              <div className="flex items-center gap-3.5 px-5 py-3 transition-colors hover:bg-neutral-50 dark:hover:bg-neutral-800/40">
                <div className="relative flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-full bg-neutral-700 text-xs font-semibold text-white">
                  DK
                  <span className="absolute bottom-0 right-0 h-3 w-3 rounded-full border-2 border-white bg-emerald-500 dark:border-neutral-900"></span>
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between">
                    <p className="truncate text-xs font-bold text-neutral-900 dark:text-neutral-100">
                      David Kim
                    </p>
                    <span className="text-[10px] text-neutral-400">14m ago</span>
                  </div>
                  <p className="truncate text-xs font-medium text-neutral-700 dark:text-neutral-300">
                    Are we still meeting up for coffee?
                  </p>
                </div>
                <div className="h-2 w-2 rounded-full bg-teal-600"></div>
              </div>

              {/* Item 3 */}
              <div className="flex items-center gap-3.5 px-5 py-3 transition-colors hover:bg-neutral-50 dark:hover:bg-neutral-800/40">
                <div className="flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-full bg-neutral-300 text-xs font-semibold text-neutral-700 dark:bg-neutral-700 dark:text-neutral-200">
                  SL
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between">
                    <p className="truncate text-xs font-semibold text-neutral-800 dark:text-neutral-200">
                      Sarah Lewis
                    </p>
                    <span className="text-[10px] text-neutral-400">1h ago</span>
                  </div>
                  <p className="truncate text-xs text-neutral-500 dark:text-neutral-400">
                    Sounds perfect, see you tomorrow!
                  </p>
                </div>
              </div>

              {/* Item 4 */}
              <div className="flex items-center gap-3.5 px-5 py-3 transition-colors hover:bg-neutral-50 dark:hover:bg-neutral-800/40">
                <div className="flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-full bg-neutral-200 text-xs font-semibold text-neutral-600 dark:bg-neutral-800 dark:text-neutral-300">
                  AR
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between">
                    <p className="truncate text-xs font-semibold text-neutral-800 dark:text-neutral-200">
                      Alex Rivera
                    </p>
                    <span className="text-[10px] text-neutral-400">3h ago</span>
                  </div>
                  <p className="truncate text-xs text-neutral-500 dark:text-neutral-400">
                    Sent you the project notes.
                  </p>
                </div>
              </div>

              {/* Item 5 */}
              <div className="flex items-center gap-3.5 px-5 py-3 transition-colors hover:bg-neutral-50 dark:hover:bg-neutral-800/40">
                <div className="flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-full bg-neutral-200 text-xs font-semibold text-neutral-600 dark:bg-neutral-800 dark:text-neutral-300">
                  JT
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between">
                    <p className="truncate text-xs font-semibold text-neutral-800 dark:text-neutral-200">
                      Jordan Taylor
                    </p>
                    <span className="text-[10px] text-neutral-400">Yesterday</span>
                  </div>
                  <p className="truncate text-xs text-neutral-500 dark:text-neutral-400">
                    Thanks for checking in!
                  </p>
                </div>
              </div>

            </div>

            {/* Guarded Bottom Navigation Bar - ONLY DMs & Notifications */}
            <div className="mt-auto border-t border-neutral-100 bg-neutral-50/90 px-8 py-2.5 backdrop-blur-sm dark:border-neutral-800 dark:bg-neutral-900/90">
              <div className="flex items-center justify-around">
                
                {/* Messages tab (Active) */}
                <div className="flex flex-col items-center gap-1 text-teal-700 dark:text-teal-400">
                  <svg className="h-5 w-5" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 2C6.48 2 2 6.03 2 11c0 2.87 1.5 5.43 3.84 7.02-.13.88-.63 2.5-1.78 3.59 0 0 2.55.15 4.88-1.42.98.26 2.01.41 3.06.41 5.52 0 10-4.03 10-9s-4.48-9-10-9z" />
                  </svg>
                  <span className="text-[10px] font-bold">Messages</span>
                </div>

                {/* Notifications tab */}
                <div className="flex flex-col items-center gap-1 text-neutral-400 transition-colors hover:text-neutral-600 dark:text-neutral-500 dark:hover:text-neutral-300">
                  <div className="relative">
                    <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                    </svg>
                    <span className="absolute -top-0.5 -right-0.5 h-2 w-2 rounded-full bg-teal-600"></span>
                  </div>
                  <span className="text-[10px] font-medium">Activity</span>
                </div>

              </div>
            </div>

            {/* Android Navigation Bar Pill Indicator */}
            <div className="flex h-4 items-center justify-center bg-neutral-50 dark:bg-neutral-900 pb-1">
              <div className="h-1 w-24 rounded-full bg-neutral-300 dark:bg-neutral-700"></div>
            </div>

          </div>
        </div>

        {/* Caption below mockup */}
        <p className="mt-4 text-center text-xs text-neutral-500 dark:text-neutral-400">
          Clean inbox interface. Strictly zero feeds, stories, or algorithmic rabbit holes.
        </p>
      </div>
    </section>
  );
}
