import { randomUUID } from "crypto";
import { NextRequest, NextResponse } from "next/server";
import sharp from "sharp";
import { getChatPhotoUploadUrl } from "@/lib/member-api";
import { isChatPhotoUrl } from "@/lib/chat-content";
import { readMember } from "@/lib/member-session";
import { bad, limited } from "@/lib/member-routes";
import { logWebError } from "@/lib/web-log";

export const runtime = "nodejs";

/** A phone camera's JPEG is 2–6 MB; a screenshot less. Anything over this is not a chat photo. */
const MAX_BYTES = 10 * 1024 * 1024;
/** The app's chat photo size (docs/chat_photos_location_delete_plan.md §6). */
const MAX_EDGE = 1600;

/**
 * POST multipart { file } → { blobUrl }   (E9.F1.S11)
 *
 * The browser hands the photo to US, not to the blob account: the SAS comes
 * from GetChatPhotoUploadToken under the member's own device credentials
 * (which never leave the server), and the bytes are PUT from here, so the
 * storage account needs no browser CORS rule.
 *
 * Every photo is re-encoded with sharp: rotated upright from its EXIF, at
 * most 1600 px on its long edge, JPEG — and with its metadata dropped,
 * which is what keeps a phone photo's GPS position out of a group chat.
 *
 * Posting it to the chat is a separate call (POST /api/member/chat with
 * messageKind 1), as it is in the app.
 */
export async function POST(req: NextRequest) {
  const s = readMember(req);
  if (!s) return bad("Not signed in.", 401);
  if (limited(`chat-photo:${s.userId}`, 30, 10 * 60 * 1000)) return bad("That's a lot of photos. Please wait a few minutes.", 429);

  // Refuse an oversized body before reading it. Multipart adds a little, so
  // allow some headroom over the file limit itself.
  const declared = Number(req.headers.get("content-length") ?? "0");
  if (declared > MAX_BYTES + 64 * 1024) return bad("That photo is too big. Photos can be up to 10 MB.", 413);

  let file: File | null = null;
  try {
    const form = await req.formData();
    const f = form.get("file");
    file = f instanceof File ? f : null;
  } catch {
    return bad("Bad request.");
  }
  if (!file || file.size === 0) return bad("No photo was attached.");
  if (file.size > MAX_BYTES) return bad("That photo is too big. Photos can be up to 10 MB.", 413);
  if (!file.type.startsWith("image/")) return bad("Only photos can be sent.");

  let jpeg: Buffer;
  try {
    jpeg = await sharp(Buffer.from(await file.arrayBuffer()), { limitInputPixels: 100_000_000 })
      .rotate()
      .resize({ width: MAX_EDGE, height: MAX_EDGE, fit: "inside", withoutEnlargement: true })
      .jpeg({ quality: 80 })
      .toBuffer();
  } catch {
    // Not decodable — a HEIC this build of libvips cannot read, a truncated
    // file, or not an image at all whatever its type says.
    return bad("That photo could not be read. Please try a JPEG or PNG.", 415);
  }

  try {
    const sas = await getChatPhotoUploadUrl(s, randomUUID());
    if ("error" in sas) return bad(sas.error, 403);
    if (!isChatPhotoUrl(sas.blobUrl)) throw new Error(`GetChatPhotoUploadToken returned an unexpected blobUrl: ${sas.blobUrl.slice(0, 120)}`);

    const put = await fetch(sas.sasUrl, {
      method: "PUT",
      headers: { "x-ms-blob-type": "BlockBlob", "Content-Type": "image/jpeg" },
      body: new Uint8Array(jpeg),
      cache: "no-store",
    });
    if (!put.ok) throw new Error(`Chat photo PUT: ${put.status} ${(await put.text().catch(() => "")).slice(0, 200)}`);
    return NextResponse.json({ blobUrl: sas.blobUrl });
  } catch (e) {
    await logWebError({ source: "/api/member/chat/photo", error: e, session: s });
    return bad("Couldn't upload the photo just now.", 502);
  }
}
