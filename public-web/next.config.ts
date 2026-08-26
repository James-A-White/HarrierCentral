import type { NextConfig } from "next";
import path from "path";

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { version } = require("./package.json") as { version: string };

const nextConfig: NextConfig = {
  env: {
    NEXT_PUBLIC_APP_VERSION: version,
  },
  output: "standalone",
  outputFileTracingRoot: path.join(__dirname),
  images: {
    // Photo blobs the /_next/image optimizer may fetch and resize (see
    // photoSrc in lib/packtrack.ts). Requires sharp at runtime — the deploy
    // zip must include the Linux x64 sharp binaries (built on macOS).
    remotePatterns: [
      { protocol: "https", hostname: "harriercentral.blob.core.windows.net" },
    ],
    // Photo blobs are immutable once uploaded (edits write a new
    // EditedBlobUrl), so optimized renditions can be cached for a month.
    minimumCacheTTL: 2678400,
  },
  experimental: {
    staleTimes: {
      dynamic: 300,
    },
  },
  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          { key: "X-Content-Type-Options",  value: "nosniff" },
          { key: "X-Frame-Options",          value: "SAMEORIGIN" },
          { key: "X-XSS-Protection",         value: "1; mode=block" },
          { key: "Referrer-Policy",          value: "strict-origin-when-cross-origin" },
          { key: "Permissions-Policy",       value: "camera=(), microphone=(), geolocation=()" },
        ],
      },
    ];
  },
};

export default nextConfig;
