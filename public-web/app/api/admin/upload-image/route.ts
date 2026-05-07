import { NextRequest, NextResponse } from "next/server";
import { randomUUID } from "crypto";
import { verifySession } from "@/lib/admin-session";

const ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp", "image/gif"];
const MAX_BYTES = 10 * 1024 * 1024; // 10 MB
const BLOB_BASE = "https://harriercentral.blob.core.windows.net/kennel-web-images";

export async function POST(req: NextRequest) {
  let formData: FormData;
  try {
    formData = await req.formData();
  } catch {
    return NextResponse.json({ error: "Invalid form data." }, { status: 400 });
  }

  const file = formData.get("file") as File | null;
  const slug = formData.get("slug") as string | null;

  if (!file || !slug) {
    return NextResponse.json({ error: "Missing file or slug." }, { status: 400 });
  }

  if (!ALLOWED_TYPES.includes(file.type)) {
    return NextResponse.json({ error: "Unsupported file type. Use JPEG, PNG, WebP, or GIF." }, { status: 400 });
  }

  if (file.size > MAX_BYTES) {
    return NextResponse.json({ error: "File too large. Maximum size is 10 MB." }, { status: 400 });
  }

  const session = verifySession(req.cookies.get("hc_admin_session")?.value);
  if (!session || session.kennelSlug !== slug) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401 });
  }

  const ext = file.name.split(".").pop()?.toLowerCase() ?? "jpg";
  const blobName = `${slug}/${randomUUID()}.${ext}`;

  const sasUrl = process.env.AZURE_BLOB_SAS_URL;
  if (!sasUrl) {
    return NextResponse.json({ error: "Storage not configured." }, { status: 500 });
  }

  // Construct per-blob URL from the container SAS URL
  const sasQuery = new URL(sasUrl).search;
  const uploadUrl = `${BLOB_BASE}/${blobName}${sasQuery}`;

  const buffer = Buffer.from(await file.arrayBuffer());

  const uploadRes = await fetch(uploadUrl, {
    method: "PUT",
    headers: {
      "x-ms-blob-type": "BlockBlob",
      "Content-Type": file.type,
      "Content-Length": String(buffer.byteLength),
    },
    body: buffer,
  });

  if (!uploadRes.ok) {
    const detail = await uploadRes.text().catch(() => "");
    return NextResponse.json({ error: "Storage upload failed.", detail }, { status: 502 });
  }

  return NextResponse.json({ url: `${BLOB_BASE}/${blobName}` });
}
