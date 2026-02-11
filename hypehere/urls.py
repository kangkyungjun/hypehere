"""
URL configuration for hypehere project.

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
from django.conf import settings
from django.conf.urls.static import static
from django.views.i18n import JavaScriptCatalog
from .views import (
    HomeView, ExploreView,
    LearningMatchingView, LearningChatView
)
from chat.views import open_chat_room_view

urlpatterns = [
    path("", HomeView.as_view(), name='home'),
    path("explore/", ExploreView.as_view(), name='explore'),
    path("learning/matching/", LearningMatchingView.as_view(), name='learning_matching'),
    path("learning/chat/", LearningChatView.as_view(), name='learning_chat'),
    path("learning/chat/<int:room_id>/", open_chat_room_view, name='open_chat_room'),
    path("admin/", admin.site.urls),
    path("accounts/", include("accounts.urls")),
    path("api/accounts/", include("accounts.api_urls")),
    path("api/posts/", include("posts.api_urls")),
    path("api/community/posts/", include("posts.api_urls")),  # MarketLens: Community API
    path("api/chat/", include("chat.urls")),  # Chat app: /api/chat/ (API)
    path("messages/", include("chat.urls")),  # Chat app: /messages/ (view)
    path("notifications/", include("notifications.urls")),  # Notifications: /notifications/ (view) + /notifications/api/ (API)
    path("learning/", include("learning.urls")),  # Learning: /learning/api/ (API)
    path("admin-dashboard/", include("analytics.urls")),  # Admin dashboard and analytics
    path("i18n/", include("django.conf.urls.i18n")),  # Language selection
    path("jsi18n/", JavaScriptCatalog.as_view(), name='javascript-catalog'),  # JavaScript i18n
]

# Media files (development only)
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
