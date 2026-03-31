import type { NextConfig } from 'next';
import path from 'path';

const nextConfig: NextConfig = {
  output: 'standalone',
  turbopack: {
    root: path.resolve(__dirname),
  },
  async redirects() {
    return [
      {
        source: '/:path*',
        has: [{ type: 'host', value: 'www.tsaeats.org' }],
        destination: 'https://tsaeats.org/:path*',
        permanent: true,
      },
    ];
  },
};

export default nextConfig;
