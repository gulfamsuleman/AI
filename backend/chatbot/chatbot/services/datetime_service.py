"""
DateTime Service Module

This module provides centralized datetime functionality for the chatbot application,
including timezone handling, natural language date/time parsing, and smart defaults.
"""

import datetime
import pytz
import re
import logging
import calendar
from dateutil.relativedelta import relativedelta

logger = logging.getLogger(__name__)


class DateTimeService:
    """
    Service class for handling datetime operations, timezone conversions,
    and natural language date/time parsing.
    """

    @staticmethod
    def convert_to_user_timezone(date_str, time_str, user_timezone):
        """
        Convert date and time strings to the user's timezone.
        
        Args:
            date_str (str|date): Date string in 'YYYY-MM-DD' format or date object
            time_str (str|time): Time string in 'HH:MM' format or time object
            user_timezone (str): Timezone string (e.g., 'America/New_York')
            
        Returns:
            tuple: (date_str, time_str) converted to user timezone
            
        Raises:
            None: Returns original values if conversion fails
        """
        try:
            if not date_str or not time_str:
                return date_str, time_str
                
            # Parse the date and time
            if isinstance(date_str, str):
                date_obj = datetime.datetime.strptime(date_str, '%Y-%m-%d').date()
            else:
                date_obj = date_str
                
            if isinstance(time_str, str):
                time_obj = datetime.datetime.strptime(time_str, '%H:%M').time()
            else:
                time_obj = time_str
                
            # Combine date and time
            datetime_obj = datetime.datetime.combine(date_obj, time_obj)
            
            # Convert to user timezone
            user_tz = pytz.timezone(user_timezone)
            local_dt = user_tz.localize(datetime_obj)
            
            return local_dt.date().isoformat(), local_dt.time().strftime('%H:%M')
        except Exception as e:
            logger.warning(f"Failed to convert to user timezone: {e}")
            # If conversion fails, return original values
            return date_str, time_str

    @staticmethod
    def get_current_date_in_timezone(user_timezone):
        """
        Get the current date in the user's timezone.
        
        Args:
            user_timezone (str): Timezone string (e.g., 'America/New_York')
            
        Returns:
            date: Current date in the specified timezone
            
        Raises:
            None: Returns UTC date if timezone is invalid
        """
        try:
            user_tz = pytz.timezone(user_timezone)
            current_time = datetime.datetime.now(user_tz)
            return current_time.date()
        except Exception as e:
            logger.warning(f"Invalid timezone '{user_timezone}': {e}")
            # Fallback to UTC if timezone is invalid
            return datetime.date.today()

    @classmethod
    def parse_natural_date_with_timezone(cls, date_str, user_timezone):
        """
        Parse natural language dates in the context of user's timezone.
        
        Args:
            date_str (str): Natural language date string (e.g., 'tomorrow', 'next monday')
            user_timezone (str): Timezone string for context
            
        Returns:
            str|None: ISO format date string (YYYY-MM-DD) or None if parsing fails
        """
        # Get current date in user's timezone
        today = cls.get_current_date_in_timezone(user_timezone)
        
        if not date_str:
            return None
        
        s = date_str.strip().lower()
        
        # Handle relative dates
        if s == 'today':
            return today.isoformat()
        elif s == 'tomorrow' or s == 'tmrw':
            return (today + datetime.timedelta(days=1)).isoformat()
        elif s == 'day after tomorrow' or s == 'day after tmrw':
            return (today + datetime.timedelta(days=2)).isoformat()
        elif s == 'yesterday':
            return (today - datetime.timedelta(days=1)).isoformat()
        
        # Handle "next [weekday]" patterns - FIXED!
        weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
        for i, day_name in enumerate(weekdays):
            if f'next {day_name}' in s:
                current_weekday = today.weekday()
                target_weekday = i
                days_ahead = (target_weekday - current_weekday) % 7
                if days_ahead == 0:
                    days_ahead = 7  # If today is the target day, go to next week
                target_date = today + datetime.timedelta(days=days_ahead)
                logger.debug(f"Parsed 'next {day_name}' as {target_date.isoformat()}")
                return target_date.isoformat()
        
        # Handle "this [weekday]" patterns
        for i, day_name in enumerate(weekdays):
            if f'this {day_name}' in s:
                current_weekday = today.weekday()
                target_weekday = i
                days_ahead = (target_weekday - current_weekday) % 7
                # For "this", include today if it matches
                target_date = today + datetime.timedelta(days=days_ahead)
                logger.debug(f"Parsed 'this {day_name}' as {target_date.isoformat()}")
                return target_date.isoformat()
        
        # Handle plain weekday names (e.g., "friday", "monday") - assumes nearest upcoming occurrence
        # This should come AFTER "next" and "this" patterns so those take precedence
        for i, day_name in enumerate(weekdays):
            # Match just the weekday name (not as part of "next friday" or "this friday")
            if day_name in s and f'next {day_name}' not in s and f'this {day_name}' not in s:
                current_weekday = today.weekday()
                target_weekday = i
                days_ahead = (target_weekday - current_weekday) % 7
                
                # If days_ahead is 0, it means today is that weekday
                # For plain weekday reference like "friday", if today is Friday, assume next Friday
                if days_ahead == 0:
                    days_ahead = 7  # Go to next week
                
                target_date = today + datetime.timedelta(days=days_ahead)
                logger.debug(f"Parsed plain weekday '{day_name}' as {target_date.isoformat()} ({days_ahead} days ahead)")
                return target_date.isoformat()
        
        # Handle "next quarter" as 90 days from today (non-recurring)
        if 'next quarter' in s:
            target_date = today + datetime.timedelta(days=90)
            logger.debug(f"Parsed 'next quarter' as {target_date.isoformat()} (90 days from today)")
            return target_date.isoformat()
        
        # Handle end of week/month
        if 'end of week' in s or 'end of the week' in s:
            # Go to Friday - matching validator logic
            days_until_friday = (4 - today.weekday()) % 7
            if days_until_friday == 0:
                days_until_friday = 7  # If today is Friday, go to next Friday
            return (today + datetime.timedelta(days=days_until_friday)).isoformat()
        
        elif s.startswith('next week'):
            return (today + datetime.timedelta(weeks=1)).isoformat()
        elif s.startswith('next month'):
            # Add one month to current date
            next_month = today.replace(day=1) + datetime.timedelta(days=32)
            next_month = next_month.replace(day=1)
            return next_month.isoformat()
        elif s.startswith('this week'):
            # Find the start of current week (Monday)
            days_since_monday = today.weekday()
            monday = today - datetime.timedelta(days=days_since_monday)
            return monday.isoformat()
        elif s.startswith('this month'):
            # First day of current month
            first_day = today.replace(day=1)
            return first_day.isoformat()
        elif s.startswith('in ') and ' days' in s:
            # Handle "in X days"
            try:
                days = int(s.split('in ')[1].split(' days')[0])
                return (today + datetime.timedelta(days=days)).isoformat()
            except:
                pass
        elif s.startswith('in ') and ' day' in s:
            # Handle "in X day" (singular)
            try:
                days = int(s.split('in ')[1].split(' day')[0])
                return (today + datetime.timedelta(days=days)).isoformat()
            except:
                pass
        
        # If already in YYYY-MM-DD format, return as is
        try:
            datetime.datetime.strptime(date_str, '%Y-%m-%d')
            return date_str
        except Exception:
            return None

    @staticmethod
    def parse_natural_time_with_timezone(time_str, user_timezone):
        """
        Parse natural language time references in the context of user's timezone.
        
        Args:
            time_str (str): Natural language time string (e.g., 'morning', '2pm')
            user_timezone (str): Timezone string for context
            
        Returns:
            str|None: Time string in HH:MM format or None if parsing fails
        """
        if not time_str:
            return None
        
        s = time_str.strip().lower()
        
        # Handle common time references
        if s == 'morning' or s == 'early morning':
            return '09:00'
        elif s == 'late morning':
            return '11:00'
        elif s == 'noon' or s == 'midday':
            return '12:00'
        elif s == 'afternoon' or s == 'early afternoon':
            return '14:00'
        elif s == 'late afternoon':
            return '16:00'
        elif s == 'evening' or s == 'early evening':
            return '18:00'
        elif s == 'late evening':
            return '20:00'
        elif s == 'night' or s == 'late night':
            return '22:00'
        elif s == 'midnight':
            return '00:00'
        elif s == 'after close' or s == 'after closing':
            return '19:00'  # 7 PM after close
        elif s == 'before close' or s == 'before closing':
            return '16:00'
        
        # Handle AM/PM format (e.g., "2pm", "12:30am", "3:45 PM")
        am_pm_match = re.match(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)', s)
        if am_pm_match:
            hour = int(am_pm_match.group(1))
            minute = int(am_pm_match.group(2) or 0)
            meridian = am_pm_match.group(3)
            
            # Convert to 24-hour format
            if meridian == 'pm' and hour != 12:
                hour += 12
            elif meridian == 'am' and hour == 12:
                hour = 0
                
            return f"{hour:02d}:{minute:02d}"
        
        # If already in HH:MM format, return as is
        try:
            datetime.datetime.strptime(time_str, '%H:%M')
            return time_str
        except Exception:
            return None

    @staticmethod
    def parse_natural_date(date_str):
        """
        Parse natural language dates (timezone-agnostic version).
        
        Args:
            date_str (str): Natural language date string
            
        Returns:
            str|None: ISO format date string (YYYY-MM-DD) or None if parsing fails
        """
        today = datetime.date.today()
        if not date_str:
            return None
        s = date_str.strip().lower()
        if s == 'today':
            return today.isoformat()
        if s == 'tomorrow' or s == 'tmrw':
            return (today + datetime.timedelta(days=1)).isoformat()
        if s == 'day after tomorrow':
            return (today + datetime.timedelta(days=2)).isoformat()
        if s == 'yesterday':
            return (today - datetime.timedelta(days=1)).isoformat()
        
        # Handle "next [weekday]" patterns
        weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
        for i, day_name in enumerate(weekdays):
            if f'next {day_name}' in s:
                current_weekday = today.weekday()
                target_weekday = i
                days_ahead = (target_weekday - current_weekday) % 7
                if days_ahead == 0:
                    days_ahead = 7  # If today is the target day, go to next week
                return (today + datetime.timedelta(days=days_ahead)).isoformat()
        
        # Handle "this [weekday]" patterns
        for i, day_name in enumerate(weekdays):
            if f'this {day_name}' in s:
                current_weekday = today.weekday()
                target_weekday = i
                days_ahead = (target_weekday - current_weekday) % 7
                return (today + datetime.timedelta(days=days_ahead)).isoformat()
        
        if s.startswith('next week'):
            return (today + datetime.timedelta(weeks=1)).isoformat()
        # Add more patterns as needed
        # If already in YYYY-MM-DD, return as is
        try:
            datetime.datetime.strptime(date_str, '%Y-%m-%d')
            return date_str
        except Exception:
            return None

    @staticmethod
    def parse_natural_time(time_str):
        """
        Parse natural language time references (timezone-agnostic version).
        
        Args:
            time_str (str): Natural language time string
            
        Returns:
            str|None: Time string in HH:MM format or None if parsing fails
        """
        if not time_str:
            return None
        s = time_str.strip().lower()
        if s == 'morning':
            return '10:00'
        if s == 'after close':
            return '15:00'
        if s == 'evening':
            return '19:00'
        # If already in HH:MM format, return as is
        try:
            datetime.datetime.strptime(time_str, '%H:%M')
            return time_str
        except Exception:
            return None

    @staticmethod
    def _calculate_monthly_recurring_due_date(current_date, target_day):
        """
        Calculate the next occurrence of a specific day of the month for monthly recurring tasks.
        
        Args:
            current_date: Current date object
            target_day: Day of month (1-31)
            
        Returns:
            str: ISO format date string for the next occurrence
        """
        try:
            # Get current month and year
            current_year = current_date.year
            current_month = current_date.month
            
            # Try to create the target date for this month
            try:
                target_date_this_month = datetime.date(current_year, current_month, target_day)
                
                # If the target date is today or in the future, use it
                if target_date_this_month >= current_date:
                    return target_date_this_month.isoformat()
                else:
                    # Target date has passed this month, go to next month
                    if current_month == 12:
                        next_year = current_year + 1
                        next_month = 1
                    else:
                        next_year = current_year
                        next_month = current_month + 1
                    
                    # Handle months with fewer days (e.g., Feb 30 -> Feb 28/29)
                    try:
                        target_date_next_month = datetime.date(next_year, next_month, target_day)
                        return target_date_next_month.isoformat()
                    except ValueError:
                        # Target day doesn't exist in next month, use last day of that month
                        last_day = calendar.monthrange(next_year, next_month)[1]
                        target_date_next_month = datetime.date(next_year, next_month, last_day)
                        return target_date_next_month.isoformat()
                        
            except ValueError:
                # Target day doesn't exist in current month (e.g., Feb 30), use last day of current month
                last_day = calendar.monthrange(current_year, current_month)[1]
                target_date_this_month = datetime.date(current_year, current_month, last_day)
                
                if target_date_this_month >= current_date:
                    return target_date_this_month.isoformat()
                else:
                    # Go to next month
                    if current_month == 12:
                        next_year = current_year + 1
                        next_month = 1
                    else:
                        next_year = current_year
                        next_month = current_month + 1
                    
                    # Handle next month
                    try:
                        target_date_next_month = datetime.date(next_year, next_month, target_day)
                        return target_date_next_month.isoformat()
                    except ValueError:
                        last_day = calendar.monthrange(next_year, next_month)[1]
                        target_date_next_month = datetime.date(next_year, next_month, last_day)
                        return target_date_next_month.isoformat()
                        
        except Exception as e:
            logger.error(f"Error calculating monthly recurring due date: {e}")
            # Fallback to tomorrow
            return (current_date + datetime.timedelta(days=1)).isoformat()

    @staticmethod
    def _calculate_next_weekly_due_date(current_date, weekday_bits):
        """
        Given a bitmask of weekdays (Sun=1, Mon=2, Tue=4, Wed=8, Thu=16, Fri=32, Sat=64),
        return the next date (>= tomorrow) that matches one of the bits.
        Prefer the soonest upcoming occurrence; if today matches, use today.
        """
        # Map Python weekday (Mon=0..Sun=6) to bit values used by system (Sun=1, Mon=2, Tue=4, Wed=8, Thu=16, Fri=32, Sat=64)
        py_to_bit = {0: 2, 1: 4, 2: 8, 3: 16, 4: 32, 5: 64, 6: 1}
        for delta in range(0, 14):  # look ahead up to two weeks
            candidate = current_date + datetime.timedelta(days=delta)
            bit = py_to_bit[candidate.weekday()]
            if weekday_bits & bit:
                return candidate.isoformat()
        # Fallback: tomorrow
        return (current_date + datetime.timedelta(days=1)).isoformat()

    @staticmethod
    def _calculate_yearly_recurring_due_date(current_date, month_bitmask: int, day_of_month: int = 1) -> str:
        """
        Given a month bitmask (Jan=1, Feb=2, Mar=4, ... Dec=2048), find the next occurrence date
        using the earliest upcoming month in the mask at the specified day_of_month.
        If the chosen month doesn't have that day (e.g., day 31 in Feb), use the month's last day.
        """
        # Build ordered list of months starting from current month
        months = list(range(1, 13))
        # Month bits mapping
        month_to_bit = {1:1, 2:2, 3:4, 4:8, 5:16, 6:32, 7:64, 8:128, 9:256, 10:512, 11:1024, 12:2048}
        # Try this year first
        for offset in [0, 1]:  # this year, next year
            year = current_date.year + offset
            start_month = current_date.month if offset == 0 else 1
            for m in range(start_month, 13):
                if month_bitmask & month_to_bit[m]:
                    # Determine day within month
                    try:
                        candidate = datetime.date(year, m, day_of_month)
                    except ValueError:
                        # Use last day of month
                        last_day = calendar.monthrange(year, m)[1]
                        candidate = datetime.date(year, m, last_day)
                    if candidate >= current_date:
                        return candidate.isoformat()
        # Fallback to one month ahead
        next_month = (current_date.month % 12) + 1
        year = current_date.year + (1 if next_month == 1 else 0)
        try:
            candidate = datetime.date(year, next_month, day_of_month)
        except ValueError:
            last_day = calendar.monthrange(year, next_month)[1]
            candidate = datetime.date(year, next_month, last_day)
        return candidate.isoformat()

    @staticmethod
    def guess_time_from_task_type(task_name):
        """
        Guess appropriate time based on task type.
        
        Args:
            task_name (str): Name of the task
            
        Returns:
            str: Time in HH:MM format based on task type patterns
        """
        task_lower = task_name.lower()
        
        # Meeting patterns
        if any(word in task_lower for word in ['meeting', 'standup', 'sync', 'huddle', 'call']):
            return '14:00'  # 2 PM for meetings
        
        # Morning tasks
        elif any(word in task_lower for word in ['check email', 'daily check', 'morning']):
            return '09:00'  # 9 AM for morning tasks
        
        # Reports/reviews
        elif any(word in task_lower for word in ['report', 'review', 'analysis', 'summary']):
            return '19:00'  # 7 PM for reports
        
        # Reminders
        elif 'remind' in task_lower:
            return '10:00'  # 10 AM for reminders
        
        # End of day tasks
        elif any(word in task_lower for word in ['end of day', 'eod', 'close']):
            return '19:00'  # 7 PM default
        
        # Default
        else:
            return '19:00'  # 7 PM default - per requirement

    @classmethod
    def set_default_due_date_time(cls, params, user_timezone):
        """
        Set default due date to tomorrow at smart time based on task type.
        Default time is 19:00 (7:00 PM) local time when not specified.
        Also automatically set LocalDueDate and SoftDueDate to match the DueDate.
        
        Args:
            params (dict): Task parameters dictionary to modify
            user_timezone (str): User's timezone string
            
        Returns:
            dict: Modified parameters with default due date and time set
        """
        current_date = cls.get_current_date_in_timezone(user_timezone)
        tomorrow = current_date + datetime.timedelta(days=1)
        
        # Set default due date if not provided
        if not params.get('DueDate') or params['DueDate'] in [None, '']:
            # Check for urgency indicators
            task_name = params.get('TaskName', '').lower()
            if any(word in task_name for word in ['urgent', 'asap', 'immediately', 'now']):
                params['DueDate'] = current_date.isoformat()  # Today for urgent tasks
            else:
                # Special handling for monthly recurring tasks with specific day
                if (params.get('IsRecurring') == 1 and 
                    params.get('FreqType') == 4 and 
                    params.get('FreqRecurrance') and 
                    isinstance(params.get('FreqRecurrance'), int) and 
                    1 <= params.get('FreqRecurrance') <= 31):
                    # This is a monthly recurring task with a specific day of month
                    target_day = params.get('FreqRecurrance')
                    params['DueDate'] = cls._calculate_monthly_recurring_due_date(current_date, target_day)
                # Weekly recurring tasks (FreqType=3): default to tomorrow, stored procedure handles recurrence
                # For FreqType=3: FreqRecurrance=weeks count (1,2,3...), FreqInterval=day bitmask
                # The first occurrence defaults to tomorrow, then repeats based on FreqInterval weekday
                elif (params.get('IsRecurring') == 1 and params.get('FreqType') == 3):
                    params['DueDate'] = tomorrow.isoformat()
                    logger.debug(f"FreqType=3 (Weekly): Setting first due date to tomorrow: {params['DueDate']}")
                # Special handling for yearly recurring tasks: pick next occurrence of specified month(s)
                elif (params.get('IsRecurring') == 1 and 
                      params.get('FreqType') == 5 and 
                      isinstance(params.get('FreqInterval'), int) and 
                      params.get('FreqInterval') > 0):
                    # FreqInterval (and/or FreqRecurrance) contains month bitmask
                    month_mask = params.get('FreqInterval') or params.get('FreqRecurrance')
                    params['DueDate'] = cls._calculate_yearly_recurring_due_date(current_date, month_mask, day_of_month=1)
                # Quarterly recurring tasks (FreqType=6): always default to tomorrow
                elif (params.get('IsRecurring') == 1 and params.get('FreqType') == 6):
                    params['DueDate'] = tomorrow.isoformat()
                    logger.debug(f"FreqType=6 (Quarterly): Setting first due date to tomorrow: {params['DueDate']}")
                else:
                    params['DueDate'] = tomorrow.isoformat()  # Tomorrow by default
        
        # Set default due time if not provided - use smart defaults
        if not params.get('DueTime') or params['DueTime'] in [None, '']:
            task_name = params.get('TaskName', '')
            params['DueTime'] = cls.guess_time_from_task_type(task_name)
        
        # Always set LocalDueDate to match the DueDate
        params['LocalDueDate'] = params['DueDate']
        
        # Only set SoftDueDate to match DueDate if not explicitly provided
        if not params.get('SoftDueDate') or params['SoftDueDate'] in [None, '']:
            params['SoftDueDate'] = params['DueDate']
        
        return params