# Demo Frontend Application

A modern React web application built with Next.js, TypeScript, and Tailwind CSS, designed for containerized deployment via AWS CI/CD pipeline.

## 🏗️ Architecture

- **Framework**: Next.js 14 with React 18
- **Language**: TypeScript 5
- **Styling**: Tailwind CSS 3
- **Runtime**: Node.js 20 LTS
- **Container**: Docker with multi-stage builds
- **Deployment**: AWS ECS Fargate with CI/CD
- **Routing**: Environment-based configuration with ALB integration

## 📁 Project Structure

```
assets/web/
├── src/
│   ├── config/
│   │   └── routes.ts           # ⭐ Centralized route configuration
│   ├── components/
│   │   └── Layout.tsx          # Main layout component
│   ├── pages/
│   │   ├── _app.tsx            # Next.js app wrapper
│   │   ├── _document.tsx       # Custom document
│   │   ├── index.tsx           # Home page
│   │   ├── about.tsx           # About page
│   │   ├── dashboard.tsx       # Dashboard page
│   │   ├── login.tsx           # Login page
│   │   └── api/
│   │       └── health.ts       # Health check endpoint
│   ├── styles/
│   │   └── globals.css         # Global styles with Tailwind
│   ├── types/                  # TypeScript type definitions
│   └── utils/                  # Utility functions
├── public/
│   └── favicon.png             # Application favicon
├── .env.example               # ⭐ Environment variables template
├── .env.local.example         # ⭐ Local development template
├── Dockerfile                  # Multi-stage Docker build
├── .dockerignore              # Docker build optimization
├── middleware.ts              # ⭐ Route prefix handling
├── package.json               # Dependencies and scripts
├── tsconfig.json              # TypeScript configuration
├── tailwind.config.js         # Tailwind CSS configuration
├── postcss.config.js          # PostCSS configuration
├── next.config.js             # ⭐ Next.js configuration with env vars
├── URL_STRUCTURE.md           # ⭐ URL routing documentation
└── ENV_VARS_GUIDE.md          # ⭐ Environment variables guide
```

## 🚀 Features

- **Modern UI**: Clean, responsive design with Tailwind CSS
- **Type Safety**: Full TypeScript integration
- **Performance**: Next.js optimizations and standalone output
- **Health Checks**: Built-in health endpoint for load balancer monitoring
- **⭐ Environment-Based Routing**: Configurable route prefixes via environment variables
- **⭐ Centralized Configuration**: Single source of truth for all routes
- **Security**: CSP headers and security best practices
- **Docker Ready**: Optimized multi-stage Docker builds
- **CI/CD Ready**: Configured for AWS CodeBuild deployment

## 📱 Pages

### Home (`/`)
- Welcome page with application overview
- Links to key features and dashboard
- Responsive hero section

### Dashboard (`/dashboard`)
- Service status monitoring
- Deployment history
- System metrics and uptime
- Real-time health indicators

### Login (`/login`)
- Authentication form (demo implementation)
- Form validation and error handling
- Responsive design

### About (`/about`)
- Technical architecture overview
- AWS infrastructure details
- CI/CD pipeline information

## 🛠️ Development

### Prerequisites

- Node.js 20 LTS
- npm or yarn
- Docker (for containerization)

### Environment Setup

1. **Copy environment template**:
   ```bash
   cp .env.local.example .env.local
   ```

2. **Configure environment variables** (see [ENV_VARS_GUIDE.md](./ENV_VARS_GUIDE.md)):
   ```bash
   # .env.local
   NEXT_PUBLIC_WEB_URL=http://localhost:3000
   NEXT_PUBLIC_API_URL=http://localhost:8080
   NEXT_PUBLIC_FRONTEND_PREFIX=/fe
   NEXT_PUBLIC_API_PREFIX=/api
   NEXT_PUBLIC_ADMIN_PREFIX=/admin
   ```

### Local Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Start production server
npm start

# Type checking
npm run type-check

# Linting
npm run lint
```

### Environment Variables

The application supports the following environment variables:

```env
# Node.js Environment
NODE_ENV=production

# Next.js Configuration
NEXT_TELEMETRY_DISABLED=1

# API Configuration
NEXT_PUBLIC_API_URL=https://api.dev.yourdns.com

# Security
NEXT_PUBLIC_ALLOWED_ORIGINS=https://demo.dev.yourdns.com
```

## 🐳 Docker Deployment

### Building the Image

```bash
# Build Docker image
docker build -t demo-frontend .

