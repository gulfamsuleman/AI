"""
Schedule Parser for QProcess Chatbot
Handles complex recurring patterns with bitmask calculations for FreqRecurrance field

FreqType values:
1 = One Time
2 = Every (freqRecurrance) Days
3 = Every (freqRecurrance) Weeks on (freqInterval)
4 = Every (freqRecurrance) Months
5 = Yearly in (freqInterval) Month

FreqRecurrance and FreqInterval encoding:
- FreqType 1 (One Time): FreqInterval = Day of week bitmask (Sun=1, Mon=2, Tue=4, Wed=8, Thu=16, Fri=32, Sat=64)
- FreqType 2 (Days): FreqInterval = Day of week bitmask (Sun=1, Mon=2, Tue=4, Wed=8, Thu=16, Fri=32, Sat=64)
- FreqType 3 (Weeks): FreqRecurrance = Weeks count (1=weekly, 2=biweekly), FreqInterval = Day of week bitmask (Sun=1, Mon=2, Tue=4, Wed=8, Thu=16, Fri=32, Sat=64)
- FreqType 4 (Months): FreqRecurrance = Day of month (1-31), FreqInterval = Month bitmask (Jan=1, Feb=2, Mar=4, Apr=8, May=16, Jun=32, Jul=64, Aug=128, Sep=256, Oct=512, Nov=1024, Dec=2048)
- FreqType 5 (Yearly): FreqRecurrance = Month bitmask (Jan=1, Feb=2, Mar=4, Apr=8, May=16, Jun=32, Jul=64, Aug=128, Sep=256, Oct=512, Nov=1024, Dec=2048)
"""

import re
from datetime import datetime, timedelta
import calendar
import logging

logger = logging.getLogger(__name__)

