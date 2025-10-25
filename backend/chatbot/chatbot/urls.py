"""
URL configuration for chatbot project.

This configuration maintains backward compatibility with existing routes
while supporting the new modular API structure.
"""

from django.contrib import admin
from django.urls import path

# Import from the refactored API router (maintains backward compatibility)
from .api import ChatView, UserListView, RunStoredProcedureView
from .api.views.status_report_connection import (
    StatusReportConnectionView, 
    search_status_reports, 
    get_task_types_for_report, 
    link_task_to_status_report
)
from django.conf import settings
from django.conf.urls.static import static

# Create aliases for backward compatibility
ChatAPIView = ChatView

from rest_framework.urlpatterns import format_suffix_patterns

# Main URL patterns - using the refactored API views
urlpatterns = [
    path('admin/', admin.site.urls),
    
    # Main chat endpoint - now using modular ChatView via ChatAPIView alias
    path('api/chat/', ChatAPIView.as_view(), name='chat-api'),
    
    # User endpoints - using refactored UserListView
    path('api/users/', UserListView.as_view(), name='user-list-api'),
    
    # Admin endpoints - using refactored RunStoredProcedureView
    path('run-stored-procedure/', RunStoredProcedureView.as_view(), name='run-procedure-api'),
    
    # Status report connection endpoints
    path('api/status-report-connection/', StatusReportConnectionView.as_view(), name='status-report-connection-api'),
    path('api/search-status-reports/', search_status_reports, name='search-status-reports-api'),
    path('api/get-task-types/', get_task_types_for_report, name='get-task-types-api'),
    path('api/link-task-to-status-report/', link_task_to_status_report, name='link-task-to-status-report-api'),
]

urlpatterns = format_suffix_patterns(urlpatterns)

if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)