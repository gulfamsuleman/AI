import pytz
from datetime import datetime, timedelta, time
from dateutil import tz

# --- Defaulting and Presentation Logic ---
def apply_task_defaults(params, user_timezone='UTC', now_utc=None):
    """
    Apply business rules for defaulting and hiding/showing task parameters.
    Returns a tuple: (params_with_defaults, fields_to_prompt)
    """
    # Set current time
    if now_utc is None:
        now_utc = datetime.utcnow().replace(tzinfo=pytz.UTC)
    user_tz = tz.gettz(user_timezone)
    now_local = now_utc.astimezone(user_tz)

    # Helper to get tomorrow at 7pm local time
    def tomorrow_7pm_local():
        tomorrow = now_local + timedelta(days=1)
        dt = datetime.combine(tomorrow.date(), time(19, 0))
        return dt

    # --- Defaults ---
    # TaskName - must be supplied by user
    if not params.get('TaskName'):
        params['TaskName'] = 'New Task'
    
    # Controllers/Assignees - defaults to person interacting, always show
    if not params.get('Controllers'):
        params['Controllers'] = params.get('user') or 'Current User'
    if not params.get('Assignees'):
        params['Assignees'] = params.get('user') or 'Current User'
    
    # DueDate - defaults to tomorrow at 7pm user's TZ (stored as UTC)
    if not params.get('DueDate'):
        dt = tomorrow_7pm_local()
        params['DueDate'] = dt.astimezone(pytz.UTC).strftime('%Y-%m-%d %H:%M:%S')
    
    # LocalDueDate - derived from DueDate and location, shown to user
    if not params.get('LocalDueDate'):
        dt = datetime.strptime(params['DueDate'], '%Y-%m-%d %H:%M:%S').replace(tzinfo=pytz.UTC).astimezone(user_tz)
        params['LocalDueDate'] = dt.strftime('%Y-%m-%d %H:%M:%S')
    
    # Location - default to user's TZ, don't show
    if not params.get('Location'):
        params['Location'] = user_timezone
    
    # DueTime - redundant with DueDate, but for completeness
    if not params.get('DueTime'):
        dt = datetime.strptime(params['DueDate'], '%Y-%m-%d %H:%M:%S').replace(tzinfo=pytz.UTC).astimezone(user_tz)
        params['DueTime'] = dt.strftime('%H')
    
    # SoftDueDate - defaults to DueDate, don't show unless user asks
    if not params.get('SoftDueDate'):
        params['SoftDueDate'] = params['DueDate']
    
    # FinalDueDate - only for recurring, don't show unless requested
    if not params.get('FinalDueDate'):
        params['FinalDueDate'] = params['DueDate']
    
    # Items - defaults to task name, don't show unless user specifies checklist items
    if not params.get('Items'):
        params['Items'] = params['TaskName']
    
    # IsRecurring - defaults to 0 (one-time), don't show parameter
    if not params.get('IsRecurring'):
        params['IsRecurring'] = 0
    
    # FreqType, FreqRecurrance, FreqInterval, BusinessDayBehavior
    if params['IsRecurring']:
        if not params.get('FreqType'):
            params['FreqType'] = 1  # One Time
        if not params.get('FreqRecurrance'):
            params['FreqRecurrance'] = 1
        if not params.get('FreqInterval'):
            params['FreqInterval'] = None
        if not params.get('BusinessDayBehavior'):
            # Special rule: If daily task without specific days, default to skip weekends/holidays
            if params.get('FreqType') == 2:  # Daily
                params['BusinessDayBehavior'] = 1  # skip weekends/holidays
            else:
                params['BusinessDayBehavior'] = 0  # can be due on weekends/holidays
    else:
        params['FreqType'] = 1
        params['FreqRecurrance'] = 1
        params['FreqInterval'] = None
        params['BusinessDayBehavior'] = 0  # can be due on weekends/holidays
    
    # Activate - always 1, not user supplied
    params['Activate'] = 1
    
    # IsReminder/ReminderDate - defaults to 0, don't show unless user requests
    if not params.get('IsReminder'):
        params['IsReminder'] = 0
    if not params.get('ReminderDate'):
        params['ReminderDate'] = None
    
    # AddToPriorityList - defaults to 0, don't show unless user requests
    if not params.get('AddToPriorityList'):
        params['AddToPriorityList'] = 0

    # --- Fields to prompt (presentation logic) ---
    fields_to_prompt = []
    
    # Always show these basic fields
    basic_fields = ['TaskName', 'Controllers', 'Assignees', 'DueDate']
    for f in basic_fields:
        if f not in params or params[f] in [None, '']:
            fields_to_prompt.append(f)
    
    # Only prompt for advanced fields if user requests them
    # This logic can be extended based on user input analysis
    advanced_fields = {
        'SoftDueDate': 'soft due date',
        'FinalDueDate': 'final due date (for recurring tasks)',
        'Items': 'checklist items',
        'IsRecurring': 'recurrence (daily/weekly/monthly/annual)',
        'BusinessDayBehavior': 'business day behavior',
        'IsReminder': 'reminders',
        'AddToPriorityList': 'priority list'
    }
    
    # Check if user has requested any advanced features
    user_input = params.get('user_input', '').lower()
    for field, description in advanced_fields.items():
        if any(keyword in user_input for keyword in description.split()):
            if field not in params or params[field] in [None, '']:
                fields_to_prompt.append(field)
    
    return params, fields_to_prompt