# Run container
docker run -p 3000:3000 demo-frontend
```

### Multi-stage Build Process

1. **Base**: Node.js 20 Alpine base image
2. **Dependencies**: Install production dependencies only
3. **Builder**: Build the Next.js application
4. **Runner**: Create optimized production image

The Dockerfile uses Next.js standalone output for minimal image size and faster cold starts.

## 🏭 CI/CD Pipeline

The application is deployed using AWS CodeBuild with the following pipeline:

### Build Process (`buildspec-frontend.yml`)

1. **Pre-build**:
   - Login to Amazon ECR
   - Set image tags based on git commit
   - Validate build environment

2. **Build**:
   - Build Docker image
   - Tag images for ECR

3. **Post-build**:
   - Push images to ECR
   - Generate ECS deployment artifacts
   - Prepare for service update

### Environment Variables (CodeBuild)

The buildspec requires these environment variables:

```yaml
AWS_ACCOUNT_ID: "123456789012"
AWS_DEFAULT_REGION: "us-east-1"
IMAGE_REPO_NAME: "demo-frontend-ecr"
ECS_SERVICE_NAME: "demo-frontend-service"
ECS_CLUSTER_NAME: "demo-cluster"
BUILD_CONTEXT_PATH: "assets/web"
```

## 🔧 Configuration Files

### Next.js Configuration (`next.config.js`)

- Standalone output for Docker optimization
- Security headers (CSP, HSTS, etc.)
- API proxy to backend services
- Static optimization settings

### TypeScript Configuration (`tsconfig.json`)

- Strict type checking
- Path mapping for clean imports
- Next.js specific settings
- ES2022 target with modern features

### Tailwind Configuration (`tailwind.config.js`)

- Custom color palette
- Component-based design system
- Responsive breakpoints
- PurgeCSS optimization

## 🔒 Security Features

- **Content Security Policy**: Prevents XSS attacks
- **HSTS Headers**: Force HTTPS connections
- **X-Frame-Options**: Prevent clickjacking
- **X-Content-Type-Options**: Prevent MIME sniffing
- **Referrer Policy**: Control referrer information

## 📊 Health Monitoring

The application includes a health check endpoint at `/api/health` that returns:

```json
{
  "status": "ok",
  "timestamp": "2026-01-14T10:30:00.000Z",
  "version": "1.0.0",
  "environment": "production"
}
```

This endpoint is used by:
- AWS Application Load Balancer health checks
- ECS service health monitoring
- Docker container health checks

## 🚦 Load Balancer Integration

The application is configured to work with AWS Application Load Balancer:

- Health check path: `/api/health`
- Health check port: 3000
- Healthy threshold: 2 consecutive successes
- Unhealthy threshold: 2 consecutive failures
- Timeout: 5 seconds
- Interval: 30 seconds

## 📈 Performance Optimizations

- **Next.js Static Generation**: Pre-rendered pages for faster loading
- **Image Optimization**: Automatic image compression and WebP conversion
- **Code Splitting**: Automatic bundle splitting for optimal loading
- **Tree Shaking**: Remove unused code in production builds
- **Gzip Compression**: Server-side compression for smaller payloads

## 🔗 Integration with Backend

The frontend integrates with the Django backend API:

- **API Base URL**: Configured via environment variables
- **Authentication**: JWT token-based authentication
- **CORS**: Properly configured for cross-origin requests
- **Error Handling**: Consistent error response handling

## 🎯 Production Readiness

The application includes production-ready features:

- **Error Boundaries**: Graceful error handling
- **Loading States**: User feedback during async operations
- **Responsive Design**: Works on all device sizes
- **SEO Optimization**: Meta tags and structured data
- **Analytics Ready**: Google Analytics integration points
- **PWA Features**: Service worker and offline support

## 📝 Deployment Checklist

Before deploying to production:

- [ ] Environment variables configured
- [ ] ECR repository created
- [ ] ECS service and cluster configured
- [ ] Load balancer target group configured
- [ ] Security groups allow traffic on port 3000
- [ ] Health check endpoint responding correctly
- [ ] Docker image builds successfully
- [ ] CI/CD pipeline environment variables set

## 🔍 Troubleshooting

### Common Issues

1. **Health Check Failures**:
   - Verify `/api/health` endpoint is accessible
   - Check container port configuration (3000)
   - Ensure security groups allow traffic

2. **Build Failures**:
   - Verify Node.js version compatibility
   - Check package.json dependencies
   - Validate TypeScript configuration

3. **Docker Issues**:
   - Check Dockerfile syntax
   - Verify .dockerignore excludes node_modules
   - Ensure proper multi-stage build configuration

### Logging

The application uses structured logging:
- Console logs for development
- JSON logs for production
- Integration with AWS CloudWatch

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with proper TypeScript types
4. Test locally with `npm run dev`
5. Build and test Docker image
6. Submit pull request

## 📄 License

This project is part of the demo application infrastructure and follows the same licensing as the parent project.

---

**Built with ❤️ using Next.js, TypeScript, and AWS**
