// Type definitions for the application

// User types
export interface User {
  id: number;
  username: string;
  email: string;
  firstName?: string;
  lastName?: string;
  isActive: boolean;
  dateJoined: string;
  lastLogin?: string;
}

// Authentication types
export interface LoginCredentials {
  username: string;
  password: string;
}

export interface AuthToken {
  access: string;
  refresh: string;
}

export interface AuthResponse {
  token: AuthToken;
  user: User;
}

// API response types
export interface ApiError {
  message: string;
  code?: string;
  details?: Record<string, any>;
}

export interface PaginatedResponse<T> {
  count: number;
  next?: string;
  previous?: string;
  results: T[];
}

// Dashboard types
export interface DashboardStats {
  totalUsers: number;
  activeServices: number;
  deployments: number;
  uptime: string;
}

export interface ServiceStatus {
  name: string;
  status: 'healthy' | 'unhealthy' | 'warning';
  lastCheck: string;
  uptime: number;
}

export interface Deployment {
  id: number;
  service: string;
  version: string;
  status: 'success' | 'failed' | 'pending' | 'running';
  timestamp: string;
  duration?: number;
  environment: 'development' | 'staging' | 'production';
}

// Health check types
export interface HealthCheck {
  status: 'ok' | 'error';
  timestamp: string;
  version?: string;
  environment?: string;
  services?: {
    database: 'ok' | 'error';
    redis?: 'ok' | 'error';
    storage?: 'ok' | 'error';
  };
}

// Form types
export interface FormField {
  name: string;
  label: string;
  type: 'text' | 'email' | 'password' | 'number' | 'textarea' | 'select';
  required?: boolean;
  placeholder?: string;
  options?: { value: string; label: string }[];
  validation?: {
    minLength?: number;
    maxLength?: number;
    pattern?: RegExp;
  };
}

export interface FormErrors {
  [key: string]: string[];
}

// Component prop types
export interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
  disabled?: boolean;
  children: React.ReactNode;
  onClick?: () => void;
  type?: 'button' | 'submit' | 'reset';
  className?: string;
}

export interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title?: string;
  children: React.ReactNode;
  size?: 'sm' | 'md' | 'lg' | 'xl';
}

// Navigation types
export interface NavigationItem {
  name: string;
  href: string;
  icon?: React.ComponentType<{ className?: string }>;
  current?: boolean;
  children?: NavigationItem[];
}

// Infrastructure types
export interface AWSResource {
  id: string;
  type: 'ecs-service' | 'rds-instance' | 'load-balancer' | 'ecr-repository';
  name: string;
  status: 'active' | 'inactive' | 'pending' | 'error';
  region: string;
  tags?: Record<string, string>;
  createdAt: string;
  updatedAt: string;
}

export interface ContainerInfo {
  id: string;
  image: string;
  status: 'running' | 'stopped' | 'pending' | 'error';
  cpu: number;
  memory: number;
  startedAt: string;
  ports: number[];
}

// Monitoring types
export interface MetricData {
  timestamp: string;
  value: number;
  unit: string;
}

export interface ServiceMetrics {
  service: string;
  metrics: {
    cpu: MetricData[];
    memory: MetricData[];
    requests: MetricData[];
    errors: MetricData[];
  };
  timeRange: '1h' | '24h' | '7d' | '30d';
}

// Configuration types
export interface AppConfig {
  apiUrl: string;
  environment: 'development' | 'staging' | 'production';
  features: {
    authentication: boolean;
    monitoring: boolean;
    notifications: boolean;
  };
  monitoring: {
    healthCheckInterval: number;
    metricsRefreshInterval: number;
  };
}

// Utility types
export type LoadingState = 'idle' | 'loading' | 'success' | 'error';

export type Theme = 'light' | 'dark';

export type NotificationType = 'success' | 'error' | 'warning' | 'info';

export interface Notification {
  id: string;
  type: NotificationType;
  title: string;
  message?: string;
  duration?: number;
  action?: {
    label: string;
    onClick: () => void;
  };
}

// Event types
export interface DeploymentEvent {
  id: string;
  type: 'deployment_started' | 'deployment_completed' | 'deployment_failed';
  service: string;
  timestamp: string;
  details: Record<string, any>;
}

export interface SystemEvent {
  id: string;
  type: 'service_health_change' | 'resource_limit_reached' | 'error_threshold_exceeded';
  severity: 'low' | 'medium' | 'high' | 'critical';
  timestamp: string;
  message: string;
  resolved?: boolean;
}

// Generic utility types
export type Optional<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>;

export type RequiredBy<T, K extends keyof T> = Omit<T, K> & Required<Pick<T, K>>;

export type Nullable<T> = T | null;

export type ArrayElement<T> = T extends (infer U)[] ? U : never;
