import { NextRequest, NextResponse } from "next/server";

/**
 * Same-origin download proxy for approved run photos. The photo blobs live on
 * Azure Storage (cross-origin), where neither the `download` attribute nor a
 * forced save works from the browser — streaming them through this route with
 * a Content-Disposition: attachment header makes "Download" work everywhere,
 * including iOS/Android browsers.
 *
 * Locked to the Harrier Central photo blob host so this cannot be used as an
 * open proxy.
 */

const ALLOWED_HOST = "harriercentral.blob.core.windows.net";

export async function GET(req: NextRequest) {
  const u = req.nextUrl.searchParams.get("u");
  const name = req.nextUrl.searchParams.get("name") ?? "run-photo.jpg";
  if (!u) return new NextResponse("Missing url", { status: 400 });

  let parsed: URL;
  try {
    parsed = new URL(u);
  } catch {
    return new NextResponse("Bad url", { status: 400 });
  }
  if (parsed.protocol !== "https:" || parsed.hostname !== ALLOWED_HOST) {
    return new NextResponse("Forbidden", { status: 403 });
  }

  const upstream = await fetch(parsed.toString());
  if (!upstream.ok || !upstream.body) {
    return new NextResponse("Not found", { status: 404 });
  }

  const safeName = name.replace(/[^\w.\- ]+/g, "_").slice(0, 100) || "run-photo.jpg";
  return new NextResponse(upstream.body, {
    headers: {
      "Content-Type": upstream.headers.get("content-type") ?? "image/jpeg",
      "Content-Disposition": `attachment; filename="${safeName}"`,
      "Cache-Control": "private, max-age=0",
    },
  });
}
