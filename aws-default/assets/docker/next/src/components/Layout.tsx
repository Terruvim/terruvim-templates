import React from 'react';
import Link from 'next/link';
import { ROUTES } from '../config/routes';

interface LayoutProps {
  children: React.ReactNode;
  title?: string;
}

export default function Layout({ children, title = 'Demo App' }: LayoutProps) {
  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center">
              <Link href={ROUTES.HOME} className="text-xl font-bold text-primary-600">
                Demo App
              </Link>
            </div>
            <div className="flex items-center space-x-4">
              <Link href={ROUTES.HOME} className="text-gray-700 hover:text-primary-600">
                Home
              </Link>
              <Link href={ROUTES.ABOUT} className="text-gray-700 hover:text-primary-600">
                About
              </Link>
              <Link href={ROUTES.DASHBOARD} className="btn-primary">
                Dashboard
              </Link>
            </div>
          </div>
        </div>
      </nav>
      
      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          {children}
        </div>
      </main>
      
      <footer className="bg-white border-t mt-auto">
        <div className="max-w-7xl mx-auto py-4 px-4 sm:px-6 lg:px-8">
          <p className="text-center text-gray-500 text-sm">
            © 2026 Demo App. Built with Next.js and deployed via AWS CI/CD.
          </p>
        </div>
      </footer>
    </div>
  );
}
