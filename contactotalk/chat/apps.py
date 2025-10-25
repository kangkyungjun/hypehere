from django.apps import AppConfig


class ChatConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "chat"

    def ready(self):
        """앱 초기화 시 signal 등록"""
        import chat.signals  # noqa: F401
