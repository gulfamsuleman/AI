"""
Parameter Extractor Module

This module provides intelligent parameter extraction using both traditional regex patterns
and advanced MCP (Model Context Protocol) service with vector similarity.
"""

import re
import logging
import datetime
from typing import Dict, Any, List, Optional
from .mcp_service import MCPService

logger = logging.getLogger(__name__)

class ParameterExtractor:
    """
    Enhanced Parameter Extractor that combines traditional regex patterns with
    advanced MCP service using vector similarity and cosine similarity.
    """
    
    @staticmethod
    def extract_individual_names_from_sentence(sentence: str) -> List[str]:
        """
        Extract individual names from a sentence, filtering out common words.
        
        Args:
            sentence: Input sentence like "Sameer the controller being Ken"
            
        Returns:
            List of potential names like ["Sameer", "Ken"]
        """
        if not sentence or not sentence.strip():
            return []
        
        # Common words to filter out
        filter_words = {
            'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 
            'of', 'with', 'by', 'from', 'up', 'about', 'into', 'through', 'during',
            'before', 'after', 'above', 'below', 'between', 'among', 'under', 'over',
            'controller', 'being', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
            'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should',
            'may', 'might', 'must', 'can', 'shall', 'this', 'that', 'these', 'those'
        }
        
        # Split sentence into words and filter
        words = sentence.split()
        potential_names = []
        
        for word in words:
            # Clean the word (remove punctuation)
            clean_word = re.sub(r'[^\w]', '', word)
            
            # Skip if it's a common word or too short
            if (clean_word.lower() in filter_words or 
                len(clean_word) < 2 or 
                clean_word.isdigit()):
                continue
                
            # Check if it looks like a name (starts with capital letter)
            if clean_word and clean_word[0].isupper():
                potential_names.append(clean_word)
        
        logger.info(f"Extracted potential names from '{sentence}': {potential_names}")
        return potential_names
    
    def __init__(self, schedule_parser=None):
        # Initialize the MCP service for intelligent intent detection
        try:
            self.mcp_service = MCPService()
            logger.info("MCP Service initialized successfully with vector similarity")
        except Exception as e:
            logger.warning(f"MCP Service initialization failed: {e}. Falling back to regex patterns.")
            self.mcp_service = None
        
        # Initialize schedule parser (either passed in or create new one)
        if schedule_parser:
            self.schedule_parser = schedule_parser
            logger.debug("Schedule parser provided externally")
        else:
            try:
                from schedule_parser import ScheduleParser
                self.schedule_parser = ScheduleParser()
                logger.debug("Schedule parser initialized")
            except ImportError:
                logger.debug("Schedule parser not available")
                self.schedule_parser = None
        
    def pre_extract_parameters(self, user_message: str, main_controller: str, current_date: datetime.date) -> Dict[str, Any]:
        """
        Pre-process the message to extract obvious patterns before AI processing.
        
        Args:
            user_message: User's task creation message
            main_controller: Main controller/group
            current_date: Current date in user's timezone
            
        Returns:
            Dictionary of pre-extracted parameters
        """
        pre_extracted = {}
        msg_lower = user_message.lower()
        
        # Pre-extract reminder settings
        if 'remind me' in msg_lower:
            pre_extracted['Assignees'] = main_controller
            pre_extracted['IsReminder'] = 1
            logger.debug("Detected reminder task - setting IsReminder=1")
            
            # Extract the exact task name for reminders
            quoted_task_match = re.search(r"'([^']+)'", user_message)
            if quoted_task_match:
                task_name = quoted_task_match.group(1).strip()
                pre_extracted['TaskName'] = task_name
                logger.debug(f"Pre-extracted reminder task name from quotes: '{task_name}'")
            else:
                # Fallback: Pattern "remind me ... to [task name]" or "remind me at [time] to [task name]"
                remind_match = re.search(r'remind\s+me.*?to\s+(.+?)(?:\s+at\s+|\s+by\s+|$)', msg_lower)
                if remind_match:
                    task_name = remind_match.group(1).strip()
                    task_name = task_name.strip("'\"")
                    if task_name.startswith("follow up on "):
                        task_name = task_name[13:].strip()
                    elif task_name.startswith("follow up with "):
                        # Handle "follow up with [person] on [topic]" pattern
                        task_name = task_name.strip()
                    pre_extracted['TaskName'] = task_name
                    logger.debug(f"Pre-extracted reminder task name: '{task_name}'")
        else:
            # Extract assignees with various patterns, mapping 'me' to the sender (main_controller)
            pre_extracted.update(self.extract_assignees(user_message, main_controller))
        
        # Pre-extract priority list
        if any(keyword in msg_lower for keyword in ['priority list', 'add to priority', 'urgent', 'high priority', 'critical']):
            pre_extracted['AddToPriorityList'] = 1
            logger.debug("Detected priority/urgent task - setting AddToPriorityList=1")
        
        # UC10: Confidential task detection
        if 'confidential' in msg_lower:
            pre_extracted['_is_confidential'] = True
        
        # UC13: Force non-recurring for "next [weekday]" patterns (including "next week Monday" and "Monday next week")
        next_weekday_patterns = [
            r'next\s+(?:week\s+)?(monday|tuesday|wednesday|thursday|friday|saturday|sunday)',
            r'(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\s+next\s+week'
        ]
        
        for pattern in next_weekday_patterns:
            match = re.search(pattern, msg_lower)
            if match:
                pre_extracted['IsRecurring'] = 0
                pre_extracted['FreqType'] = 0
                pre_extracted['FreqRecurrance'] = 0
                pre_extracted['FreqInterval'] = 0
                logger.info(f"UC13: Detected 'next [weekday]' pattern '{match.group(0)}' - forcing non-recurring task")
                break
        
        # UC12: Team assignment parsing
        team_assignment = self.extract_team_assignments(user_message)
        if team_assignment:
            pre_extracted.update(team_assignment)
        
        # UC11: Checklist items extraction
        checklist_items = self.extract_checklist_items(user_message)
        if checklist_items:
            pre_extracted['Items'] = checklist_items
        
        # UC13: Time-based names detection
        time_based = self.extract_time_based_names(msg_lower)
        if time_based:
            pre_extracted.update(time_based)
        
        # UC14: Relative dates parsing
        relative_dates = self.extract_relative_dates(msg_lower, current_date)
        if relative_dates:
            pre_extracted.update(relative_dates)
        
        # UC15: Controller override
        controller_override = self.extract_controller_override(user_message)
        if controller_override:
            pre_extracted.update(controller_override)
        
        # UC16: Multi-controller detection
        multi_controllers = self.extract_multi_controllers(user_message)
        if multi_controllers:
            pre_extracted.update(multi_controllers)
        
        # UC17: Business day handling
        if 'skip weekend' in msg_lower or 'business day' in msg_lower or 'weekday' in msg_lower:
            pre_extracted['BusinessDayBehavior'] = 1
        
        # UC22: Timezone awareness
        timezone_info = self.extract_timezone_aware(user_message)
        if timezone_info:
            pre_extracted.update(timezone_info)
        
        # UC24: Template reference handling
        template_ref = self.extract_template_reference(user_message, main_controller)
        if template_ref:
            pre_extracted.update(template_ref)
        
        # UC23: Batch task creation
        batch_tasks = self.extract_batch_tasks(user_message)
        if batch_tasks:
            pre_extracted['_batch_tasks'] = batch_tasks
        
        # UC30: Custom notifications
        notification_info = self.extract_custom_notifications(msg_lower)
        if notification_info:
            pre_extracted.update(notification_info)

        # UC31: Alert requirements extraction - AI will handle this intelligently
        # The AI service will now intelligently detect alert requirements from natural language
        # We no longer need to rely on brittle regex patterns for alert detection
        logger.debug("Alert detection will be handled by AI service during task extraction")
        
        # Keep minimal regex fallback for very basic patterns only
        basic_alert_info = self.extract_basic_alert_indicators(user_message)
        if basic_alert_info:
            pre_extracted.update(basic_alert_info)

        # UC32: Status report requirements extraction
        status_report_info = self.extract_status_report_requirements(user_message)
        if status_report_info:
            pre_extracted.update(status_report_info)
        
        # Use the schedule parser for recurring patterns
        if self.schedule_parser:
            schedule_params = self.schedule_parser.parse_schedule(user_message)
            if schedule_params['IsRecurring'] == 1:
                pre_extracted.update(schedule_params)
                logger.debug(f"Schedule parser detected recurring pattern: {schedule_params}")
                # Add explicit logging for FreqRecurrance debugging
                logger.info(f"FREQ_DEBUG: Schedule parser returned FreqRecurrance={schedule_params.get('FreqRecurrance')} for message: {user_message[:100]}")
        else:
            # Fallback recurring pattern extraction
            recurring_patterns = self.extract_recurring_patterns(user_message)
            if recurring_patterns:
                pre_extracted.update(recurring_patterns)
        
        # Pre-extract time patterns
        time_patterns = self.extract_time_patterns(msg_lower, current_date)
        if time_patterns:
            pre_extracted.update(time_patterns)
        
        return pre_extracted
    
    def extract_assignees(self, user_message: str, main_controller: str) -> Dict[str, Any]:
        """Extract assignees using various patterns, mapping 'me' to main_controller."""
        assignee_data = {}
        
        # Normalize whitespace for consistent regex behavior
        message = ' '.join(user_message.split())

        # Handle cases where 'me' is explicitly included as an assignee
        # Examples:
        #   - assign to me and John Doe
        #   - for me and Aidan South
        #   - with me and Jane Doe
        #   - to me, John Doe
        me_patterns = [
            r'(?:assign(?:ed)?\s+to|to|for|with)\s+me\s*(?:,|and|&|plus)?\s*(.*?)(?:\.|$)',
            r'\bme\b\s*(?:,|and|&|plus)\s*(.*?)(?:\.|$)'
        ]
        for me_pat in me_patterns:
            me_match = re.search(me_pat, message, re.IGNORECASE)
            if me_match:
                trailing = me_match.group(1).strip() if me_match.lastindex else ''
                names: List[str] = []
                if trailing:
                    parts = re.split(r'\s*,\s*|\s+and\s+|\s+&\s+|\s+plus\s+', trailing)
                    for part in parts:
                        candidate = part.strip()
                        if re.match(r'^[A-Z][a-z]+\s+[A-Z][a-z]+$', candidate):
                            names.append(candidate)
                # Always include main_controller when 'me' is present
                ordered = []
                seen = set()
                for candidate in [main_controller] + names:
                    if candidate and candidate not in seen:
                        seen.add(candidate)
                        ordered.append(candidate)
                if ordered:
                    assignee_data['Assignees'] = ','.join(ordered)
                    return assignee_data

        # Enhanced "with" pattern to handle multiple assignees
        with_pattern = r'with\s+((?:[A-Z][a-z]+\s+[A-Z][a-z]+(?:\s*,?\s*(?:and|&|plus)\s*)?)+)'
        with_match = re.search(with_pattern, message)
        if with_match:
            assignees_text = with_match.group(1)
            assignees = re.split(r'\s*,\s*|\s+and\s+|\s+&\s+|\s+plus\s+', assignees_text)
            assignees = [a.strip() for a in assignees if a.strip() and re.match(r'^[A-Z][a-z]+\s+[A-Z][a-z]+$', a.strip())]
            if assignees:
                assignee_data['Assignees'] = ','.join(assignees)
        else:
            # "for" pattern - handle both names and groups
            for_match = re.search(r'for\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?(?:\s+(?:Team|Group|Department|Control))?)', message)
            if for_match:
                assignee_data['Assignees'] = for_match.group(1)
        
        return assignee_data
    
    def extract_team_assignments(self, user_message: str) -> Dict[str, Any]:
        """Extract team assignment patterns."""
        team_patterns = [
            r'for\s+(\w+)\s+[Tt]eam',  # "for Marketing Team"
            r'[Tt]eam\s+(\w+)\s+to',   # "Team Marketing to"
            r'(\w+)\s+[Tt]eam\s+(?:to|should|will|must)', # "Marketing Team to complete"
        ]
        for pattern in team_patterns:
            team_match = re.search(pattern, user_message)
            if team_match:
                team_name = team_match.group(1)
                logger.debug(f"Detected team assignment: {team_name} Team")
                return {'Assignees': f"{team_name} Team"}
        return {}
    
    def extract_checklist_items(self, user_message: str) -> Optional[str]:
        """Extract checklist items from the message."""
        checklist_match = re.search(r'with\s+(?:checkboxes?|checklist|items)(?:\s+for)?[:\s]+(.+?)(?:\.|$)', user_message, re.IGNORECASE)
        if not checklist_match:
            checklist_match = re.search(r'with\s+items[:\s]+(.+?)(?:\.|$)', user_message, re.IGNORECASE)
        
        if checklist_match:
            items_text = checklist_match.group(1)
            # Split on commas, semicolons, and numbered items
            items = [item.strip() for item in re.split(r'[,;]|\d+\.\s*', items_text) if item.strip()]
            # Remove empty items and clean up
            cleaned_items = []
            for item in items:
                if item and item.strip() and len(item.strip()) > 1:
                    cleaned_items.append(item.strip())
            
            if cleaned_items:
                checklist_items = ','.join(cleaned_items)
                logger.debug(f"Extracted {len(cleaned_items)} checklist items: {checklist_items}")
                return checklist_items
        return None
    
    def extract_time_based_names(self, msg_lower: str) -> Dict[str, Any]:
        """Extract time-based scheduling information."""
        time_data = {}
        if any(time_word in msg_lower for time_word in ['morning', 'afternoon', 'evening', 'night', 'after close', 'after the close', 'after market close', 'after market', 'post-close', 'post close', 'postmarket', 'post-market']):
            # Specific mappings per request
            # "morning" = 10:00
            if 'morning' in msg_lower:
                time_data['DueTime'] = '10:00'
            # "after close" and market-close variants = 15:00
            elif (
                'after close' in msg_lower or
                'after the close' in msg_lower or
                'after market close' in msg_lower or
                'after market' in msg_lower or
                'post-close' in msg_lower or
                'post close' in msg_lower or
                'postmarket' in msg_lower or
                'post-market' in msg_lower
            ):
                time_data['DueTime'] = '15:00'
            # "evening" = 19:00; treat "night" similarly
            elif 'evening' in msg_lower or 'night' in msg_lower:
                time_data['DueTime'] = '19:00'
            # Keep a sensible default for "afternoon" if present and no other mapping applied
            elif 'afternoon' in msg_lower:
                time_data['DueTime'] = '14:00'
        return time_data
    
    def extract_relative_dates(self, msg_lower: str, current_date: datetime.date) -> Dict[str, Any]:
        """Extract relative date patterns."""
        date_data = {}
        
        # Handle "next [weekday]"
        next_day_match = re.search(r'next\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)', msg_lower)
        if next_day_match:
            target_day = next_day_match.group(1)
            days = {
                'monday': 0, 'tuesday': 1, 'wednesday': 2, 'thursday': 3,
                'friday': 4, 'saturday': 5, 'sunday': 6
            }
            target_weekday = days[target_day]
            current_weekday = current_date.weekday()
            days_ahead = (target_weekday - current_weekday) % 7
            if days_ahead == 0:
                days_ahead = 7  # Next week, not today
            target_date = current_date + datetime.timedelta(days=days_ahead)
            date_data['DueDate'] = target_date.strftime('%Y-%m-%d')
            # Explicitly mark as non-recurring for "next [weekday]" patterns
            date_data['IsRecurring'] = 0
            date_data['FreqType'] = 0
        # Handle "tomorrow"
        elif 'tomorrow' in msg_lower:
            tomorrow = current_date + datetime.timedelta(days=1)
            date_data['DueDate'] = tomorrow.strftime('%Y-%m-%d')
        
        return date_data
    
    def extract_controller_override(self, user_message: str) -> Dict[str, Any]:
        """Extract controller override patterns."""
        controller_match = re.search(r'(?:managed|controlled)\s+by\s+([A-Z][a-z]+\s+[A-Z][a-z]+)', user_message)
        if controller_match:
            return {'_override_controller': controller_match.group(1)}
        return {}
    
    def extract_multi_controllers(self, user_message: str) -> Dict[str, Any]:
        """Extract multi-controller patterns."""
        multi_controller_match = re.search(r'controlled\s+by\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?(?:\s+(?:Team|Group|Department))?)(?:\s+and\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?(?:\s+(?:Team|Group|Department))?))+', user_message)
        if multi_controller_match:
            controllers = [multi_controller_match.group(1)]
            if multi_controller_match.group(2):
                controllers.append(multi_controller_match.group(2))
            return {'_multi_controllers': ','.join(controllers)}
        return {}
    
    def extract_business_days(self, user_message: str) -> Dict[str, Any]:
        """Extract business day handling patterns."""
        msg_lower = user_message.lower()
        if 'skip weekend' in msg_lower or 'business day' in msg_lower or 'weekday' in msg_lower:
            return {'BusinessDayBehavior': 1}
        return {}
    
    def extract_timezone_aware(self, user_message: str) -> Dict[str, Any]:
        """Extract timezone information."""
        timezone_match = re.search(r'at\s+\d{1,2}(?::\d{2})?\s*(?:am|pm)?\s+(ET|EST|EDT|PT|PST|PDT|CT|CST|CDT|MT|MST|MDT)', user_message, re.IGNORECASE)
        if timezone_match:
            source_tz = timezone_match.group(1).upper()
            return {'_source_timezone': source_tz}
        return {}
    
    def extract_template_reference(self, user_message: str, main_controller: str) -> Dict[str, Any]:
        """Extract template reference patterns."""
        msg_lower = user_message.lower()
        if 'template' in msg_lower:
            logger.debug(f"Template reference detected - using default assignee: {main_controller}")
            return {'Assignees': main_controller}
        return {}
    
    def extract_batch_tasks(self, user_message: str) -> Optional[List[str]]:
        """Extract batch task creation patterns."""
        msg_lower = user_message.lower()
        
        # Pattern 1: "create tasks:" or "tasks:"
        if 'create tasks:' in msg_lower or 'tasks:' in msg_lower:
            tasks_match = re.search(r'(?:create\s+)?tasks:\s*(.+)', user_message, re.IGNORECASE)
            if tasks_match:
                tasks_text = tasks_match.group(1)
                # First try to find quoted tasks
                quoted_tasks = re.findall(r"'([^']+)'", tasks_text)
                if quoted_tasks:
                    tasks = quoted_tasks
                else:
                    # Fall back to splitting by comma, semicolon
                    tasks = [t.strip() for t in re.split(r'[,;]', tasks_text) if t.strip()]
                
                # Clean up task names
                cleaned_tasks = []
                for task in tasks:
                    task = task.strip().strip("'\"")
                    if task:
                        cleaned_tasks.append(task)
                
                if len(cleaned_tasks) >= 1:
                    logger.debug(f"Detected batch task creation with {len(cleaned_tasks)} tasks")
                    return cleaned_tasks
        
        # Pattern 2: "create tasks for: task1, task2, task3"
        if 'create tasks for:' in msg_lower:
            tasks_match = re.search(r'create\s+tasks\s+for:\s*(.+)', user_message, re.IGNORECASE)
            if tasks_match:
                tasks_text = tasks_match.group(1)
                # Split by comma
                tasks = [t.strip() for t in tasks_text.split(',') if t.strip()]
                
                # Clean up task names
                cleaned_tasks = []
                for task in tasks:
                    task = task.strip().strip("'\"")
                    if task:
                        cleaned_tasks.append(task)
                
                if len(cleaned_tasks) >= 1:
                    logger.debug(f"Detected batch task creation (for pattern) with {len(cleaned_tasks)} tasks")
                    return cleaned_tasks
        
        return None
    
    def extract_custom_notifications(self, msg_lower: str) -> Dict[str, Any]:
        """Extract custom notification patterns."""
        notification_match = re.search(r'(?:email\s+)?notification\s+(\d+)\s+(hour|minute)s?\s+before', msg_lower)
        if notification_match:
            amount = int(notification_match.group(1))
            unit = notification_match.group(2)
            return {
                'IsReminder': 1,
                '_reminder_offset_hours': amount if unit == 'hour' else amount / 60
            }
        return {}
    
    def extract_alert_requirements(self, user_message: str) -> Dict[str, Any]:
        """Extract alert requirements from user messages."""
        alert_data = {}
        msg_lower = user_message.lower()

        # New Pattern: "alert [NAME] about [THING]"
        alert_about_match = re.search(r"\balert\s+([A-Z][A-Za-z\s]+?)\s+about\s+(.+)$", user_message, re.IGNORECASE)
        if alert_about_match:
            raw_recipient = alert_about_match.group(1).strip()
            potential_names = self.extract_individual_names_from_sentence(raw_recipient)
            recipient = potential_names[0] if potential_names else raw_recipient
            alert_data.update({
                '_alert_required': True,
                '_alert_recipient': recipient,
                '_alert_condition': 'at_due',
                '_alert_type': 'reminder'
            })
            logger.info("ALERT REQUIREMENTS DETECTED (about pattern):")
            logger.info(f"  Alert required: True")
            logger.info(f"  Alert recipient: {recipient}")
            logger.info(f"  Alert condition: at_due")
            logger.info(f"  Alert type: reminder")
            return alert_data

        # Pattern 1: "add alert if overdue to [RECIPIENT]" - handles both groups and individuals
        overdue_alert_match = re.search(r'add\s+alert\s+if\s+overdue\s+to\s+([A-Z][A-Za-z\s]+?)(?:\s+with\s+alert\s+message|$)', user_message, re.IGNORECASE)
        if overdue_alert_match:
            raw_recipient = overdue_alert_match.group(1).strip()
            
            # Extract individual names from the sentence
            potential_names = self.extract_individual_names_from_sentence(raw_recipient)
            
            # Use the first extracted name as the recipient, or fall back to raw recipient
            if potential_names:
                recipient = potential_names[0]  # Use first name found
                logger.info(f"Extracted individual name '{recipient}' from sentence '{raw_recipient}'")
            else:
                recipient = raw_recipient
                logger.info(f"Could not extract individual names from '{raw_recipient}', using as-is")
            
            alert_data.update({
                '_alert_required': True,
                '_alert_recipient': recipient,
                '_alert_condition': 'overdue',
                '_alert_type': 'email'
            })
            
            # Check for custom alert message
            custom_message_match = re.search(r'with\s+alert\s+message\s+["\']([^"\']+)["\']', user_message, re.IGNORECASE)
            if custom_message_match:
                alert_data['_alert_custom_message'] = custom_message_match.group(1).strip()
                logger.info(f"  Custom alert message: {alert_data['_alert_custom_message']}")
            
            logger.info("ALERT REQUIREMENTS DETECTED:")
            logger.info(f"  Alert required: True")
            logger.info(f"  Alert recipient: {recipient}")
            logger.info(f"  Alert condition: overdue")
            logger.info(f"  Alert type: email")
            return alert_data

        # Pattern 1b: "add alert if [CONDITION]" - uses task assignee as recipient
        # Make this pattern more specific to avoid conflicts with "add alert if overdue to [RECIPIENT]"
        conditional_alert_match = re.search(r'add\s+alert\s+if\s+(?!overdue\s+to\s+)([A-Za-z\s]+?)(?:\s+with\s+alert\s+message|$)', user_message, re.IGNORECASE)
        if conditional_alert_match:
            condition = conditional_alert_match.group(1).strip()
            # Use task assignee as recipient (will be resolved later)
            alert_data.update({
                '_alert_required': True,
                '_alert_recipient': 'task_assignee',  # Special marker to use task assignee
                '_alert_condition': condition,
                '_alert_type': 'email'
            })
            
            # Check for custom alert message
            custom_message_match = re.search(r'with\s+alert\s+message\s+["\']([^"\']+)["\']', user_message, re.IGNORECASE)
            if custom_message_match:
                alert_data['_alert_custom_message'] = custom_message_match.group(1).strip()
                logger.info(f"  Custom alert message: {alert_data['_alert_custom_message']}")
            
            logger.info("ALERT REQUIREMENTS DETECTED:")
            logger.info(f"  Alert required: True")
            logger.info(f"  Alert recipient: task_assignee (will use task assignee)")
            logger.info(f"  Alert condition: {condition}")
            logger.info(f"  Alert type: email")
            return alert_data

        # Pattern 1c: "add alert for [NAME]" - specific pattern for "for" format
        for_alert_match = re.search(r'add\s+alert\s+for\s+([A-Z][A-Za-z\s]+?)(?:\s+with\s+alert\s+message|$)', user_message, re.IGNORECASE)
        if for_alert_match:
            raw_recipient = for_alert_match.group(1).strip()
            
            # Extract individual names from the sentence
            potential_names = self.extract_individual_names_from_sentence(raw_recipient)
            
            # Use the first extracted name as the recipient, or fall back to raw recipient
            if potential_names:
                recipient = potential_names[0]  # Use first name found
                logger.info(f"Extracted individual name '{recipient}' from sentence '{raw_recipient}'")
            else:
                recipient = raw_recipient
                logger.info(f"Could not extract individual names from '{raw_recipient}', using as-is")
            
            alert_data.update({
                '_alert_required': True,
                '_alert_recipient': recipient,
                '_alert_condition': 'overdue',
                '_alert_type': 'email'
            })
            
            # Check for custom alert message
            custom_message_match = re.search(r'with\s+alert\s+message\s+["\']([^"\']+)["\']', user_message, re.IGNORECASE)
            if custom_message_match:
                alert_data['_alert_custom_message'] = custom_message_match.group(1).strip()
                logger.info(f"  Custom alert message: {alert_data['_alert_custom_message']}")
            
            logger.info("ALERT REQUIREMENTS DETECTED:")
            logger.info(f"  Alert required: True")
            logger.info(f"  Alert recipient: {recipient}")
            logger.info(f"  Alert condition: overdue")
            logger.info(f"  Alert type: email")
            return alert_data

        # Pattern 2: "alert me"
        if 'alert me' in msg_lower:
            alert_data['IsAlert'] = 1
            logger.debug("Detected alert task - setting IsAlert=1")

        # Pattern 3: "alert [amount] [unit] before"
        alert_match = re.search(r'(?:email\s+)?alert\s+(\d+)\s+(hour|minute)s?\s+before', msg_lower)
        if alert_match:
            amount = int(alert_match.group(1))
            unit = alert_match.group(2)
            alert_data['IsAlert'] = 1
            alert_data['_alert_offset_hours'] = amount if unit == 'hour' else amount / 60
            logger.debug(f"Detected alert task with offset: {amount} {unit} before")

        # Pattern 4: "add alert" with recipient - handles both groups and individuals
        # Handle various formats: "add alert for Ken", "add alert to Ken", "add alert Ken"
        add_alert_match = re.search(r'add\s+alert\s+(?:if\s+)?(?:overdue\s+)?(?:for\s+|to\s+)?([A-Z][A-Za-z\s]+?)(?:\s+with\s+alert\s+message|\s+in\s+case\s+|\s*$)', user_message, re.IGNORECASE)
        if add_alert_match:
            raw_recipient = add_alert_match.group(1).strip()
            
            # Extract individual names from the sentence
            potential_names = self.extract_individual_names_from_sentence(raw_recipient)
            
            # Use the first extracted name as the recipient, or fall back to raw recipient
            if potential_names:
                recipient = potential_names[0]  # Use first name found
                logger.info(f"Extracted individual name '{recipient}' from sentence '{raw_recipient}'")
            else:
                recipient = raw_recipient
                logger.info(f"Could not extract individual names from '{raw_recipient}', using as-is")
            
            alert_data.update({
                '_alert_required': True,
                '_alert_recipient': recipient,
                '_alert_condition': 'overdue',
                '_alert_type': 'email'
            })
            
            # Check for custom alert message
            custom_message_match = re.search(r'with\s+alert\s+message\s+["\']([^"\']+)["\']', user_message, re.IGNORECASE)
            if custom_message_match:
                alert_data['_alert_custom_message'] = custom_message_match.group(1).strip()
                logger.info(f"  Custom alert message: {alert_data['_alert_custom_message']}")
            
            logger.info("ALERT REQUIREMENTS DETECTED:")
            logger.info(f"  Alert required: True")
            logger.info(f"  Alert recipient: {recipient}")
            logger.info(f"  Alert condition: overdue")
            logger.info(f"  Alert type: email")

        # Pattern 5: "create an alert message" - default to task assignee
        alert_message_match = re.search(r'create\s+an?\s+alert\s+message\s+["\']([^"\']+)["\']', user_message, re.IGNORECASE)
        if alert_message_match:
            custom_message = alert_message_match.group(1).strip()
            alert_data.update({
                '_alert_required': True,
                '_alert_recipient': 'task_assignee',  # Use task assignee as default
                '_alert_condition': 'overdue',
                '_alert_type': 'email',
                '_alert_custom_message': custom_message
            })
            
            logger.info("ALERT REQUIREMENTS DETECTED:")
            logger.info(f"  Alert required: True")
            logger.info(f"  Alert recipient: task_assignee (will use task assignee)")
            logger.info(f"  Alert condition: overdue")
            logger.info(f"  Alert type: email")
            logger.info(f"  Custom alert message: {custom_message}")
            return alert_data

        # Pattern 6: "alert message" or "create alert" - general alert patterns
        general_alert_match = re.search(r'(?:create\s+)?alert\s+message\s+["\']([^"\']+)["\']', user_message, re.IGNORECASE)
        if general_alert_match:
            custom_message = general_alert_match.group(1).strip()
            alert_data.update({
                '_alert_required': True,
                '_alert_recipient': 'task_assignee',  # Use task assignee as default
                '_alert_condition': 'overdue',
                '_alert_type': 'email',
                '_alert_custom_message': custom_message
            })
            
            logger.info("ALERT REQUIREMENTS DETECTED:")
            logger.info(f"  Alert required: True")
            logger.info(f"  Alert recipient: task_assignee (will use task assignee)")
            logger.info(f"  Alert condition: overdue")
            logger.info(f"  Alert type: email")
            logger.info(f"  Custom alert message: {custom_message}")
            return alert_data

        # Pattern 7: "send alert with text" - another common pattern
        send_alert_match = re.search(r'send\s+alert\s+with\s+text\s+["\']([^"\']+)["\']', user_message, re.IGNORECASE)
        if send_alert_match:
            custom_message = send_alert_match.group(1).strip()
            alert_data.update({
                '_alert_required': True,
                '_alert_recipient': 'task_assignee',  # Use task assignee as default
                '_alert_condition': 'overdue',
                '_alert_type': 'email',
                '_alert_custom_message': custom_message
            })
            
            logger.info("ALERT REQUIREMENTS DETECTED:")
            logger.info(f"  Alert required: True")
            logger.info(f"  Alert recipient: task_assignee (will use task assignee)")
            logger.info(f"  Alert condition: overdue")
            logger.info(f"  Alert type: email")
            logger.info(f"  Custom alert message: {custom_message}")
            return alert_data

        # Pattern 8: "reminder alert of [TIME] with alert text [MESSAGE]" - handles reminder alerts with specific time
        reminder_alert_match = re.search(r'reminder\s+alert\s+of\s+(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)\s+with\s+alert\s+text\s+["\']([^"\']+)["\']', user_message, re.IGNORECASE)
        if reminder_alert_match:
            reminder_time = reminder_alert_match.group(1).strip()
            custom_message = reminder_alert_match.group(2).strip()
            
            # Convert time to hours for alert processing
            alert_time_hours = self._convert_time_to_hours(reminder_time)
            
            alert_data.update({
                '_alert_required': True,
                '_alert_recipient': 'task_assignee',  # Use task assignee as default
                '_alert_condition': 'at_due',
                '_alert_type': 'reminder',
                '_alert_custom_message': custom_message,
                '_alert_due_time_hours': alert_time_hours
            })
            
            logger.info("ALERT REQUIREMENTS DETECTED:")
            logger.info(f"  Alert required: True")
            logger.info(f"  Alert recipient: task_assignee (will use task assignee)")
            logger.info(f"  Alert condition: at_due")
            logger.info(f"  Alert type: reminder")
            logger.info(f"  Reminder time: {reminder_time} ({alert_time_hours} hours)")
            logger.info(f"  Custom alert message: {custom_message}")
            return alert_data

        # Pattern 9: "reminder alert of [TIME]" - reminder alert without custom message
        reminder_alert_simple_match = re.search(r'reminder\s+alert\s+of\s+(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)', user_message, re.IGNORECASE)
        if reminder_alert_simple_match:
            reminder_time = reminder_alert_simple_match.group(1).strip()
            
            # Convert time to hours for alert processing
            alert_time_hours = self._convert_time_to_hours(reminder_time)
            
            alert_data.update({
                '_alert_required': True,
                '_alert_recipient': 'task_assignee',  # Use task assignee as default
                '_alert_condition': 'at_due',
                '_alert_type': 'reminder',
                '_alert_due_time_hours': alert_time_hours
            })
            
            logger.info("ALERT REQUIREMENTS DETECTED:")
            logger.info(f"  Alert required: True")
            logger.info(f"  Alert recipient: task_assignee (will use task assignee)")
            logger.info(f"  Alert condition: at_due")
            logger.info(f"  Alert type: reminder")
            logger.info(f"  Reminder time: {reminder_time} ({alert_time_hours} hours)")
            return alert_data

        return alert_data
    
    def extract_basic_alert_indicators(self, user_message: str) -> Dict[str, Any]:
        """
        Extract only basic alert indicators - AI will handle the complex parsing.
        This is a minimal fallback for very obvious alert keywords.
        """
        alert_data = {}
        msg_lower = user_message.lower()
        
        # Only detect very basic alert keywords
        basic_alert_keywords = ['alert', 'reminder', 'notify', 'notification']
        
        for keyword in basic_alert_keywords:
            if keyword in msg_lower:
                alert_data['_has_alert_keyword'] = True
                logger.debug(f"Detected basic alert keyword: '{keyword}'")
                break
        
        return alert_data
    
    def _convert_time_to_hours(self, time_str: str) -> float:
        """
        Convert time string to decimal hours for alert processing.
        Handles formats like '4PM', '4:00 PM', '16:00', '16'
        """
        try:
            time_str = time_str.strip().upper()
            
            # Handle PM/AM format
            if 'PM' in time_str:
                time_str = time_str.replace('PM', '').strip()
                if ':' in time_str:
                    hour, minute = time_str.split(':')
                    hour = int(hour)
                    minute = int(minute)
                    if hour != 12:  # 12 PM stays 12
                        hour += 12
                else:
                    hour = int(time_str)
                    minute = 0
                    if hour != 12:  # 12 PM stays 12
                        hour += 12
            elif 'AM' in time_str:
                time_str = time_str.replace('AM', '').strip()
                if ':' in time_str:
                    hour, minute = time_str.split(':')
                    hour = int(hour)
                    minute = int(minute)
                    if hour == 12:  # 12 AM becomes 0
                        hour = 0
                else:
                    hour = int(time_str)
                    minute = 0
                    if hour == 12:  # 12 AM becomes 0
                        hour = 0
            else:
                # 24-hour format
                if ':' in time_str:
                    hour, minute = time_str.split(':')
                    hour = int(hour)
                    minute = int(minute)
                else:
                    hour = int(time_str)
                    minute = 0
            
            # Convert to decimal hours
            decimal_hours = hour + (minute / 60.0)
            return decimal_hours
            
        except Exception as e:
            logger.warning(f"Could not parse time '{time_str}', using default 9.0 hours: {e}")
            return 9.0  # Default to 9 AM
    
    def extract_alert_requirements_mcp(self, user_message: str) -> Dict[str, Any]:
        """
        Extract alert requirements using MCP service with vector similarity.
        This is more intelligent than regex patterns and can understand semantic variations.
        """
        if not self.mcp_service:
            logger.debug("MCP service not available, falling back to regex patterns")
            return self.extract_alert_requirements(user_message)
        
        try:
            # Use MCP service to detect intent and extract parameters
            execution_plan = self.mcp_service.get_execution_plan(user_message)
            
            if execution_plan['success'] and execution_plan['detected_intent'] == 'alert_creation':
                logger.info("MCP Service detected alert creation intent")
                logger.info(f"   Confidence score: {execution_plan['confidence_score']:.3f}")
                logger.info(f"   Stored procedure: {execution_plan['stored_procedure']}")
                
                # Extract parameters using MCP service
                mcp_params = self.mcp_service.extract_parameters_for_intent(
                    user_message, 
                    'alert_creation'
                )
                
                # Convert MCP parameters to our format
                alert_data = {}
                if mcp_params.get('alert_recipient'):
                    alert_data.update({
                        '_alert_required': True,
                        '_alert_recipient': mcp_params['alert_recipient'],
                        '_alert_condition': mcp_params.get('alert_condition', 'overdue'),
                        '_alert_type': 'email'
                    })
                    
                    logger.info("ALERT REQUIREMENTS DETECTED (MCP):")
                    logger.info(f"  Alert required: True")
                    logger.info(f"  Alert recipient: {mcp_params['alert_recipient']}")
                    logger.info(f"  Alert condition: {mcp_params.get('alert_condition', 'overdue')}")
                    logger.info(f"  Alert type: email")
                    logger.info(f"  MCP confidence: {execution_plan['confidence_score']:.3f}")
                    
                    return alert_data
            
            # If MCP didn't detect alert creation, try regex as fallback
            logger.debug("MCP service didn't detect alert creation, trying regex fallback")
            return self.extract_alert_requirements(user_message)
            
        except Exception as e:
            logger.error(f"Error in MCP alert detection: {e}")
            logger.debug("Falling back to regex patterns")
            return self.extract_alert_requirements(user_message)
    
    def extract_status_report_requirements(self, user_message: str) -> Dict[str, Any]:
        """Extract status report requirements from user messages."""
        status_report_data = {}
        msg_lower = user_message.lower()

        # Pattern 1: "include in [GROUP] status report" - handles both groups and individuals
        include_status_match = re.search(r'include\s+in\s+([A-Z][A-Za-z\s]+?)\s+status\s+report', user_message, re.IGNORECASE)
        if include_status_match:
            group_name = include_status_match.group(1).strip()
            status_report_data.update({
                '_status_report_required': True,
                '_status_report_group': group_name
            })
            
            # Check for custom report name
            report_name_match = re.search(r'status\s+report\s+(?:under\s+)?([A-Z][A-Za-z\s]+?)(?:\s|$)', user_message, re.IGNORECASE)
            if report_name_match:
                status_report_data['_status_report_name'] = report_name_match.group(1).strip()
                logger.info(f"  Custom status report name: {status_report_data['_status_report_name']}")
            
            logger.info("STATUS REPORT REQUIREMENTS DETECTED:")
            logger.info(f"  Status report required: True")
            logger.info(f"  Status report group: {group_name}")
            if '_status_report_name' in status_report_data:
                logger.info(f"  Status report name: {status_report_data['_status_report_name']}")
            return status_report_data

        # Pattern 5: "provide status report named 'X' to [GROUP]"
        provide_named_pattern = re.search(r'provide\s+status\s+report\s+named\s+[\'"]([^\'"]+)[\'"]\s+to\s+([A-Z][A-Za-z\s]+?)(?:\s|$)', user_message, re.IGNORECASE)
        if provide_named_pattern:
            report_name = provide_named_pattern.group(1).strip()
            group_name = provide_named_pattern.group(2).strip()
            status_report_data.update({
                '_status_report_required': True,
                '_status_report_group': group_name,
                '_status_report_name': report_name
            })
            
            logger.info("STATUS REPORT REQUIREMENTS DETECTED:")
            logger.info(f"  Status report required: True")
            logger.info(f"  Status report group: {group_name}")
            logger.info(f"  Status report name: {report_name}")
            return status_report_data

        # Pattern 6: "add status report name 'X' for [GROUP]"
        add_named_for_pattern = re.search(r'add\s+status\s+report\s+name\s+[\'"]([^\'"]+)[\'"]\s+for\s+([A-Z][A-Za-z\s]+?)(?:\s|$)', user_message, re.IGNORECASE)
        if add_named_for_pattern:
            report_name = add_named_for_pattern.group(1).strip()
            group_name = add_named_for_pattern.group(2).strip()
            status_report_data.update({
                '_status_report_required': True,
                '_status_report_group': group_name,
                '_status_report_name': report_name
            })
            
            logger.info("STATUS REPORT REQUIREMENTS DETECTED:")
            logger.info(f"  Status report required: True")
            logger.info(f"  Status report group: {group_name}")
            logger.info(f"  Status report name: {report_name}")
            return status_report_data



        # Pattern 3: "report to [GROUP]"
        report_to_match = re.search(r'report\s+to\s+([A-Z][A-Za-z\s]+?)(?:\s|$)', user_message, re.IGNORECASE)
        if report_to_match:
            group_name = report_to_match.group(1).strip()
            status_report_data.update({
                '_status_report_required': True,
                '_status_report_group': group_name
            })
            
            logger.info("STATUS REPORT REQUIREMENTS DETECTED:")
            logger.info(f"  Status report required: True")
            logger.info(f"  Status report group: {group_name}")
            return status_report_data

        # Pattern 2: "status report for [GROUP]" (moved after more specific patterns)
        # Pattern 1: "status report for this to [GROUP]" - specific pattern for your use case
        status_report_for_this_to_match = re.search(r'status\s+report\s+for\s+this\s+to\s+([A-Z][A-Za-z\s]+?)(?:\s|$|,|\.)', user_message, re.IGNORECASE)
        if status_report_for_this_to_match:
            group_name = status_report_for_this_to_match.group(1).strip()
            status_report_data.update({
                '_status_report_required': True,
                '_status_report_group': group_name
            })
            
            logger.info("STATUS REPORT REQUIREMENTS DETECTED (for this to pattern):")
            logger.info(f"  Status report required: True")
            logger.info(f"  Status report group: {group_name}")
            return status_report_data

        # Pattern 2: "status report for [GROUP]" - general pattern
        status_report_match = re.search(r'status\s+report\s+for\s+([A-Z][A-Za-z\s]+?)(?:\s|$|,|\.)', user_message, re.IGNORECASE)
        if status_report_match:
            group_name = status_report_match.group(1).strip()
            status_report_data.update({
                '_status_report_required': True,
                '_status_report_group': group_name
            })
            
            logger.info("STATUS REPORT REQUIREMENTS DETECTED (for pattern):")
            logger.info(f"  Status report required: True")
            logger.info(f"  Status report group: {group_name}")
            return status_report_data

        # Pattern 4: "add status report" (general request) - including variations
        add_status_patterns = [
            r'add\s+status\s+report',
            r'add\s+status\s+report\s+on\s+this',
            r'also\s+add\s+status\s+report',
            r'also\s+add\s+status\s+report\s+on\s+this'
        ]
        
        for pattern in add_status_patterns:
            if re.search(pattern, user_message, re.IGNORECASE):
                # For general status report requests, we'll let the MCP service or AI service handle the group
                # Just mark that a status report is required
                status_report_data.update({
                    '_status_report_required': True,
                    '_status_report_group': '',  # Empty - will be filled by MCP service or AI service
                    '_status_report_name': ''  # No custom name specified
                })
                
                logger.info("STATUS REPORT REQUIREMENTS DETECTED:")
                logger.info(f"  Status report required: True")
                logger.info(f"  Status report group: (to be determined)")
                logger.info(f"  Pattern matched: '{pattern}'")
                return status_report_data

        return status_report_data
    
    def extract_status_report_group_with_ai(self, user_message: str) -> str:
        """
        Use Claude API to extract status report group when regex patterns fail.
        
        Args:
            user_message: The user's message
            
        Returns:
            The extracted status report group name
        """
        try:
            # Simple prompt to extract status report group
            prompt = f"""
            Extract the status report group name from this message. 
            Look for patterns like "status report for this to [GROUP]", "add status report for [GROUP]", etc.
            
            Message: "{user_message}"
            
            Return only the group name, nothing else. If no group is specified, return "General".
            """
            
            # For now, we'll use a simple heuristic approach
            # In a full implementation, you'd call the Claude API here
            
            # Look for "to [GROUP]" pattern specifically
            to_group_match = re.search(r'to\s+([A-Z][A-Za-z\s]+?)(?:\s|$|,|\.)', user_message, re.IGNORECASE)
            if to_group_match:
                group_name = to_group_match.group(1).strip()
                logger.info(f"AI extraction found group: {group_name}")
                return group_name
            
            # Look for "for [GROUP]" pattern
            for_group_match = re.search(r'for\s+([A-Z][A-Za-z\s]+?)(?:\s|$|,|\.)', user_message, re.IGNORECASE)
            if for_group_match:
                group_name = for_group_match.group(1).strip()
                logger.info(f"AI extraction found group: {group_name}")
                return group_name
            
            logger.info("AI extraction found no specific group, using default")
            return "General"
            
        except Exception as e:
            logger.error(f"Error in AI extraction: {e}")
            return "General"
    
    def determine_status_report_group(self, user_message: str, context: Dict[str, Any] = None) -> str:
        """
        Intelligently determine the status report group when not explicitly specified.
        
        Args:
            user_message: The user's message
            context: Context containing task parameters
            
        Returns:
            The determined group name for the status report
        """
        # If we have context with task parameters, use intelligent defaults
        if context:
            # Priority 1: Use the task assignee's group if available
            if context.get('Assignees'):
                return context['Assignees']
            
            # Priority 2: Use the main controller if available
            if context.get('MainController'):
                return context['MainController']
            
            # Priority 3: Use the controllers if available
            if context.get('Controllers'):
                return context['Controllers']
        
        # If no context, try to extract from the message
        msg_lower = user_message.lower()
        
        # Look for any group names mentioned in the message
        group_patterns = [
            r'status\s+report\s+for\s+this\s+to\s+([A-Z][A-Za-z\s]+?)(?:\s|$|,|\.)',  # "status report for this to CLO"
            r'for\s+this\s+to\s+([A-Z][A-Za-z\s]+?)(?:\s|$|,|\.)',  # "for this to CLO"
            r'to\s+([A-Z][A-Za-z\s]+?)(?:\s+Team\s+|\s+Group\s+|\s+Department\s+|\s|$|,|\.)',  # "to CLO"
            r'for\s+([A-Z][A-Za-z\s]+?)(?:\s+to\s+|\s+Team\s+|\s+Group\s+|\s+Department\s+|\s|$|,|\.)',  # "for CLO"
            r'assigned\s+to\s+([A-Z][A-Za-z\s]+?)(?:\s|$|,|\.)',  # "assigned to CLO"
            r'assign\s+to\s+([A-Z][A-Za-z\s]+?)(?:\s|$|,|\.)'   # "assign to CLO"
        ]
        
        for pattern in group_patterns:
            match = re.search(pattern, user_message, re.IGNORECASE)
            if match:
                group_name = match.group(1).strip()
                logger.info(f"Extracted status report group from message: {group_name}")
                return group_name
        
        # If no group found with regex patterns, try AI extraction
        logger.info("No group found with regex patterns, trying AI extraction...")
        ai_extracted_group = self.extract_status_report_group_with_ai(user_message)
        if ai_extracted_group and ai_extracted_group != "General":
            logger.info(f"AI extraction successful: {ai_extracted_group}")
            return ai_extracted_group
        
        # Default fallback - use a common group that should exist
        default_group = 'General'
        logger.info(f"No status report group determined, using default: {default_group}")
        return default_group
    
    def is_reminder_task(self, user_message: str) -> bool:
        """Check if the message indicates a reminder task."""
        msg_lower = user_message.lower()
        return 'remind me' in msg_lower
    
    def extract_recurring_patterns(self, user_message: str) -> Dict[str, Any]:
        """Extract recurring patterns when schedule parser is not available."""
        msg_lower = user_message.lower()
        recurring_data = {}
        
        # Daily patterns - must have scheduling context
        if any(word in msg_lower for word in ['every day', 'each day']) or re.search(r'\b(?:recurring|repeat|repeating)\s+daily\b', msg_lower):
            recurring_data.update({
                'IsRecurring': 1,
                'FreqType': 2,  # Every (freqRecurrance) Days
                'FreqRecurrance': 1,
                'FreqInterval': 1,
                # Daily default: skip weekends/holidays unless specified
                'BusinessDayBehavior': 1
            })
        # Weekly patterns - must have scheduling context
        elif any(word in msg_lower for word in ['every week', 'each week', 'weekday', 'weekdays', 'business day', 'business days']) or re.search(r'\b(?:recurring|repeat|repeating)\s+weekly\b', msg_lower):
            recurring_data.update({
                'IsRecurring': 1,
                'FreqType': 3,  # Every (freqRecurrance) Weeks on (freqInterval)
                'FreqRecurrance': 1,  # weekly interval
                'FreqInterval': 62 if any(w in msg_lower for w in ['weekday', 'weekdays', 'business day', 'business days']) else 2  # Mon-Fri else Monday
            })
        # Monthly patterns - MUST have scheduling context words like "every", "each", or "recurring"
        # This prevents "monthly report" from being treated as a recurring task
        elif any(word in msg_lower for word in ['every month', 'each month']) or re.search(r'\b(?:recurring|repeat|repeating)\s+monthly\b', msg_lower):
            recurring_data.update({
                'IsRecurring': 1,
                'FreqType': 4,  # Every (freqRecurrance) Months
                'FreqRecurrance': 1,
                'FreqInterval': 1
            })
            logger.debug(f"Detected monthly recurring pattern with scheduling context")
        # Yearly patterns - must have scheduling context
        elif any(word in msg_lower for word in ['every year', 'each year', 'annually']) or re.search(r'\b(?:recurring|repeat|repeating)\s+(?:yearly|annual)\b', msg_lower):
            recurring_data.update({
                'IsRecurring': 1,
                'FreqType': 5,  # Yearly in (freqInterval) Month
                'FreqRecurrance': 1,
                'FreqInterval': 1
            })
        # Quarterly patterns - must have scheduling context
        elif any(word in msg_lower for word in ['every quarter', 'each quarter']) or re.search(r'\b(?:recurring|repeat|repeating)\s+quarterly\b', msg_lower):
            recurring_data.update({
                'IsRecurring': 1,
                'FreqType': 6,  # Quarterly
                'FreqRecurrance': 1,
                'FreqInterval': 1
            })
        
        return recurring_data
    
    def extract_time_patterns(self, msg_lower: str, current_date: datetime.date) -> Dict[str, Any]:
        """Extract time patterns from message."""
        time_data = {}
        # Match both "at 12pm" and "due 12pm" patterns
        time_match = re.search(r'(?:at|due)\s+(\d{1,2})\s*(?::(\d{2}))?\s*(am|pm)?', msg_lower)
        if time_match:
            hour = int(time_match.group(1))
            minute = int(time_match.group(2) or 0)
            meridian = time_match.group(3)
            if meridian == 'pm' and hour != 12:
                hour += 12
            elif meridian == 'am' and hour == 12:
                hour = 0
            time_data['DueTime'] = f"{hour:02d}:{minute:02d}"
            # Default to tomorrow when time is specified without a date
            # Only set to today if "today" is explicitly mentioned
            # Check for explicit date keywords
            has_date_keyword = any(word in msg_lower for word in ['tomorrow', 'next', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'])
            
            if 'today' in msg_lower:
                # Explicitly mentioned "today" - use today
                time_data['DueDate'] = current_date.strftime('%Y-%m-%d')
                logger.debug(f"Time with 'today' keyword - set due date to today: {time_data['DueDate']}")
            elif not has_date_keyword:
                # No date keyword specified - default to tomorrow
                tomorrow = current_date + datetime.timedelta(days=1)
                time_data['DueDate'] = tomorrow.strftime('%Y-%m-%d')
                logger.debug(f"Time without date keyword - defaulting to tomorrow: {time_data['DueDate']}")
        return time_data