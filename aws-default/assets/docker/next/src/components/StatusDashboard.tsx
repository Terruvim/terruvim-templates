import React, { useEffect, useState } from 'react';
import { apiClient } from '../utils/api';
import { formatRelativeTime, getStatusColor, cn } from '../utils/helpers';

interface ServiceHealth {
  name: string;
  status: 'healthy' | 'unhealthy' | 'warning';
  lastCheck: string;
  responseTime: number;
}

interface StatusCardProps {
  title: string;
  value: string | number;
  status: 'success' | 'warning' | 'error' | 'info';
  description?: string;
  icon?: React.ReactNode;
}

function StatusCard({ title, value, status, description, icon }: StatusCardProps) {
  const statusStyles = {
    success: 'bg-green-50 border-green-200 text-green-800',
    warning: 'bg-yellow-50 border-yellow-200 text-yellow-800',
    error: 'bg-red-50 border-red-200 text-red-800',
    info: 'bg-blue-50 border-blue-200 text-blue-800',
  };

  return (
    <div className={cn('p-4 rounded-lg border', statusStyles[status])}>
      <div className="flex items-center justify-between">
        <div className="flex-1">
          <h3 className="text-lg font-semibold">{title}</h3>
          <p className="text-2xl font-bold mt-1">{value}</p>
          {description && (
            <p className="text-sm mt-2 opacity-75">{description}</p>
          )}
        </div>
        {icon && (
          <div className="flex-shrink-0 ml-4">
            {icon}
          </div>
        )}
      </div>
    </div>
  );
}

interface StatusBadgeProps {
  status: string;
  children: React.ReactNode;
}

function StatusBadge({ status, children }: StatusBadgeProps) {
  return (
    <span className={cn('inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium', getStatusColor(status))}>
      <div className={cn('w-2 h-2 rounded-full mr-2', {
        'bg-green-400': status === 'healthy' || status === 'success',
        'bg-yellow-400': status === 'warning' || status === 'pending',
        'bg-red-400': status === 'unhealthy' || status === 'error',
        'bg-gray-400': status === 'unknown',
      })}>
      </div>
      {children}
    </span>
  );
}

