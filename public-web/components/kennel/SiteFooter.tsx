"use client";

export function SiteFooter() {
  const year = new Date().getFullYear();
  return (
    <footer className="relative z-10 mt-16 border-t dark:border-white/[0.08] border-zinc-200">
      <div className="mx-auto max-w-7xl px-4 md:px-6 py-8 flex flex-col sm:flex-row items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src="/images/hc-logo.png"
            alt="Harrier Central"
            className="h-7 w-auto opacity-70"
            onError={(e) => { (e.target as HTMLImageElement).style.display = "none"; }}
          />
          <span className="text-sm dark:text-white/50 text-zinc-500">
            Powered by{" "}
            <a
              href="https://harriercentral.com"
              target="_blank"
              rel="noopener noreferrer"
              className="underline underline-offset-2 hover:dark:text-white/80 hover:text-zinc-700 transition-colors"
            >
              Harrier Central
            </a>
          </span>
        </div>
        <p className="text-sm dark:text-white/40 text-zinc-400">
          © {year} Harrier Central
        </p>
      </div>
    </footer>
  );
}
