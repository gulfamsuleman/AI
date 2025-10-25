"""
Status Report Connection Service

Handles the multi-step workflow for connecting tasks to status reports through task types.
This service manages the session state and coordinates the connection process.
"""

import logging
import re
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime

from .database_service import DatabaseService
from ..config.queries import (
    FIND_STATUS_REPORTS_BY_NAME,
    GET_TASK_TYPES_FOR_REPORT,
    ADD_INSTANCE_TASK_TYPE_PROCEDURE
)

logger = logging.getLogger(__name__)


class StatusReportConnectionService:
    """
    Service to handle the status report connection workflow.
    
    Workflow:
    1. User mentions wanting to connect to a status report
    2. Task is created with InstanceID
    3. System searches for status reports by partial name
    4. User selects specific status report
    5. System shows available task types for that report
    6. User selects task type
    7. System links task instance to task type
    """
    
    # Session keys for storing connection state
    SESSION_KEY_PENDING_CONNECTION = "status_report_connection_pending"
    SESSION_KEY_INSTANCE_ID = "status_report_instance_id"
    SESSION_KEY_REPORT_NAME = "status_report_name"
    SESSION_KEY_REPORT_ID = "status_report_id"
    SESSION_KEY_TASK_TYPE_ID = "status_report_task_type_id"
    
    def __init__(self):
        self.logger = logger
    
    def detect_connection_request(self, user_message: str) -> Dict[str, Any]:
        """
        Detect if user wants to connect a task to a status report.
        
        Args:
            user_message: User's message
            
        Returns:
            Dictionary with connection request details or None if not detected
        """
        logger.info(f"STATUS REPORT CONNECTION: Detecting connection request in: '{user_message[:100]}...'")
        message_lower = user_message.lower()
        
        # Patterns that indicate status report connection request
        connection_patterns = [
            r'connect.*status\s+report',
            r'link.*status\s+report',
            r'link\s+to\s+status\s+report',
            r'add.*status\s+report',
            r'associate.*status\s+report',
            r'include.*status\s+report',
            r'status\s+report.*connection',
            r'status\s+report.*link',
            r'link.*report',
            r'connect.*report',
            r'add.*report'
        ]
        
        for pattern in connection_patterns:
            if re.search(pattern, message_lower):
                # Extract the status report name if mentioned
                name_patterns = [
                    r'status\s+report\s+["\']([^"\']+)["\']',
                    r'status\s+report\s+named\s+["\']([^"\']+)["\']',
                    r'status\s+report\s+called\s+["\']([^"\']+)["\']',
                    r'["\']([^"\']+)["\']\s*status\s+report',
                    r'link.*status\s+report\s+["\']([^"\']+)["\']',
                    r'link\s+to\s+status\s+report\s+["\']([^"\']+)["\']',
                    r'connect.*status\s+report\s+["\']([^"\']+)["\']',
                    r'add.*status\s+report\s+["\']([^"\']+)["\']',
                    r'link.*report\s+["\']([^"\']+)["\']',
                    r'connect.*report\s+["\']([^"\']+)["\']'
                ]
                
                report_name = None
                for name_pattern in name_patterns:
                    match = re.search(name_pattern, user_message, re.IGNORECASE)
                    if match:
                        report_name = match.group(1).strip()
                        break
                
                logger.info(f"STATUS REPORT CONNECTION: Pattern detected! Report name: '{report_name}'")
                return {
                    'connection_requested': True,
                    'report_name': report_name,
                    'message': user_message
                }
        
        logger.info(f"STATUS REPORT CONNECTION: No connection pattern detected")
        return {'connection_requested': False}
    
    def search_status_reports(self, partial_name: str) -> List[Dict[str, Any]]:
        """
        Search for status reports by partial name.
        
        Args:
            partial_name: Partial name to search for
            
        Returns:
            List of matching status reports with ID and Name
        """
        try:
            # Add wildcards for LIKE search
            search_pattern = f"%{partial_name}%"
            
            with DatabaseService.get_cursor() as cursor:
                cursor.execute(FIND_STATUS_REPORTS_BY_NAME, [search_pattern])
                results = cursor.fetchall()
                
                reports = []
                for row in results:
                    reports.append({
                        'id': row[0],
                        'name': row[1]
                    })
                
                self.logger.info(f"Found {len(reports)} status reports matching '{partial_name}'")
                return reports
                
        except Exception as e:
            self.logger.error(f"Error searching status reports: {e}")
            return []
    
    def get_task_types_for_report(self, report_id: int) -> List[Dict[str, Any]]:
        """
        Get available task types for a specific status report.
        
        Args:
            report_id: ID of the status report
            
        Returns:
            List of task types with ID and Description
        """
        try:
            with DatabaseService.get_cursor() as cursor:
                cursor.execute(GET_TASK_TYPES_FOR_REPORT, [report_id])
                results = cursor.fetchall()
                
                task_types = []
                for row in results:
                    task_types.append({
                        'id': row[0],
                        'description': row[1]
                    })
                
                self.logger.info(f"Found {len(task_types)} task types for report ID {report_id}")
                return task_types
                
        except Exception as e:
            self.logger.error(f"Error getting task types for report {report_id}: {e}")
            return []
    
    def link_instance_to_task_type(self, instance_id: int, task_type_id: int, priority: int = 1) -> Optional[int]:
        """
        Link a task instance to a specific task type.
        
        Args:
            instance_id: ID of the task instance
            task_type_id: ID of the task type
            priority: Priority level (default: 1)
            
        Returns:
            Return ID from the stored procedure, or None if failed
        """
        try:
            with DatabaseService.get_cursor() as cursor:
                self.logger.info(f"Executing stored procedure to link instance {instance_id} to task type {task_type_id}")
                cursor.execute(ADD_INSTANCE_TASK_TYPE_PROCEDURE, [
                    instance_id,
                    task_type_id,
                    priority
                ])
                self.logger.info("Stored procedure executed successfully")
                
                # The stored procedure should return a result, but if it doesn't, we'll assume success
                try:
                    if cursor.description is not None:
                        result = cursor.fetchone()
                        if result and result[0] is not None:
                            return_id = result[0]
                            self.logger.info(f"Successfully linked instance {instance_id} to task type {task_type_id}, Return ID: {return_id}")
                            return return_id
                    else:
                        self.logger.info(f"Stored procedure executed successfully for instance {instance_id} and task type {task_type_id} (no result set)")
                        return 1  # Return a success indicator
                except Exception as fetch_error:
                    self.logger.warning(f"Could not fetch result from stored procedure: {fetch_error}")
                    self.logger.info(f"Assuming success for instance {instance_id} and task type {task_type_id}")
                    return 1  # Return a success indicator
                    
        except Exception as e:
            self.logger.error(f"Error linking instance {instance_id} to task type {task_type_id}: {e}")
            return None
    
    def format_status_reports_for_user(self, reports: List[Dict[str, Any]]) -> str:
        """
        Format status reports list for user display.
        
        Args:
            reports: List of status report dictionaries
            
        Returns:
            Formatted string for user display
        """
        if not reports:
            return "No status reports found matching your search."
        
        formatted_list = "### Please select the status report you want to connect to:\n\n"
        for i, report in enumerate(reports, 1):
            formatted_list += f"{i}. **{report['name']}** (ID: `{report['id']}`)\n"
        
        formatted_list += f"\nReply with the number (1-{len(reports)}) or the exact name."
        return formatted_list
    
    def format_task_types_for_user(self, task_types: List[Dict[str, Any]]) -> str:
        """
        Format task types list for user display.
        
        Args:
            task_types: List of task type dictionaries
            
        Returns:
            Formatted string for user display
        """
        if not task_types:
            return "No task types found for this status report."
        
        formatted_list = "### Please select the task type that best describes your task:\n\n"
        for i, task_type in enumerate(task_types, 1):
            formatted_list += f"{i}. **{task_type['description']}** (ID: `{task_type['id']}`)\n"
        
        formatted_list += f"\nReply with the number (1-{len(task_types)}) or the exact description."
        return formatted_list
    
    def parse_user_selection(self, user_input: str, options: List[Dict[str, Any]], key_field: str = 'name') -> Optional[Dict[str, Any]]:
        """
        Parse user selection from a list of options.
        
        Args:
            user_input: User's input (number, name, or partial name)
            options: List of option dictionaries
            key_field: Field to use for name matching (default: 'name')
            
        Returns:
            Selected option dictionary or None if not found
        """
        user_input = user_input.strip()
        
        # Check if input is a number
        try:
            selection_num = int(user_input)
            if 1 <= selection_num <= len(options):
                return options[selection_num - 1]
        except ValueError:
            pass
        
        # Check for exact match
        for option in options:
            if option[key_field].lower() == user_input.lower():
                return option
        
        # Check for partial match
        for option in options:
            if user_input.lower() in option[key_field].lower():
                return option
        
        return None
    
    def handle_connection_workflow(self, session_data: Dict[str, Any], user_message: str, instance_id: Optional[int] = None) -> Dict[str, Any]:
        """
        Handle the complete status report connection workflow.
        
        Args:
            session_data: Current session data
            user_message: User's current message
            instance_id: Task instance ID (if available)
            
        Returns:
            Dictionary with workflow response and next steps
        """
        logger.info(f"STATUS REPORT CONNECTION: handle_connection_workflow called with instance_id: {instance_id}")
        logger.info(f"STATUS REPORT CONNECTION: session_data: {session_data}")
        
        # Check if this is the start of a connection request
        connection_request = self.detect_connection_request(user_message)
        logger.info(f"STATUS REPORT CONNECTION: connection_request result: {connection_request}")
        
        if connection_request['connection_requested']:
            # Start new connection workflow
            if instance_id:
                # Task already created, start with status report search
                session_data[self.SESSION_KEY_PENDING_CONNECTION] = True
                session_data[self.SESSION_KEY_INSTANCE_ID] = instance_id
                session_data[self.SESSION_KEY_REPORT_NAME] = connection_request.get('report_name')
                
                if connection_request.get('report_name'):
                    # Search for status reports with the provided name
                    reports = self.search_status_reports(connection_request['report_name'])
                    if reports:
                        # Store reports in session data for selection handling
                        session_data['reports'] = reports
                        return {
                            'workflow_step': 'select_status_report',
                            'message': self.format_status_reports_for_user(reports),
                            'reports': reports,
                            'session_data': session_data
                        }
                    else:
                        return {
                            'workflow_step': 'search_status_reports',
                            'message': f"No status reports found matching '{connection_request['report_name']}'. Please provide a different name or partial name to search for.",
                            'session_data': session_data
                        }
                else:
                    return {
                        'workflow_step': 'search_status_reports',
                        'message': "I understand you want to connect this task to a status report. Please provide the name or partial name of the status report you want to connect to.",
                        'session_data': session_data
                    }
            else:
                # Task not created yet, store the request for later
                return {
                    'workflow_step': 'task_creation_required',
                    'message': "I understand you want to connect this task to a status report. Please first create the task, and then I'll help you connect it to the appropriate status report.",
                    'session_data': session_data,
                    'connection_pending': True
                }
        
        # Check if we're in the middle of a connection workflow
        if session_data.get(self.SESSION_KEY_PENDING_CONNECTION):
            return self._continue_connection_workflow(session_data, user_message)
        
        return {
            'workflow_step': 'none',
            'message': None,
            'session_data': session_data
        }
    
    def _continue_connection_workflow(self, session_data: Dict[str, Any], user_message: str) -> Dict[str, Any]:
        """
        Continue the connection workflow based on current step.
        
        Args:
            session_data: Current session data
            user_message: User's current message
            
        Returns:
            Dictionary with workflow response and next steps
        """
        # Check current workflow step
        if not session_data.get(self.SESSION_KEY_REPORT_ID):
            # Step 1: User is selecting a status report
            return self._handle_status_report_selection(session_data, user_message)
        elif not session_data.get(self.SESSION_KEY_TASK_TYPE_ID):
            # Step 2: User is selecting a task type
            return self._handle_task_type_selection(session_data, user_message)
        else:
            # All selections made, perform the connection
            return self._perform_connection(session_data, user_message)
    
    def _handle_status_report_selection(self, session_data: Dict[str, Any], user_message: str) -> Dict[str, Any]:
        """Handle status report selection step."""
        # Check if user is selecting from a previous list
        if 'reports' in session_data:
            reports = session_data['reports']
            # Try to parse as number (1-10)
            try:
                selection_num = int(user_message.strip())
                if 1 <= selection_num <= len(reports):
                    selected_report = reports[selection_num - 1]
                    session_data[self.SESSION_KEY_REPORT_ID] = selected_report['id']
                    session_data[self.SESSION_KEY_REPORT_NAME] = selected_report['name']
                    
                    # Get task types for this report
                    task_types = self.get_task_types_for_report(selected_report['id'])
                    
                    if task_types:
                        return {
                            'workflow_step': 'select_task_type',
                            'message': f"Selected status report: '{selected_report['name']}'\n\n" + self.format_task_types_for_user(task_types),
                            'task_types': task_types,
                            'session_data': session_data
                        }
                    else:
                        return {
                            'workflow_step': 'error',
                            'message': f"Found status report '{selected_report['name']}' but no task types are available for this report.",
                            'session_data': session_data
                        }
            except ValueError:
                pass  # Not a number, continue with search
        
        # Search for status reports
        reports = self.search_status_reports(user_message)
        
        if not reports:
            return {
                'workflow_step': 'search_status_reports',
                'message': f"No status reports found matching '{user_message}'. Please try a different name or provide more details.",
                'session_data': session_data
            }
        
        # If only one report found, select it automatically
        if len(reports) == 1:
            session_data[self.SESSION_KEY_REPORT_ID] = reports[0]['id']
            session_data[self.SESSION_KEY_REPORT_NAME] = reports[0]['name']
            
            # Get task types for this report
            task_types = self.get_task_types_for_report(reports[0]['id'])
            
            if task_types:
                return {
                    'workflow_step': 'select_task_type',
                    'message': f"Found status report: '{reports[0]['name']}'\n\n" + self.format_task_types_for_user(task_types),
                    'task_types': task_types,
                    'session_data': session_data
                }
            else:
                return {
                    'workflow_step': 'error',
                    'message': f"Found status report '{reports[0]['name']}' but no task types are available for this report.",
                    'session_data': session_data
                }
        
        # Multiple reports found, let user choose and store in session
        session_data['reports'] = reports
        return {
            'workflow_step': 'select_status_report',
            'message': self.format_status_reports_for_user(reports),
            'reports': reports,
            'session_data': session_data
        }
    
    def _handle_task_type_selection(self, session_data: Dict[str, Any], user_message: str) -> Dict[str, Any]:
        """Handle task type selection step."""
        # Get task types for the selected report
        report_id = session_data.get(self.SESSION_KEY_REPORT_ID)
        task_types = self.get_task_types_for_report(report_id)
        
        if not task_types:
            return {
                'workflow_step': 'error',
                'message': "No task types found for the selected status report.",
                'session_data': session_data
            }
        
        # Parse user selection
        selected_task_type = self.parse_user_selection(user_message, task_types, 'description')
        
        if selected_task_type:
            session_data[self.SESSION_KEY_TASK_TYPE_ID] = selected_task_type['id']
            return self._perform_connection(session_data, user_message)
        else:
            return {
                'workflow_step': 'select_task_type',
                'message': f"Please select a valid task type from the list:\n\n{self.format_task_types_for_user(task_types)}",
                'task_types': task_types,
                'session_data': session_data
            }
    
    def _perform_connection(self, session_data: Dict[str, Any], user_message: str) -> Dict[str, Any]:
        """Perform the final connection."""
        instance_id = session_data.get(self.SESSION_KEY_INSTANCE_ID)
        task_type_id = session_data.get(self.SESSION_KEY_TASK_TYPE_ID)
        report_name = session_data.get(self.SESSION_KEY_REPORT_NAME)
        
        if not instance_id or not task_type_id:
            return {
                'workflow_step': 'error',
                'message': "Missing required information for connection.",
                'session_data': session_data
            }
        
        # Perform the connection
        return_id = self.link_instance_to_task_type(instance_id, task_type_id)
        
        logger.info(f"STATUS REPORT CONNECTION: link_instance_to_task_type returned: {return_id} (type: {type(return_id)})")
        
        if return_id is not None:
            # Clear session data
            session_data.pop(self.SESSION_KEY_PENDING_CONNECTION, None)
            session_data.pop(self.SESSION_KEY_INSTANCE_ID, None)
            session_data.pop(self.SESSION_KEY_REPORT_NAME, None)
            session_data.pop(self.SESSION_KEY_REPORT_ID, None)
            session_data.pop(self.SESSION_KEY_TASK_TYPE_ID, None)
            
            return {
                'workflow_step': 'completed',
                'message': f"🎉 Task created successfully and connected to status report '{report_name}'!\n\n✅ Task Instance ID: {instance_id}\n✅ Status Report: {report_name}\n✅ Task Type ID: {task_type_id}\n\nYour task is now linked to the status report and ready for tracking.",
                'session_data': session_data,
                'connection_result': {
                    'instance_id': instance_id,
                    'task_type_id': task_type_id,
                    'report_name': report_name,
                    'return_id': return_id
                }
            }
        else:
            return {
                'workflow_step': 'error',
                'message': "Failed to connect the task to the status report. Please try again.",
                'session_data': session_data
            }