export default function StatusDashboard() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdate, setLastUpdate] = useState<string>(new Date().toISOString());
  const [backendHealth, setBackendHealth] = useState<ServiceHealth | null>(null);

  const checkBackendHealth = async () => {
    try {
      const startTime = Date.now();
      const response = await apiClient.healthCheck();
      const responseTime = Date.now() - startTime;

      if (response.error) {
        setBackendHealth({
          name: 'Django Backend',
          status: 'unhealthy',
          lastCheck: new Date().toISOString(),
          responseTime,
        });
        setError(response.error);
      } else {
        setBackendHealth({
          name: 'Django Backend',
          status: 'healthy',
          lastCheck: new Date().toISOString(),
          responseTime,
        });
        setError(null);
      }
    } catch (err) {
      setBackendHealth({
        name: 'Django Backend',
        status: 'unhealthy',
        lastCheck: new Date().toISOString(),
        responseTime: 0,
      });
      setError('Failed to connect to backend');
    } finally {
      setLoading(false);
      setLastUpdate(new Date().toISOString());
    }
  };

  useEffect(() => {
    checkBackendHealth();

    // Set up polling every 30 seconds
    const interval = setInterval(checkBackendHealth, 30000);
    return () => clearInterval(interval);
  }, []);

  const mockServices: ServiceHealth[] = [
    {
      name: 'Load Balancer',
      status: 'healthy',
      lastCheck: new Date().toISOString(),
      responseTime: 15,
    },
    {
      name: 'PostgreSQL Database',
      status: 'healthy',
      lastCheck: new Date().toISOString(),
      responseTime: 25,
    },
    {
      name: 'Redis Cache',
      status: 'warning',
      lastCheck: new Date().toISOString(),
      responseTime: 120,
    },
  ];

  const allServices = backendHealth ? [backendHealth, ...mockServices] : mockServices;
  const healthyCount = allServices.filter(s => s.status === 'healthy').length;
  const unhealthyCount = allServices.filter(s => s.status === 'unhealthy').length;
  const warningCount = allServices.filter(s => s.status === 'warning').length;

  const overallStatus = unhealthyCount > 0 ? 'error' : warningCount > 0 ? 'warning' : 'success';
  const uptime = unhealthyCount === 0 ? '99.9%' : `${Math.max(0, 100 - (unhealthyCount * 25)).toFixed(1)}%`;

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-gray-900 mb-2">System Status</h2>
        <p className="text-gray-600">
          Last updated: {formatRelativeTime(lastUpdate)}
          {!loading && (
            <button
              onClick={checkBackendHealth}
              className="ml-4 text-primary-600 hover:text-primary-700 text-sm"
            >
              Refresh
            </button>
          )}
        </p>
      </div>

      {/* Overall Status Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <StatusCard
          title="Overall Status"
          value={overallStatus === 'success' ? 'Operational' : overallStatus === 'warning' ? 'Degraded' : 'Outage'}
          status={overallStatus}
          description="All systems status"
          icon={
            <svg className="w-8 h-8" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
            </svg>
          }
        />

        <StatusCard
          title="Healthy Services"
          value={healthyCount}
          status="success"
          description={`${healthyCount}/${allServices.length} services`}
          icon={
            <svg className="w-8 h-8" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
            </svg>
          }
        />

        <StatusCard
          title="System Uptime"
          value={uptime}
          status={parseFloat(uptime) > 99 ? 'success' : 'warning'}
          description="Last 30 days"
          icon={
            <svg className="w-8 h-8" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clipRule="evenodd" />
            </svg>
          }
        />

        <StatusCard
          title="Response Time"
          value={`${Math.round(allServices.reduce((acc, s) => acc + s.responseTime, 0) / allServices.length)}ms`}
          status={allServices.some(s => s.responseTime > 1000) ? 'warning' : 'success'}
          description="Average response"
          icon={
            <svg className="w-8 h-8" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM6.293 6.707a1 1 0 10-1.414-1.414l-3 3a1 1 0 000 1.414l3 3a1 1 0 001.414-1.414L4.414 10H17a1 1 0 100-2H4.414l1.879-1.293z" clipRule="evenodd" />
            </svg>
          }
        />
      </div>

      {/* Service Details */}
      <div className="bg-white shadow-sm rounded-lg border overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">Service Details</h3>
        </div>
        <div className="divide-y divide-gray-200">
          {loading ? (
            <div className="p-6 text-center">
              <div className="inline-flex items-center">
                <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-gray-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Loading service status...
              </div>
            </div>
          ) : (
            allServices.map((service, index) => (
              <div key={index} className="p-6">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-3">
                    <div className={cn('w-3 h-3 rounded-full', {
                      'bg-green-400': service.status === 'healthy',
                      'bg-yellow-400': service.status === 'warning',
                      'bg-red-400': service.status === 'unhealthy',
                    })}></div>
                    <div>
                      <h4 className="text-sm font-medium text-gray-900">{service.name}</h4>
                      <p className="text-sm text-gray-500">
                        Last check: {formatRelativeTime(service.lastCheck)}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center space-x-4">
                    <div className="text-right">
                      <div className="text-sm text-gray-500">Response Time</div>
                      <div className="text-sm font-medium">{service.responseTime}ms</div>
                    </div>
                    <StatusBadge status={service.status}>
                      {service.status.charAt(0).toUpperCase() + service.status.slice(1)}
                    </StatusBadge>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Error Display */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-center">
            <svg className="w-5 h-5 text-red-400 mr-3" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
            </svg>
            <div>
              <h4 className="text-sm font-medium text-red-800">Connection Error</h4>
              <p className="text-sm text-red-600 mt-1">{error}</p>
            </div>
          </div>
        </div>
      )}

      {/* Incident History */}
      <div className="bg-white shadow-sm rounded-lg border overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">Recent Incidents</h3>
        </div>
        <div className="p-6">
          <div className="text-center text-gray-500">
            <svg className="w-12 h-12 mx-auto mb-4 opacity-50" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
            </svg>
            <p>No incidents in the last 30 days</p>
            <p className="text-sm mt-1">All systems are operating normally</p>
          </div>
        </div>
      </div>
    </div>
  );
}
