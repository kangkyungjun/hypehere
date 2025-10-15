"""
Django settings loader based on DJANGO_SETTINGS_MODULE or DJANGO_ENV.
"""

import os

# Get environment from DJANGO_ENV or default to 'development'
env = os.environ.get('DJANGO_ENV', 'development')

if env == 'production':
    from .production import *
else:
    from .base import *
