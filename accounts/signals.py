"""
Signal handlers for accounts app.

This module handles automatic profile picture optimization when users
upload or update their profile pictures.
"""

from django.db.models.signals import pre_save, post_delete
from django.dispatch import receiver
from django.conf import settings
import os


@receiver(pre_save, sender=settings.AUTH_USER_MODEL)
def optimize_profile_picture_on_save(sender, instance, **kwargs):
    """
    Automatically optimize profile picture before saving User model.

    This signal handler:
    1. Detects new profile picture uploads
    2. Optimizes the image using optimize_profile_image()
    3. Deletes old profile picture when replaced

    Triggered: Before User.save()
    """
    from accounts.utils import optimize_profile_image

    # Check if profile_picture field has a new upload
    if instance.profile_picture and hasattr(instance.profile_picture, 'file'):
        # Only optimize if it's a new upload (not already optimized)
        # Check if file object is an uploaded file (not a FieldFile from database)
        try:
            # If the file is new (not saved yet), optimize it
            if hasattr(instance.profile_picture.file, 'content_type'):
                # This is a new upload via form/API
                instance.profile_picture = optimize_profile_image(
                    instance.profile_picture.file
                )
        except Exception as e:
            # If optimization fails, continue with original file
            print(f"Profile picture optimization skipped: {e}")

    # Delete old profile picture if being replaced
    if instance.pk:  # Only for existing users (not new signups)
        try:
            old_instance = sender.objects.get(pk=instance.pk)

            # Check if profile picture is being changed
            if old_instance.profile_picture and old_instance.profile_picture != instance.profile_picture:
                # Delete old file from storage
                if os.path.isfile(old_instance.profile_picture.path):
                    os.remove(old_instance.profile_picture.path)

        except sender.DoesNotExist:
            # New user being created, no old file to delete
            pass
        except Exception as e:
            # Log error but don't block save operation
            print(f"Error deleting old profile picture: {e}")


@receiver(post_delete, sender=settings.AUTH_USER_MODEL)
def delete_profile_picture_on_user_delete(sender, instance, **kwargs):
    """
    Delete profile picture file when user is deleted.

    This ensures no orphaned files remain in storage after user deletion.

    Triggered: After User.delete()
    """
    try:
        if instance.profile_picture:
            # Check if file exists before trying to delete
            if os.path.isfile(instance.profile_picture.path):
                os.remove(instance.profile_picture.path)
    except Exception as e:
        # Log error but don't raise exception (user is already deleted)
        print(f"Error deleting profile picture on user delete: {e}")