def parse_recurrence_from_user_input(user_input):
    """
    Parse recurrence information from user input and set appropriate defaults.
    Returns updated params dict.
    """
    user_input_lower = user_input.lower()
    params = {}
    
    # Check for recurrence keywords
    if 'daily' in user_input_lower:
        params['IsRecurring'] = 1
        params['FreqType'] = 2  # Daily
        
        # Check for specific days (e.g., "Monday through Friday")
        if any(day in user_input_lower for day in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']):
            # Convert to weekly with bitmask
            params['FreqType'] = 3  # Weekly
            params['FreqRecurrance'] = 1
            
            # Build bitmask for specified days
            bitmask = 0
            if 'monday' in user_input_lower:
                bitmask |= 2
            if 'tuesday' in user_input_lower:
                bitmask |= 4
            if 'wednesday' in user_input_lower:
                bitmask |= 8
            if 'thursday' in user_input_lower:
                bitmask |= 16
            if 'friday' in user_input_lower:
                bitmask |= 32
            if 'saturday' in user_input_lower:
                bitmask |= 64
            if 'sunday' in user_input_lower:
                bitmask |= 1
            
            params['FreqInterval'] = bitmask
            params['BusinessDayBehavior'] = 0  # can be due on weekends/holidays
        else:
            # Daily without specific days - default to skip weekends/holidays
            params['BusinessDayBehavior'] = 1  # skip weekends/holidays
            
    elif 'weekly' in user_input_lower:
        params['IsRecurring'] = 1
        params['FreqType'] = 3  # Weekly
        params['FreqRecurrance'] = 1
        params['BusinessDayBehavior'] = 0  # can be due on weekends/holidays
        
    elif 'monthly' in user_input_lower:
        params['IsRecurring'] = 1
        params['FreqType'] = 4  # Monthly
        params['FreqRecurrance'] = 1
        params['BusinessDayBehavior'] = 0  # can be due on weekends/holidays
        
    elif 'annual' in user_input_lower or 'yearly' in user_input_lower:
        params['IsRecurring'] = 1
        params['FreqType'] = 5  # Yearly
        params['FreqRecurrance'] = 1
        params['BusinessDayBehavior'] = 0  # can be due on weekends/holidays
    
    return params

# --- Recurrence/Bitmask Mapping ---
FREQ_TYPE_MAP = {
    1: 'One Time',
    2: 'Every (freqRecurrance) Days',
    3: 'Every (freqRecurrance) Weeks on (freqInterval)',
    4: 'Every (freqRecurrance) Months',
    5: 'Yearly in (freqInterval) Month',
}

WEEKDAY_BITMASK = {
    1: 'Sunday', 2: 'Monday', 4: 'Tuesday', 8: 'Wednesday', 16: 'Thursday', 32: 'Friday', 64: 'Saturday'
}

MONTH_BITMASK = {
    1: 'Jan', 2: 'Feb', 4: 'Mar', 8: 'Apr', 16: 'May', 32: 'June', 64: 'Jul', 128: 'Aug', 256: 'Sep', 512: 'Oct', 1024: 'Nov', 2048: 'Dec'
}

def describe_recurrence(freq_type, freq_recurrance, freq_interval):
    """Convert recurrence parameters to human-readable description."""
    if freq_type == 1:
        return "One Time"
    elif freq_type == 2:
        return f"Every {freq_recurrance} Day(s)"
    elif freq_type == 3 and freq_interval:
        # Weekly bitmask
        days = [name for bit, name in WEEKDAY_BITMASK.items() if freq_interval & bit]
        if days:
            return f"Every {freq_recurrance} Week(s) on {', '.join(days)}"
        else:
            return f"Every {freq_recurrance} Week(s)"
    elif freq_type == 4:
        if freq_interval:
            # Monthly bitmask
            months = [name for bit, name in MONTH_BITMASK.items() if freq_interval & bit]
            if months:
                return f"Every {freq_recurrance} Month(s) in {', '.join(months)}"
        return f"Every {freq_recurrance} Month(s)"
    elif freq_type == 5 and freq_interval:
        # Yearly bitmask
        months = [name for bit, name in MONTH_BITMASK.items() if freq_interval & bit]
        if months:
            return f"Yearly in {', '.join(months)}"
    return "Unknown recurrence" 