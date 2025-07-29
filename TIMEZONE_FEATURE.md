# Timezone Auto-Detection Feature

## Overview
The Acme Chatbot now automatically detects the user's timezone and uses it for date/time calculations, eliminating the need for users to manually specify their timezone. The system is now **current date aware**, meaning it automatically knows today's date and can calculate relative dates like "tomorrow" correctly. Additionally, if users don't provide a due date, the system automatically defaults to **tomorrow at 7 PM** in their timezone.

## Features

### Frontend Changes
- **Automatic Timezone Detection**: Uses `Intl.DateTimeFormat().resolvedOptions().timeZone` to detect the user's timezone
- **Visual Indicator**: Displays the detected timezone in the UI with a 📍 icon
- **Automatic Transmission**: Sends timezone information with every chat message to the backend

### Backend Changes
- **Timezone Reception**: Backend receives timezone information from frontend requests
- **Current Date Awareness**: System automatically knows today's date in user's timezone
- **Default Due Date**: Automatically sets due date to tomorrow at 7 PM if not provided
- **Enhanced AI Prompt**: System prompt includes user's timezone and current date for better date/time interpretation
- **Advanced Natural Language Processing**: Improved parsing of relative dates and times in user's timezone
- **Timezone Conversion**: Utility functions to convert dates and times to user's timezone

## Technical Implementation

### Frontend (React)
```javascript
// Timezone detection in useEffect
const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
setUserTimezone(timezone);

// Sending timezone with requests
body: JSON.stringify({ 
  message: input, 
  user: selectedUser,
  timezone: userTimezone 
})
```

### Backend (Django)
```python
# Receiving timezone from frontend
user_timezone = request.data.get('timezone', 'UTC')

# Get current date in user's timezone
current_date = get_current_date_in_timezone(user_timezone)

# Enhanced system prompt with current date and default behavior
system_prompt = f"You are a helpful assistant. The user's timezone is {user_timezone} and today's date is {current_date.isoformat()}. ..."

# Default due date function
def set_default_due_date_time(params, user_timezone):
    # Sets DueDate to tomorrow, DueTime to 19:00 (7 PM)
    # Automatically sets LocalDueDate and SoftDueDate to match DueDate

# Automatic parameters function
def set_automatic_parameters(params, user_timezone):
    # Sets Location to user's timezone, Activate to 1, FinalDueDate to match DueDate
    # Sets AddToPriorityList to 0, IsReminder to 1, ReminderDate to day before DueDate
    
# Advanced natural language parsing
def parse_natural_date_with_timezone(date_str, user_timezone):
    # Handles: today, tomorrow, next week, next month, in X days, etc.
    
def parse_natural_time_with_timezone(time_str, user_timezone):
    # Handles: morning, afternoon, evening, night, noon, etc.
```

## Supported Natural Language Patterns

### Date Patterns
- **Relative Dates**: `today`, `tomorrow`, `yesterday`, `day after tomorrow`
- **Week References**: `next week`, `this week`
- **Month References**: `next month`, `this month`
- **Day Counts**: `in 3 days`, `in 1 day`, `in 5 days`
- **Exact Dates**: `2024-01-15` (YYYY-MM-DD format)

### Time Patterns
- **Morning**: `morning`, `early morning`, `late morning` → 09:00, 11:00
- **Afternoon**: `afternoon`, `early afternoon`, `late afternoon` → 14:00, 16:00
- **Evening**: `evening`, `early evening`, `late evening` → 18:00, 20:00
- **Night**: `night`, `late night`, `midnight` → 22:00, 00:00
- **Business Hours**: `after close`, `before close` → 17:00, 16:00
- **Exact Times**: `14:30` (HH:MM format)

## Default Due Date Behavior

### Automatic Defaults
When users don't specify a due date or time, the system automatically applies these defaults:
- **DueDate**: Tomorrow's date in user's timezone
- **LocalDueDate**: Automatically set to match DueDate
- **SoftDueDate**: Automatically set to match DueDate
- **FinalDueDate**: Automatically set to match DueDate
- **DueTime**: 19:00 (7 PM) in 24-hour format

