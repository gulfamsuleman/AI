"""
Status Report Connection API Views

Handles the multi-step workflow for connecting tasks to status reports through task types.
"""

import logging
from typing import Dict, Any
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.utils.decorators import method_decorator
from django.views import View
import json

from ...services.task_service import TaskService
from ...services.ai_service import AIService
from ...services.status_report_connection_service import StatusReportConnectionService
from ...services.session_service import SessionService
from ...services.database_service import DatabaseService
from ...services.error_handler import error_handler

logger = logging.getLogger(__name__)


@method_decorator(csrf_exempt, name='dispatch')
class StatusReportConnectionView(View):
    """
    API endpoint for handling status report connection workflow.
    
    This endpoint handles the multi-step process:
    1. User mentions wanting to connect to a status report
    2. Task is created with InstanceID
    3. System searches for status reports by partial name
    4. User selects specific status report
    5. System shows available task types for that report
    6. User selects task type
    7. System links task instance to task type
    """
    
    def __init__(self):
        self.ai_service = AIService()
        self.task_service = TaskService(self.ai_service)
        self.status_report_connection_service = StatusReportConnectionService()
    
    def post(self, request):
        """
        Handle status report connection requests.
        
        Expected JSON payload:
        {
            "user_message": "User's message",
            "user_name": "Username",
            "main_controller": "Main controller/group",
            "user_timezone": "UTC" (optional, defaults to UTC)
        }
        """
        try:
            # Parse request data
            data = json.loads(request.body)
            user_message = data.get('user_message', '').strip()
            user_name = data.get('user_name', '').strip()
            main_controller = data.get('main_controller', '').strip()
            user_timezone = data.get('user_timezone', 'UTC')
            
            # Validate required fields
            if not user_message:
                return JsonResponse({
                    'error': 'user_message is required'
                }, status=400)
            
            if not user_name:
                return JsonResponse({
                    'error': 'user_name is required'
                }, status=400)
            
            if not main_controller:
                return JsonResponse({
                    'error': 'main_controller is required'
                }, status=400)
            
            logger.info(f"Status report connection request from {user_name}: {user_message}")
            
            # Handle session management
            session = SessionService.manage_task_session(user_name, user_message)
            session_data = session.get('data', {})
            
            # Check if this is a continuation of an existing workflow
            if session_data.get('status_report_connection_pending'):
                # Continue existing workflow
                result = self._handle_workflow_continuation(session_data, user_message, user_name, main_controller, user_timezone)
            else:
                # Check if this is a new connection request
                connection_request = self.status_report_connection_service.detect_connection_request(user_message)
                
                if connection_request['connection_requested']:
                    # Start new connection workflow
                    result = self._handle_new_connection_request(session_data, user_message, user_name, main_controller, user_timezone, connection_request)
                else:
                    # Regular task creation
                    result = self.task_service.create_task(user_message, user_name, main_controller, user_timezone)
            
            # Save session
            SessionService.save_session(session)
            
            return JsonResponse(result)
            
        except json.JSONDecodeError:
            return JsonResponse({
                'error': 'Invalid JSON payload'
            }, status=400)
        except Exception as e:
            logger.error(f"Error in status report connection endpoint: {e}")
            
            # Use error handler for consistent error responses
            context = {
                'user_fullname': data.get('user_name', 'Unknown'),
                'operation': 'status_report_connection'
            }
            tracking_id = error_handler.log_error(e, context, data.get('user_name', 'Unknown'))
            
            return JsonResponse({
                'error': f'Internal server error: {str(e)}',
                'tracking_id': tracking_id
            }, status=500)
    
    def _handle_workflow_continuation(self, session_data: Dict[str, Any], user_message: str, user_name: str, main_controller: str, user_timezone: str) -> Dict[str, Any]:
        """Handle continuation of existing status report connection workflow."""
        try:
            # Continue the connection workflow
            workflow_result = self.status_report_connection_service.handle_connection_workflow(
                session_data, user_message
            )
            
            # Update session data
            session_data.update(workflow_result.get('session_data', {}))
            
            if workflow_result.get('workflow_step') == 'completed':
                # Workflow completed successfully
                connection_result = workflow_result.get('connection_result', {})
                return {
                    'reply': workflow_result.get('message', ''),
                    'workflow_completed': True,
                    'connection_result': connection_result
                }
            elif workflow_result.get('workflow_step') == 'error':
                # Workflow encountered an error
                return {
                    'reply': workflow_result.get('message', ''),
                    'workflow_error': True
                }
            else:
                # Continue workflow
                return {
                    'reply': workflow_result.get('message', ''),
                    'workflow_active': True,
                    'workflow_step': workflow_result.get('workflow_step'),
                    'next_action': self._get_next_action_instruction(workflow_result.get('workflow_step'))
                }
                
        except Exception as e:
            logger.error(f"Error handling workflow continuation: {e}")
            return {
                'reply': f"Sorry, there was an error processing your request: {str(e)}",
                'workflow_error': True
            }
    
    def _handle_new_connection_request(self, session_data: Dict[str, Any], user_message: str, user_name: str, main_controller: str, user_timezone: str, connection_request: Dict[str, Any]) -> Dict[str, Any]:
        """Handle new status report connection request."""
        try:
            # Create the task first
            task_result = self.task_service.create_task(user_message, user_name, main_controller, user_timezone)
            
            if 'error' in task_result:
                return task_result
            
            instance_id = task_result.get('instance_id')
            if not instance_id:
                return {
                    'reply': 'Task created successfully, but no instance ID was returned. Cannot proceed with status report connection.',
                    'workflow_error': True
                }
            
            # Start the connection workflow with the created task
            session_data['status_report_connection_pending'] = True
            session_data['status_report_instance_id'] = instance_id
            session_data['status_report_name'] = connection_request.get('report_name')
            
            # Handle the connection workflow
            workflow_result = self.status_report_connection_service.handle_connection_workflow(
                session_data, user_message, instance_id
            )
            
            # Update session data
            session_data.update(workflow_result.get('session_data', {}))
            
            if workflow_result.get('workflow_step') == 'task_creation_required':
                return {
                    'reply': f"✅ Task created successfully with ID {instance_id}.\n\n{workflow_result.get('message', '')}",
                    'instance_id': instance_id,
                    'workflow_active': True,
                    'workflow_step': 'search_status_reports'
                }
            else:
                return {
                    'reply': f"✅ Task created successfully with ID {instance_id}.\n\n{workflow_result.get('message', '')}",
                    'instance_id': instance_id,
                    'workflow_active': True,
                    'workflow_step': workflow_result.get('workflow_step'),
                    'next_action': self._get_next_action_instruction(workflow_result.get('workflow_step'))
                }
                
        except Exception as e:
            logger.error(f"Error handling new connection request: {e}")
            return {
                'reply': f"Task created successfully, but there was an error starting the status report connection workflow: {str(e)}",
                'workflow_error': True
            }
    
    def _get_next_action_instruction(self, workflow_step: str) -> str:
        """Get instruction for next user action based on workflow step."""
        instructions = {
            'search_status_reports': 'Please provide the name or partial name of the status report you want to connect to.',
            'select_status_report': 'Please select the status report from the list above by number or name.',
            'select_task_type': 'Please select the task type that best describes your task from the list above.',
            'completed': 'Status report connection completed successfully!',
            'error': 'There was an error in the connection process. Please try again.'
        }
        return instructions.get(workflow_step, 'Please provide your next instruction.')


