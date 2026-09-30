import Link from "next/link";
import Image from "next/image";

export default function Footer() {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="border-t border-neutral-200/80 bg-neutral-100/50 py-12 transition-colors dark:border-neutral-800/80 dark:bg-neutral-900/40">
      <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
        <div className="flex flex-col items-center justify-between gap-6 sm:flex-row">
          {/* Logo and Copyright */}
          <div className="flex items-center gap-2.5 text-sm text-neutral-600 dark:text-neutral-400">
            <Image
              src="/logo.png"
              alt="ZeroScroll logo"
              width={22}
              height={22}
              className="h-5.5 w-5.5 rounded-md object-contain"
            />
            <span className="font-semibold text-neutral-900 dark:text-neutral-200">
              ZeroScroll
            </span>
            <span>&copy; {currentYear}</span>
          </div>

          {/* Links */}
          <nav className="flex flex-wrap items-center justify-center gap-6 text-sm text-neutral-600 dark:text-neutral-400">
            <Link
              href="/privacy"
              className="transition-colors hover:text-teal-700 dark:hover:text-teal-400"
            >
              Privacy
            </Link>
            <Link
              href="/terms"
              className="transition-colors hover:text-teal-700 dark:hover:text-teal-400"
            >
              Terms
            </Link>
            <a
              href="mailto:contact@zoomschool.app"
              className="transition-colors hover:text-teal-700 dark:hover:text-teal-400"
            >
              contact@zoomschool.app
            </a>
          </nav>
        </div>

        {/* Disclaimer */}
        <div className="mt-8 border-t border-neutral-200/60 pt-6 text-center text-xs leading-relaxed text-neutral-500 dark:border-neutral-800/60 dark:text-neutral-500">
          <p>
            ZeroScroll is not affiliated with or endorsed by Meta or Instagram.
          </p>
        </div>
      </div>
    </footer>
  );
}
