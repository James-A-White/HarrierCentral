import { NextRequest, NextResponse } from "next/server";

/**
 * Streams one run photo back with `Content-Disposition: attachment`, so the
 * Download button on the photo carousel actually downloads.
 *
 * It has to exist because HTML's `download` attribute is **ignored
 * cross-origin**: the photos live on harriercentral.blob.core.windows.net, so
 * `<a href={blobUrl} download>` just opens the image — which is precisely the
 * dead end the carousel replaced. Re-serving the bytes from our own origin
 * makes the attachment header apply, and lets us give the file a name that
 * says which run it came from rather than a blob GUID.
 *
 * **Allowlisted to our own storage account.** Without that check this route
 * would be an open proxy: anybody could hand it any URL and have our server
 * fetch it, which is how a server ends up laundering someone else's traffic.
 */
const ALLOWED_HOST = "harriercentral.blob.core.windows.net";

/** Belt and braces: a photo is a photo, not whatever else sits in the account. */
const ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp", "image/avif", "image/heic"];

function safeFileName(raw: string | null, fallbackExt: string): string {
  const base = (raw ?? "photo")
    .replace(/[^\w\-. ]+/g, "")
    .trim()
    .slice(0, 80);
  const name = base.length > 0 ? base : "photo";
  return /\.[a-z0-9]{3,4}$/i.test(name) ? name : `${name}.${fallbackExt}`;
}

export async function GET(req: NextRequest) {
  const src = req.nextUrl.searchParams.get("url");
  if (!src) return new NextResponse("Missing url", { status: 400 });

  let target: URL;
  try {
    target = new URL(src);
  } catch {
    return new NextResponse("Bad url", { status: 400 });
  }

  if (target.protocol !== "https:" || target.hostname !== ALLOWED_HOST) {
    return new NextResponse("Not a Harrier Central photo", { status: 400 });
  }

  try {
    const upstream = await fetch(target.toString(), { cache: "no-store" });
    if (!upstream.ok || !upstream.body) {
      return new NextResponse("Photo not available", { status: 502 });
    }

    const contentType = upstream.headers.get("content-type") ?? "application/octet-stream";
    if (!ALLOWED_TYPES.includes(contentType.split(";")[0].trim().toLowerCase())) {
      return new NextResponse("Not an image", { status: 400 });
    }

    const ext = contentType.includes("png")
      ? "png"
      : contentType.includes("webp")
        ? "webp"
        : contentType.includes("avif")
          ? "avif"
          : "jpg";
    const fileName = safeFileName(req.nextUrl.searchParams.get("name"), ext);

    return new NextResponse(upstream.body, {
      headers: {
        "Content-Type": contentType,
        "Content-Disposition": `attachment; filename="${fileName}"`,
        // The blob itself is immutable once uploaded, so this is safe to hold.
        "Cache-Control": "public, max-age=86400",
      },
    });
  } catch (e) {
    console.error("[run-photos/download]", e);
    return new NextResponse("Photo not available", { status: 502 });
  }
}
