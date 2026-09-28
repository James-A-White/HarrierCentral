/**
 * Adding a kennel from hashruns.org/add-kennel (E12.F1.S7). Server only.
 *
 * The form carries a signed "started at" stamp minted when the page was
 * rendered. A person takes more than a few seconds to fill in a kennel's
 * details; a script posting straight at the route does not — and cannot
 * forge an older stamp without the secret. That, a honeypot field and a
 * per-IP limit stop most bots before an email is ever sent; the emailed
 * code stops the rest.
 */
import "server-only";
import { createHmac, timingSafeEqual } from "node:crypto";

const MIN_FILL_MS = 5_000;
const MAX_FILL_MS = 24 * 60 * 60_000;

function secret(): string {
  return process.env.HC_INTERNAL_SECRET || process.env.HC_ADMIN_SESSION_SECRET || "hc-dev-only";
}

function sign(value: string): string {
  return createHmac("sha256", secret()).update(`kennel-request:${value}`).digest("base64url");
}

/** A stamp for a form rendered now. */
export function mintFormStamp(now = Date.now()): string {
  const t = String(now);
  return `${t}.${sign(t)}`;
}

/** Whether a stamp is ours and the form took a human amount of time. */
export function checkFormStamp(stamp: string | undefined, now = Date.now()): "ok" | "too-fast" | "bad" {
  const [t, mac] = (stamp ?? "").split(".");
  if (!t || !mac) return "bad";
  const expected = Buffer.from(sign(t));
  const given = Buffer.from(mac);
  if (expected.length !== given.length || !timingSafeEqual(expected, given)) return "bad";
  const age = now - Number(t);
  if (!Number.isFinite(age) || age > MAX_FILL_MS) return "bad";
  return age < MIN_FILL_MS ? "too-fast" : "ok";
}

/** The form's fields, as the browser posts them. */
export interface KennelRequestForm {
  firstName: string;
  lastName: string;
  hashName: string;
  email: string;
  kennelName: string;
  kennelShortName: string;
  kennelDescription: string;
  kennelUrl: string;
  kennelFacebookUrl: string;
  countryId: string;
  regionId: string;
  cityId: string;
  cityText: string;
  runsPerMonth: string;
  hashersPerRun: string;
  hashCash: string;
  nextRunNumber: string;
  howDidYouLearn: string;
  comments: string;
}
