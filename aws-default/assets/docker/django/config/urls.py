from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse, HttpResponse
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
from django.conf import settings
from django.conf.urls.static import static

@csrf_exempt
def health_check(request):
    """
    Health check endpoint for ALB target groups.
    Returns 200 OK without authentication or CSRF validation.
    Works with FORCE_SCRIPT_NAME='/admin' - ALB sends /admin/health/, Django matches /health/
    """
    if request.method in ['GET', 'HEAD']:
        return HttpResponse("OK", status=200, content_type='text/plain')
    return HttpResponse("Method Not Allowed", status=405)

@require_http_methods(["GET"])
def api_root(request):
    """API root endpoint"""
    return JsonResponse({
        "message": "Django Admin is running",
        "endpoints": {
            "admin": "/admin/",
        }
    })

urlpatterns = [
    path('admin/health/', health_check, name='health-check'),
    path('admin/admin/', admin.site.urls),
    path('admin/', api_root, name='api-root'),
]

# Serve static files - WhiteNoise will handle them
# Static files will be served at /admin/static/* matching STATIC_URL
if settings.STATIC_URL:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
