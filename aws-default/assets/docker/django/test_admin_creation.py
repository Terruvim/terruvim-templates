#!/usr/bin/env python
"""
Test script to create admin user via Django shell
Run this in the Django container to create the admin user manually
"""

# You can run this in the Django container with:
# docker exec -it <container_id> python /app/test_admin_creation.py

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.contrib.auth.models import User

# Create admin user
username = 'admin'
password = 'admin'
email = 'admin@yourdns.com'

if User.objects.filter(username=username).exists():
    print(f"User '{username}' already exists")
    user = User.objects.get(username=username)
else:
    user = User.objects.create_superuser(username, email, password)
    print(f"Created superuser '{username}' with password '{password}'")

print(f"User: {user.username}")
print(f"Email: {user.email}")
print(f"Is superuser: {user.is_superuser}")
print(f"Is staff: {user.is_staff}")
print(f"Is active: {user.is_active}")
