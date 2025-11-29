from django.utils import timezone
from .models import DailyVisitor, UserActivityLog


class VisitorTrackingMiddleware:
    """
    Middleware to track visitors and active users
    Records IP addresses, page views, and user activity
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Track visitor before processing request
        self.track_visitor(request)

        # Track active user if authenticated
        if request.user.is_authenticated:
            self.track_user_activity(request)

        response = self.get_response(request)
        return response

    def get_client_ip(self, request):
        """
        Get client IP address from request
        Handles X-Forwarded-For header for proxies
        """
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0].strip()
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip

    def track_visitor(self, request):
        """
        Track daily visitor by IP and user
        Increments visit_count for repeated visits
        """
        try:
            ip = self.get_client_ip(request)
            today = timezone.now().date()
            user = request.user if request.user.is_authenticated else None

            visitor, created = DailyVisitor.objects.get_or_create(
                date=today,
                ip_address=ip,
                user=user,
                defaults={'visit_count': 1}
            )

            if not created:
                visitor.visit_count += 1
                visitor.save(update_fields=['visit_count', 'last_visit'])

        except Exception as e:
            # Fail silently to avoid breaking the app
            print(f"[VisitorTrackingMiddleware] Error tracking visitor: {e}")

    def track_user_activity(self, request):
        """
        Track authenticated user's daily activity
        Increments page_views for each request
        """
        try:
            today = timezone.now().date()

            activity, created = UserActivityLog.objects.get_or_create(
                user=request.user,
                date=today,
                defaults={'page_views': 1}
            )

            if not created:
                activity.page_views += 1
                activity.save(update_fields=['page_views', 'last_activity'])

        except Exception as e:
            # Fail silently to avoid breaking the app
            print(f"[VisitorTrackingMiddleware] Error tracking user activity: {e}")
