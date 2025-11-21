from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

# REST API Router
router = DefaultRouter()
router.register(r'', views.NotificationViewSet, basename='notification')
router.register(r'settings', views.NotificationSettingsViewSet, basename='notification-settings')

app_name = 'notifications'

urlpatterns = [
    # API endpoints
    path('api/', include(router.urls)),

    # Root notification page (must be last to avoid catching all paths)
    path('', views.notifications_page, name='notifications'),
]
