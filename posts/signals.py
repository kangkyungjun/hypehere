"""
Signal handlers for post report moderation
"""
from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from .models import PostReport


@receiver(pre_save, sender=PostReport)
def track_old_status(sender, instance, **kwargs):
    """Track old status before save"""
    if instance.pk:
        try:
            instance._old_status = PostReport.objects.get(pk=instance.pk).status
        except PostReport.DoesNotExist:
            instance._old_status = None
    else:
        instance._old_status = None


@receiver(post_save, sender=PostReport)
def update_report_count_on_status_change(sender, instance, created, **kwargs):
    """
    Automatically update user's report_count when report status changes
    Increment: pending/dismissed → reviewing/resolved
    Decrement: reviewing/resolved → dismissed (also handled in admin_actions)
    """
    if not created and hasattr(instance, '_old_status'):
        old_status = instance._old_status
        new_status = instance.status

        # Status changed from non-counted to counted
        if old_status in ('pending', 'dismissed', None) and new_status in ('reviewing', 'resolved'):
            instance.reported_user.increment_report_count()

        # Status changed from counted to non-counted
        elif old_status in ('reviewing', 'resolved') and new_status in ('pending', 'dismissed'):
            instance.reported_user.decrement_report_count()
