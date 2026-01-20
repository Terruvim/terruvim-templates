# Django settings for Docker deployment
import os
from pathlib import Path

# Try to import dj_database_url, fallback if not available
try:
    import dj_database_url
    HAS_DJ_DATABASE_URL = True
except ImportError:
    HAS_DJ_DATABASE_URL = False

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.environ.get('SECRET_KEY', 'django-insecure-change-me-in-production')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = os.environ.get('DEBUG', 'False').lower() == 'true'

ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '*').split(',')

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'corsheaders',
    'config',  # Add the config app to enable management commands
]

MIDDLEWARE = [
    'config.middleware.HealthCheckMiddleware',  # Health check bypass - MUST be first!
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

# Database configuration with fallback logic
DATABASE_URL = os.environ.get('DATABASE_URL')

# Individual DB variables
DB_HOST = os.environ.get('DB_HOST')
DB_NAME = os.environ.get('DB_NAME')
DB_USER = os.environ.get('DB_USER')
DB_PASSWORD = os.environ.get('DB_PASSWORD')
DB_PORT = os.environ.get('DB_PORT', '5432')

# Initialize DATABASES variable
DATABASES = None

if DATABASE_URL and HAS_DJ_DATABASE_URL:
    try:
        parsed_db = dj_database_url.parse(DATABASE_URL, conn_max_age=600, conn_health_checks=True)
        # Ensure SSL preferences are set for production
        if 'OPTIONS' not in parsed_db:
            parsed_db['OPTIONS'] = {}
        parsed_db['OPTIONS']['sslmode'] = 'prefer'
        DATABASES = {
            'default': parsed_db
        }
    except Exception:
        DATABASES = None  # Force fallback to manual parsing

if DATABASE_URL and DATABASES is None:
    # Manual parsing of DATABASE_URL if dj_database_url failed
    import re
    match = re.match(r'postgresql://([^:]+):([^@]+)@([^:]+):(\d+)/(.+)', DATABASE_URL)
    if match:
        user, password, host, port, dbname = match.groups()
        DATABASES = {
            'default': {
                'ENGINE': 'django.db.backends.postgresql',
                'NAME': dbname,
                'USER': user,
                'PASSWORD': password,
                'HOST': host,
                'PORT': port,
                'OPTIONS': {
                    'connect_timeout': 10,
                    'sslmode': 'prefer',  # Prefer SSL but don't require it
                },
            }
        }
    else:
        # Try simpler regex patterns
        simple_match = re.match(r'postgres://([^:]+):([^@]+)@([^:]+):(\d+)/(.+)', DATABASE_URL)
        if simple_match:
            user, password, host, port, dbname = simple_match.groups()
            DATABASES = {
                'default': {
                    'ENGINE': 'django.db.backends.postgresql',
                    'NAME': dbname,
                    'USER': user,
                    'PASSWORD': password,
                    'HOST': host,
                    'PORT': port,
                    'OPTIONS': {
                        'connect_timeout': 10,
                        'sslmode': 'prefer',  # Prefer SSL but don't require it
                    },
                }
            }
            
if DATABASES is None:
    # Fallback to individual components  
    if DB_NAME and DB_USER and DB_PASSWORD and DB_HOST:
        DATABASES = {
            'default': {
                'ENGINE': 'django.db.backends.postgresql',
                'NAME': DB_NAME,
                'USER': DB_USER,
                'PASSWORD': DB_PASSWORD,
                'HOST': DB_HOST,
                'PORT': DB_PORT,
                'OPTIONS': {
                    'connect_timeout': 10,
                    'sslmode': 'prefer',  # Prefer SSL but don't require it
                },
            }
        }
    else:
        # No valid database configuration found, use SQLite for local development
        DATABASES = {
            'default': {
                'ENGINE': 'django.db.backends.sqlite3',
                'NAME': BASE_DIR / 'db.sqlite3',
            }
        }

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
# STATIC_URL includes /admin prefix for proper routing through ALB
# ALB forwards /admin/static/* to Django, Django serves from STATIC_ROOT
STATIC_URL = os.getenv('DJANGO_STATIC_URL', '/admin/static/')
STATIC_ROOT = BASE_DIR / 'staticfiles'

# Additional static file handling for WhiteNoise
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Collect static files into subdirectories
STATICFILES_DIRS = []

# WhiteNoise settings for better admin static files serving
WHITENOISE_USE_FINDERS = True
WHITENOISE_AUTOREFRESH = DEBUG

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Port configuration (for gunicorn or development server)
PORT = int(os.environ.get('PORT', 8080))

# Security settings for production
if not DEBUG:
    # CSRF settings
    CSRF_TRUSTED_ORIGINS = [
        'https://application.dev.yourdns.com',
        'https://api.dev.yourdns.com',
        'https://*.yourdns.com',
    ]
    
    # Security middleware settings
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    X_FRAME_OPTIONS = 'DENY'
    
    # Since we're behind ALB, we need these settings
    USE_TZ = True
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
    
    # Session security
    SESSION_COOKIE_SECURE = True
    SESSION_COOKIE_HTTPONLY = True
    CSRF_COOKIE_SECURE = True
    CSRF_COOKIE_HTTPONLY = True
    
else:
    # Development CSRF settings
    CSRF_TRUSTED_ORIGINS = [
        'http://localhost:8080',
        'http://127.0.0.1:8080',
        'https://application.dev.yourdns.com',
        'https://api.dev.yourdns.com',
    ]

# CORS settings
CORS_ALLOW_ALL_ORIGINS = True

# REST Framework
REST_FRAMEWORK = {
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',
    ]
}

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
}
