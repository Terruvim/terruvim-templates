/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  poweredByHeader: false,
  
  // ALB transforms /fe/* -> /* before sending to container
  // assetPrefix needed so browser requests /fe/_next/static/* (ALB routes to container)
  assetPrefix: process.env.NEXT_PUBLIC_FRONTEND_PREFIX || '/fe',
  
  // Environment variables that should be available on client side
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'https://application.dev.yourdns.com',
    NEXT_PUBLIC_WEB_URL: process.env.NEXT_PUBLIC_WEB_URL || 'https://application.dev.yourdns.com',
    NEXT_PUBLIC_FRONTEND_PREFIX: process.env.NEXT_PUBLIC_FRONTEND_PREFIX || '/fe',
    NEXT_PUBLIC_API_PREFIX: process.env.NEXT_PUBLIC_API_PREFIX || '/api',
    NEXT_PUBLIC_ADMIN_PREFIX: process.env.NEXT_PUBLIC_ADMIN_PREFIX || '/admin',
    NEXT_PUBLIC_APP_ENV: process.env.NEXT_PUBLIC_APP_ENV || 'development',
  },

  // Security headers
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'origin-when-cross-origin',
          },
        ],
      },
    ];
  },
  
  // Image optimization settings
  images: {
    unoptimized: true, // Disable Next.js image optimization for static export
  },
};

module.exports = nextConfig;