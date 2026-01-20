#!/usr/bin/env python
"""Debug Django database configuration"""

import os
import sys
from pathlib import Path

# Add the current directory to Python path
sys.path.insert(0, '/app')

# Set Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

print("🔍 DEBUG: Django Database Configuration")
print("=" * 50)

print("\n📍 Environment Variables:")
print(f"DJANGO_SETTINGS_MODULE: {os.environ.get('DJANGO_SETTINGS_MODULE')}")
print(f"DATABASE_URL: {os.environ.get('DATABASE_URL')}")
print(f"DEBUG: {os.environ.get('DEBUG')}")

# Check if dj_database_url is available
try:
    import dj_database_url
    print(f"✅ dj-database-url available: v{dj_database_url.__version__ if hasattr(dj_database_url, '__version__') else 'unknown'}")
    
    # Test parsing DATABASE_URL
    if os.environ.get('DATABASE_URL'):
        try:
            parsed = dj_database_url.parse(os.environ.get('DATABASE_URL'))
            print(f"✅ DATABASE_URL parsed successfully:")
            print(f"   Engine: {parsed.get('ENGINE')}")
            print(f"   Name: {parsed.get('NAME')}")
            print(f"   Host: {parsed.get('HOST')}")
            print(f"   Port: {parsed.get('PORT')}")
        except Exception as e:
            print(f"❌ Failed to parse DATABASE_URL: {e}")
except ImportError as e:
    print(f"❌ dj-database-url not available: {e}")

print("\n📍 Django Setup:")
try:
    import django
    print(f"✅ Django version: {django.get_version()}")
    
    # Configure Django
    django.setup()
    
    from django.conf import settings
    print(f"✅ Settings loaded successfully")
    print(f"✅ DEBUG: {settings.DEBUG}")
    
    # Check if we can manually import and check our settings module
    print("\n🔍 Direct settings module check:")
    try:
        import config.settings as config_settings
        if hasattr(config_settings, 'DATABASES'):
            databases_from_module = config_settings.DATABASES
            print(f"   DATABASES found in module: {bool(databases_from_module)}")
            if databases_from_module:
                default_db = databases_from_module.get('default', {})
                print(f"   Engine from module: {default_db.get('ENGINE', 'NOT SET')}")
        else:
            print("   DATABASES not found in settings module")
    except Exception as e:
        print(f"   Error importing config.settings: {e}")
    
    # Check database configuration
    print(f"\n📊 Database Configuration (from django.conf.settings):")
    databases = getattr(settings, 'DATABASES', {})
    if databases:
        default_db = databases.get('default', {})
        print(f"   Engine: {default_db.get('ENGINE', 'NOT SET')}")
        print(f"   Name: {default_db.get('NAME', 'NOT SET')}")
        print(f"   Host: {default_db.get('HOST', 'NOT SET')}")
        print(f"   Port: {default_db.get('PORT', 'NOT SET')}")
        print(f"   User: {default_db.get('USER', 'NOT SET')}")
        print(f"   Password: {'***set***' if default_db.get('PASSWORD') else 'NOT SET'}")
    else:
        print("❌ No DATABASES configuration found")
    
    # Test database connection
    print(f"\n🔌 Database Connection Test:")
    try:
        from django.db import connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            result = cursor.fetchone()
            print(f"✅ Database connection successful: {result}")
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        print(f"   Error type: {type(e).__name__}")
        
        # Check if it's a dummy backend issue
        if "dummy" in str(e).lower():
            print("   🚨 This indicates Django is using dummy database backend!")
            print("   🚨 Check DATABASES configuration in settings.py")
    
except Exception as e:
    print(f"❌ Django setup failed: {e}")
    import traceback
    traceback.print_exc()

print("\n" + "=" * 50)
