"""
Django management command to create a superuser
"""
import os
from django.core.management.base import BaseCommand
from django.contrib.auth.models import User


class Command(BaseCommand):
    help = 'Create a superuser if it does not exist'

    def handle(self, *args, **options):
        username = os.environ.get('DJANGO_SUPERUSER_USERNAME', 'admin')
        email = os.environ.get('DJANGO_SUPERUSER_EMAIL', 'admin@example.com')
        password = os.environ.get('DJANGO_SUPERUSER_PASSWORD', 'admin')

        self.stdout.write(f"🔍 Checking for superuser: {username}")

        if User.objects.filter(username=username).exists():
            self.stdout.write(
                self.style.SUCCESS(f"✅ Superuser '{username}' already exists")
            )
            return

        try:
            User.objects.create_superuser(
                username=username,
                email=email,
                password=password
            )
            self.stdout.write(
                self.style.SUCCESS(f"✅ Superuser '{username}' created successfully!")
            )
            self.stdout.write(f"   Email: {email}")
            self.stdout.write(f"   Password: {'*' * len(password)}")

        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f"❌ Error creating superuser: {e}")
            )
            raise
