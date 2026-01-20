import type { NextPage } from 'next';
import Link from 'next/link';
import { ROUTES, adminRoute } from '../config/routes';

const Custom404: NextPage = () => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50 flex items-center justify-center px-4">
      <div className="max-w-2xl w-full text-center">
        {/* 404 Illustration */}
        <div className="mb-8">
          <div className="inline-block">
            <svg className="w-64 h-64 mx-auto text-blue-600 opacity-20" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={0.5} d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <div className="absolute inset-0 flex items-center justify-center">
              <h1 className="text-9xl font-extrabold text-gray-200">404</h1>
            </div>
          </div>
        </div>

        {/* Error Message */}
        <div className="space-y-4 mb-12">
          <h2 className="text-4xl font-bold text-gray-900">
            Page Not Found
          </h2>
          <p className="text-xl text-gray-600 max-w-md mx-auto">
            Oops! The page you're looking for doesn't exist or has been moved.
          </p>
        </div>

        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row gap-4 justify-center items-center mb-12">
          <Link href={ROUTES.HOME} className="w-full sm:w-auto inline-flex items-center justify-center px-8 py-3 bg-blue-600 text-white font-semibold rounded-lg hover:bg-blue-700 transition-all transform hover:scale-105 shadow-lg hover:shadow-xl">
            <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
            </svg>
            Back to Home
          </Link>
          
          <Link href={ROUTES.DASHBOARD} className="w-full sm:w-auto inline-flex items-center justify-center px-8 py-3 bg-white text-gray-900 font-semibold rounded-lg hover:bg-gray-50 transition-all border-2 border-gray-200">
            <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
            </svg>
            Go to Dashboard
          </Link>
        </div>

        {/* Quick Links */}
        <div className="border-t border-gray-200 pt-8">
          <p className="text-sm text-gray-500 mb-4">Quick Links</p>
          <div className="flex flex-wrap justify-center gap-4 text-sm">
            <a href={adminRoute('admin/')} target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:text-blue-800 transition-colors">
              Django Admin
            </a>
            <span className="text-gray-300">•</span>
            <a href={ROUTES.API_HEALTH} className="text-blue-600 hover:text-blue-800 transition-colors">
              Health Check
            </a>
            <span className="text-gray-300">•</span>
            <Link href={ROUTES.ABOUT} className="text-blue-600 hover:text-blue-800 transition-colors">
              About
            </Link>
            <span className="text-gray-300">•</span>
            <Link href={ROUTES.LOGIN} className="text-blue-600 hover:text-blue-800 transition-colors">
              Login
            </Link>
          </div>
        </div>

        {/* Footer */}
        <div className="mt-12">
          <p className="text-xs text-gray-400">
            Powered by Next.js • Deployed on AWS ECS • CI/CD with Terruvim
          </p>
        </div>
      </div>
    </div>
  );
};

export default Custom404;