### Automatic Parameters
The system automatically sets these parameters without user input:
- **Location**: User's timezone (e.g., "America/New_York", "Europe/London")
- **Activate**: Always set to 1 (task is always active)
- **FinalDueDate**: Automatically matches the DueDate value
- **AddToPriorityList**: Defaults to 0 (not in priority list) unless user specifies
- **IsReminder**: Defaults to 1 (reminder enabled) unless user specifies
- **ReminderDate**: Defaults to the day before the due date unless user specifies

### Smart Default Application
- **Preserves User Input**: If user provides a date or time, defaults are not applied
- **Timezone Aware**: Defaults are calculated in user's local timezone
- **Current Date Aware**: "Tomorrow" is calculated based on actual current date
- **Auto-Sync**: LocalDueDate, SoftDueDate, and FinalDueDate always match the DueDate value

### Simplified User Experience
- **No Repeated Questions**: LocalDueDate, SoftDueDate, FinalDueDate, Location, Activate, AddToPriorityList, IsReminder, and ReminderDate are automatically set
- **Consistent Dates**: All date fields are synchronized to the same value
- **Reduced Complexity**: Users only need to specify the main due date and essential task information
- **Automatic Location**: No need to specify location - uses user's timezone
- **Always Active**: Tasks are automatically activated
- **Smart Reminders**: Reminders are enabled by default and set to the day before the due date
- **Priority Management**: Tasks are not added to priority list by default

## Benefits
1. **User Experience**: No need to manually specify timezone, current date, due date, location, activation status, priority, or reminder settings
2. **Accuracy**: All date/time calculations are done in user's local timezone with current date awareness
3. **Natural Language**: Better understanding of relative time references
4. **Consistency**: All time-related fields are automatically converted and synchronized
5. **Intelligence**: System automatically calculates "tomorrow" as today + 1 day in user's timezone
6. **Convenience**: Users can create tasks without specifying due dates - defaults to tomorrow at 7 PM
7. **Automatic Configuration**: Location, activation status, date synchronization, priority, and reminder settings are handled automatically
8. **Reduced Complexity**: Fewer fields for users to specify, leading to faster task creation
9. **Smart Reminders**: Reminders are automatically enabled and set to the day before the due date
10. **Priority Management**: Tasks are not added to priority list by default, keeping it clean

## Dependencies Added
- `pytz==2024.1`: Python timezone library
- `python-dateutil==2.8.2`: Enhanced date parsing

## Testing
Run the test script to verify timezone functionality:
```bash
python test_timezone.py
```

## Usage Examples

### With Default Due Date
- User says "Create a meeting" → Automatically set to tomorrow at 7 PM in their timezone
- User says "Task for project review" → Automatically set to tomorrow at 7 PM in their timezone
- User says "Reminder to call client" → Automatically set to tomorrow at 7 PM in their timezone

### With Partial Information
- User says "meeting tomorrow at 2pm" → Due date: tomorrow, Due time: 14:00, Local/Soft/Final: tomorrow, Location: user's timezone, Activate: 1, AddToPriorityList: 0, IsReminder: 1, ReminderDate: today
- User says "task due next week" → Due date: next week, Due time: 19:00 (default), Local/Soft/Final: next week, Location: user's timezone, Activate: 1, AddToPriorityList: 0, IsReminder: 1, ReminderDate: day before next week
- User says "reminder this afternoon" → Due date: today, Due time: 14:00, Local/Soft/Final: today, Location: user's timezone, Activate: 1, AddToPriorityList: 0, IsReminder: 1, ReminderDate: yesterday
- User says "in 3 days" → Due date: today + 3 days, Due time: 19:00 (default), Local/Soft/Final: today + 3 days, Location: user's timezone, Activate: 1, AddToPriorityList: 0, IsReminder: 1, ReminderDate: today + 2 days

### With Complete Information
- User says "Meeting on 2024-01-20 at 15:30" → Due date: 2024-01-20, Due time: 15:30

## Browser Compatibility
Timezone detection works in all modern browsers that support the `Intl` API (Chrome, Firefox, Safari, Edge).

## Current Date Awareness
The system now automatically:
- Detects the current date in the user's timezone
- Provides this information to the AI assistant
- Calculates relative dates based on the actual current date
- Handles timezone transitions (daylight saving time, etc.)
- Applies intelligent defaults when due dates are not specified

This means when a user says "tomorrow", the system knows exactly what date that is in their timezone, regardless of when the request is made. If they don't specify a due date at all, it defaults to tomorrow at 7 PM in their local time. 