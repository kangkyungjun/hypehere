"""
Middleware for account suspension and ban management
"""


class SuspensionCheckMiddleware:
    """
    Middleware to check and auto-lift expired suspensions
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Check if user is authenticated
        if request.user.is_authenticated:
            # Check if suspension has expired and auto-lift
            if request.user.is_suspended and request.user.suspended_until:
                if not request.user.is_currently_suspended():
                    # Suspension period expired - auto lift
                    request.user.lift_suspension()

        response = self.get_response(request)
        return response
