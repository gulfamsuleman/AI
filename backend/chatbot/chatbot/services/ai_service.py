"""
AI Service Module

This module provides centralized AI functionality for the chatbot application,
including Claude API integration, request handling, and response processing.
"""

import os
import json
import re
import time
import logging
import requests
import csv
from datetime import datetime
from typing import Dict, Any, Tuple, Optional, List

from ..config.prompts import SystemPrompts, PromptHints
from .error_handler import error_handler, AIServiceError, retry_ai_service_call

logger = logging.getLogger(__name__)


# AIServiceError is now imported from error_handler


class AIService:
    """
    Service class for handling Groq AI API interactions, including
    configuration, request processing, and response parsing.
    """
    
    def __init__(self):
        """Initialize the AI service with Groq API configuration."""
        self.api_key = os.getenv('CLAUDE_API_KEY')
        if not self.api_key:
            raise ValueError("CLAUDE_API_KEY environment variable is not set. Please set it in your .env file or environment.")
        
        # Anthropic Messages API endpoint
        self.api_url = 'https://api.anthropic.com/v1/messages'
        self.model = 'claude-opus-4-1-20250805'
        self.max_tokens = 1024
        
        # Default headers for Anthropic API
        self.headers = {
            'x-api-key': self.api_key,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json'
        }
        
        # Retry configuration
        self.max_retries = 2
        self.base_timeout = 30
        
        # Token usage tracking
        self.token_log_file = os.path.join(os.path.dirname(__file__), '../../token_usage.csv')
        self._ensure_token_log_file()
    
    def _ensure_token_log_file(self):
        """Ensure the token usage CSV file exists with headers."""
        if not os.path.exists(self.token_log_file):
            with open(self.token_log_file, 'w', newline='') as f:
                writer = csv.writer(f)
                writer.writerow(['timestamp', 'model', 'input_tokens', 'output_tokens', 'total_tokens', 'cost_usd', 'success', 'error'])
    
    def _log_token_usage(self, model: str, input_tokens: int, output_tokens: int, success: bool = True, error: str = ''):
        """Log token usage to CSV file."""
        total_tokens = input_tokens + output_tokens
        
        # Calculate cost based on Claude model pricing (prices per million tokens)
        if 'claude-opus' in model.lower():
            # Claude Opus: $15.00 input, $75.00 output per million
            cost = (input_tokens * 15.00 / 1_000_000) + (output_tokens * 75.00 / 1_000_000)
        elif 'claude-sonnet' in model.lower():
            # Claude Sonnet: $3.00 input, $15.00 output per million
            cost = (input_tokens * 3.00 / 1_000_000) + (output_tokens * 15.00 / 1_000_000)
        elif 'claude-haiku' in model.lower():
            # Claude Haiku: $0.25 input, $1.25 output per million
            cost = (input_tokens * 0.25 / 1_000_000) + (output_tokens * 1.25 / 1_000_000)
        else:
            # Default to Claude Opus pricing if unknown
            cost = (input_tokens * 15.00 / 1_000_000) + (output_tokens * 75.00 / 1_000_000)
        
        timestamp = datetime.now().isoformat()
        
        try:
            with open(self.token_log_file, 'a', newline='') as f:
                writer = csv.writer(f)
                writer.writerow([timestamp, model, input_tokens, output_tokens, total_tokens, f"{cost:.6f}", success, error])
            logger.debug(f"Logged token usage: {input_tokens} input, {output_tokens} output, ${cost:.6f}")
        except Exception as e:
            logger.error(f"Failed to log token usage: {e}")
    
    def calculate_timeout(self, message_length: int, is_batch: bool = False, is_complex_recurring: bool = False) -> int:
        """
        Calculate dynamic timeout based on request complexity.
        
        Args:
            message_length (int): Length of the user message
            is_batch (bool): Whether this is a batch request
            is_complex_recurring (bool): Whether this involves complex recurring patterns
            
        Returns:
            int: Timeout in seconds
        """
        timeout = self.base_timeout
        
        if message_length > 200:
            timeout += 15
        if is_batch:
            timeout += 20
        if is_complex_recurring:
            timeout += 10
            
        return timeout
    
    def send_request_to_claude(self, messages: List[Dict], system_prompt: str, 
                              timeout: int, debug_mode: bool = False) -> Tuple[bool, Dict[str, Any]]:
        """
        Send a request to Anthropic Messages API with retry logic and error handling.
        
        Args:
            messages (List[Dict]): Conversation history messages
            system_prompt (str): System prompt for the conversation
            timeout (int): Request timeout in seconds
            debug_mode (bool): Enable debug logging
            
        Returns:
            Tuple[bool, Dict]: (success, response_data)
        """
        # Anthropic uses Messages API: system prompt is a separate field, messages are role+content strings
        anthropic_messages = []
        for msg in messages:
            role = msg.get('role')
            content = msg.get('content')
            if role in ('user', 'assistant') and isinstance(content, str):
                anthropic_messages.append({"role": role, "content": content})
        
        # If no valid messages, ensure at least the user input is present
        if not anthropic_messages and messages:
            last = messages[-1]
            anthropic_messages = [{"role": "user", "content": last.get('content', '')}]

        payload = {
            'model': self.model,
            'max_tokens': self.max_tokens,
            'temperature': 0.1,
            'system': system_prompt,
            'messages': anthropic_messages
        }
        
        try:
            logger.debug(f"Sending Anthropic API request")
            logger.debug(f"Payload: {json.dumps(payload, indent=2)}")
            response = requests.post(self.api_url, headers=self.headers, json=payload, timeout=timeout)
            response_data = response.json()
            
            if response.status_code != 200:
                # Anthropic returns error details under 'error'
                error_message = response_data.get("error", {}).get("message", str(response_data))
                logger.error(f"Anthropic API error: Status {response.status_code}, Response: {response_data}")
                
                # Log failed request with available token info
                if 'usage' in response_data:
                    input_tokens = response_data['usage'].get('input_tokens', 0)
                    output_tokens = response_data['usage'].get('output_tokens', 0)
                    self._log_token_usage(self.model, input_tokens, output_tokens, success=False, error=error_message)
                
                raise AIServiceError(f'LLM error: {error_message}', 'GROQ_API_ERROR')
            
            # Validate response structure
            if 'content' not in response_data or not response_data['content']:
                logger.error(f"No content in Anthropic response: {response_data}")
                raise AIServiceError('Invalid LLM response format', 'INVALID_RESPONSE_FORMAT')
            
            # Extract content from response (Anthropic-style)
            content_blocks = response_data['content']
            # Concatenate text blocks
            content_texts = []
            for block in content_blocks:
                if isinstance(block, dict) and block.get('type') == 'text':
                    content_texts.append(block.get('text', ''))
                elif isinstance(block, str):
                    content_texts.append(block)
            content = "\n".join([t for t in content_texts if t])
            
            # Extract and log token usage
            if 'usage' in response_data:
                input_tokens = response_data['usage'].get('input_tokens', 0)
                output_tokens = response_data['usage'].get('output_tokens', 0)
                self._log_token_usage(self.model, input_tokens, output_tokens, success=True)
                logger.info(f"Token usage - Input: {input_tokens}, Output: {output_tokens}")
            
            # Log the response for debugging
            if debug_mode:
                logger.info(f"Groq raw response: {content}")
            else:
                logger.debug(f"Groq raw response: {content[:500]}...")
            
            return True, {'content': content, 'raw_response': response_data}
            
        except requests.exceptions.Timeout as e:
            logger.error(f"Groq API timeout: {e}")
            raise AIServiceError('Request timeout - please try again', 'GROQ_API_TIMEOUT')
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Groq API request error: {e}")
            raise AIServiceError('Failed to communicate with AI service', 'GROQ_API_REQUEST_ERROR')
            
        except AIServiceError:
            # Re-raise AIServiceError as-is
            raise
            
        except Exception as e:
            logger.error(f"Unexpected error calling Groq API: {type(e).__name__}: {e}")
            error_handler.log_error(e, {'operation': 'groq_api_call'})
            raise AIServiceError('Sorry, I could not understand the AI response. Please try again.', 'UNEXPECTED_ERROR')
    
    def parse_json_response(self, content: str) -> Tuple[bool, Dict[str, Any]]:
        """
        Parse JSON from Claude's response content.
        
        Args:
            content (str): Raw response content from Claude
            
        Returns:
            Tuple[bool, Dict]: (is_json_response, parsed_json)
        """
        # First try to find JSON block in code fence
        json_match = re.search(r'```json\s*(\{[\s\S]*?\})\s*```', content)
        if not json_match:
            # Try to find any JSON object
            json_match = re.search(r'\{[\s\S]*?\}', content)
        
        if json_match:
            try:
                json_str = json_match.group(1) if '```' in content else json_match.group(0)
                parsed_json = json.loads(json_str)
                logger.debug(f"Successfully parsed JSON from Claude response")
                return True, parsed_json
            except json.JSONDecodeError as e:
                logger.error(f"JSON parsing error: {e}, Content: {json_match.group(0)[:200]}...")
                return False, {}
        else:
            logger.warning(f"No JSON found in response: {content[:200]}...")
            return False, {}
    
    def validate_and_process_alert_parameters(self, llm_json: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate and process alert parameters extracted by AI.
        Ensures alert parameters are properly formatted and consistent.
        
        Args:
            llm_json: JSON response from AI containing task parameters
            
        Returns:
            Dict with validated and processed parameters
        """
        if not llm_json.get('_alert_required'):
            return llm_json
        
        logger.info("Processing AI-extracted alert parameters")
        
        # Validate and set default values for alert parameters
        alert_params = {
            '_alert_required': True,
            '_alert_recipient': llm_json.get('_alert_recipient', 'task_assignee'),
            '_alert_condition': llm_json.get('_alert_condition', 'at_due'),
            '_alert_type': llm_json.get('_alert_type', 'reminder'),
            '_alert_custom_message': llm_json.get('_alert_custom_message', ''),
            '_alert_due_time_hours': llm_json.get('_alert_due_time_hours', 9.0)
        }
        
        # Validate alert type mapping
        alert_type_mapping = {
            'overdue': 'Overdue',
            'at_due': 'Reminder',
            'assignment': 'Assignment',
            'schedule': 'Schedule',
            'complete': 'Complete',
            'hours': 'Hours',
            'custom': 'Custom',
            'reminder': 'Reminder'
        }
        
        condition = alert_params['_alert_condition']
        if condition in alert_type_mapping:
            alert_params['_alert_type'] = alert_type_mapping[condition]
        
        # Log the processed alert parameters
        logger.info("AI-EXTRACTED ALERT PARAMETERS:")
        logger.info(f"  Alert required: {alert_params['_alert_required']}")
        logger.info(f"  Alert recipient: {alert_params['_alert_recipient']}")
        logger.info(f"  Alert condition: {alert_params['_alert_condition']}")
        logger.info(f"  Alert type: {alert_params['_alert_type']}")
        logger.info(f"  Alert time (hours): {alert_params['_alert_due_time_hours']}")
        if alert_params['_alert_custom_message']:
            logger.info(f"  Custom message: {alert_params['_alert_custom_message']}")
        
        # Update the original parameters
        llm_json.update(alert_params)
        return llm_json
    
    def process_task_extraction(self, user_message: str, main_controller: str, 
                               current_date, pre_extracted: Dict[str, Any], 
                               history: List[Dict], debug_mode: bool = False) -> Tuple[bool, Dict[str, Any], str]:
        """
        Process task parameter extraction using Groq AI.
        
        Args:
            user_message (str): User's input message
            main_controller (str): Main controller name
            current_date: Current date object
            pre_extracted (Dict): Pre-extracted parameters
            history (List[Dict]): Conversation history
            debug_mode (bool): Enable debug mode
            
        Returns:
            Tuple[bool, Dict, str]: (success, extracted_params, response_content)
        """
        # Generate hint text from pre-extracted parameters
        pre_extracted_with_message = pre_extracted.copy()
        pre_extracted_with_message['_original_message'] = user_message
        hint_text = PromptHints.generate_hint_text(pre_extracted_with_message)
        
        # Generate system prompt
        system_prompt = SystemPrompts.get_task_extraction_prompt(
            current_date, main_controller, hint_text
        )
        
        # Calculate timeout based on request complexity
        message_length = len(user_message)
        is_batch = '_batch_tasks' in pre_extracted
        is_complex_recurring = (pre_extracted.get('IsRecurring') == 1 and 
                               pre_extracted.get('FreqType', 0) in [5, 6])
        
        timeout = self.calculate_timeout(message_length, is_batch, is_complex_recurring)
        
        logger.debug(f"Using API timeout: {timeout}s (message_length={message_length}, "
                    f"batch={is_batch}, complex_recurring={is_complex_recurring})")
        
        # CRITICAL: Validate history before sending to Claude API
        # WARNING: Conversation history can contaminate parameter extraction if not properly managed!
        # Previous assignee names or task details could leak into new task creation requests.
        if not history or len(history) == 0:
            logger.warning("Empty history detected, creating fallback message")
            history = [{"role": "user", "content": user_message}]
        
        # Ensure all messages have required fields
        validated_history = []
        for msg in history:
            if isinstance(msg, dict) and 'role' in msg and 'content' in msg:
                validated_history.append(msg)
            else:
                logger.warning(f"Invalid message format in history: {msg}")
        
        if not validated_history:
            validated_history = [{"role": "user", "content": user_message}]
            logger.warning("No valid messages in history, using fallback")
        
        # Log the conversation history being sent to Claude for debugging
        logger.info(f"=== CONVERSATION HISTORY SENT TO CLAUDE ({len(validated_history)} messages) ===")
        for i, msg in enumerate(validated_history):
            content_preview = msg['content'][:100] + '...' if len(msg['content']) > 100 else msg['content']
            logger.info(f"  [{i+1}] {msg['role']}: {content_preview}")
        logger.info(f"=== END CONVERSATION HISTORY ===")
        
        # Send request to Claude
        try:
            success, response_data = self.send_request_to_claude(
                validated_history, system_prompt, timeout, debug_mode
            )
        except AIServiceError as e:
            error_handler.log_error(e, {'operation': 'task_extraction', 'message_length': message_length})
            return False, {}, str(e)
        
        if not success:
            return False, {}, response_data.get('error', 'Unknown error')
        
        content = response_data['content']
        
        # Parse JSON from response
        is_json_response, parsed_json = self.parse_json_response(content)
        
        if is_json_response:
            # Debug logging for parameter analysis
            logger.info("="*60)
            logger.info("PARAMETER EXTRACTION DEBUG")
            logger.info(f"Pre-extracted params: {pre_extracted}")
            logger.info(f"LLM JSON params: {parsed_json}")
            
            # Special debug for UC08 monthly pattern
            if "on the" in user_message.lower() and "month" in user_message.lower():
                logger.warning(f"UC08 PATTERN DETECTED: Monthly with specific day")
                logger.warning(f"User message: {user_message}")
                logger.warning(f"Claude's FreqType: {parsed_json.get('FreqType')}")
                logger.warning(f"Claude's FreqRecurrance: {parsed_json.get('FreqRecurrance')}")
                logger.warning(f"Claude's FreqInterval: {parsed_json.get('FreqInterval')}")
            
            # Validate and process alert parameters extracted by AI
            parsed_json = self.validate_and_process_alert_parameters(parsed_json)
            
            # Debug: Log what the AI returned for DueDate
            if 'DueDate' in parsed_json:
                logger.debug(f"AI returned DueDate: '{parsed_json['DueDate']}' (type: {type(parsed_json['DueDate'])})")
            
            # Merge pre-extracted parameters with LLM parameters
            # Include the original message in pre_extracted for pattern matching
            pre_extracted_with_message = pre_extracted.copy()
            pre_extracted_with_message['_original_message'] = user_message
            final_params = self._merge_parameters(parsed_json, pre_extracted_with_message)
            
            logger.info(f"Final merged params: {final_params}")
            logger.info("="*60)
            
            return True, final_params, content
        else:
            # Return the text response if no JSON was found
            return False, {}, content
    
    def _merge_parameters(self, llm_json: Dict[str, Any], pre_extracted: Dict[str, Any]) -> Dict[str, Any]:
        """
        Merge pre-extracted parameters with LLM-extracted parameters.
        
        Args:
            llm_json (Dict): Parameters extracted by LLM
            pre_extracted (Dict): Pre-extracted parameters
            
        Returns:
            Dict: Merged parameters with proper precedence
        """
        merged = llm_json.copy()
        
        # Special handling for schedule parser results - they should take precedence
        # BUT: Don't override AI's correct interpretation for "next [weekday]" patterns
        if pre_extracted.get('IsRecurring') == 1:
            # Check if this might be a "next [weekday]" pattern that should be non-recurring
            msg_lower = pre_extracted.get('_original_message', '').lower()
            next_weekday_patterns = [
                r'next\s+(?:week\s+)?(?:on\s+)?(monday|tuesday|wednesday|thursday|friday|saturday|sunday)',
                r'(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\s+next\s+week'
            ]
            
            is_next_weekday = any(re.search(pattern, msg_lower) for pattern in next_weekday_patterns)
            
            if is_next_weekday and merged.get('IsRecurring') == 0:
                logger.warning(f"Schedule parser incorrectly detected recurring pattern for 'next [weekday]' - using AI's non-recurring interpretation")
                # Keep AI's non-recurring interpretation
                merged['IsRecurring'] = 0
                merged['FreqType'] = 0
                merged['FreqRecurrance'] = 0
                merged['FreqInterval'] = 0  # Non-recurring task
            else:
                # If schedule parser detected recurring pattern, preserve its parameters
                schedule_params = ['IsRecurring', 'FreqType', 'FreqInterval', 'FreqRecurrance', 'BusinessDayBehavior']
                for param in schedule_params:
                    if param in pre_extracted and pre_extracted[param] is not None:
                        if param in merged and merged[param] != pre_extracted[param]:
                            logger.warning(f"Schedule parser {param}={pre_extracted[param]} overriding LLM {param}={merged.get(param)}")
                        merged[param] = pre_extracted[param]
                        logger.debug(f"Using schedule parser value for {param}: {pre_extracted[param]}")
                # Add explicit logging for FreqRecurrance debugging
                logger.info(f"FREQ_DEBUG: After merge, FreqRecurrance={merged.get('FreqRecurrance')} (from schedule parser={pre_extracted.get('FreqRecurrance')})")
        
        for key, value in pre_extracted.items():
            # Skip internal pre-extraction markers, but preserve alert and status report parameters
            if key.startswith('_') and not (key.startswith('_alert_') or key.startswith('_status_report_')):
                continue
            
            # Skip schedule params already handled above
            if pre_extracted.get('IsRecurring') == 1 and key in ['IsRecurring', 'FreqType', 'FreqInterval', 'FreqRecurrance', 'BusinessDayBehavior']:
                continue
                
            # Special handling for AddToPriorityList - always preserve if set to 1
            if key == 'AddToPriorityList' and value == 1:
                merged[key] = value
                logger.debug(f"Preserving pre-extracted AddToPriorityList=1")
            elif key not in merged or merged[key] in [None, '', 0]:
                merged[key] = value
                logger.debug(f"Using pre-extracted value for {key}: {value}")
            elif merged[key] != value:
                logger.debug(f"LLM overrode pre-extracted {key}: {value} -> {merged[key]}")
                # Special case: don't let LLM override priority list to 0 if we detected it
                if key == 'AddToPriorityList' and value == 1 and merged[key] == 0:
                    logger.warning(f"LLM tried to override AddToPriorityList from 1 to 0, keeping 1")
                    merged[key] = 1
        
        # CRITICAL FIX: Set IsRecurring to 0 by default if not explicitly set
        if 'IsRecurring' not in merged or merged['IsRecurring'] is None:
            merged['IsRecurring'] = 0
            logger.debug("Set IsRecurring to 0 (default for non-recurring tasks)")
        
        # Force non-recurring for "next [weekday]" patterns (including "next week Monday" and "Monday next week")
        msg_lower = pre_extracted.get('_original_message', '').lower()
        next_weekday_patterns = [
            r'next\s+(?:week\s+)?(monday|tuesday|wednesday|thursday|friday|saturday|sunday)',
            r'(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\s+next\s+week'
        ]
        
        # Force non-recurring for "due in X weeks/days/months" patterns
        due_in_patterns = [
            r'due\s+in\s+\d+\s+(weeks?|days?|months?)',
            r'in\s+\d+\s+(weeks?|days?|months?)',
            r'\d+\s+(weeks?|days?|months?)\s+(from\s+now|later)'
        ]
        
        # Force non-recurring for "next quarter" patterns (should be 90 days, not recurring)
        next_quarter_patterns = [
            r'next\s+quarter',
            r'due\s+next\s+quarter',
            r'by\s+next\s+quarter'
        ]
        
        for pattern in next_weekday_patterns:
            match = re.search(pattern, msg_lower)
            if match:
                if merged.get('IsRecurring') == 1:
                    logger.warning(f"LLM incorrectly set IsRecurring=1 for 'next [weekday]' pattern '{match.group(0)}'. Forcing to 0.")
                merged['IsRecurring'] = 0
                merged['FreqType'] = 0
                merged['FreqRecurrance'] = 0
                merged['FreqInterval'] = 0
                logger.debug(f"Forced IsRecurring=0 for 'next [weekday]' pattern '{match.group(0)}'")
                break
        
        # Check for "due in X weeks/days/months" patterns
        for pattern in due_in_patterns:
            match = re.search(pattern, msg_lower)
            if match:
                if merged.get('IsRecurring') == 1:
                    logger.warning(f"LLM incorrectly set IsRecurring=1 for 'due in X time' pattern '{match.group(0)}'. Forcing to 0.")
                merged['IsRecurring'] = 0
                merged['FreqType'] = 0
                merged['FreqRecurrance'] = 0
                merged['FreqInterval'] = 0
                logger.debug(f"Forced IsRecurring=0 for 'due in X time' pattern '{match.group(0)}'")
                break
        
        # Check for "next quarter" patterns (should be 90 days, not recurring)
        for pattern in next_quarter_patterns:
            match = re.search(pattern, msg_lower)
            if match:
                if merged.get('IsRecurring') == 1:
                    logger.warning(f"LLM incorrectly set IsRecurring=1 for 'next quarter' pattern '{match.group(0)}'. Forcing to 0.")
                merged['IsRecurring'] = 0
                merged['FreqType'] = 0
                merged['FreqRecurrance'] = 0
                merged['FreqInterval'] = 0
                
                # Override the DueDate to "next quarter" string so it gets parsed as 90 days
                merged['DueDate'] = 'next quarter'
                logger.debug(f"Forced IsRecurring=0 and DueDate='next quarter' for pattern '{match.group(0)}'")
                break
        
        return merged
    
    def check_conditional_logic(self, user_message: str) -> bool:
        """
        Check if user message contains conditional logic patterns.
        
        Args:
            user_message (str): User's input message
            
        Returns:
            bool: True if conditional logic is detected
        """
        msg_lower = user_message.lower()
        patterns = SystemPrompts.get_conditional_logic_patterns()
        
        for pattern in patterns:
            if re.search(pattern, msg_lower):
                logger.debug("Detected conditional logic in message")
                return True
        
        return False
    
    def get_conditional_logic_error(self) -> str:
        """
        Get the error message for conditional logic rejection.
        
        Returns:
            str: Error message
        """
        return SystemPrompts.get_conditional_logic_error_message()