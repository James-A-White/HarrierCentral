export const GLOBAL_BASE_URL = "https://hashruns.org";

export function kennelBaseUrl(slug: string, customDomain: string | null | undefined): string {
  if (customDomain) return `https://${customDomain}`;
  return `${GLOBAL_BASE_URL}/${slug}`;
}
