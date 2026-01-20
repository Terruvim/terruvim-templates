#!/usr/bin/env python
"""
Custom superuser creation script for Docker deployment
"""
import os
import django
from django.conf import settings

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.contrib.auth.models import User

def create_superuser():
    """Create superuser if it doesn't exist"""
    username = os.environ.get('DJANGO_SUPERUSER_USERNAME', 'admin')
    email = os.environ.get('DJANGO_SUPERUSER_EMAIL', 'admin@example.com')
    password = os.environ.get('DJANGO_SUPERUSER_PASSWORD', 'admin')
    
    print(f"🔍 Checking for superuser: {username}")
    
    try:
        # Check if superuser already exists
        if User.objects.filter(username=username).exists():
            print(f"✅ Superuser '{username}' already exists")
            return
        
        # Create superuser
        User.objects.create_superuser(
            username=username,
            email=email,
            password=password
        )
        print(f"✅ Superuser '{username}' created successfully!")
        print(f"   Email: {email}")
        print(f"   Password: {'*' * len(password)}")
        
    except Exception as e:
        print(f"❌ Error creating superuser: {e}")
        return False
    
    return True

if __name__ == '__main__':
    create_superuser()
