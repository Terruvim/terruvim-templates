// API utility functions for making HTTP requests
import { ROUTE_CONFIG, apiRoute } from '../config/routes';

interface ApiResponse<T = any> {
  data?: T;
  error?: string;
  status: number;
}

interface RequestConfig {
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE';
  headers?: Record<string, string>;
  body?: any;
  timeout?: number;
}

class ApiClient {
  private baseURL: string;
  private defaultHeaders: Record<string, string>;

  constructor(baseURL: string = ROUTE_CONFIG.API_URL) {
    this.baseURL = baseURL.replace(/\/$/, ''); // Remove trailing slash
    this.defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  private async request<T = any>(
    endpoint: string,
    config: RequestConfig = {}
  ): Promise<ApiResponse<T>> {
    const {
      method = 'GET',
      headers = {},
      body,
      timeout = 10000,
    } = config;

    const url = `${this.baseURL}${endpoint.startsWith('/') ? endpoint : '/' + endpoint}`;
    
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout);

    try {
      const response = await fetch(url, {
        method,
        headers: {
          ...this.defaultHeaders,
          ...headers,
        },
        body: body ? JSON.stringify(body) : undefined,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      const contentType = response.headers.get('content-type');
      const isJson = contentType?.includes('application/json');
      
      let responseData: any = null;
      if (isJson) {
        responseData = await response.json();
      } else {
        responseData = await response.text();
      }

      if (!response.ok) {
        return {
          error: responseData?.message || responseData || `HTTP ${response.status}`,
          status: response.status,
        };
      }

      return {
        data: responseData,
        status: response.status,
      };
    } catch (error) {
      clearTimeout(timeoutId);
      
      if (error instanceof Error) {
        if (error.name === 'AbortError') {
          return {
            error: 'Request timeout',
            status: 408,
          };
        }
        return {
          error: error.message,
          status: 0,
        };
      }

      return {
        error: 'Unknown error occurred',
        status: 0,
      };
    }
  }

  // Convenience methods
  async get<T = any>(endpoint: string, headers?: Record<string, string>): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, { method: 'GET', headers });
  }

  async post<T = any>(
    endpoint: string,
    body?: any,
    headers?: Record<string, string>
  ): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, { method: 'POST', body, headers });
  }

  async put<T = any>(
    endpoint: string,
    body?: any,
    headers?: Record<string, string>
  ): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, { method: 'PUT', body, headers });
  }

  async delete<T = any>(endpoint: string, headers?: Record<string, string>): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, { method: 'DELETE', headers });
  }

  // Health check method
  async healthCheck(): Promise<ApiResponse<{
    status: string;
    timestamp: string;
    version?: string;
    environment?: string;
  }>> {
    return this.get(apiRoute('health'));
  }

  // Authentication methods
  async login(username: string, password: string): Promise<ApiResponse<{
    success: boolean;
    message: string;
    token?: string;
    user?: {
      id: string;
      username: string;
      email: string;
    };
    expiresIn?: string;
  }>> {
    return this.post(apiRoute('auth'), { username, password });
  }

  async logout(): Promise<ApiResponse<{
    success: boolean;
    message: string;
  }>> {
    return this.delete(apiRoute('auth'));
  }

  // User methods
  async getUserStatus(): Promise<ApiResponse<{
    id: string;
    username: string;
    isAuthenticated: boolean;
    lastLogin: string;
    permissions: string[];
    profile: {
      email: string;
      firstName: string;
      lastName: string;
      avatar?: string;
    };
    preferences: {
      theme: string;
      language: string;
      notifications: boolean;
    };
  }>> {
    return this.get(apiRoute('user'));
  }

  async updateUserPreferences(preferences: {
    theme?: string;
    language?: string;
    notifications?: boolean;
  }): Promise<ApiResponse<{
    message: string;
    preferences: any;
  }>> {
    return this.put(apiRoute('user'), { preferences });
  }

  // System stats method
  async getSystemStats(): Promise<ApiResponse<{
    timestamp: string;
    environment: string;
    version: string;
    stats: {
      uptime: number;
      memory: {
        used: number;
        total: number;
        free: number;
      };
      cpu: {
        usage: number;
        cores: number;
        loadAverage: string[];
      };
      services: Array<{
        name: string;
        status: string;
        port: number;
        pid: number;
      }>;
      requests: {
        total: number;
        perSecond: number;
        errors: number;
        avgResponseTime: number;
      };
    };
  }>> {
    return this.get(apiRoute('stats'));
  }

  // Token management methods
  setAuthToken(token: string): void {
    this.defaultHeaders['Authorization'] = `Bearer ${token}`;
  }

  removeAuthToken(): void {
    delete this.defaultHeaders['Authorization'];
  }
}

// Create singleton instance
export const apiClient = new ApiClient();

// Export types for use in components
export type { ApiResponse, RequestConfig };
