"""
URL configuration for marketlens_backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""

from django.contrib import admin
from django.urls import path, include
from django.views.generic import TemplateView
from accounts.views import internal_user_profiles_view
from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularSwaggerView,
    SpectacularRedocView,
)

urlpatterns = [
    path("admin/", admin.site.urls),
    # API endpoints
    path("api/accounts/", include("accounts.urls")),
    path("api/community/", include("community.urls")),
    # Internal API (Mac mini)
    path("api/v1/internal/users/profiles/", internal_user_profiles_view, name="internal-user-profiles"),
    # API Documentation
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger-ui"),
    path("api/redoc/", SpectacularRedocView.as_view(url_name="schema"), name="redoc"),
    # Legal pages (privacy policy & terms of service)
    path("marketlens/privacy/", TemplateView.as_view(template_name="privacy.html"), name="privacy-policy"),
    path("marketlens/terms/", TemplateView.as_view(template_name="terms.html"), name="terms-of-service"),
]
