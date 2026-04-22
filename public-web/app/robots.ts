import type { MetadataRoute } from "next";
import { GLOBAL_BASE_URL } from "@/lib/seo";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: "*", allow: "/" },
    sitemap: `${GLOBAL_BASE_URL}/sitemap.xml`,
  };
}
