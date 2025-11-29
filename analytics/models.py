from django.db import models
from django.conf import settings
from django.utils import timezone
from django.db.models import Sum, Avg


class DailyVisitor(models.Model):
    """
    Track unique daily visitors by IP and user
    Increments visit_count for each page view
    """
    date = models.DateField(auto_now_add=True, db_index=True, verbose_name='Date')
    ip_address = models.GenericIPAddressField(verbose_name='IP Address')
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='visitor_logs',
        verbose_name='User'
    )
    visit_count = models.IntegerField(default=1, verbose_name='Visit Count')
    first_visit = models.DateTimeField(auto_now_add=True, verbose_name='First Visit')
    last_visit = models.DateTimeField(auto_now=True, verbose_name='Last Visit')

    class Meta:
        unique_together = ['date', 'ip_address', 'user']
        indexes = [
            models.Index(fields=['date', '-last_visit']),
            models.Index(fields=['user', 'date']),
        ]
        ordering = ['-date', '-last_visit']
        verbose_name = 'Daily Visitor'
        verbose_name_plural = 'Daily Visitors'

    def __str__(self):
        user_info = f"{self.user.email}" if self.user else "Anonymous"
        return f"{self.date} - {self.ip_address} - {user_info} ({self.visit_count} visits)"


class UserActivityLog(models.Model):
    """
    Track daily active users (DAU) and their activity metrics
    One record per user per day
    """
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='activity_logs',
        verbose_name='User'
    )
    date = models.DateField(auto_now_add=True, db_index=True, verbose_name='Date')
    last_activity = models.DateTimeField(auto_now=True, verbose_name='Last Activity')

    # Activity metrics
    page_views = models.IntegerField(default=0, verbose_name='Page Views')
    posts_created = models.IntegerField(default=0, verbose_name='Posts Created')
    comments_created = models.IntegerField(default=0, verbose_name='Comments Created')
    messages_sent = models.IntegerField(default=0, verbose_name='Messages Sent')

    class Meta:
        unique_together = ['user', 'date']
        indexes = [
            models.Index(fields=['date', '-last_activity']),
            models.Index(fields=['user', 'date']),
        ]
        ordering = ['-date', '-last_activity']
        verbose_name = 'User Activity Log'
        verbose_name_plural = 'User Activity Logs'

    def __str__(self):
        return f"{self.user.email} - {self.date} ({self.page_views} views)"


class AnonymousChatUsageStats(models.Model):
    """
    Track anonymous chat usage per user per day
    Records conversation starts, messages sent, and duration
    """
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='anonymous_chat_stats',
        verbose_name='User'
    )
    date = models.DateField(auto_now_add=True, db_index=True, verbose_name='Date')

    # Usage metrics
    conversations_started = models.IntegerField(default=0, verbose_name='Conversations Started')
    messages_sent = models.IntegerField(default=0, verbose_name='Messages Sent')
    total_duration_seconds = models.IntegerField(default=0, verbose_name='Total Duration (seconds)')

    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Created At')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='Updated At')

    class Meta:
        unique_together = ['user', 'date']
        indexes = [
            models.Index(fields=['date', '-updated_at']),
            models.Index(fields=['user', 'date']),
        ]
        ordering = ['-date', '-updated_at']
        verbose_name = 'Anonymous Chat Usage Stat'
        verbose_name_plural = 'Anonymous Chat Usage Stats'

    def __str__(self):
        return f"{self.user.email} - {self.date} ({self.conversations_started} chats, {self.messages_sent} msgs)"


class DailySummary(models.Model):
    """
    Aggregated daily statistics for faster dashboard loading
    Generated via management command (cron job)
    """
    date = models.DateField(unique=True, db_index=True, verbose_name='Date')

    # Visitor stats
    unique_visitors = models.IntegerField(default=0, verbose_name='Unique Visitors')
    total_page_views = models.IntegerField(default=0, verbose_name='Total Page Views')

    # User stats
    new_users = models.IntegerField(default=0, verbose_name='New Users')
    active_users = models.IntegerField(default=0, verbose_name='Active Users')

    # Content stats
    posts_created = models.IntegerField(default=0, verbose_name='Posts Created')
    comments_created = models.IntegerField(default=0, verbose_name='Comments Created')

    # Chat stats
    anonymous_chat_users = models.IntegerField(default=0, verbose_name='Anonymous Chat Users')
    anonymous_chat_conversations = models.IntegerField(default=0, verbose_name='Anonymous Chat Conversations')
    anonymous_chat_messages = models.IntegerField(default=0, verbose_name='Anonymous Chat Messages')

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Created At')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='Updated At')

    class Meta:
        ordering = ['-date']
        verbose_name = 'Daily Summary'
        verbose_name_plural = 'Daily Summaries'
        indexes = [
            models.Index(fields=['-date']),
        ]

    def __str__(self):
        return f"Summary for {self.date} ({self.unique_visitors} visitors, {self.new_users} new users)"