@csrf_exempt
@require_http_methods(["POST"])
def search_status_reports(request):
    """
    Direct endpoint for searching status reports by name.
    
    Expected JSON payload:
    {
        "partial_name": "Partial name to search for"
    }
    """
    try:
        data = json.loads(request.body)
        partial_name = data.get('partial_name', '').strip()
        
        if not partial_name:
            return JsonResponse({
                'error': 'partial_name is required'
            }, status=400)
        
        # Search for status reports
        reports = DatabaseService.search_status_reports_by_name(partial_name)
        
        return JsonResponse({
            'reports': reports,
            'count': len(reports)
        })
        
    except json.JSONDecodeError:
        return JsonResponse({
            'error': 'Invalid JSON payload'
        }, status=400)
    except Exception as e:
        logger.error(f"Error searching status reports: {e}")
        return JsonResponse({
            'error': f'Error searching status reports: {str(e)}'
        }, status=500)


@csrf_exempt
@require_http_methods(["POST"])
def get_task_types_for_report(request):
    """
    Direct endpoint for getting task types for a specific status report.
    
    Expected JSON payload:
    {
        "report_id": 123456
    }
    """
    try:
        data = json.loads(request.body)
        report_id = data.get('report_id')
        
        if not report_id:
            return JsonResponse({
                'error': 'report_id is required'
            }, status=400)
        
        # Get task types for the report
        task_types = DatabaseService.get_task_types_for_status_report(report_id)
        
        return JsonResponse({
            'task_types': task_types,
            'count': len(task_types)
        })
        
    except json.JSONDecodeError:
        return JsonResponse({
            'error': 'Invalid JSON payload'
        }, status=400)
    except Exception as e:
        logger.error(f"Error getting task types for report {report_id}: {e}")
        return JsonResponse({
            'error': f'Error getting task types: {str(e)}'
        }, status=500)


@csrf_exempt
@require_http_methods(["POST"])
def link_task_to_status_report(request):
    """
    Direct endpoint for linking a task instance to a task type.
    
    Expected JSON payload:
    {
        "instance_id": 123456,
        "task_type_id": 789012,
        "priority": 1 (optional, defaults to 1)
    }
    """
    try:
        data = json.loads(request.body)
        instance_id = data.get('instance_id')
        task_type_id = data.get('task_type_id')
        priority = data.get('priority', 1)
        
        if not instance_id or not task_type_id:
            return JsonResponse({
                'error': 'instance_id and task_type_id are required'
            }, status=400)
        
        # Link the task instance to the task type
        return_id = DatabaseService.link_task_instance_to_task_type(instance_id, task_type_id, priority)
        
        if return_id:
            return JsonResponse({
                'success': True,
                'return_id': return_id,
                'message': f'Successfully linked task instance {instance_id} to task type {task_type_id}'
            })
        else:
            return JsonResponse({
                'success': False,
                'error': 'Failed to link task instance to task type'
            }, status=500)
        
    except json.JSONDecodeError:
        return JsonResponse({
            'error': 'Invalid JSON payload'
        }, status=400)
    except Exception as e:
        logger.error(f"Error linking task to status report: {e}")
        return JsonResponse({
            'error': f'Error linking task: {str(e)}'
        }, status=500)
