"""
Task Service Module

This module provides centralized task creation orchestration for the chatbot application,
coordinating between AI, database, and validation services to handle business logic for task creation.
"""

import datetime
import re
import time
import logging
import json as pyjson
from typing import Dict, Any, List, Tuple, Optional

from .datetime_service import DateTimeService
from .ai_service import AIService  
from .database_service import DatabaseService
from .parameter_extractor import ParameterExtractor
from .validation_service import ValidationService
from .session_service import SessionService
from .name_resolution_service import NameResolutionService
from .status_report_connection_service import StatusReportConnectionService
from .error_handler import error_handler, TaskCreationError, ValidationError, DatabaseError

# Import the schedule parser
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from schedule_parser import ScheduleParser

logger = logging.getLogger(__name__)


# TaskCreationError is now imported from error_handler


class TaskService:
    """
    Service class for handling task creation orchestration.
    Coordinates between AI, database, and validation services to handle
    all business logic related to task creation.
    """
    
    def __init__(self, ai_service: AIService):
        """
        Initialize the task service with required dependencies.
        
        Args:
            ai_service: AI service instance for processing task extraction
        """
        self.ai_service = ai_service
        self.schedule_parser = ScheduleParser()
        self.parameter_extractor = ParameterExtractor(self.schedule_parser)
        self.status_report_connection_service = StatusReportConnectionService()
        
    def create_task(self, user_message: str, user_name: str, main_controller: str, 
                   user_timezone: str = 'UTC', debug_mode: bool = False) -> Dict[str, Any]:
        """
        Main orchestration method for task creation.
        
        Args:
            user_message: User's task creation message
            user_name: Username making the request
            main_controller: Main controller/group for the task
            user_timezone: User's timezone
            debug_mode: Enable debug mode for testing
            
        Returns:
            Dictionary containing the response data
            
        Raises:
            TaskCreationError: If task creation fails
        """
        logger.info(f"STATUS REPORT CONNECTION: create_task called with message: '{user_message[:100]}...'")
        print(f"DEBUG: create_task called with message: '{user_message[:100]}...'")
        request_start_time = time.time()
        
        # Get or reset session appropriately for this message
        session = SessionService.manage_task_session(user_name, user_message)
        session_data = session.parameters.get('data', {})
        
        logger.info(f"STATUS REPORT CONNECTION: Checking for pending workflow. Session data: {session_data}")
        
        # Early guard: detect ordinal monthly schedules and ask for clarification
        if self._contains_ordinal_monthly_schedule(user_message):
            clarification = (
                "I can’t schedule ordinal monthly patterns like 'first Monday of the month' or 'last Friday of every month' yet. "
                "Please provide a specific non-ordinal schedule (e.g., 'every Monday', '15th of each month', or a specific date)."
            )
            return { 'reply': clarification }

        # Confirmation workflow: if we have pending task parameters and user confirms/cancels
        pending_params = session_data.get('pending_task_params') if isinstance(session_data, dict) else None
        if pending_params:
            if self._is_affirmative(user_message):
                logger.info("CONFIRMATION: Positive confirmation received. Proceeding to create pending task.")
                # Use pending parameters directly
                params = pending_params
                # Clear pending state
                session_data.pop('pending_task_params', None)
                session.parameters['data'] = session_data
                SessionService.save_session(session)
                
                # Continue normal pipeline from date processing
                try:
                    # Normalize weekly encoding if needed
                    params = self._normalize_weekly_encoding(params)
                    
                    # Apply defaults and processing
                    params = self._apply_smart_defaults(params, main_controller)
                    
                    # Prepare pre_extracted with original message for business rules
                    pre_extracted_with_message = {'_original_message': user_message}
                    params = self._apply_business_rules(params, pre_extracted_with_message, user_timezone)
                    
                    params = self._process_dates_and_times(params, user_timezone)
                    params = self._set_automatic_parameters(params, user_timezone)
                    params = self._convert_parameter_types(params)
                    params['MainController'] = SessionService.get_user_fullname(user_name) if hasattr(SessionService, 'get_user_fullname') else main_controller
                    instance_id = self._create_single_task(params, params.get('MainController', main_controller), debug_mode)
                    SessionService.delete_session(session)
                    return self._build_success_response(params, instance_id, main_controller)
                except Exception:
                    # On any error, clear pending and re-raise
                    session_data.pop('pending_task_params', None)
                    session.parameters['data'] = session_data
                    SessionService.save_session(session)
                    raise
            elif self._is_negative(user_message):
                logger.info("CONFIRMATION: Negative confirmation received. Clearing pending and asking for new details.")
                session_data.pop('pending_task_params', None)
                session.parameters['data'] = session_data
                SessionService.save_session(session)
                return { 'reply': "Okay, I won't create that. Please provide the task details again when you're ready." }
        
        # Check if this is a new connection request first
        connection_request = self.status_report_connection_service.detect_connection_request(user_message)
        
        # If there's a pending status report connection workflow AND no new connection request, continue the workflow
        if session_data.get('status_report_connection_pending') and not connection_request['connection_requested']:
            logger.info(f"STATUS REPORT CONNECTION: Found pending workflow, continuing workflow")
            workflow_result = self.status_report_connection_service._continue_connection_workflow(session_data, user_message)
            
            # Update session data
            session.parameters['data'] = session_data
            
            if workflow_result.get('workflow_step') != 'none':
                SessionService.save_session(session)
                return {
                    'workflow_active': True,
                    'reply': workflow_result.get('message', ''),
                    'workflow_step': workflow_result.get('workflow_step'),
                    'session_data': session_data
                }
            else:
                # Workflow completed, clean up session
                SessionService.delete_session(session)
        
        # If user provided a JSON payload of task parameters, store for confirmation
        parsed_inline_params = self._try_parse_inline_json(user_message)
        if parsed_inline_params:
            logger.info("CONFIRMATION: Parsed inline task parameters. Storing for confirmation.")
            # Normalize weekly encoding if needed
            parsed_inline_params = self._normalize_weekly_encoding(parsed_inline_params)
            session_data['pending_task_params'] = parsed_inline_params
            session.parameters['data'] = session_data
            SessionService.save_session(session)
            confirmation_text = self._build_confirmation_message(parsed_inline_params)
            return { 'reply': confirmation_text }

        # Validate input message and group
        try:
            ValidationService.validate_message_length(user_message)
            ValidationService.validate_content_safety(user_message)
            group_exists, user_fullname, similar_groups = ValidationService.validate_group(main_controller)
        except ValidationError as e:
            raise TaskCreationError(str(e), 'VALIDATION_FAILED')
        
        # Session already created above for workflow continuation check
        
        try:
            # Get parameters and history from session
            params = SessionService.get_session_parameters(session)
            history = SessionService.get_session_history(session)
            
            # Add current user message to history BEFORE calling AI service
            SessionService.add_to_session_history(session, "user", user_message)
            # Get updated history that includes the current message
            history = SessionService.get_session_history(session)
            
            # Ensure history has at least one message for Groq API
            if not history:
                history = [{"role": "user", "content": user_message}]
            
            # Get current date in user's timezone for context
            current_date = DateTimeService.get_current_date_in_timezone(user_timezone)
            
            # Check for conditional logic patterns and reject
            if self.ai_service.check_conditional_logic(user_message):
                raise TaskCreationError('Conditional logic is not supported')
            
            # Pre-process the message to extract obvious patterns
            pre_extracted = self.parameter_extractor.pre_extract_parameters(user_message, main_controller, current_date)
            
            # Process task extraction using AI service
            logger.debug(f"Pre-extracted parameters: {pre_extracted}")
            logger.debug(f"History length: {len(history)}")
            success, llm_json, content = self.ai_service.process_task_extraction(
                user_message, main_controller, current_date, pre_extracted, history, debug_mode
            )
            
            if not success:
                # Handle AI service errors or non-JSON responses with a clarifying counter-question
                SessionService.save_session(session)
                return {'reply': self._build_counter_question(user_message, missing_fields=['Task name'])}
            
            # Merge new parameters from LLM with those already stored
            params.update(llm_json)
            SessionService.update_session_parameters(session, params)
            SessionService.save_session(session)

            # Apply smart defaults for Assignees and DueDate BEFORE checking for missing fields
            # This allows users to create tasks with just a task name
            if not params.get('Assignees'):
                # Default assignee to the user creating the task
                params['Assignees'] = user_fullname
                logger.debug(f"Applied default assignee: {user_fullname}")
            
            if not params.get('DueDate') or params['DueDate'] in [None, '']:
                # Default due date to tomorrow
                current_date = DateTimeService.get_current_date_in_timezone(user_timezone)
                tomorrow = current_date + datetime.timedelta(days=1)
                params['DueDate'] = tomorrow.isoformat()
                logger.debug(f"Applied default due date: {params['DueDate']}")
            
            if not params.get('DueTime') or params['DueTime'] in [None, '']:
                # Default due time to 7 PM (19:00)
                params['DueTime'] = '19:00'
                logger.debug(f"Applied default due time: 19:00")

            # Nonsense/low-signal fallback: if key fields are missing, ask a targeted question
            missing: List[str] = []
            if not params.get('TaskName'):
                missing.append('Task name')
            # Note: Assignees and DueDate are now automatically defaulted above, so we don't check for them
            # Consider due date missing only if it's explicitly set to empty after our defaults
            # (this should rarely happen now)
            if missing:
                return {'reply': self._build_counter_question(user_message, missing_fields=missing)}
            
            # Apply smart defaults and business rules
            params = self._apply_smart_defaults(params, main_controller)
            
            # Apply fallback extraction if needed
            params = self._apply_fallback_extraction(params, user_message, main_controller)
            
            # Apply business rule transformations
            # Ensure original message is available to business rules
            try:
                if isinstance(pre_extracted, dict):
                    pre_extracted['_original_message'] = user_message
                    logger.debug(f"MAIN-WORKFLOW: Added original message to pre_extracted: {user_message[:50]}...")
                else:
                    logger.debug(f"MAIN-WORKFLOW: pre_extracted is not dict: {type(pre_extracted)}")
            except Exception as e:
                logger.error(f"MAIN-WORKFLOW: Error adding original message: {e}")
                pass
            
            logger.debug(f"MAIN-WORKFLOW: About to call _apply_business_rules with IsRecurring={params.get('IsRecurring')}")
            params = self._apply_business_rules(params, pre_extracted, user_timezone)
            logger.debug(f"MAIN-WORKFLOW: After _apply_business_rules, FinalDueDate={params.get('FinalDueDate')}")
            
            # Check for batch task creation
            if pre_extracted.get('_batch_tasks'):
                return self._handle_batch_task_creation(
                    pre_extracted['_batch_tasks'], params, user_fullname, user_timezone, debug_mode
                )
            
            # Ensure 'me' maps to the sender in assignees even if LLM extracted others
            try:
                if re.search(r'\bme\b', user_message.lower()) and params.get('Assignees'):
                    current_assignees = [a.strip() for a in params['Assignees'].split(',') if a and a.strip()]
                    if user_fullname not in current_assignees:
                        params['Assignees'] = ','.join([user_fullname] + current_assignees)
                        logger.debug(f"Including sender due to 'me' in message → Assignees='{params['Assignees']}'")
            except Exception:
                pass

            # Validate required fields and other parameters
            try:
                ValidationService.validate_required_fields(params)
                if 'TaskName' in params:
                    ValidationService.validate_task_name(params['TaskName'])
                # Note: Assignee validation is now handled by NameResolutionService
                if params.get('IsRecurring', 0) == 1:
                    ValidationService.validate_recurring_parameters(params)
                if 'Items' in params and params['Items']:
                    ValidationService.validate_checklist_items(params['Items'])
            except ValidationError as e:
                raise TaskCreationError(str(e), 'VALIDATION_FAILED')
            
            # Validate and resolve user names using fuzzy matching (including assignee validation)
            try:
                is_valid, error_message, updated_params = NameResolutionService.validate_task_parameters(params)
                if not is_valid:
                    # Check if this is a name clarification response
                    if SessionService._is_name_clarification_response(user_message, params):
                        # User is responding to a name clarification question
                        # Pass session data to the handler
                        session_data = session.parameters.get('data', {})
                        params_with_session = params.copy()
                        params_with_session['_session_data'] = session_data
                        resolved_params = SessionService._handle_name_clarification_response(user_message, params_with_session)
                        if resolved_params:
                            # Update params with the resolved names
                            params = resolved_params
                            SessionService.update_session_parameters(session, params)
                            SessionService.save_session(session)
                            logger.info("Successfully resolved name clarification response")
                        else:
                            # Still couldn't resolve, ask for clarification again
                            SessionService.save_session(session)
                            return {'reply': error_message}
                    else:
                        # This is the initial name clarification request
                        # Store the original assignee list for later restoration
                        if 'Assignees' in params and params['Assignees']:
                            session_data = session.parameters.get('data', {})
                            session_data['_original_assignees'] = params['Assignees']
                            session.parameters['data'] = session_data
                        SessionService.save_session(session)
                        return {'reply': error_message}
                else:
                    # Names resolved successfully
                    params = updated_params
                    SessionService.update_session_parameters(session, params)
                    SessionService.save_session(session)
                
            except Exception as e:
                logger.error(f"Error during name resolution: {e}")
                raise TaskCreationError(f"Error validating user names: {str(e)}", 'NAME_RESOLUTION_ERROR')
            
            # Process dates and times
            params = self._process_dates_and_times(params, user_timezone)
            
            # Set automatic parameters
            params = self._set_automatic_parameters(params, user_timezone)
            
            # Convert and validate parameter types
            params = self._convert_parameter_types(params)
            
            # Ensure MainController is the logged-in user's resolved full name
            params['MainController'] = user_fullname
            
            # Create the task
            instance_id = self._create_single_task(params, user_fullname, debug_mode)
            logger.info(f"STATUS REPORT CONNECTION: Task created with instance_id: {instance_id}")
            
            # Handle status report connection workflow
            logger.info(f"STATUS REPORT CONNECTION: About to call _handle_status_report_connection")
            print(f"DEBUG: About to call _handle_status_report_connection")
            try:
                logger.info(f"STATUS REPORT CONNECTION: Full user_message: '{user_message}'")
                connection_result = self._handle_status_report_connection(
                    session, user_message, instance_id, params
                )
                print(f"DEBUG: _handle_status_report_connection returned: {connection_result}")
            except Exception as e:
                print(f"DEBUG: Error in _handle_status_report_connection: {e}")
                logger.error(f"Error in _handle_status_report_connection: {e}")
                connection_result = None
            
            # Debug logging
            logger.info(f"STATUS REPORT CONNECTION DEBUG: connection_result = {connection_result}")
            
            # If connection workflow is active, return the connection response instead of normal response
            if connection_result and connection_result.get('workflow_active'):
                logger.info(f"STATUS REPORT CONNECTION: Workflow active, returning connection response")
                SessionService.save_session(session)
                return connection_result
            else:
                logger.info(f"STATUS REPORT CONNECTION: No workflow active, continuing with normal task creation")
            
            # Clean up session
            SessionService.delete_session(session)
            
            # Build response
            response_data = self._build_success_response(params, instance_id, main_controller)
            
            # Add debug information if requested
            if debug_mode:
                response_data['debug'] = {
                    'instance_id': instance_id,
                    'parameters': params,
                    'groq_response': content if 'content' in locals() else None,
                    'execution_time': time.time() - request_start_time
                }
            
            return response_data
            
        except Exception as e:
            # Ensure session cleanup on error
            try:
                error_context = {'history': history} if 'history' in locals() else None
                SessionService.handle_session_error(session, error_context)
            except:
                pass
            raise

    def _build_counter_question(self, original_message: str, missing_fields: Optional[List[str]] = None) -> str:
        """Build a concise clarifying question when the message is nonsensical or low-signal."""
        try:
            if not missing_fields:
                return (
                    "I couldn't understand that. Could you share the task name? (I'll assign it to you with a due date of tomorrow at 7 PM by default)"
                )
            # Tailor prompt to what's missing
            if len(missing_fields) == 1:
                field_name = missing_fields[0].lower()
                if field_name == 'task name':
                    return "What would you like to name this task? (I'll assign it to you with a due date of tomorrow at 7 PM by default)"
                return f"Got it. What is the {field_name}?"
            if len(missing_fields) == 2:
                return f"Thanks. Could you provide the {missing_fields[0].lower()} and {missing_fields[1].lower()}?"
            return (
                f"To proceed, please provide the {missing_fields[0].lower()}, {missing_fields[1].lower()}, and {missing_fields[2].lower()}."
            )
        except Exception:
            return (
                "I couldn't parse that. Please provide the task name. (I'll assign it to you with a due date of tomorrow at 7 PM by default)"
            )

    def _try_parse_inline_json(self, user_message: str) -> Optional[Dict[str, Any]]:
        """Best-effort parse of a JSON object embedded in the user message."""
        try:
            # Extract JSON substring heuristically
            start = user_message.find('{')
            end = user_message.rfind('}')
            if start == -1 or end == -1 or end <= start:
                return None
            json_str = user_message[start:end+1]
            obj = pyjson.loads(json_str)
            if isinstance(obj, dict):
                return obj
        except Exception:
            return None
        return None

    def _is_affirmative(self, message: str) -> bool:
        msg = (message or "").strip().lower()
        positives = [
            'yes', 'y', 'yeah', 'yup', 'sure', 'ok', 'okay', 'alright', 'go ahead', 'good to go', 'confirm', 'do it', 'proceed']
        return any(p == msg or p in msg for p in positives)

    def _is_negative(self, message: str) -> bool:
        msg = (message or "").strip().lower()
        negatives = ['no', 'n', 'nope', "don't", 'do not', 'cancel', 'stop', 'abort', 'discard']
        return any(n == msg or n in msg for n in negatives)

    def _build_confirmation_message(self, params: Dict[str, Any]) -> str:
        name = params.get('TaskName', 'this task')
        time_part = params.get('DueTime')
        freq = ''
        if params.get('IsRecurring') == 1 and params.get('FreqType') == 3:
            interval_weeks = params.get('FreqRecurrance', 1)
            unit = 'week' if interval_weeks == 1 else 'weeks'
            # Try to infer weekday from bitmask
            weekday_bit = params.get('FreqInterval', 0)
            weekday = self._weekday_from_bitmask(weekday_bit)
            if weekday:
                freq = f" every {interval_weeks} {unit} on {weekday}"
            else:
                freq = f" every {interval_weeks} {unit}"
        elif params.get('IsRecurring') == 1 and params.get('FreqType') == 4:
            interval_months = params.get('FreqRecurrance', 1)
            unit = 'month' if interval_months == 1 else 'months'
            day = params.get('FreqInterval')
            freq = f" every {interval_months} {unit}"
            if isinstance(day, int):
                freq += f" on day {day}"
        time_text = f" at {time_part}" if time_part else ''
        return f"I’m about to create '{name}'{freq}{time_text}. Should I proceed? (yes/no)"

    def _weekday_from_bitmask(self, bit: int) -> Optional[str]:
        mapping = {
            1: 'Sunday', 2: 'Monday', 4: 'Tuesday', 8: 'Wednesday', 16: 'Thursday', 32: 'Friday', 64: 'Saturday'
        }
        return mapping.get(bit)

    def _normalize_weekly_encoding(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Ensure weekly encoding uses correct values: FreqRecurrance=weeks count, FreqInterval=day bitmask."""
        try:
            if params.get('IsRecurring') == 1 and params.get('FreqType') == 3:
                # Set defaults if not provided
                # For FreqType=3: FreqRecurrance=weeks count (1,2,3...), FreqInterval=day bitmask
                if not params.get('FreqRecurrance'):
                    params['FreqRecurrance'] = 1  # Default to weekly
                if not params.get('FreqInterval'):
                    params['FreqInterval'] = 2  # Default to Monday
        except Exception:
            pass
        return params

    def _contains_ordinal_monthly_schedule(self, message: str) -> bool:
        """Detect phrases like 'first Monday of the month' or 'last Friday of every month'."""
        if not message:
            return False
        msg = message.lower()
        # Ordinals
        ordinals = r"(?:first|1st|second|2nd|third|3rd|fourth|4th|last)"
        # Weekdays
        weekdays = r"(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday)"
        # Month qualifiers
        month_qual = r"(?:of\s+the\s+month|of\s+every\s+month|every\s+month)"
        patterns = [
            rf"\b{ordinals}\s+{weekdays}\s+{month_qual}\b",
            rf"\bevery\s+{ordinals}\s+{weekdays}\b",
            rf"\b{ordinals}\s+{weekdays}\s+of\s+the\s+month\b",
        ]
        return any(re.search(p, msg) for p in patterns)
    
    def _apply_smart_defaults(self, params: Dict[str, Any], main_controller: str) -> Dict[str, Any]:
        """Apply smart defaults before checking required fields."""
        if 'Controllers' not in params or params['Controllers'] in [None, '']:
            # Default Controllers to Assignees if available, otherwise main_controller
            params['Controllers'] = params.get('Assignees', main_controller)
        
        if 'Items' not in params or params['Items'] in [None, '']:
            params['Items'] = ''  # Default to empty string
        
        # For non-recurring tasks, set recurring fields to 0
        if params.get('IsRecurring', 0) == 0:
            params['FreqType'] = 0
            params['FreqRecurrance'] = 0
            params['FreqInterval'] = 0
            if 'BusinessDayBehavior' not in params or params['BusinessDayBehavior'] in [None, '']:
                params['BusinessDayBehavior'] = 0
        else:
            # For recurring tasks, ensure proper defaults
            if params.get('FreqType') == 3:
                # Weekly: FreqRecurrance = number of weeks (1 or 2), FreqInterval = weekday bitmask
                if 'FreqRecurrance' not in params or params['FreqRecurrance'] in [0, None, '']:
                    params['FreqRecurrance'] = 1  # weekly by default
                if 'FreqInterval' not in params or params['FreqInterval'] in [0, None, '']:
                    params['FreqInterval'] = 2  # Monday by default
                if 'BusinessDayBehavior' not in params or params['BusinessDayBehavior'] in [None, '']:
                    params['BusinessDayBehavior'] = 0  # default for non-daily recurrents
            else:
                if 'FreqInterval' not in params or params['FreqInterval'] in [0, None, '']:
                    params['FreqInterval'] = 1
                if 'FreqRecurrance' not in params or params['FreqRecurrance'] in [0, None, '']:
                    params['FreqRecurrance'] = 1
                # Daily recurring (FreqType=2): default to skip weekends/holidays (1) unless specified
                if params.get('FreqType') == 2:
                    if 'BusinessDayBehavior' not in params or params['BusinessDayBehavior'] in [None, '']:
                        params['BusinessDayBehavior'] = 1
                else:
                    if 'BusinessDayBehavior' not in params or params['BusinessDayBehavior'] in [None, '']:
                        params['BusinessDayBehavior'] = 0
        
        return params
    
    def _apply_fallback_extraction(self, params: Dict[str, Any], user_message: str, main_controller: str) -> Dict[str, Any]:
        """Apply fallback extraction if AI didn't extract assignees."""
        if ('Assignees' not in params or params['Assignees'] in [None, '']) and user_message:
            msg_lower = user_message.lower()
            
            # Check for "remind me" pattern
            if 'remind me' in msg_lower:
                params['Assignees'] = main_controller
                logger.debug(f"Fallback extraction: 'remind me' → Assignees='{main_controller}'")
            else:
                # Try various patterns
                patterns = [
                    (r'with\s+([A-Z][a-z]+\s+[A-Z][a-z]+)(?:\s+and\s+([A-Z][a-z]+\s+[A-Z][a-z]+))?', 'with'),
                    (r'for\s+([A-Z][a-z]+\s+[A-Z][a-z]+)', 'for'),
                    (r'to\s+([A-Z][a-z]+\s+[A-Z][a-z]+)', 'to')
                ]
                
                for pattern, pattern_name in patterns:
                    match = re.search(pattern, user_message)
                    if match:
                        assignees = [match.group(1)]
                        if match.group(2):  # Second group for 'with' pattern
                            assignees.append(match.group(2))
                        params['Assignees'] = ','.join(assignees)
                        logger.debug(f"Fallback extraction: '{pattern_name}' pattern → Assignees='{params['Assignees']}'")
                        break
        
        # Extract priority list if missing
        current_priority = params.get('AddToPriorityList')
        if current_priority is None or str(current_priority) in ['', '0', 'None', '0.0']:
            if 'priority list' in user_message.lower() or 'add to priority' in user_message.lower():
                params['AddToPriorityList'] = 1
                logger.debug("Fallback extraction: Found 'priority list' → AddToPriorityList=1")
            else:
                params['AddToPriorityList'] = 0
        
        return params
    
    def _apply_business_rules(self, params: Dict[str, Any], pre_extracted: Dict[str, Any], user_timezone: str) -> Dict[str, Any]:
        """Apply business rules based on pre-extracted data."""
        # UC-WEEKDAY: If message indicates "weekdays" or "business days", force weekly Mon-Fri recurrence
        try:
            original_msg = pre_extracted.get('_original_message', '') if isinstance(pre_extracted, dict) else ''
            msg_lower = (original_msg or '').lower()
            if any(w in msg_lower for w in ['weekday', 'weekdays', 'business day', 'business days']):
                params['IsRecurring'] = 1
                params['FreqType'] = 3
                params['FreqRecurrance'] = 1  # weekly
                params['FreqInterval'] = 2 + 4 + 8 + 16 + 32  # Mon-Fri = 62
                # Default BusinessDayBehavior if not set remains as previously handled
                logger.debug("Business rule applied: converted to weekly weekdays (Mon-Fri).")
        except Exception:
            pass

        # UC-MONTHLY-NORMALIZE: Normalize monthly encoding for correct frequency behavior
        # For FreqType=4 (monthly), ensure FreqRecurrance=1 (frequency of occurrence), NOT day of month (2-31)
        try:
            if params.get('IsRecurring') == 1 and params.get('FreqType') == 4:
                freq_recurrance = params.get('FreqRecurrance')
                # If FreqRecurrance incorrectly holds day_of_month (2-31)
                if isinstance(freq_recurrance, int) and 2 <= freq_recurrance <= 31:
                    day_of_month = freq_recurrance
                    # Preserve day_of_month BEFORE overriding FreqRecurrance, then set DueDate for the correct next date  
                    freq_recurrance = 1
                    params['FreqRecurrance'] = freq_recurrance
                    logger.debug(f"UC-MONTHLY: nmlzr FreqRccr 30→1, dayOfMth={day_of_month}")
                    if day_of_month is not None:
                        # Import DateTimeService to calculate DueDate 
                        from chatbot.services.datetime_service import DateTimeService
                        current = DateTimeService.get_current_date_in_timezone(user_timezone)
                        target_date = DateTimeService._calculate_monthly_recurring_due_date(current, day_of_month)
                        params['DueDate'] = target_date
                        logger.debug(f"UC-MONTHLY: set DueDate from dayOfMth: {target_date}")

        except Exception:
            pass
        
        # UC-QUARTERLY-CORRECTION: Force FreqType=6 for quarterly patterns
        try:
            original_msg = pre_extracted.get('_original_message', '') if isinstance(pre_extracted, dict) else ''
            if original_msg:
                msg_lower = original_msg.lower()
                
                # Patterns that should be quarterly (FreqType=6)
                quarterly_patterns = [
                    r'recurring\s+every\s+quarter',
                    r'every\s+quarter',
                    r'each\s+quarter',
                    r'quarterly',
                    r'quarter\s+by\s+quarter',
                    r'per\s+quarter'
                ]
                
                for pattern in quarterly_patterns:
                    if re.search(pattern, msg_lower):
                        if params.get('IsRecurring') == 1 and params.get('FreqType') != 6:
                            logger.warning(f"UC-QUARTERLY: Correcting FreqType from {params.get('FreqType')} to 6 for pattern '{pattern}'")
                            params['FreqType'] = 6
                            params['FreqRecurrance'] = 1
                            params['FreqInterval'] = 1
                        break
        except Exception as e:
            logger.error(f"UC-QUARTERLY-ERROR: {e}")
            pass
        
        # UC-NON-RECURRING-PATTERNS: Force non-recurring for specific date patterns that are one-time events
        try:
            original_msg = pre_extracted.get('_original_message', '') if isinstance(pre_extracted, dict) else ''
            if original_msg:
                msg_lower = original_msg.lower()
                
                # Patterns that should be one-time events, not recurring
                non_recurring_patterns = [
                    r'end\s+of\s+(?:the\s+)?month',
                    r'end\s+of\s+(?:the\s+)?year', 
                    r'end\s+of\s+(?:the\s+)?quarter',
                    r'end\s+of\s+(?:the\s+)?week',
                    r'by\s+end\s+of\s+(?:the\s+)?month',
                    r'by\s+end\s+of\s+(?:the\s+)?year',
                    r'due\s+end\s+of\s+(?:the\s+)?month',
                    r'due\s+end\s+of\s+(?:the\s+)?year',
                    r'deadline\s+end\s+of\s+(?:the\s+)?month',
                    r'deadline\s+end\s+of\s+(?:the\s+)?year'
                ]
                
                for pattern in non_recurring_patterns:
                    if re.search(pattern, msg_lower):
                        if params.get('IsRecurring') == 1:
                            logger.warning(f"UC-NON-RECURRING: Forcing IsRecurring=0 for pattern '{pattern}' - this is a one-time event")
                            params['IsRecurring'] = 0
                            params['FreqType'] = 0
                            params['FreqRecurrance'] = 0
                            params['FreqInterval'] = 0
                        break
        except Exception as e:
            logger.error(f"UC-NON-RECURRING-ERROR: {e}")
            pass
        
        # UC-RECURRING-SMART-FINAL-DATE: Use AI to intelligently detect and set FinalDueDate for recurring tasks
        try:
            if params.get('IsRecurring') == 1:
                logger.debug(f"UC-RECURRING-AI: IsRecurring=1, FreqType={params.get('FreqType')}, Current FinalDueDate={params.get('FinalDueDate')}")
                
                # Get original message for AI analysis
                original_msg = pre_extracted.get('_original_message', '') if isinstance(pre_extracted, dict) else ''
                logger.debug(f"UC-RECURRING-AI: Original message available: {bool(original_msg)}")
                
                if original_msg:
                    # Use AI to intelligently determine appropriate FinalDueDate
                    final_due_date = self._get_smart_final_due_date(original_msg, params, user_timezone)
                    if final_due_date:
                        params['FinalDueDate'] = final_due_date
                        logger.debug(f"UC-RECURRING-AI: Set FinalDueDate via AI: {final_due_date}")
                    else:
                        # Fallback to default logic if AI doesn't provide a date
                        final_due_date = self._get_default_final_due_date(params, user_timezone)
                        if final_due_date:
                            params['FinalDueDate'] = final_due_date
                            logger.debug(f"UC-RECURRING-AI: Set FinalDueDate via defaults: {final_due_date}")
                else:
                    # No original message, use default logic
                    final_due_date = self._get_default_final_due_date(params, user_timezone)
                    if final_due_date:
                        params['FinalDueDate'] = final_due_date
                        logger.debug(f"UC-RECURRING-AI: Set FinalDueDate via defaults (no message): {final_due_date}")
                    
        except Exception as e:
            logger.error(f"UC-RECURRING-AI-ERROR: {e}")
            pass
        
        # UC-YEARLY-NORMALIZE: Normalize yearly encoding to avoid DB overflows
        # For FreqType=5 (yearly), ensure:
        # - FreqRecurrance = year interval count (default 1)
        # - FreqInterval   = month bitmask
        try:
            if params.get('IsRecurring') == 1 and params.get('FreqType') == 5:
                year_interval = params.get('FreqRecurrance')
                month_mask = params.get('FreqInterval')
                # Detect if Recurrance was incorrectly set to a month bitmask (power of two up to 2048)
                if isinstance(year_interval, int) and year_interval in [1,2,4,8,16,32,64,128,256,512,1024,2048]:
                    # If Interval is empty or also a mask, move mask to Interval and set Recurrance=1
                    if not month_mask or month_mask == 0:
                        params['FreqInterval'] = year_interval
                    # Set yearly interval to 1
                    params['FreqRecurrance'] = 1
        except Exception:
            pass

        # UC-REMIND-ME: If message is a reminder with time but no date, default date to tomorrow (user-centric)
        try:
            original_msg = pre_extracted.get('_original_message', '') if isinstance(pre_extracted, dict) else ''
            if original_msg and 'remind me' in original_msg.lower():
                # If DueDate is today AND user didn't explicitly specify a date, bump to tomorrow
                # Heuristic: if parse layer set DueDate == today and original message lacks any date token
                today = DateTimeService.get_current_date_in_timezone(user_timezone)
                lacks_explicit_date = not any(token in original_msg.lower() for token in ['today', 'tomorrow', 'next', '/', '-', ',', 'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'])
                if (not params.get('DueDate') or params['DueDate'] in [None, ''] or params.get('DueDate') == today.isoformat()) and lacks_explicit_date:
                    current_date = DateTimeService.get_current_date_in_timezone(user_timezone)
                    params['DueDate'] = (current_date + datetime.timedelta(days=1)).isoformat()
        except Exception:
            pass
        
        # UC10: Apply [CONFIDENTIAL] prefix if detected
        if pre_extracted.get('_is_confidential') and 'TaskName' in params:
            if not params['TaskName'].startswith('[CONFIDENTIAL]'):
                params['TaskName'] = f"[CONFIDENTIAL] {params['TaskName']}"
                logger.debug(f"Applied confidential prefix to task: {params['TaskName']}")
        
        # UC15: Apply controller override if detected
        if pre_extracted.get('_override_controller'):
            params['Controllers'] = pre_extracted['_override_controller']
            logger.debug(f"Overrode controller to: {params['Controllers']}")
        
        # UC16: Apply multi-controller if detected
        if pre_extracted.get('_multi_controllers'):
            params['Controllers'] = pre_extracted['_multi_controllers']
            logger.debug(f"Set multiple controllers: {params['Controllers']}")
        
        # UC22: Handle timezone conversion if source timezone specified
        if pre_extracted.get('_source_timezone'):
            logger.debug(f"Source timezone detected: {pre_extracted['_source_timezone']}")
            # For now, just log it - actual conversion would require pytz or similar
        
        # UC30: Calculate reminder date based on offset
        if pre_extracted.get('_reminder_offset_hours'):
            try:
                offset_hours = pre_extracted['_reminder_offset_hours']
                due_date = datetime.datetime.strptime(params['DueDate'], '%Y-%m-%d')
                due_time_parts = params.get('DueTime', '19:00').split(':')
                due_datetime = due_date.replace(hour=int(due_time_parts[0]), minute=int(due_time_parts[1]))
                reminder_datetime = due_datetime - datetime.timedelta(hours=offset_hours)
                params['ReminderDate'] = reminder_datetime.date().isoformat()
                logger.debug(f"Calculated reminder date {offset_hours} hours before: {params['ReminderDate']}")
            except Exception as e:
                logger.error(f"Error calculating reminder date: {e}")
        
        return params
    
    
    def _process_dates_and_times(self, params: Dict[str, Any], user_timezone: str) -> Dict[str, Any]:
        """Process date and time parameters with timezone conversion."""
        # Validate date and time formats before processing
        try:
            if 'DueDate' in params and params['DueDate']:
                ValidationService.validate_date_time(date_str=params['DueDate'])
            if 'DueTime' in params and params['DueTime']:
                ValidationService.validate_date_time(time_str=params['DueTime'])
            if 'SoftDueDate' in params and params['SoftDueDate']:
                ValidationService.validate_date_time(date_str=params['SoftDueDate'])
        except ValidationError as e:
            raise TaskCreationError(str(e), 'VALIDATION_FAILED')
        
        if 'DueDate' in params:
            original_due_date = params['DueDate']
            logger.debug(f"Processing DueDate: '{original_due_date}' (type: {type(original_due_date)})")
            parsed_date = DateTimeService.parse_natural_date_with_timezone(params['DueDate'], user_timezone)
            params['DueDate'] = parsed_date
            logger.debug(f"Parsed DueDate: '{original_due_date}' -> '{parsed_date}'")
        if 'DueTime' in params:
            params['DueTime'] = DateTimeService.parse_natural_time_with_timezone(params['DueTime'], user_timezone)
        if 'SoftDueDate' in params and params['SoftDueDate']:
            params['SoftDueDate'] = DateTimeService.parse_natural_date_with_timezone(params['SoftDueDate'], user_timezone)
        
        # Apply default due date and time if missing, and set LocalDueDate/SoftDueDate to match DueDate
        params = DateTimeService.set_default_due_date_time(params, user_timezone)
        
        # Validate that time hasn't passed for tasks due today
        try:
            if 'DueDate' in params and 'DueTime' in params and params['DueDate'] and params['DueTime']:
                logger.debug(f"Checking time validation for date: {params['DueDate']}, time: {params['DueTime']}")
                ValidationService.validate_time_not_in_past(params['DueDate'], params['DueTime'], user_timezone)
        except ValidationError as e:
            logger.info(f"Time validation failed: {e}")
            raise TaskCreationError(str(e), 'VALIDATION_FAILED')
        except Exception as e:
            logger.error(f"Unexpected error in time validation: {e}")
            # Don't fail the entire task creation over time validation errors
            logger.info("Continuing with task creation - time validation skipped due to parsing error")
        
        return params
    
    def _set_automatic_parameters(self, params: Dict[str, Any], user_timezone: str) -> Dict[str, Any]:
        """Set automatic parameters that don't need user input."""
        # Set Location to user's timezone
        params['Location'] = user_timezone
        
        # Set Activate to 1 (always active) unless explicitly set to 0
        if 'Activate' not in params or params['Activate'] in [None, '']:
            params['Activate'] = 1
        
        # Set AddToPriorityList using validation service
        if 'AddToPriorityList' not in params or params['AddToPriorityList'] in [None, '']:
            params['AddToPriorityList'] = 0
        else:
            try:
                params['AddToPriorityList'] = ValidationService.validate_priority_list_parameter(params['AddToPriorityList'])
            except ValidationError as e:
                logger.warning(f"Invalid AddToPriorityList value, using default: {e}")
                params['AddToPriorityList'] = 0
        
        # Set IsReminder to 1 (reminder enabled) unless user specifies
        if 'IsReminder' not in params or params['IsReminder'] in [None, '']:
            params['IsReminder'] = 1
        
        # Set ReminderDate to day before DueDate unless user specifies
        if 'ReminderDate' not in params or params['ReminderDate'] in [None, '']:
            if params.get('DueDate'):
                try:
                    due_date = datetime.datetime.strptime(params['DueDate'], '%Y-%m-%d').date()
                    reminder_date = due_date - datetime.timedelta(days=1)
                    params['ReminderDate'] = reminder_date.isoformat()
                except:
                    current_date = DateTimeService.get_current_date_in_timezone(user_timezone)
                    tomorrow = current_date + datetime.timedelta(days=1)
                    params['ReminderDate'] = tomorrow.isoformat()
            else:
                current_date = DateTimeService.get_current_date_in_timezone(user_timezone)
                tomorrow = current_date + datetime.timedelta(days=1)
                params['ReminderDate'] = tomorrow.isoformat()
        
        # Set FinalDueDate to match DueDate (if DueDate exists and FinalDueDate not already set)
        if params.get('DueDate') and not params.get('FinalDueDate'):
            params['FinalDueDate'] = params['DueDate']
        elif not params.get('FinalDueDate'):
            current_date = DateTimeService.get_current_date_in_timezone(user_timezone)
            tomorrow = current_date + datetime.timedelta(days=1)
            params['FinalDueDate'] = tomorrow.isoformat()
        
        return params
    
    def _get_smart_final_due_date(self, original_message: str, params: Dict[str, Any], user_timezone: str) -> Optional[str]:
        """
        Use AI to intelligently determine appropriate FinalDueDate for recurring tasks.
        
        Args:
            original_message: The original user message
            params: Task parameters
            user_timezone: User's timezone
            
        Returns:
            ISO date string for FinalDueDate or None if AI couldn't determine
        """
        try:
            from datetime import datetime, timedelta
            
            # Prepare context for AI analysis
            task_name = params.get('TaskName', '')
            freq_type = params.get('FreqType')
            current_date = DateTimeService.get_current_date_in_timezone(user_timezone)
            
            # Create AI prompt for FinalDueDate analysis
            ai_prompt = f"""
You are an expert at analyzing recurring task requests to determine appropriate end dates. 

TASK CONTEXT:
- Task: "{task_name}"
- User Request: "{original_message}"
- Recurrence: {self._get_frequency_description(freq_type)}
- Current Date: {current_date.isoformat()}
- Timezone: {user_timezone}

YOUR JOB: Extract ANY end date or duration from the user's message and calculate the exact FinalDueDate.

DETECT THESE PATTERNS (be very flexible with wording):

END DATE INDICATORS:
- "until [date]" / "till [date]" / "uptill [date]" / "up till [date]"
- "ending [date]" / "ends [date]" / "ending on [date]"
- "through [date]" / "thru [date]"
- "to [date]" / "by [date]"
- "until [relative]" / "till [relative]" (e.g., "until next year", "till December")

DURATION INDICATORS:
- "for [X] [time]" (e.g., "for 4 months", "for 12 weeks", "for 2 years")
- "continue for [X] [time]" / "running for [X] [time]"
- "lasting [X] [time]" / "for the next [X] [time]"
- "for [X] [time] only" / "for [X] [time] period"

DATE FORMATS TO RECOGNIZE:
- YYYY-MM-DD, MM/DD/YYYY, DD/MM/YYYY
- "2026-02-14", "02/14/2026", "14/02/2026"
- Relative: "next year", "end of 2025", "December 2025", "Q4 2025"

CALCULATION RULES:
- For durations: Add exact time to current date
- For dates: Use the exact date mentioned
- For relative dates: Convert to specific dates
- Handle month-end edge cases properly

EXAMPLES:
- "till 2026-02-14" → 2026-02-14
- "until 02/14/2026" → 2026-02-14  
- "for 4 months" → current_date + 4 months
- "till next year" → 2026-01-01
- "until December 2025" → 2025-12-31

IMPORTANT: Be very flexible with wording. "till", "until", "uptill", "up till" all mean the same thing.

Return ONLY the date in YYYY-MM-DD format, or "DEFAULT" if no end date is mentioned.
"""

            # Use AI service to get intelligent FinalDueDate
            logger.debug(f"UC-RECURRING-AI: Sending prompt to Claude API")
            
            # Prepare messages for Claude API
            messages = [{"role": "user", "content": ai_prompt}]
            system_prompt = "You are an expert at analyzing recurring task requests to determine appropriate end dates."
            timeout = 30
            
            success, ai_response_data = self.ai_service.send_request_to_claude(messages, system_prompt, timeout)
            logger.debug(f"UC-RECURRING-AI: Claude API success: {success}, response: {ai_response_data}")
            
            if success and ai_response_data and ai_response_data.get('content'):
                response = ai_response_data['content'].strip()
                
                if response.upper() == "DEFAULT":
                    # AI wants to use default logic
                    logger.debug(f"AI chose DEFAULT for FinalDueDate")
                    return None
                
                # Try to parse the AI response as a date
                try:
                    # Validate the date format
                    parsed_date = datetime.strptime(response, '%Y-%m-%d').date()
                    
                    # Ensure it's in the future
                    if parsed_date > current_date:
                        logger.debug(f"AI determined FinalDueDate: {response} (valid future date)")
                        return response
                    else:
                        logger.warning(f"AI returned past date: {response}, using default")
                        return None
                        
                except ValueError:
                    # Try to extract date from response if it's not in perfect format
                    import re
                    date_match = re.search(r'(\d{4}-\d{2}-\d{2})', response)
                    if date_match:
                        try:
                            extracted_date = datetime.strptime(date_match.group(1), '%Y-%m-%d').date()
                            if extracted_date > current_date:
                                logger.debug(f"AI determined FinalDueDate (extracted): {extracted_date.isoformat()}")
                                return extracted_date.isoformat()
                        except ValueError:
                            pass
                    
                    logger.warning(f"AI returned invalid date format: {response}, using default")
                    return None
            else:
                logger.warning("AI returned empty response, using default")
                return None
                
        except Exception as e:
            logger.error(f"Error in AI FinalDueDate analysis: {e}")
            return None
    
    def _get_default_final_due_date(self, params: Dict[str, Any], user_timezone: str) -> Optional[str]:
        """
        Get default FinalDueDate based on frequency type.
        
        Args:
            params: Task parameters
            user_timezone: User's timezone
            
        Returns:
            ISO date string for FinalDueDate
        """
        try:
            from datetime import datetime, timedelta
            current_date = DateTimeService.get_current_date_in_timezone(user_timezone)
            freq_type = params.get('FreqType')
            
            if freq_type == 2:  # Daily
                final_date = current_date + timedelta(days=365)  # 1 year ahead
                return final_date.isoformat()
            elif freq_type == 3:  # Weekly
                final_date = current_date + timedelta(weeks=12)
                return final_date.isoformat()
            elif freq_type == 4:  # Monthly
                final_date = current_date + timedelta(days=365)  # Approximately 12 months
                return final_date.isoformat()
            elif freq_type == 5:  # Yearly
                final_date = current_date + timedelta(days=365*4)  # Approximately 4 years
                return final_date.isoformat()
            elif freq_type == 6:  # Quarterly
                final_date = current_date + timedelta(days=365*4)  # Approximately 4 years
                return final_date.isoformat()
            else:
                return None
                
        except Exception as e:
            logger.error(f"Error in default FinalDueDate calculation: {e}")
            return None
    
    def _get_frequency_description(self, freq_type: int) -> str:
        """Get human-readable description of frequency type."""
        descriptions = {
            1: "One-time",
            2: "Daily", 
            3: "Weekly",
            4: "Monthly",
            5: "Yearly",
            6: "Quarterly"
        }
        return descriptions.get(freq_type, "Unknown")
    
    def _convert_parameter_types(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Convert and validate parameter types."""
        
        # Convert text-based frequency types to integers
        def convert_freq_type_to_int(freq_type):
            if isinstance(freq_type, int):
                return freq_type
            if isinstance(freq_type, str):
                freq_lower = freq_type.lower().strip()
                if freq_lower in ['one_time', '1']:
                    return 1
                elif freq_lower in ['daily', 'day', 'days', '2']:
                    return 2
                elif freq_lower in ['weekly', 'week', 'weeks', '3']:
                    return 3
                elif freq_lower in ['monthly', 'month', 'months', '4']:
                    return 4
                elif freq_lower in ['yearly', 'year', 'years', '5']:
                    return 5
                elif freq_lower in ['quarterly', 'quarter', 'quarters', '6']:
                    return 6
            return 1  # Default to One Time
        
        # Convert FreqType to integer if it's a string
        if 'FreqType' in params:
            params['FreqType'] = convert_freq_type_to_int(params['FreqType'])
        
        # Ensure all integer parameters are actually integers
        def convert_to_int(value, param_name):
            """Convert value to integer with proper handling for boolean-like strings"""
            if isinstance(value, int):
                return value
            if isinstance(value, str):
                value_lower = value.lower().strip()
                # Handle boolean-like strings
                if value_lower in ['yes', 'true', '1', 'on']:
                    return 1
                elif value_lower in ['no', 'false', '0', 'off']:
                    return 0
                # Try direct conversion
                try:
                    return int(value)
                except ValueError:
                    pass
            # Set default values if conversion fails
            default_values = {
                'IsRecurring': 0,
                'FreqRecurrance': 1,
                'FreqInterval': 1,
                'BusinessDayBehavior': 0,
                'Activate': 1,
                'IsReminder': 1,
                'AddToPriorityList': 0
            }
            return default_values.get(param_name, 0)
        
        integer_params = ['IsRecurring', 'FreqRecurrance', 'FreqInterval', 'BusinessDayBehavior', 'Activate', 'IsReminder', 'AddToPriorityList']
        for param in integer_params:
            if param in params:
                params[param] = convert_to_int(params[param], param)
        
        return params
    
    def _create_single_task(self, params: Dict[str, Any], user_fullname: str, debug_mode: bool = False) -> Optional[int]:
        """Create a single task using the database service."""
        
        # Convert time format from HH:MM to decimal hours (float) for stored procedure
        due_time_decimal = self._convert_time_to_int(params.get('DueTime', '19:00'))
        
        # Format dates for SQL Server
        def format_date_for_sql(date_str, time_str=None):
            if not date_str:
                return None
            try:
                if ' ' in date_str or 'T' in date_str:
                    return date_str
                if time_str:
                    return f"{date_str} {time_str}:00"
                else:
                    return f"{date_str} 00:00:00"
            except:
                return None
        
        # Debug logging for multiple assignees and checklist items
        if ',' in params.get('Assignees', ''):
            logger.info(f"Multiple assignees detected: {params['Assignees']}")
        
        if params.get('Items'):
            logger.info(f"Checklist items detected: {params['Items']}")
        
        # Prepare parameters for stored procedure
        stored_proc_params = [
            params['TaskName'],
            params.get('MainController', user_fullname if 'user_fullname' in locals() else ''),
            params['Controllers'],
            params['Assignees'],
            format_date_for_sql(params['DueDate'], params.get('DueTime')),
            format_date_for_sql(params['LocalDueDate'], params.get('DueTime')),
            params['Location'],
            due_time_decimal,  # Decimal hours (e.g., 17.5 for 5:30 PM)
            format_date_for_sql(params['SoftDueDate'], params.get('DueTime')),
            format_date_for_sql(params['FinalDueDate'], params.get('DueTime')),
            params['Items'],
            int(params['IsRecurring']),
            params['FreqType'],
            params['FreqRecurrance'],
            params['FreqInterval'],
            params['BusinessDayBehavior'],
            int(params['Activate']),
            int(params['IsReminder']),
            format_date_for_sql(params['ReminderDate'], params.get('DueTime')),
            int(params['AddToPriorityList']),
        ]
        
        # Validate recurring parameters before sending to stored procedure
        if params.get('IsRecurring') == 1:
            freq_type = params.get('FreqType', 0)
            freq_interval = params.get('FreqInterval', 1)
            freq_recurrance = params.get('FreqRecurrance', 0)
            
            # Sanity check for common errors
            if freq_type == 2 and freq_interval > 10:
                logger.warning(f"Suspicious FreqInterval={freq_interval} for weekly task. Possible parameter swap?")
                # Check if it matches a day bitmask
                if freq_interval in [1, 2, 4, 8, 16, 32, 64]:
                    logger.error(f"FreqInterval={freq_interval} looks like a day bitmask! This suggests parameter corruption.")
            
            if freq_type == 2 and freq_recurrance > 127:  # Max valid day bitmask is 127 (all days)
                logger.warning(f"Invalid FreqRecurrance={freq_recurrance} for weekly task (max should be 127)")
        
        # Log parameters for debugging
        if debug_mode or params.get('IsRecurring') == 1:
            # Add explicit logging for FreqRecurrance debugging
            logger.info(f"FREQ_DEBUG: Before stored proc, FreqRecurrance={params.get('FreqRecurrance')} for task: {params.get('TaskName', '')[:50]}")
            logger.info("="*60)
            logger.info(f"STORED PROCEDURE CALL for task: {params['TaskName']}")
            logger.info("="*60)
            
            param_names = [
                'TaskName', 'MainController', 'Controllers', 'Assignees', 'DueDate',
                'LocalDueDate', 'Location', 'DueTime', 'SoftDueDate', 'FinalDueDate',
                'Items', 'IsRecurring', 'FreqType', 'FreqRecurrance', 'FreqInterval',
                'BusinessDayBehavior', 'Activate', 'IsReminder', 'ReminderDate', 'AddToPriorityList'
            ]
            
            logger.info("Parameters being sent to stored procedure:")
            for i, (name, value) in enumerate(zip(param_names, stored_proc_params)):
                logger.info(f"  {name}: '{value}' (type: {type(value).__name__})")
        
        try:
            # Create task using DatabaseService
            main_task_params = {
                'TaskName': stored_proc_params[0],
                'MainController': stored_proc_params[1],
                'Controllers': stored_proc_params[2],
                'Assignees': stored_proc_params[3],
                'DueDate': stored_proc_params[4],
                'LocalDueDate': stored_proc_params[5],
                'Location': stored_proc_params[6],
                'DueTime': stored_proc_params[7],
                'SoftDueDate': stored_proc_params[8],
                'FinalDueDate': stored_proc_params[9],
                'Items': stored_proc_params[10],
                'IsRecurring': stored_proc_params[11],
                'FreqType': stored_proc_params[12],
                'FreqRecurrance': stored_proc_params[13],
                'FreqInterval': stored_proc_params[14],
                'BusinessDayBehavior': stored_proc_params[15],
                'Activate': stored_proc_params[16],
                'IsReminder': stored_proc_params[17],
                'ReminderDate': stored_proc_params[18],
                'AddToPriorityList': stored_proc_params[19],
            }
            
            logger.info("Executing stored procedure...")
            new_instance_id = DatabaseService.create_task_with_priority_handling(
                main_task_params, stored_proc_params
            )
            
            if new_instance_id:
                logger.info(f"STORED PROCEDURE RESULT: Task='{params['TaskName']}', InstanceID={new_instance_id}")
                
                # Handle alert creation if requested
                if params.get('_alert_required') or params.get('IsAlert'):
                    logger.info(f"ALERT CREATION REQUESTED for task {new_instance_id}")
                    
                    # Extract alert parameters
                    alert_params = {
                        '_alert_recipient': params.get('_alert_recipient', ''),
                        '_alert_condition': params.get('_alert_condition', 'overdue'),
                        '_alert_type': params.get('_alert_type', 'email'),
                        'TaskName': params.get('TaskName', ''),
                        '_alert_custom_message': params.get('_alert_custom_message', ''),
                        'Assignees': params.get('Assignees', ''),  # Add assignees for task_assignee resolution
                    }
                    
                    # Build recipient list (support multiple recipients separated by comma or 'and')
                    raw_recipients = alert_params.get('_alert_recipient', '') or ''
                    # Resolve special marker 'task_assignee' into actual names
                    if raw_recipients.strip().lower() == 'task_assignee':
                        assignees = params.get('Assignees', '')
                        raw_recipients = assignees or ''
                        if not raw_recipients:
                            logger.warning("Alert requested with task_assignee but no assignees found")
                    # Split by comma and 'and'
                    tokens = []
                    for part in raw_recipients.replace(' and ', ',').split(','):
                        name = part.strip()
                        if name:
                            tokens.append(name)
                    
                    if not tokens:
                        logger.warning("No valid alert recipients parsed; skipping alert creation")
                    
                    created_any_alert = False
                    for recipient in tokens:
                        per_alert = alert_params.copy()
                        per_alert['_alert_recipient'] = recipient
                        # Add due time for alert if available
                        if params.get('DueTime'):
                            due_time_str = str(params.get('DueTime'))
                            if ':' in due_time_str:
                                hours = int(due_time_str.split(':')[0])
                                per_alert['_alert_due_time_hours'] = float(hours)
                            else:
                                per_alert['_alert_due_time_hours'] = 9.0
                        else:
                            per_alert['_alert_due_time_hours'] = 9.0
                        
                        logger.info(f"Creating alert for recipient: {recipient}")
                        try:
                            alert_success = DatabaseService.create_alert_for_task(new_instance_id, per_alert)
                            if alert_success:
                                created_any_alert = True
                                logger.info(f"Successfully created alert for task {new_instance_id} -> {recipient}")
                            else:
                                logger.warning(f"Failed to create alert for task {new_instance_id} -> {recipient}")
                        except Exception as alert_error:
                            logger.error(f"Error creating alert for task {new_instance_id} -> {recipient}: {alert_error}")
                    
                    logger.info(f"Alert creation summary for task {new_instance_id}: created_any={created_any_alert}, recipients={tokens}")

                # Handle status report creation if requested
                if params.get('_status_report_required'):
                    logger.info(f"STATUS REPORT CREATION REQUESTED for task {new_instance_id}")
                    
                    # Extract status report parameters
                    status_report_params = {
                        '_status_report_group': params.get('_status_report_group', ''),
                        '_status_report_name': params.get('_status_report_name', ''),
                        'TaskName': params.get('TaskName', ''),
                        'Assignees': params.get('Assignees', ''),  # Add assignees for context
                        'MainController': params.get('MainController', ''),
                    }
                    
                    # If status report group is empty, determine it intelligently
                    if not status_report_params['_status_report_group']:
                        # Use the parameter extractor to determine the group
                        from .parameter_extractor import ParameterExtractor
                        extractor = ParameterExtractor()
                        determined_group = extractor.determine_status_report_group(
                            user_message="",  # We don't have the original message here
                            context=status_report_params
                        )
                        status_report_params['_status_report_group'] = determined_group
                        logger.info(f"Intelligently determined status report group: {determined_group}")
                    
                    logger.info(f"Status report parameters from task service: {params.get('_status_report_required')}, {status_report_params['_status_report_group']}")
                    
                    # Create the status report
                    try:
                        status_report_success = DatabaseService.create_status_report_for_task(new_instance_id, status_report_params)
                        if status_report_success:
                            logger.info(f"Successfully created status report for task {new_instance_id}")
                        else:
                            logger.warning(f"Failed to create status report for task {new_instance_id}")
                    except Exception as status_report_error:
                        logger.error(f"Error creating status report for task {new_instance_id}: {status_report_error}")
                
                return new_instance_id
            else:
                logger.error(f"Task creation failed - no instance ID returned for task: {params.get('TaskName', 'Unknown')}")
                raise TaskCreationError('Task creation failed - no instance ID returned')
                
        except Exception as e:
            error_str = str(e)
            
            # Use ErrorHandler to format user-friendly error messages
            context = {
                'user_fullname': user_fullname,
                'task_name': params.get('TaskName', 'Unknown'),
                'operation': 'task_creation'
            }
            
            # Log the error with context
            tracking_id = error_handler.log_error(e, context, user_fullname)
            
            # Format user-friendly error message
            user_message = error_handler.format_user_error(e, context)
            
            logger.error(f"Stored procedure error [{tracking_id}]: {str(e)}. Parameters: {stored_proc_params}")
            raise TaskCreationError(user_message, 'TASK_CREATION_FAILED', {'tracking_id': tracking_id})
    
    def _convert_time_to_int(self, time_str: str) -> float:
        """
        Convert time string to decimal hours for SQL Server stored procedure.
        
        Examples:
            "5:30" or "5.5" → 5.5
            "17:30" or "17.5" → 17.5
            "5" → 5.0
            "17" → 17.0
            "6:15" → 6.25
            "18:45" → 18.75
            
        Args:
            time_str: Time string in format "HH:MM", "HH", or "HH.H"
            
        Returns:
            float: Decimal hours (e.g., 17.5 for 5:30 PM)
        """
        try:
            # Handle None or empty string
            if not time_str:
                return 19.0  # Default to 7 PM
            
            time_str = str(time_str).strip()
            
            # Check if already in decimal format (e.g., "17.5")
            if '.' in time_str and ':' not in time_str:
                return float(time_str)
            
            # Handle HH:MM format
            if ':' in time_str:
                time_parts = time_str.split(':')
                hours = int(time_parts[0])
                minutes = int(time_parts[1]) if len(time_parts) > 1 else 0
                
                # Convert minutes to decimal (30 minutes = 0.5 hours)
                decimal_hours = hours + (minutes / 60.0)
                return decimal_hours
            
            # Handle plain hour format (e.g., "17" or "5")
            return float(time_str)
            
        except Exception as e:
            logger.warning(f"Error converting time '{time_str}' to decimal hours: {e}. Using default 19.0")
            return 19.0  # Default to 7 PM (19 hours)
    
    def _handle_batch_task_creation(self, batch_tasks: List[str], base_params: Dict[str, Any], 
                                  user_fullname: str, user_timezone: str, debug_mode: bool = False) -> Dict[str, Any]:
        """Handle creation of multiple tasks in a batch."""
        logger.info(f"Starting batch task creation for {len(batch_tasks)} tasks")
        created_tasks = []
        failed_tasks = []
        
        for task_name in batch_tasks:
            batch_params = base_params.copy()
            batch_params['TaskName'] = task_name.strip()
            
            # Skip if task name is empty
            if not batch_params['TaskName']:
                continue
            
            try:
                # Validate batch task parameters
                ValidationService.validate_task_name(batch_params['TaskName'])
                if 'Assignees' in batch_params:
                    ValidationService.validate_assignees(batch_params['Assignees'])
                
                # Apply defaults and automatic parameters for each task
                batch_params = DateTimeService.set_default_due_date_time(batch_params, user_timezone)
                batch_params = self._set_automatic_parameters(batch_params, user_timezone)
                batch_params = self._convert_parameter_types(batch_params)
                
                # Create the task
                instance_id = self._create_single_task(batch_params, user_fullname, debug_mode)
                
                if instance_id:
                    created_tasks.append((batch_params['TaskName'], instance_id))
                    logger.debug(f"Successfully created batch task: {batch_params['TaskName']} with ID: {instance_id}")
                else:
                    failed_tasks.append((batch_params['TaskName'], "Task creation failed"))
                    
            except Exception as e:
                logger.error(f"Failed to create batch task '{batch_params['TaskName']}': {e}")
                failed_tasks.append((batch_params['TaskName'], str(e)))
        
        # Build response
        if created_tasks:
            task_list_items = []
            instance_ids = []
            for task_info in created_tasks:
                if isinstance(task_info, tuple):
                    task_name, instance_id = task_info
                    if instance_id:
                        task_list_items.append(f"• {task_name} (ID: {instance_id})")
                        instance_ids.append(instance_id)
                    else:
                        task_list_items.append(f"• {task_name}")
                else:
                    task_list_items.append(f"• {task_info}")
            
            task_list = '\n'.join(task_list_items)
            response_msg = f"I've created {len(created_tasks)} tasks:\n{task_list}"
            
            if failed_tasks:
                failed_list = '\n'.join([f"• {t}: {err}" for t, err in failed_tasks])
                response_msg += f"\n\nFailed to create {len(failed_tasks)} tasks:\n{failed_list}"
            
            response_data = {'reply': response_msg}
            
            if instance_ids:
                response_data['instance_ids'] = instance_ids
            
            if debug_mode:
                response_data['debug'] = {'created': created_tasks, 'failed': failed_tasks}
            
            return response_data
        else:
            error_msg = 'Failed to create any tasks from the batch'
            if debug_mode:
                return {'error': error_msg, 'debug': {'failed': failed_tasks}}
            else:
                raise TaskCreationError(error_msg)
    
    def _build_success_response(self, params: Dict[str, Any], instance_id: int, main_controller: str) -> Dict[str, Any]:
        """Build a conversational success response."""
        task_name = params.get('TaskName', 'the task')
        
        # Format the due date nicely
        due_date_str = ""
        if params.get('DueDate'):
            try:
                due_date = datetime.datetime.strptime(params['DueDate'], '%Y-%m-%d')
                due_date_str = due_date.strftime('%A, %b %d')
            except:
                due_date_str = params['DueDate']
        
        # Format time nicely
        time_str = ""
        if params.get('DueTime') and params['DueTime'] != '19:00':
            try:
                time_obj = datetime.datetime.strptime(params['DueTime'], '%H:%M')
                time_str = f" at {time_obj.strftime('%-I:%M %p').lower()}"
            except:
                time_str = f" at {params['DueTime']}"
        
        # Build assignee string
        assignee_str = ""
        if params.get('Assignees') and params['Assignees'] != main_controller:
            assignees_list = [a.strip() for a in params['Assignees'].split(',')]
            if len(assignees_list) == 1:
                assignee_str = f", assigned to {assignees_list[0]}"
            elif len(assignees_list) == 2:
                assignee_str = f", assigned to {assignees_list[0]} and {assignees_list[1]}"
            else:
                assignee_str = f", assigned to {', '.join(assignees_list[:-1])}, and {assignees_list[-1]}"
        
        # Build the conversational response
        if due_date_str:
            reply = f"✓ I've created '{task_name}' for {due_date_str}{time_str}{assignee_str}."
        else:
            reply = f"✓ I've created '{task_name}'{assignee_str}."
        
        # Add recurrence info if applicable
        if params.get('IsRecurring') == 1:
            freq_type = params.get('FreqType', 0)
            freq_interval = params.get('FreqInterval', 1)
            freq_recurrance = params.get('FreqRecurrance', 1)
            
            # Debug logging
            logger.info(f"DEBUG: Response generation - FreqType: {freq_type}, FreqInterval: {freq_interval}, FreqRecurrance: {freq_recurrance}")
            logger.info(f"DEBUG: Full params: {params}")
            
            # Weekly special-case: use FreqRecurrance (number of weeks between occurrences)
            if freq_type == 3:
                if freq_recurrance == 1:
                    freq_text = 'weekly'
                elif freq_recurrance == 2:
                    freq_text = 'every 2 weeks'
                else:
                    freq_text = f'every {freq_recurrance} weeks'
            else:
                # Base frequency names aligned with system enums:
                # 2=daily (days), 4=monthly (months), 5=yearly (years)
                base_freq_map = {2: 'day', 4: 'month', 5: 'year'}
                base_freq = base_freq_map.get(freq_type, 'interval')
                
                if freq_type == 4:
                    # Monthly: describe using the month interval (FreqRecurrance)
                    if freq_recurrance == 1:
                        freq_text = 'monthly'
                    else:
                        freq_text = f'every {freq_recurrance} months'
                elif freq_type == 5:
                    # Yearly: use FreqRecurrance for interval count, FreqInterval contains month bitmask
                    if freq_recurrance == 1:
                        freq_text = 'yearly'
                    else:
                        freq_text = f'every {freq_recurrance} years'
                elif freq_type == 2:
                    # Daily: use FreqRecurrance for interval count, FreqInterval contains day bitmask
                    if freq_recurrance == 1:
                        freq_text = 'daily'
                    else:
                        freq_text = f'every {freq_recurrance} days'
                elif freq_type == 4 and freq_interval == 4095:
                    # Month bitmask of all months -> monthly
                    freq_text = 'monthly'
                else:
                    # General case: "every N [units]"
                    plural_s = 's' if freq_interval > 1 else ''
                    freq_text = f'every {freq_interval} {base_freq}{plural_s}'
            
            reply += f" This will repeat {freq_text}."
        
        logger.info(f"API SUCCESS: Returning instance_id={instance_id}")
        
        return {
            'reply': reply,
            'instance_id': instance_id
        }

    def _handle_status_report_connection(self, session: Dict[str, Any], user_message: str, instance_id: int, params: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Handle the status report connection workflow.
        
        Args:
            session: Current session data
            user_message: User's current message
            instance_id: Created task instance ID
            params: Task parameters
            
        Returns:
            Dictionary with workflow response if active, None otherwise
        """
        logger.info(f"STATUS REPORT CONNECTION: Method called with message: '{user_message[:100]}...'")
        try:
            # Get session data for status report connection workflow
            # session is a PendingTaskSession object, not a dictionary
            session_data = getattr(session, 'data', {}) if hasattr(session, 'data') else {}
            
            logger.info(f"STATUS REPORT CONNECTION: Starting workflow for message: '{user_message[:100]}...'")
            logger.info(f"STATUS REPORT CONNECTION: Instance ID: {instance_id}")
            logger.info(f"STATUS REPORT CONNECTION: Session data: {session_data}")
            
            # Handle the connection workflow
            workflow_result = self.status_report_connection_service.handle_connection_workflow(
                session_data, user_message, instance_id
            )
            
            logger.info(f"STATUS REPORT CONNECTION: Workflow result: {workflow_result}")
            
            # Update session data
            session.parameters['data'] = session_data
            logger.info(f"STATUS REPORT CONNECTION: Saving session with data: {session_data}")
            
            # Check if workflow is active
            if workflow_result.get('workflow_step') != 'none':
                SessionService.save_session(session)
                logger.info(f"STATUS REPORT CONNECTION: Session saved, returning workflow response")
                return {
                    'workflow_active': True,
                    'reply': workflow_result.get('message', ''),
                    'workflow_step': workflow_result.get('workflow_step'),
                    'session_data': session_data
                }
            
            return None
            
        except Exception as e:
            logger.error(f"Error handling status report connection: {e}")
            return None