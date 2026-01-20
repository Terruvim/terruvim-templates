# Django Backend Dockerfile
# Multi-stage build for production-ready Django application

# Build stage
FROM python:3.12-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

# Production stage
FROM python:3.12-slim

# Create non-root user for security
RUN groupadd -r django && useradd -r -g django django

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    netcat-openbsd \
    dnsutils \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Copy wheels from builder
COPY --from=builder /app/wheels /wheels
COPY --from=builder /app/requirements.txt .

# Install Python packages
RUN pip install --no-cache /wheels/*

# Copy application code
COPY --chown=django:django . .

# Create directories with proper permissions before switching user
RUN mkdir -p /app/staticfiles /app/media && \
    chmod 755 /app/staticfiles /app/media && \
    chown -R django:django /app

# Copy entrypoint script
COPY --chown=django:django entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy superuser creation script
COPY --chown=django:django create_superuser.py /app/create_superuser.py

# Copy debug script
COPY --chown=django:django debug.sh /debug.sh
RUN chmod +x /debug.sh

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DJANGO_SETTINGS_MODULE=config.settings

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/api/health/ || exit 1

# Switch to non-root user
USER django

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Run with gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "4", "--threads", "2", "--worker-class", "gthread", "--access-logfile", "-", "--error-logfile", "-", "config.wsgi:application"]
