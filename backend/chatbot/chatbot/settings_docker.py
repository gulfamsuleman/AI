"""
Docker-specific Django settings for chatbot project.
This file extends the base settings.py and overrides configurations for Docker deployment.
"""

from .settings import *
import os

# Override settings for Docker environment

# Security
DEBUG = os.getenv('DEBUG', 'False') == 'True'
SECRET_KEY = os.getenv('SECRET_KEY', SECRET_KEY)
ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', '*').split(',')

# Database configuration from environment variables
DATABASES = {
    'default': {
        'ENGINE': os.getenv('DB_ENGINE', 'mssql'),
        'NAME': os.getenv('DB_NAME', 'QTasks'),
        'USER': os.getenv('DB_USER', ''),
        'PASSWORD': os.getenv('DB_PASSWORD', ''),
        'HOST': os.getenv('DB_HOST', 'host.docker.internal'),
        'PORT': os.getenv('DB_PORT', ''),
        'OPTIONS': {
            'driver': 'ODBC Driver 18 for SQL Server',
            'extra_params': 'TrustServerCertificate=yes;Encrypt=no',
        },
    }
}

# Only use trusted_connection if no user/password provided
if not DATABASES['default']['USER'] and not DATABASES['default']['PASSWORD']:
    DATABASES['default']['OPTIONS']['trusted_connection'] = 'yes'

# CORS Configuration
cors_origins = os.getenv('CORS_ALLOWED_ORIGINS', '')
if cors_origins:
    CORS_ALLOWED_ORIGINS = cors_origins.split(',')
    CORS_ALLOW_ALL_ORIGINS = False
else:
    CORS_ALLOW_ALL_ORIGINS = True

# Static files
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

# Logging - ensure logs directory exists
LOGS_DIR = BASE_DIR / 'logs'
LOGS_DIR.mkdir(exist_ok=True)

