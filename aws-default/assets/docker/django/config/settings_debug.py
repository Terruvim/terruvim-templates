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
]

MIDDLEWARE = [
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

# Database
# Database configuration with detailed logging
print("🔍 DATABASE CONFIGURATION DEBUG:")
print("===============================")

DATABASE_URL = os.environ.get('DATABASE_URL')
print(f"DATABASE_URL present: {bool(DATABASE_URL)}")
if DATABASE_URL:
    print(f"DATABASE_URL length: {len(DATABASE_URL)}")
    print(f"DATABASE_URL starts with: {DATABASE_URL[:20]}...")

# Individual DB variables
DB_HOST = os.environ.get('DB_HOST')
DB_NAME = os.environ.get('DB_NAME')
DB_USER = os.environ.get('DB_USER')
DB_PASSWORD = os.environ.get('DB_PASSWORD')
DB_PORT = os.environ.get('DB_PORT', '5432')

print(f"DB_HOST: {DB_HOST}")
print(f"DB_NAME: {DB_NAME}")
print(f"DB_USER: {DB_USER}")
print(f"DB_PASSWORD: {'***set***' if DB_PASSWORD else 'not set'}")
print(f"DB_PORT: {DB_PORT}")

# Initialize DATABASES variable
DATABASES = None

if DATABASE_URL and HAS_DJ_DATABASE_URL:
    print("🔧 Trying to parse DATABASE_URL with dj_database_url...")
    try:
        parsed_db = dj_database_url.parse(DATABASE_URL, conn_max_age=600, conn_health_checks=True)
        print(f"✅ Successfully parsed DATABASE_URL with dj_database_url")
        print(f"Engine: {parsed_db.get('ENGINE')}")
        print(f"Name: {parsed_db.get('NAME')}")
        print(f"Host: {parsed_db.get('HOST')}")
        print(f"Port: {parsed_db.get('PORT')}")
        DATABASES = {
            'default': parsed_db
        }
        print("✅ DATABASES assigned from dj_database_url")
    except Exception as e:
        print(f"❌ Failed to parse DATABASE_URL with dj_database_url: {e}")
        DATABASES = None  # Force fallback to manual parsing

if DATABASE_URL and DATABASES is None:
    # Manual parsing of DATABASE_URL if dj_database_url failed
    import re
    print("🔧 Using manual DATABASE_URL parsing...")
    match = re.match(r'postgresql://([^:]+):([^@]+)@([^:]+):(\d+)/(.+)', DATABASE_URL)
    if match:
        user, password, host, port, dbname = match.groups()
        print(f"✅ Successfully parsed DATABASE_URL manually")
        print(f"User: {user}")
        print(f"Host: {host}")
        print(f"Port: {port}")
        print(f"Database: {dbname}")
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
        print("✅ DATABASES assigned from manual parsing")
    else:
        print(f"❌ Invalid DATABASE_URL format: {DATABASE_URL}")
        # Try simpler regex patterns
        simple_match = re.match(r'postgres://([^:]+):([^@]+)@([^:]+):(\d+)/(.+)', DATABASE_URL)
        if simple_match:
            user, password, host, port, dbname = simple_match.groups()
            print(f"✅ Successfully parsed DATABASE_URL with postgres:// scheme")
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
            print("✅ DATABASES assigned from postgres:// parsing")
        else:
            print(f"❌ Could not parse DATABASE_URL with any pattern")
            DATABASES = None  # Force fallback to individual vars
            
if DATABASES is None:
    # Fallback to individual components  
    print("🔧 Using individual database variables...")
    if DB_NAME and DB_USER and DB_PASSWORD and DB_HOST:
        print(f"✅ All required individual DB variables present")
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
        print(f"❌ Missing required individual DB variables")
        missing = []
        if not DB_NAME: missing.append('DB_NAME')
        if not DB_USER: missing.append('DB_USER')
        if not DB_PASSWORD: missing.append('DB_PASSWORD')
        if not DB_HOST: missing.append('DB_HOST')
        print(f"Missing variables: {missing}")
        
        # No valid database configuration found, use SQLite for local development
        print("🔧 Falling back to SQLite")
        DATABASES = {
            'default': {
                'ENGINE': 'django.db.backends.sqlite3',
                'NAME': BASE_DIR / 'db.sqlite3',
            }
        }
        print("✅ DATABASES assigned from SQLite fallback")

# Final verification
print(f"Final DATABASES configuration:")
if DATABASES:
    print(f"Engine: {DATABASES['default'].get('ENGINE')}")
    print(f"Name: {DATABASES['default'].get('NAME')}")
    print(f"Host: {DATABASES['default'].get('HOST', 'N/A')}")
    print(f"DATABASES type: {type(DATABASES)}")
else:
    print("❌ DATABASES is None! This should not happen!")
    # Emergency fallback
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }
    print("✅ Emergency DATABASES fallback assigned")
print("===============================")

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
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Port configuration (for gunicorn or development server)
PORT = int(os.environ.get('PORT', 8080))

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
