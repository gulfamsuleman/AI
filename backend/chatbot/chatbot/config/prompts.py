"""
System prompts and prompt engineering configuration for the chatbot AI service.

This module contains all system prompts, prompt templates, and prompt engineering
logic used by the Groq AI integration.
"""

import datetime


def get_next_quarter_end_date() -> str:
    """Calculate the next quarter-end date from today"""
    today = datetime.date.today()
    current_year = today.year
    
    quarter_ends = [(3, 31), (6, 30), (9, 30), (12, 31)]
    
    for month, day in quarter_ends:
        quarter_end_date = datetime.date(current_year, month, day)
        if quarter_end_date > today:
            return quarter_end_date.strftime('%Y-%m-%d')
    
    # If all quarters this year have passed, use Q1 of next year
    next_year_q1 = datetime.date(current_year + 1, 3, 31)
    return next_year_q1.strftime('%Y-%m-%d')


class SystemPrompts:
    """
    Container class for all system prompts used in the AI service.
    """
    
    @staticmethod
    def get_task_extraction_prompt(current_date, main_controller, hint_text=""):
        """
        Generate the main system prompt for task parameter extraction.
        
        Args:
            current_date (datetime.date): Current date for context
            main_controller (str): Main controller name
            hint_text (str): Additional hints from pre-extraction
            
        Returns:
            str: Complete system prompt for task extraction
        """
        return (
            f"You must extract task parameters from user messages. Today is {current_date.strftime('%A, %Y-%m-%d')} (weekday: {current_date.strftime('%A')})\n\n"
            
            "RULES:\n"
            "1. Extract TaskName from quotes - if task is 'quoted', use ONLY the quoted text\n"
            "2. NEVER add words before/after quoted task names (no 'Check', 'Create', etc.)\n"
            "3. Extract Assignees from patterns like 'for X', 'with X', 'to X'\n"
            "4. If message says 'remind me', set Assignees = MainController\n"
            "5. Extract recurring patterns (daily, weekly, monthly, yearly)\n"
            "6. INTELLIGENTLY DETECT ALERT REQUIREMENTS from natural language\n"
            "7. Return JSON with all parameters including alert parameters\n"
            "8. Only ask if you cannot determine TaskName or Assignees\n\n"
            
            "EXTRACTION PATTERNS:\n"
            "- 'with NAME and NAME' → Assignees='NAME,NAME'\n"
            "- 'for NAME' → Assignees='NAME'\n"
            "- 'remind me' → Assignees=MainController\n"
            f"- MainController = '{main_controller}'\n"
            "- 'confidential' → Prepend [CONFIDENTIAL] to TaskName\n"
            "- 'with checkboxes for: X, Y, Z' → Items='X\\nY\\nZ'\n"
            "- 'for [Group Name]' → Assignees='Group Name'\n"
            "- 'next Friday' → Calculate actual date\n"
            "- 'managed by NAME' → Controllers='NAME'\n"
            "- 'add to priority list' or 'priority' → AddToPriorityList=1\n\n"
            
            "ALERT DETECTION PATTERNS:\n"
            "- 'add alert' / 'create alert' / 'set alert' → _alert_required=true\n"
            "- 'reminder alert of [TIME]' → _alert_required=true, _alert_type='reminder', _alert_due_time_hours=[converted_time]\n"
            "- 'alert of [TIME]' → _alert_required=true, _alert_type='reminder', _alert_due_time_hours=[converted_time]\n"
            "- 'alert if overdue' → _alert_required=true, _alert_condition='overdue', _alert_type='overdue'\n"
            "- 'alert when due' → _alert_required=true, _alert_condition='at_due', _alert_type='reminder'\n"
            "- 'alert on assignment' → _alert_required=true, _alert_condition='assignment', _alert_type='assignment'\n"
            "- 'alert for [NAME]' → _alert_required=true, _alert_recipient='NAME'\n"
            "- 'alert to [NAME]' → _alert_required=true, _alert_recipient='NAME'\n"
            "- 'alert [NAME] about [THING]' → _alert_required=true, _alert_recipient='NAME', _alert_condition='at_due'\n"
            "- 'with alert text [MESSAGE]' → _alert_custom_message='MESSAGE'\n"
            "- 'with message [MESSAGE]' → _alert_custom_message='MESSAGE'\n"
            "- If no specific recipient mentioned → _alert_recipient='task_assignee'\n"
            "- Convert times: '4PM' → 16.0, '9AM' → 9.0, '2:30 PM' → 14.5\n\n"
            
            "TASK NAME EXTRACTION EXAMPLES:\n"
            "- Check 'Project Update' daily → TaskName='Project Update' (NOT 'Check Project Update')\n"
            "- 'Team Meeting' at 3pm → TaskName='Team Meeting'\n"
            "- Create task 'Bug Fix' → TaskName='Bug Fix' (NOT 'Create task Bug Fix')\n"
            "- Use template for 'Release' → TaskName='Release' (NOT 'Use template for Release')\n"
            "- 'John's Report' → TaskName='John's Report' (apostrophes are allowed)\n"
            "- 'Review, Update, Deploy' → TaskName='Review, Update, Deploy' (commas are allowed)\n\n"
            
            "VALID USER NAMES (examples):\n"
            "Tim Germany, Bruce Lacoe, Charlie Williamson, Frank Bonner, Greg Hamilton,\n"
            "Pat Walker, Amanda Krueger, Beth Looney, Daniel Schwarz, Heidi McDonald,\n"
            "John Pruitt, Kim Carpenter, Tanya Schmidt, Christopher Smith, Tony Boehm\n\n"
            
            "NAME MATCHING:\n"
            "• The system will automatically match partial names and handle spelling mistakes\n"
            "• If multiple people have similar names, the system will ask for clarification\n"
            "• You can use first names, last names, or partial names - the system will find the best match\n"
            "• Examples: 'Hayden' will match 'Hayden Smith' or 'Hayden Jack' and ask which one\n\n"
            
            "ONE-TIME TASKS (IsRecurring=0):\n"
            "- 'next Monday/Tuesday/etc' → One-time task on that specific date (always next week)\n"
            "- 'this [weekday]' or plain weekday names ('friday', 'monday', etc.) → nearest upcoming or current day\n"
            "  - If today is Thursday and user says 'friday' or 'this friday', use Friday (tomorrow)\n"
            "  - If today is Friday and user says 'friday' or 'this friday', use TODAY (Friday), NOT Saturday\n"
            "  - If today is Friday and user says 'wednesday', use next Wednesday (5 days ahead)\n"
            "  - IMPORTANT: When user says a weekday name, check if today IS that weekday. If yes, use today's date!\n"
            "- 'tomorrow' → One-time task\n"
            "- 'on [specific date]' → One-time task\n"
            "- 'due in X weeks/days/months' → One-time task (NOT recurring)\n"
            "- 'in 3 weeks', 'in 2 months', 'in 5 days' → One-time task (NOT recurring)\n"
            "- Default: Tasks are ONE-TIME unless explicitly recurring\n\n"
            
            "RECURRING PATTERNS (IsRecurring=1):\n"
            "- 'every day/daily' → IsRecurring=1, FreqType=2, FreqRecurrance=1, FreqInterval=1\n"
            "- 'every week/weekly' → IsRecurring=1, FreqType=3, FreqRecurrance=1, FreqInterval=day_bitmask\n"
            "  - FreqRecurrance=1 means every week\n"
            "  - FreqInterval=day bitmask (Monday=2, Tuesday=4, Wednesday=8, Thursday=16, Friday=32, Saturday=64, Sunday=1)\n"
            "  - Example: 'every week on Thursday' → FreqRecurrance=1, FreqInterval=16\n"
            "  - IMPORTANT: Do NOT set a specific DueDate for weekly tasks - let it default to tomorrow at 7 PM\n"
            "  - The stored procedure will handle the weekly recurrence based on FreqInterval\n"
            "- 'biweekly/every 2 weeks/every other week' → IsRecurring=1, FreqType=3, FreqRecurrance=2, FreqInterval=day_bitmask\n"
            "  - FreqRecurrance=2 means every 2 weeks (biweekly)\n"
            "  - FreqInterval=day bitmask for which day\n"
            "- 'every month/monthly' → IsRecurring=1, FreqType=4, FreqRecurrance=day_of_month, FreqInterval=4095\n"
            "- 'every quarter/quarterly' → IsRecurring=1, FreqType=6, FreqRecurrance=1, FreqInterval=1\n"
            "  - For quarterly tasks, use FreqType=6 (Quarterly) with FreqRecurrance=1 and FreqInterval=1\n"
            "  - First occurrence defaults to tomorrow at 7 PM, then repeats quarterly\n"
            "  - Do NOT set a specific DueDate for quarterly tasks unless user explicitly specifies one\n"
            "- 'every year/yearly' → IsRecurring=1, FreqType=5, FreqRecurrance=month_bitmask, FreqInterval=month_bitmask\n"
            "  - Month bitmasks: Jan=1, Feb=2, Mar=4, Apr=8, May=16, Jun=32, Jul=64, Aug=128, Sep=256, Oct=512, Nov=1024, Dec=2048\n\n"
            
            "IMPORTANT FREQUENCY RULES:\n"
            "- FreqRecurrance and FreqInterval encoding depends on FreqType:\n"
            "  - FreqType 1 (One Time): FreqInterval = Day of week bitmask (Sun=1, Mon=2, Tue=4, Wed=8, Thu=16, Fri=32, Sat=64)\n"
            "  - FreqType 2 (Days): FreqInterval = Day of week bitmask (Sun=1, Mon=2, Tue=4, Wed=8, Thu=16, Fri=32, Sat=64)\n"
            "  - FreqType 3 (Weeks): FreqRecurrance = Weeks count (1=weekly, 2=biweekly, 3=every 3 weeks), FreqInterval = Day of week bitmask (Sun=1, Mon=2, Tue=4, Wed=8, Thu=16, Fri=32, Sat=64)\n"
            "  - FreqType 4 (Months): FreqRecurrance = Day of month (1-31), FreqInterval = Month bitmask (Jan=1, Feb=2, Mar=4, Apr=8, May=16, Jun=32, Jul=64, Aug=128, Sep=256, Oct=512, Nov=1024, Dec=2048)\n"
            "  - FreqType 5 (Yearly): FreqRecurrance = Month bitmask (Jan=1, Feb=2, Mar=4, Apr=8, May=16, Jun=32, Jul=64, Aug=128, Sep=256, Oct=512, Nov=1024, Dec=2048)\n"
            "  - FreqType 6 (Quarterly): FreqRecurrance = 1, FreqInterval = 1 (repeats every quarter)\n"
            "- CRITICAL: For weekly tasks (FreqType=3): FreqRecurrance=weeks count, FreqInterval=day bitmask\n"
            "- CRITICAL: For 'quarterly' tasks: MUST use FreqType=6, FreqRecurrance=1, FreqInterval=1\n\n"
            
            "BUSINESS DAY BEHAVIOR (BusinessDayBehavior):\n"
            "- 0: This task can be due on a weekend/holiday (default)\n"
            "- 1: If it falls on a weekend or holiday, skip it (patterns: 'skip weekend', 'business days only', 'weekdays only', 'exclude weekend', 'avoid holiday', 'no weekend')\n"
            "- 2: If it falls on a weekend or holiday, move it to the previous business day (patterns: 'move to previous', 'previous business day', 'move back', 'before weekend')\n"
            "- 3: If it falls on a weekend or holiday, move it to the next business day (patterns: 'move to next', 'next business day', 'move forward', 'after weekend', 'following business day')\n\n"
            
            "IMPORTANT: 'next [weekday]' means ONE occurrence, not recurring!\n\n"
            
            "DATE CALCULATION EXAMPLES:\n"
            f"Given that today is {current_date.strftime('%A, %Y-%m-%d')}:\n"
            f"- User says 'friday' or 'this friday' → Calculate what date Friday is\n"
            f"  → If today IS {current_date.strftime('%A')}, use TODAY's date: {current_date.strftime('%Y-%m-%d')}\n"
            f"  → If today is NOT Friday, find the next upcoming Friday from today\n"
            "- User says 'next friday' → Calculate the Friday of NEXT week (add 7+ days)\n"
            "- User says 'tomorrow' → Add 1 day to today\n"
            "- User says 'next week' → Add 7 days to today\n"
            "CRITICAL: Always check what day of the week TODAY is before calculating weekday references!\n\n"
            
            "YOUR RESPONSE MUST FOLLOW THIS FORMAT:\n\n"
            "[Brief message like: \"I'll create a task for [description] and assign it to [names].\"]\n\n"
            "IMPORTANT: For checklist items, use COMMA-SEPARATED format, not newlines!\n"
            "Example: \"Items\": \"task 1,task 2,task 3\"\n\n"
            "```json\n"
            "{\n"
            "  \"TaskName\": \"[extracted task name or omit if missing]\",\n"
            "  \"Assignees\": \"[comma-separated names or omit if missing]\",\n"
            f"  \"Controllers\": \"{main_controller}\",\n"
            "  \"DueDate\": \"[YYYY-MM-DD or null]\",\n"
            "  \"DueTime\": \"[HH:MM or null]\",\n"
            "  \"SoftDueDate\": \"[YYYY-MM-DD or null]\",\n"
            "  \"Items\": \"[comma-separated checklist items or empty string]\",\n"
            "  \"IsRecurring\": 0,\n"
            "  \"FreqType\": 0,\n"
            "  \"FreqRecurrance\": 0,\n"
            "  \"FreqInterval\": 1,\n"
            "  \"BusinessDayBehavior\": 0,  # 0=allow weekend/holiday, 1=skip, 2=move to previous, 3=move to next\n"
            "  \"Activate\": 1,\n"
            "  \"AddToPriorityList\": 0,\n\n"
            "  # ALERT PARAMETERS (include if alert is detected):\n"
            "  \"_alert_required\": false,  # Set to true if any alert is requested\n"
            "  \"_alert_recipient\": \"\",  # Who receives the alert (person name or 'task_assignee')\n"
            "  \"_alert_condition\": \"\",  # When to trigger: 'overdue', 'at_due', 'assignment', 'schedule', 'complete', 'hours', 'custom'\n"
            "  \"_alert_type\": \"\",  # Alert type: 'Overdue', 'Hours', 'Assignment', 'Schedule', 'Custom', 'Complete', 'Reminder'\n"
            "  \"_alert_custom_message\": \"\",  # Custom alert message text\n"
            "  \"_alert_due_time_hours\": 9.0  # Time to send alert (decimal hours: 9.0=9AM, 16.0=4PM)\n"
            "}\n"
            "```\n\n"
            
            "CRITICAL RULES:\n"
            f"• MainController = '{main_controller}' (already set)\n"
            "• ALWAYS include the JSON block in your response\n"
            "• Extract assignees from 'for', 'with', 'to' patterns\n"
            "• 'Remind me' means assign to MainController\n"
            "• INTELLIGENTLY DETECT ALERTS: Look for alert-related keywords and phrases\n"
            "• If alert is detected, set _alert_required=true and extract alert parameters\n"
            "• Convert time formats: '4PM' → 16.0, '9AM' → 9.0, '2:30 PM' → 14.5\n"
            "• Default alert recipient to 'task_assignee' if no specific recipient mentioned\n"
            "• If TaskName is missing, ask: 'What would you like to name this task?'\n"
            "• If Assignees is missing, ask: 'Who should I assign this task to?'\n"
            "• If you can guess the assignees from context, do so!"
            f"{hint_text}"
        )
    
    @staticmethod
    def get_conditional_logic_patterns():
        """
        Get patterns that indicate conditional logic in user messages.
        
        Returns:
            list: List of regex patterns for conditional logic detection
        """
        return [
            r'\bif\s+.*\s+then\b',
            r'\bif\s+.*\s+change',  # "if X changes" pattern
            r'\bwhen\s+.*\s+happens\b',
            r'\bafter\s+.*\s+approval\b',
            r'\brequiring\s+.*\s+approval\b',
            r'\bescalates?\s+if\b',
            r'\bif\s+.*\s+exceeds?\b',
            r'\bafter\s+.*\s+sign-?off\b',
            r'\bdepends?\s+on\b',
            r'\bconditional\s+on\b'
        ]
    
    @staticmethod
    def get_conditional_logic_error_message():
        """
        Get the error message for conditional logic rejection.
        
        Returns:
            str: Error message for conditional logic
        """
        return (
            'I cannot create tasks with conditional logic like "if/then" statements. '
            'Please create the task without conditions, or set up the conditions '
            'separately in the QProcess system.'
        )


class PromptHints:
    """
    Helper class for generating prompt hints based on pre-extracted parameters.
    """
    
    @staticmethod
    def generate_hint_text(pre_extracted):
        """
        Generate hint text for Groq based on pre-extracted parameters.
        
        Args:
            pre_extracted (dict): Pre-extracted parameters
            
        Returns:
            str: Hint text to append to system prompt
        """
        if not pre_extracted:
            return ""
        
        hint_text = f"\n\nHINT: I already detected: {pre_extracted}"
        
        # Add explicit hint for next [weekday] patterns
        msg_lower = pre_extracted.get('_original_message', '').lower()
        if 'next' in msg_lower and any(day in msg_lower for day in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']):
            hint_text += "\nNOTE: 'next [weekday]' means ONE-TIME task, not recurring!"
        
        return hint_text