"""
Custom decorators for accounts app.

Includes permission decorators for access control.
"""
from functools import wraps
from django.shortcuts import redirect
from django.core.exceptions import PermissionDenied


def prime_or_superuser_required(view_func):
    """
    Decorator that requires the user to be a Prime user or Superuser.

    Usage:
        @prime_or_superuser_required
        def my_view(request):
            ...

    Returns:
        - If user is not authenticated: Redirect to login page
        - If user is not prime/superuser: Raise PermissionDenied (403)
        - Otherwise: Execute the view function
    """
    @wraps(view_func)
    def wrapper(request, *args, **kwargs):
        if not request.user.is_authenticated:
            return redirect('accounts:login')

        if not (request.user.is_prime or request.user.is_superuser):
            raise PermissionDenied("Prime 또는 Superuser 권한이 필요합니다")

        return view_func(request, *args, **kwargs)

    return wrapper
