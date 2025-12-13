"""
Signal handlers for post report moderation and post image optimization
"""
from django.db.models.signals import post_save, pre_save, post_delete
from django.dispatch import receiver
from django.core.files.storage import default_storage
from .models import PostReport
import os
import logging

logger = logging.getLogger(__name__)


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


# ============================================================
# Post Image Optimization Signals
# ============================================================

import os


@receiver(pre_save, sender='posts.PostImage')
def optimize_post_image_on_save(sender, instance, **kwargs):
    """
    Automatically optimize post image before saving PostImage model.

    This signal handler:
    1. Detects new post image uploads
    2. Optimizes the image using optimize_post_image() (1280px, 90% quality)
    3. Deletes old image when replaced

    Triggered: Before PostImage.save()
    """
    from posts.utils import optimize_post_image

    # Check if image field has a new upload
    if instance.image and hasattr(instance.image, 'file'):
        # Only optimize if it's a new upload (not already optimized)
        # Check if file object is an uploaded file (not a FieldFile from database)
        try:
            # If the file is new (not saved yet), optimize it
            if hasattr(instance.image.file, 'content_type'):
                # This is a new upload via form/API
                instance.image = optimize_post_image(
                    instance.image.file
                )
        except Exception as e:
            # If optimization fails, continue with original file
            print(f"Post image optimization skipped: {e}")

    # Delete old image if being replaced
    if instance.pk:  # Only for existing images (not new uploads)
        try:
            old_instance = sender.objects.get(pk=instance.pk)

            # Check if image is being changed
            if old_instance.image and old_instance.image != instance.image:
                # Delete old file from storage (S3-compatible)
                try:
                    if default_storage.exists(old_instance.image.name):
                        default_storage.delete(old_instance.image.name)
                except Exception as delete_error:
                    logger.error(f"Error deleting old post image: {delete_error}")

        except sender.DoesNotExist:
            # New image being created, no old file to delete
            pass
        except Exception as e:
            # Log error but don't block save operation
            logger.error(f"Error during post image replacement: {e}")


@receiver(post_delete, sender='posts.PostImage')
def delete_post_image_on_delete(sender, instance, **kwargs):
    """
    Delete post image file when PostImage is deleted.

    This ensures no orphaned files remain in storage after image deletion.

    Triggered: After PostImage.delete()
    """
    try:
        if instance.image:
            # Check if file exists before trying to delete (S3-compatible)
            if default_storage.exists(instance.image.name):
                default_storage.delete(instance.image.name)
    except Exception as e:
        # Log error but don't raise exception (image is already deleted from DB)
        logger.error(f"Error deleting post image file: {e}")
