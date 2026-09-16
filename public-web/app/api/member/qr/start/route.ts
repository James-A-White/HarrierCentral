import { NextResponse } from "next/server";
import { randomUUID } from "crypto";
import { signValue } from "@/lib/member-session";

const SITE = process.env.NEXT_PUBLIC_SITE_ORIGIN ?? "https://www.hashruns.org";

/**
 * POST → { ticket, url }
 * A fresh auth code and device id for one QR sign-in. The QR encodes a URL so
 * the phone's camera opens the app through the universal link; the app calls
 * hcapp_authenticateWebPortal with the 'UWP:<code>' scan text, exactly as it
 * does for the portal's QR. The pair rides back in a signed ticket so the
 * poll cannot be pointed at somebody else's code.
 */
export async function POST() {
  const authCode = randomUUID();
  const deviceId = randomUUID();
  // The QR carries 'UWP:' + code (the prefix is how the app's scanner
  // recognises it), but the app records the BARE code — validateScan splits
  // the prefix off before hcapp_authenticateWebPortal — so the poll must
  // match on the bare code too.
  return NextResponse.json({
    ticket: signValue({ scanData: authCode, deviceId }, 6 * 60),
    url: `${SITE}/login/UWP:${authCode}`,
  });
}
