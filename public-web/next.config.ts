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
  experimental: {
    staleTimes: {
      dynamic: 300,
    },
  },
};

export default nextConfig;
