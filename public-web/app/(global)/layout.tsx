import type { Metadata } from "next";
import { GLOBAL_BASE_URL } from "@/lib/seo";
import { LegacyRedirectHandler } from "./LegacyRedirectHandler";

const SITE_NAME = "hashruns.org";
const DESCRIPTION =
  "Find hash runs worldwide. Browse upcoming runs, explore the global calendar, and discover kennels near you.";

export const metadata: Metadata = {
  metadataBase: new URL(GLOBAL_BASE_URL),
  title: {
    default: `${SITE_NAME} — Hash Runs Worldwide`,
    template: `%s | ${SITE_NAME}`,
  },
  description: DESCRIPTION,
  openGraph: {
    type: "website",
    siteName: SITE_NAME,
    title: `${SITE_NAME} — Hash Runs Worldwide`,
    description: DESCRIPTION,
    url: GLOBAL_BASE_URL,
    images: [{ url: "/images/og-hashruns.jpg", width: 1200, height: 630, alt: "hashruns.org" }],
  },
  twitter: {
    card: "summary_large_image",
    title: `${SITE_NAME} — Hash Runs Worldwide`,
    description: DESCRIPTION,
  },
  alternates: { canonical: GLOBAL_BASE_URL },
};

const jsonLd = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "WebSite",
      "@id": `${GLOBAL_BASE_URL}/#website`,
      url: GLOBAL_BASE_URL,
      name: SITE_NAME,
      description: DESCRIPTION,
      potentialAction: {
        "@type": "SearchAction",
        target: { "@type": "EntryPoint", urlTemplate: `${GLOBAL_BASE_URL}/?q={search_term_string}` },
        "query-input": "required name=search_term_string",
      },
    },
    {
      "@type": "Organization",
      "@id": `${GLOBAL_BASE_URL}/#organization`,
      name: "Harrier Central",
      url: GLOBAL_BASE_URL,
      logo: `${GLOBAL_BASE_URL}/images/logo.png`,
      sameAs: [],
    },
  ],
};

export default function GlobalLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark">
      <head>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
        {/* Legacy hash URL shim — runs before first paint.
            Single UUID: replace() to /rd/<uuid> (real server page, back button skips this).
            Multiple UUIDs: do nothing — LegacyRedirectHandler shows a picker. */}
        <script dangerouslySetInnerHTML={{ __html:
          `(function(){try{var h=window.location.hash,m,ids,parts;` +
          `if(!h)return;` +
          `if(m=h.match(/^#\\/RD\\/([a-fA-F0-9\\-]+)$/i)){window.location.replace('/rd/'+m[1]);return;}` +
          `if(h.indexOf('#/RD?')===0){` +
          `ids=(new URLSearchParams(h.slice(5))).get('publicKennelIds');` +
          `if(ids){parts=ids.split(',').map(function(s){return s.trim();}).filter(Boolean);` +
          `if(parts.length===1){window.location.replace('/rd/'+parts[0]);}}}` +
          `}catch(e){}})();`
        }} />
      </head>
      <body className="text-zinc-100 antialiased overflow-x-hidden">
        {/* Platform background — jungle tile + dark overlay */}
        <div
          className="fixed inset-0 -z-10 bg-repeat"
          style={{
            backgroundImage: "url(/images/jungle_background.jpg)",
            backgroundSize: "1024px 1024px",
          }}
        />
        <div
          className="fixed inset-0 -z-[9]"
          style={{ backgroundColor: "#000000", opacity: 0.55 }}
        />
        <LegacyRedirectHandler />
        {children}
      </body>
    </html>
  );
}
