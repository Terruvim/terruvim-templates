#!/usr/bin/env python
"""Manually load and test Django settings"""

import os
import sys
from pathlib import Path

# Add the current directory to Python path
sys.path.insert(0, '/app')

# Set Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

print("🔍 MANUAL SETTINGS LOAD TEST")
print("=" * 50)

print("\n📍 Environment Variables:")
print(f"DJANGO_SETTINGS_MODULE: {os.environ.get('DJANGO_SETTINGS_MODULE')}")
print(f"DATABASE_URL: {os.environ.get('DATABASE_URL')}")

# Import and check our actual settings module
print("\n📍 Importing settings module directly:")
try:
    # Import directly with a fresh import (no Django setup)
    print("   Step 1: Trying to import config.settings...")
    import config.settings as settings_module
    
    print(f"✅ Config.settings module imported")
    print(f"   Settings module file: {settings_module.__file__}")
    print(f"   Has DATABASES: {hasattr(settings_module, 'DATABASES')}")
    
    # List all attributes to see what's actually available
    print(f"   All attributes: {[attr for attr in dir(settings_module) if not attr.startswith('_')]}")
    
    if hasattr(settings_module, 'DATABASES'):
        databases = settings_module.DATABASES
        print(f"   DATABASES type: {type(databases)}")
        print(f"   DATABASES content: {databases}")
        
        if databases and isinstance(databases, dict):
            default_db = databases.get('default', {})
            if default_db:
                print(f"   Engine: {default_db.get('ENGINE', 'NOT SET')}")
                print(f"   Name: {default_db.get('NAME', 'NOT SET')}")
                print(f"   Host: {default_db.get('HOST', 'NOT SET')}")
    else:
        print("   ❌ DATABASES attribute not found in settings module")
        
    # Check what variables are set
    print(f"   Has SECRET_KEY: {hasattr(settings_module, 'SECRET_KEY')}")
    print(f"   Has DEBUG: {hasattr(settings_module, 'DEBUG')}")
    print(f"   DEBUG value: {getattr(settings_module, 'DEBUG', 'NOT SET')}")
    
    # Try to reload the module to see if it executes print statements
    print("   Step 2: Reloading module...")
    import importlib
    importlib.reload(settings_module)
    print("   ✅ Module reloaded successfully")

except ImportError as e:
    print(f"   ❌ ImportError loading config.settings: {e}")
    import traceback
    traceback.print_exc()
except Exception as e:
    print(f"   ❌ Runtime error in config.settings: {e}")
    print(f"   Error type: {type(e).__name__}")
    import traceback
    traceback.print_exc()

print("\n" + "=" * 50)
