/**
 * Route Configuration
 * 
 * Centralized routing configuration using environment variables.
 * All URL prefixes are defined here to ensure consistency across the application.
 */

// Get base URL from environment or use default
const getBaseUrl = () => {
  if (typeof window !== 'undefined') {
    // Client-side: use current origin
    return window.location.origin;
  }
  // Server-side: use environment variable
  return process.env.NEXT_PUBLIC_WEB_URL || 'https://application.dev.yourdns.com';
};

// Route prefixes from environment variables
export const ROUTE_CONFIG = {
  // Base URLs
  BASE_URL: getBaseUrl(),
  API_URL: process.env.NEXT_PUBLIC_API_URL || 'https://application.dev.yourdns.com',
  
  // Path prefixes (without trailing slash)
  FRONTEND_PREFIX: process.env.NEXT_PUBLIC_FRONTEND_PREFIX || '/fe',
  API_PREFIX: process.env.NEXT_PUBLIC_API_PREFIX || '/api',
  ADMIN_PREFIX: process.env.NEXT_PUBLIC_ADMIN_PREFIX || '/admin',
} as const;

/**
 * Route Helper Functions
 */

/**
 * Creates a frontend route with the correct prefix
 * @param path - Path without leading slash (e.g., 'dashboard', 'login')
 * @returns Full path with frontend prefix (e.g., '/fe/dashboard')
 */
export function frontendRoute(path: string = ''): string {
  const cleanPath = path.startsWith('/') ? path.slice(1) : path;
  return cleanPath ? `${ROUTE_CONFIG.FRONTEND_PREFIX}/${cleanPath}` : ROUTE_CONFIG.FRONTEND_PREFIX;
}

/**
 * Creates an API route with the correct prefix
 * @param endpoint - API endpoint without leading slash (e.g., 'health', 'users')
 * @returns Full path with API prefix (e.g., '/api/health')
 */
export function apiRoute(endpoint: string = ''): string {
  const cleanEndpoint = endpoint.startsWith('/') ? endpoint.slice(1) : endpoint;
  return cleanEndpoint ? `${ROUTE_CONFIG.API_PREFIX}/${cleanEndpoint}` : ROUTE_CONFIG.API_PREFIX;
}

/**
 * Creates a full API URL
 * @param endpoint - API endpoint without leading slash
 * @returns Full URL (e.g., 'https://application.dev.yourdns.com/api/health')
 */
export function apiUrl(endpoint: string = ''): string {
  return `${ROUTE_CONFIG.API_URL}${apiRoute(endpoint)}`;
}

/**
 * Creates an admin route with the correct prefix
 * @param path - Admin path without leading slash (e.g., 'admin/', 'health/')
 * @returns Full path with admin prefix (e.g., '/admin/admin/')
 */
export function adminRoute(path: string = ''): string {
  const cleanPath = path.startsWith('/') ? path.slice(1) : path;
  return cleanPath ? `${ROUTE_CONFIG.ADMIN_PREFIX}/${cleanPath}` : ROUTE_CONFIG.ADMIN_PREFIX;
}

/**
 * Named Routes for common pages
 */
export const ROUTES = {
  // Frontend routes
  HOME: frontendRoute(''),
  DASHBOARD: frontendRoute('dashboard'),
  LOGIN: frontendRoute('login'),
  ABOUT: frontendRoute('about'),
  NOT_FOUND: frontendRoute('404'),
  
  // API routes
  API_HEALTH: apiRoute('health'),
  API_AUTH: apiRoute('auth'),
  API_USERS: apiRoute('users'),
  API_STATS: apiRoute('stats'),
  
  // Admin routes
  ADMIN_PANEL: adminRoute('admin/'),
  ADMIN_HEALTH: adminRoute('health/'),
  ADMIN_ROOT: adminRoute(''),
} as const;

/**
 * External URLs (full URLs)
 */
export const EXTERNAL_ROUTES = {
  API_HEALTH: apiUrl('health'),
  API_AUTH: apiUrl('auth'),
  API_USERS: apiUrl('users'),
} as const;

// Export route config for use in next.config.js
export default ROUTE_CONFIG;
