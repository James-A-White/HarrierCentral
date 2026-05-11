import { headers } from "next/headers";

/**
 * Returns true when the current request came in via a tenant's custom domain.
 * The proxy middleware sets x-custom-domain on every custom-domain request.
 */
export async function getIsCustomDomain(): Promise<boolean> {
  const h = await headers();
  return !!h.get("x-custom-domain");
}
