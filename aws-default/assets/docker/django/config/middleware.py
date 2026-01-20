"""
Middleware to bypass certain checks for health check endpoint
"""
from django.http import HttpResponse


class HealthCheckMiddleware:
    """
    Middleware that bypasses normal Django processing for health checks.
    This ensures ALB target group health checks always get a quick 200 OK response.
    
    ALB sends: /admin/health/
    This middleware intercepts it and returns 200 OK immediately.
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        # Check if this is a health check request
        path = request.path_info
        
        if path == '/admin/health/':
            # Return immediate 200 OK for health checks
            return HttpResponse("OK", status=200, content_type='text/plain')
        
        # Normal request processing
        response = self.get_response(request)
        return response
