from django.apps import AppConfig


class NotificationsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "notifications"
    verbose_name = "알림"

    def ready(self):
        """앱이 준비되면 시그널 등록"""
        import notifications.signals
