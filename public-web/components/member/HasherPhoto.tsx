/**
 * A hasher's profile photo, as a circle — a portrait keeps the circle the
 * app gives it (the no-mask rule is for kennel logos). A grey disc when
 * there is none, so a list keeps its rhythm. Server- and client-safe.
 */
export function HasherPhoto({ url, className = "h-10 w-10" }: { url: string | null | undefined; className?: string }) {
  return (
    <div className={`${className} shrink-0 overflow-hidden rounded-full bg-zinc-200`}>
      {url?.startsWith("http") && (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={url} alt="" className="h-full w-full object-cover" />
      )}
    </div>
  );
}
