from django.apps import AppConfig


class AccountsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "accounts"

    def ready(self):
        """
        Import signal handlers when Django starts.

        This ensures profile picture optimization signals are registered
        and will automatically trigger when users upload profile pictures.
        """
        import accounts.signals  # noqa: F401