class ScheduleParser:
    """Parse natural language schedules into QProcess parameters"""
    
    # Day of week mappings for weekly bitmasks
    WEEKDAY_BITS = {
        'sunday': 1, 'sun': 1,
        'monday': 2, 'mon': 2,
        'tuesday': 4, 'tue': 4, 'tues': 4,
        'wednesday': 8, 'wed': 8,
        # Common misspellings
        'wedeneday': 8, 'wedneseday': 8,
        'thursday': 16, 'thu': 16, 'thur': 16, 'thurs': 16,
        'friday': 32, 'fri': 32,
        'saturday': 64, 'sat': 64
    }
    
    # Month mappings for yearly bitmasks
    MONTH_BITS = {
        'january': 1, 'jan': 1,
        'february': 2, 'feb': 2,
        'march': 4, 'mar': 4,
        'april': 8, 'apr': 8,
        'may': 16,
        'june': 32, 'jun': 32,
        'july': 64, 'jul': 64,
        'august': 128, 'aug': 128,
        'september': 256, 'sep': 256, 'sept': 256,
        'october': 512, 'oct': 512,
        'november': 1024, 'nov': 1024,
        'december': 2048, 'dec': 2048
    }
    
    # Quarter mappings
    QUARTER_BITS = {
        'q1': 1, 'first': 1, '1st': 1,
        'q2': 2, 'second': 2, '2nd': 2,
        'q3': 4, 'third': 4, '3rd': 4,
        'q4': 8, 'fourth': 8, '4th': 8
    }
    
    def __init__(self):
        self.logger = logger
    
    def _detect_business_day_behavior(self, msg):
        """
        Detect BusinessDayBehavior based on user prompt patterns.
        
        Returns:
        0: This task can be due on a weekend/holiday
        1: If it falls on a weekend or holiday, skip it
        2: If it falls on a weekend or holiday, move it to the previous business day
        3: If it falls on a weekend or holiday, move it to the next business day
        """
        msg_lower = msg.lower()
        
        # Pattern 1: Skip weekend/holiday
        skip_patterns = [
            'skip weekend', 'skip holidays', 'skip holiday',
            'no weekend', 'no holidays', 'no holiday',
            'weekdays only', 'business days only', 'business day only',
            'weekday only', 'weekdays', 'business days',
            'exclude weekend', 'exclude holidays', 'exclude holiday',
            'avoid weekend', 'avoid holidays', 'avoid holiday'
        ]
        if any(pattern in msg_lower for pattern in skip_patterns):
            return 1
        
        # Pattern 2: Move to previous business day
        previous_patterns = [
            'move to previous', 'previous business day', 'previous weekday',
            'move back', 'move earlier', 'earlier business day',
            'before weekend', 'before holiday', 'before holidays'
        ]
        if any(pattern in msg_lower for pattern in previous_patterns):
            return 2
        
        # Pattern 3: Move to next business day
        next_patterns = [
            'move to next', 'next business day', 'next weekday',
            'move forward', 'move later', 'later business day',
            'after weekend', 'after holiday', 'after holidays',
            'following business day', 'following weekday'
        ]
        if any(pattern in msg_lower for pattern in next_patterns):
            return 3
        
        # Default: Allow weekend/holiday
        return 0
    
    def _has_explicit_recurrence(self, msg):
        """Check if message has explicit recurrence pattern and return the pattern type"""
        explicit_patterns = [
            (r'recurring\s+(daily|weekly|bi-?weekly|monthly|quarterly|yearly|annually)', 1),
            (r'every\s+(day(?!\s+of\s+the\s+week)|week|month|quarter|year)', 1),  # Exclude "every day of the week"
            (r'repeat\s+(daily|weekly|monthly|quarterly|yearly)', 1),
            (r'repeats?\s+(daily|weekly|monthly|quarterly|yearly)', 1)
        ]
        
        for pattern, group_num in explicit_patterns:
            match = re.search(pattern, msg)
            if match:
                recurrence_type = match.group(group_num).lower()
                # Normalize variations
                if recurrence_type == 'day':
                    return 'daily'
                elif recurrence_type == 'week':
                    return 'weekly'
                elif recurrence_type in ['bi-weekly', 'biweekly']:
                    return 'biweekly'
                elif recurrence_type == 'month':
                    return 'monthly'
                elif recurrence_type == 'quarter':
                    return 'quarterly'
                elif recurrence_type in ['year', 'yearly', 'annually']:
                    return 'yearly'
                return recurrence_type
        return None
        
    def parse_schedule(self, message):
        """
        Parse a message and extract schedule parameters
        
        Returns dict with:
        - IsRecurring: 0 or 1
        - FreqType: 1-6 
        - FreqRecurrance: Bitmask value
        - FreqInterval: Interval multiplier (e.g., 2 for "every other")
        - BusinessDayBehavior: 0, 1, 2, or 3
        """
        msg_lower = message.lower()
        result = {
            'IsRecurring': 0,
            'FreqType': 0,
            'FreqRecurrance': 0,
            'FreqInterval': 1,
            'BusinessDayBehavior': self._detect_business_day_behavior(message)
        }
        
        # Check for non-recurring "next [weekday]" pattern first
        if self._is_next_weekday_pattern(msg_lower):
            self.logger.debug("Detected 'next [weekday]' pattern - not recurring")
            return result
        
        # Handle non-recurring quarter references before explicit recurrence
        # e.g., "due next quarter", "by next quarter", "this quarter" should be treated as one-time
        nonrecurring_quarter_patterns = [
            r'\bnext\s+quarter\b',
            r'\bthis\s+quarter\b',
            r'\bend\s+of\s+next\s+quarter\b',
            r'\bby\s+next\s+quarter\b',
            r'\bdue\s+next\s+quarter\b',
        ]
        if any(re.search(p, msg_lower) for p in nonrecurring_quarter_patterns):
            self.logger.debug("Detected non-recurring quarter reference (e.g., 'next quarter') - not recurring")
            return result

        # NEW: Check for explicit recurrence patterns first
        explicit_pattern = self._has_explicit_recurrence(msg_lower)
        if explicit_pattern:
            self.logger.debug(f"Detected explicit recurrence pattern: {explicit_pattern}")
            
            if explicit_pattern == 'daily':
                result.update(self._parse_daily(msg_lower))
                return result
            elif explicit_pattern in ['weekly', 'biweekly']:
                result.update(self._parse_weekly(msg_lower))
                return result
            elif explicit_pattern == 'monthly':
                result.update(self._parse_monthly(msg_lower))
                return result
            elif explicit_pattern == 'quarterly':
                result.update(self._parse_quarterly(msg_lower))
                return result
            elif explicit_pattern in ['yearly', 'annually']:
                result.update(self._parse_annual(msg_lower))
                return result
            
        # Check patterns in order of specificity (only if no explicit pattern found)
        # Daily should be checked before weekly since "daily" might trigger weekly pattern
        
        # Check for quarterly patterns
        if self._is_quarterly_pattern(msg_lower):
            result.update(self._parse_quarterly(msg_lower))
            return result
            
        # Check for annual/yearly patterns
        if self._is_annual_pattern(msg_lower):
            result.update(self._parse_annual(msg_lower))
            return result
            
        # Check for monthly patterns
        if self._is_monthly_pattern(msg_lower):
            result.update(self._parse_monthly(msg_lower))
            return result
            
        # Check for daily patterns BEFORE weekly
        if self._is_daily_pattern(msg_lower):
            result.update(self._parse_daily(msg_lower))
            return result
            
        # Check for weekly patterns
        if self._is_weekly_pattern(msg_lower):
            result.update(self._parse_weekly(msg_lower))
            return result
            
        return result
    
    def _is_next_weekday_pattern(self, msg):
        """Check if message contains 'next [weekday]', 'next week [weekday]', or '[weekday] next week' (non-recurring)"""
        next_day_patterns = [
            r'next\s+(?:week\s+)?(?:on\s+)?(monday|tuesday|wednesday|thursday|friday|saturday|sunday)',
            r'(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\s+next\s+week'
        ]
        return any(re.search(pattern, msg) for pattern in next_day_patterns)
    
    def _is_quarterly_pattern(self, msg):
        """Check if message contains quarterly pattern with scheduling context"""
        # Only match "quarterly" when it has scheduling context
        # This prevents "quarterly report" from being treated as a recurring task
        patterns = [
            r'\b(?:every|each|recurring|repeat|repeating)\s+quarter(?:ly)?',  # Requires scheduling context
            r'every\s+quarter',
            r'each\s+quarter',
            r'end\s+of\s+each\s+quarter',  # "end of each quarter" is recurring
            r'every\s+quarter\s+end'  # "every quarter end" is recurring
        ]
        return any(re.search(pattern, msg) for pattern in patterns)
    
    def _parse_quarterly(self, msg):
        """Parse quarterly schedules using FreqType=6.

        For quarterly recurrence we use FreqType=6 with FreqRecurrance=1 and FreqInterval=1.
        The first occurrence defaults to tomorrow at 7 PM (handled by default date logic),
        then repeats quarterly from that date.
        """
        result = {
            'IsRecurring': 1,
            'FreqType': 6,              # Quarterly recurrence
            'FreqRecurrance': 1,        # Standard quarterly interval
            'FreqInterval': 1,          # Standard interval
            'BusinessDayBehavior': self._detect_business_day_behavior(msg)
        }

        # If the message specifies particular quarters, note the selection
        if any(quarter in msg for quarter in self.QUARTER_BITS):
            bitmask = 0
            for quarter, bit in self.QUARTER_BITS.items():
                if quarter in msg:
                    bitmask |= bit
            if bitmask > 0:
                self.logger.debug(f"Quarterly with specific quarters mentioned. Quarter mask={bitmask}")

        # Note: We do NOT set a DueDate here - let the default date logic handle it
        # This ensures quarterly tasks start from tomorrow at 7 PM (the default)
        # and then repeat quarterly from that first occurrence
        # 
        # FreqType=6 should default to tomorrow at 7 PM unless user specifies a date

        self.logger.debug(f"Parsed quarterly schedule: {result}")
        return result
    
    def _is_annual_pattern(self, msg):
        """Check if message contains annual/yearly pattern with scheduling context"""
        # Don't match if explicitly monthly (handles "last day of year, recurring monthly" case)
        if any(phrase in msg for phrase in ['recurring monthly', 'every month', 'repeat monthly']):
            return False
        
        # Only match "annual/yearly" when it has scheduling context
        # This prevents "annual report" or "yearly review" from being treated as recurring tasks
        patterns = [
            r'\b(?:every|each|recurring|repeat|repeating)\s+(?:year(?:ly)?|annual(?:ly)?)',  # Requires scheduling context
            r'every\s+year',
            r'each\s+year',
            r'once\s+a\s+year',
            r'\bannually\b'  # "annually" by itself is clear scheduling intent
        ]
        return any(re.search(pattern, msg) for pattern in patterns)
    
    def _parse_annual(self, msg):
        """Parse annual/yearly schedules"""
        result = {
            'IsRecurring': 1,
            'FreqType': 5,  # Yearly in (freqInterval) Month
            'FreqRecurrance': 1,  # Default to January (month bitmask)
            'FreqInterval': 1,  # Default to January (month bitmask)
            'BusinessDayBehavior': self._detect_business_day_behavior(msg)
        }
        
        # Extract month from message
        month_bitmask = 0
        for month, bit in self.MONTH_BITS.items():
            if month in msg:
                month_bitmask |= bit
                
        if month_bitmask > 0:
            # For yearly, FreqRecurrance and FreqInterval both hold the month bitmask
            result['FreqRecurrance'] = month_bitmask
            result['FreqInterval'] = month_bitmask
            
        # Extract specific date if present  
        date_match = re.search(r'(\w+)\s+(\d{1,2})', msg)
        if date_match:
            month_str = date_match.group(1).lower()
            day = int(date_match.group(2))
            
            # Store month in bitmask
            if month_str in self.MONTH_BITS:
                result['FreqRecurrance'] = self.MONTH_BITS[month_str]
                result['FreqInterval'] = self.MONTH_BITS[month_str]
                # Note: Day of month would need to be stored separately in the system
                
        self.logger.debug(f"Parsed annual schedule: {result}")
        return result
    
    def _is_monthly_pattern(self, msg):
        """Check if message contains monthly pattern with scheduling context"""
        # Only match "monthly" when it has scheduling context (every, each, recurring, etc.)
        # This prevents "monthly report" from being treated as a recurring task
        patterns = [
            r'\b(?:every|each|recurring|repeat|repeating)\s+month(?:ly)?',  # Requires scheduling context
            r'every\s+month',
            r'each\s+month',
            r'once\s+a\s+month',
            r'every\s+\d+\s+months?',  # "every 2 months"
            r'\d{1,2}(st|nd|rd|th)\s+of\s+(?:the\s+)?month',  # "15th of the month" - clear recurring intent
            r'\d{1,2}(st|nd|rd|th)\s+of\s+(january|february|march|april|may|june|july|august|september|october|november|december)',
            r'\d{1,2}(st|nd|rd|th)\s+of\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)'
        ]
        return any(re.search(pattern, msg) for pattern in patterns)
    
    def _parse_monthly(self, msg):
        """Parse monthly schedules"""
        result = {
            'IsRecurring': 1,
            'FreqType': 4,  # Every (freqRecurrance) Months
            'FreqRecurrance': 1,  # Default to every 1 month
            'FreqInterval': 4095,  # All months (Jan=1, Feb=2, Mar=4, Apr=8, May=16, Jun=32, Jul=64, Aug=128, Sep=256, Oct=512, Nov=1024, Dec=2048) = 4095
            'BusinessDayBehavior': self._detect_business_day_behavior(msg)
        }
        
        # Check for month interval phrases: "every other month" or "every N months"
        if 'every other month' in msg:
            result['FreqRecurrance'] = 2
        else:
            interval_match = re.search(r'every\s+(\d+)\s+months?', msg)
            if interval_match:
                try:
                    month_interval = int(interval_match.group(1))
                    if month_interval >= 1:
                        result['FreqRecurrance'] = month_interval
                except Exception:
                    pass
            
        # Extract specific months if mentioned
        month_bitmask = 0
        for month, bit in self.MONTH_BITS.items():
            if month in msg:
                month_bitmask |= bit
        if month_bitmask > 0:
            result['FreqInterval'] = month_bitmask
            
        # Extract day of month (e.g., "28th"). We keep FreqRecurrance as the month interval.
        ordinal_pattern = r'(\d{1,2})(st|nd|rd|th)'
        match = re.search(ordinal_pattern, msg)
        if match:
            day = int(match.group(1))
            if 1 <= day <= 31:
                # Day of month will be captured via DueDate; do not overwrite month interval
                pass
        elif month_bitmask > 0:
            # Months specified; keep month bitmask in FreqInterval and retain interval in FreqRecurrance
            pass
                
        # Handle "last day of month"
        if 'last day' in msg:
            result['FreqRecurrance'] = 31  # Use 31 for last day of month
            
        self.logger.debug(f"Parsed monthly schedule: {result}")
        return result
    
    def _is_weekly_pattern(self, msg):
        """Check if message contains weekly pattern with scheduling context"""
        # Exclude "end of week" which is not recurring
        if 'end of week' in msg or 'end of the week' in msg:
            return False
            
        # Exclude "due in X weeks" which is not recurring
        if re.search(r'due\s+in\s+\d+\s+weeks?', msg) or re.search(r'in\s+\d+\s+weeks?', msg):
            return False
            
        # Only match "weekly" when it has scheduling context
        # This prevents "weekly report" from being treated as a recurring task
        patterns = [
            r'\b(?:every|each|recurring|repeat|repeating)\s+week(?:ly)?',  # Requires scheduling context
            r'every\s+week',
            r'each\s+week',
            r'every\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)',
            r'every\s+other\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)',
            r'\bbi-?weekly\b',  # biweekly or bi-weekly
            r'every\s+(?:2|two)\s+weeks?',  # every 2 weeks or every two weeks
            r'every\s+second\s+week',  # every second week
            r'every\s+day\s+of\s+the\s+week',  # every day of the week
            r'\bweekday[s]?\b',  # weekday / weekdays (clear scheduling intent)
            r'every\s+weekday',
            r'each\s+weekday',
            r'business\s+days?'  # business days (clear scheduling intent)
        ]
        return any(re.search(pattern, msg) for pattern in patterns)
    
    def _parse_weekly(self, msg):
        """Parse weekly schedules
        Encoding for FreqType=3 (weekly):
        - FreqRecurrance = number of weeks between occurrences (1=weekly, 2=biweekly)
        - FreqInterval  = day-of-week bitmask (Sun=1, Mon=2, Tue=4, Wed=8, Thu=16, Fri=32, Sat=64)
        """
        result = {
            'IsRecurring': 1,
            'FreqType': 3,  # Every (freqRecurrance) Weeks on (freqInterval)
            'FreqRecurrance': 1,  # Weekly by default
            'FreqInterval': 2,  # Default to Monday (2), not Sunday (1)
            'BusinessDayBehavior': self._detect_business_day_behavior(msg)
        }
        
        # Check for biweekly patterns first (before "every other")
        biweekly_patterns = [
            r'\bbi-?weekly\b',  # biweekly or bi-weekly
            r'every\s+(?:2|two)\s+weeks?',  # every 2 weeks or every two weeks
            r'every\s+second\s+week',  # every second week
        ]
        
        if any(re.search(pattern, msg) for pattern in biweekly_patterns):
            result['FreqRecurrance'] = 2  # Every 2 weeks (biweekly)
            self.logger.debug("Detected biweekly pattern")
            
            # Extract specific day if mentioned
            days_bitmask = 0
            for day, bit in self.WEEKDAY_BITS.items():
                if day in msg:
                    days_bitmask |= bit
            if days_bitmask > 0:
                result['FreqInterval'] = days_bitmask
        
        # Check for "every other" pattern
        elif re.search(r'every\s+other\s+(\w+)', msg):
            every_other_match = re.search(r'every\s+other\s+(\w+)', msg)
            result['FreqRecurrance'] = 2  # Every 2 weeks
            day_name = every_other_match.group(1).lower()
            if day_name in self.WEEKDAY_BITS:
                result['FreqInterval'] = self.WEEKDAY_BITS[day_name]
        else:
            # Check for "every day of the week" pattern
            if 'every day of the week' in msg:
                result['FreqInterval'] = 127  # All days (1+2+4+8+16+32+64)
                result['FreqRecurrance'] = 1
            # Check for weekdays / business days
            elif ('weekday' in msg or 'weekdays' in msg or 'business day' in msg or 'business days' in msg):
                result['FreqInterval'] = 2 + 4 + 8 + 16 + 32  # Mon-Fri = 62
                result['FreqRecurrance'] = 1
            else:
                # Extract days of week and create bitmask
                days_bitmask = 0
                for day, bit in self.WEEKDAY_BITS.items():
                    if day in msg:
                        days_bitmask |= bit
                        
                if days_bitmask > 0:
                    result['FreqInterval'] = days_bitmask
                    result['FreqRecurrance'] = 1
                
        # Handle patterns like "every Monday and Thursday"
        if ' and ' in msg:
            days_bitmask = 0
            for day, bit in self.WEEKDAY_BITS.items():
                if day in msg:
                    days_bitmask |= bit
            if days_bitmask > 0:
                result['FreqInterval'] = days_bitmask
                
        self.logger.debug(f"Parsed weekly schedule: {result}")
        return result
    
    def _is_daily_pattern(self, msg):
        """Check if message contains daily pattern with scheduling context"""
        # Exclude cases where "every day" is used in weekly context
        if 'weekly' in msg and 'every day' in msg:
            return False
        if 'every day of the week' in msg:
            return False
            
        # Only match "daily" when it has clear scheduling context
        # This prevents "daily report" or "daily standup" (task names) from being treated as recurring
        patterns = [
            r'\b(?:recurring|repeat|repeating)\s+daily',  # "recurring daily" - clear intent
            r'every\s+day(?!\s+of\s+the\s+week)',  # "every day" - clear intent
            r'each\s+day(?!\s+of\s+the\s+week)',   # "each day" - clear intent
            r'daily\s+(?:task|recurrence|recurring|schedule)',  # "daily task/recurrence" - clear intent
        ]
        return any(re.search(pattern, msg) for pattern in patterns)
    
    def _parse_daily(self, msg):
        """Parse daily schedules"""
        result = {
            'IsRecurring': 1,
            'FreqType': 2,  # Every (freqRecurrance) Days
            'FreqRecurrance': 1,
            'FreqInterval': 1,
            # Default business day behavior for daily: skip weekends/holidays (1)
            'BusinessDayBehavior': 1
        }
            
        # Check for "every other day"
        if 'every other day' in msg:
            result['FreqInterval'] = 2
            
        self.logger.debug(f"Parsed daily schedule: {result}")
        return result
    
    def calculate_bitmask_for_days(self, days_list):
        """Calculate bitmask for a list of weekday names"""
        bitmask = 0
        for day in days_list:
            day_lower = day.lower().strip()
            if day_lower in self.WEEKDAY_BITS:
                bitmask |= self.WEEKDAY_BITS[day_lower]
        return bitmask
    
    def calculate_bitmask_for_months(self, months_list):
        """Calculate bitmask for a list of month names"""
        bitmask = 0
        for month in months_list:
            month_lower = month.lower().strip()
            if month_lower in self.MONTH_BITS:
                bitmask |= self.MONTH_BITS[month_lower]
        return bitmask