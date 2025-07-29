#!/usr/bin/env python3
"""
Test script to verify timezone functionality
"""
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'backend', 'chatbot'))

from chatbot.api import (
    convert_to_user_timezone, 
    parse_natural_date_with_timezone, 
    parse_natural_time_with_timezone,
    get_current_date_in_timezone,
    set_default_due_date_time,
    set_automatic_parameters
)
import datetime

def test_timezone_conversion():
    """Test timezone conversion functionality"""
    print("Testing timezone conversion...")
    
    # Test cases
    test_cases = [
        {
            'date': '2024-01-15',
            'time': '14:30',
            'timezone': 'America/New_York',
            'description': 'New York timezone'
        },
        {
            'date': '2024-01-15',
            'time': '14:30',
            'timezone': 'Europe/London',
            'description': 'London timezone'
        },
        {
            'date': '2024-01-15',
            'time': '14:30',
            'timezone': 'Asia/Tokyo',
            'description': 'Tokyo timezone'
        }
    ]
    
    for test_case in test_cases:
        date, time = convert_to_user_timezone(
            test_case['date'], 
            test_case['time'], 
            test_case['timezone']
        )
        print(f"{test_case['description']}: {date} {time}")

def test_current_date_awareness():
    """Test current date awareness in different timezones"""
    print("\nTesting current date awareness...")
    
    timezones = ['America/New_York', 'Europe/London', 'Asia/Tokyo', 'UTC']
    
    for tz in timezones:
        current_date = get_current_date_in_timezone(tz)
        print(f"Current date in {tz}: {current_date}")

def test_automatic_parameters():
    """Test automatic parameters functionality"""
    print("\nTesting automatic parameters...")
    
    timezones = ['America/New_York', 'Europe/London', 'Asia/Tokyo', 'UTC']
    
    for tz in timezones:
        # Test with DueDate provided
        params_with_due_date = {
            'DueDate': '2024-01-25',
            'TaskName': 'Test task'
        }
        result = set_automatic_parameters(params_with_due_date, tz)
        print(f"With DueDate in {tz}:")
        print(f"  Location: {result.get('Location')}")
        print(f"  Activate: {result.get('Activate')}")
        print(f"  FinalDueDate: {result.get('FinalDueDate')}")
        print(f"  AddToPriorityList: {result.get('AddToPriorityList')}")
        print(f"  IsReminder: {result.get('IsReminder')}")
        print(f"  ReminderDate: {result.get('ReminderDate')}")
        
        # Test without DueDate (should default to tomorrow)
        params_without_due_date = {
            'TaskName': 'Test task'
        }
        result2 = set_automatic_parameters(params_without_due_date, tz)
        print(f"Without DueDate in {tz}:")
        print(f"  Location: {result2.get('Location')}")
        print(f"  Activate: {result2.get('Activate')}")
        print(f"  FinalDueDate: {result2.get('FinalDueDate')}")
        print(f"  AddToPriorityList: {result2.get('AddToPriorityList')}")
        print(f"  IsReminder: {result2.get('IsReminder')}")
        print(f"  ReminderDate: {result2.get('ReminderDate')}")
        
        # Test with user-provided values (should preserve them)
        params_with_user_values = {
            'DueDate': '2024-01-30',
            'TaskName': 'Test task',
            'AddToPriorityList': 1,
            'IsReminder': 0,
            'ReminderDate': '2024-01-28'
        }
        result3 = set_automatic_parameters(params_with_user_values, tz)
        print(f"With user values in {tz}:")
        print(f"  Location: {result3.get('Location')}")
        print(f"  Activate: {result3.get('Activate')}")
        print(f"  FinalDueDate: {result3.get('FinalDueDate')}")
        print(f"  AddToPriorityList: {result3.get('AddToPriorityList')}")
        print(f"  IsReminder: {result3.get('IsReminder')}")
        print(f"  ReminderDate: {result3.get('ReminderDate')}")

def test_default_due_date_time():
    """Test default due date and time functionality"""
    print("\nTesting default due date and time...")
    
    timezones = ['America/New_York', 'Europe/London', 'Asia/Tokyo', 'UTC']
    
    for tz in timezones:
        # Test with empty parameters
        params = {}
        result = set_default_due_date_time(params, tz)
        print(f"Default due date in {tz}: {result.get('DueDate')} at {result.get('DueTime')}")
        print(f"  LocalDueDate: {result.get('LocalDueDate')}")
        print(f"  SoftDueDate: {result.get('SoftDueDate')}")
        
        # Test with existing parameters (should not override DueDate/Time, but should set Local/Soft)
        params_with_existing = {
            'DueDate': '2024-01-20',
            'DueTime': '15:30'
        }
        result2 = set_default_due_date_time(params_with_existing, tz)
        print(f"With existing values in {tz}: {result2.get('DueDate')} at {result2.get('DueTime')}")
        print(f"  LocalDueDate: {result2.get('LocalDueDate')}")
        print(f"  SoftDueDate: {result2.get('SoftDueDate')}")
        
        # Test with user-provided date but no time
        params_date_only = {
            'DueDate': 'tomorrow'
        }
        result3 = set_default_due_date_time(params_date_only, tz)
        print(f"Date only in {tz}: {result3.get('DueDate')} at {result3.get('DueTime')}")
        print(f"  LocalDueDate: {result3.get('LocalDueDate')}")
        print(f"  SoftDueDate: {result3.get('SoftDueDate')}")

def test_natural_date_parsing():
    """Test natural date parsing with current date awareness"""
    print("\nTesting natural date parsing...")
    
    test_cases = [
        ('tomorrow', 'America/New_York'),
        ('next week', 'Europe/London'),
        ('today', 'Asia/Tokyo'),
        ('day after tomorrow', 'UTC'),
        ('yesterday', 'America/New_York'),
        ('next month', 'Europe/London'),
        ('this week', 'Asia/Tokyo'),
        ('in 3 days', 'UTC'),
        ('in 1 day', 'America/New_York'),
        ('2024-01-15', 'UTC')
    ]
    
    for date_str, timezone in test_cases:
        result = parse_natural_date_with_timezone(date_str, timezone)
        print(f"'{date_str}' in {timezone}: {result}")

def test_natural_time_parsing():
    """Test natural time parsing"""
    print("\nTesting natural time parsing...")
    
    test_cases = [
        'morning',
        'afternoon',
        'evening',
        'night',
        'noon',
        'midnight',
        'late morning',
        'early evening',
        'after close',
        '14:30'
    ]
    
    for time_str in test_cases:
        result = parse_natural_time_with_timezone(time_str, 'America/New_York')
        print(f"'{time_str}': {result}")

def test_comprehensive_examples():
    """Test comprehensive real-world examples"""
    print("\nTesting comprehensive examples...")
    
    examples = [
        {
            'message': 'Meeting tomorrow at 2pm',
            'timezone': 'America/New_York',
            'expected_date': 'tomorrow',
            'expected_time': '14:00'
        },
        {
            'message': 'Task due next week in the morning',
            'timezone': 'Europe/London',
            'expected_date': 'next week',
            'expected_time': 'morning'
        },
        {
            'message': 'Reminder this afternoon',
            'timezone': 'Asia/Tokyo',
            'expected_date': 'today',
            'expected_time': 'afternoon'
        }
    ]
    
    for example in examples:
        date_result = parse_natural_date_with_timezone(example['expected_date'], example['timezone'])
        time_result = parse_natural_time_with_timezone(example['expected_time'], example['timezone'])
        print(f"'{example['message']}' in {example['timezone']}: {date_result} at {time_result}")

def test_default_scenarios():
    """Test scenarios where defaults should be applied"""
    print("\nTesting default scenarios...")
    
    scenarios = [
        {
            'description': 'User only provides task name',
            'params': {'TaskName': 'Important meeting'},
            'timezone': 'America/New_York'
        },
        {
            'description': 'User provides date but no time',
            'params': {'TaskName': 'Project review', 'DueDate': 'tomorrow'},
            'timezone': 'Europe/London'
        },
        {
            'description': 'User provides time but no date',
            'params': {'TaskName': 'Call client', 'DueTime': 'morning'},
            'timezone': 'Asia/Tokyo'
        },
        {
            'description': 'User provides specific date and time',
            'params': {'TaskName': 'Team meeting', 'DueDate': '2024-01-25', 'DueTime': '14:00'},
            'timezone': 'UTC'
        }
    ]
    
    for scenario in scenarios:
        # Apply both default due date and automatic parameters
        result = set_default_due_date_time(scenario['params'].copy(), scenario['timezone'])
        result = set_automatic_parameters(result, scenario['timezone'])
        print(f"{scenario['description']} in {scenario['timezone']}: {result.get('DueDate')} at {result.get('DueTime')}")
        print(f"  Location: {result.get('Location')}")
        print(f"  Activate: {result.get('Activate')}")
        print(f"  FinalDueDate: {result.get('FinalDueDate')}")
        print(f"  LocalDueDate: {result.get('LocalDueDate')}")
        print(f"  SoftDueDate: {result.get('SoftDueDate')}")
        print(f"  AddToPriorityList: {result.get('AddToPriorityList')}")
        print(f"  IsReminder: {result.get('IsReminder')}")
        print(f"  ReminderDate: {result.get('ReminderDate')}")

if __name__ == "__main__":
    test_timezone_conversion()
    test_current_date_awareness()
    test_automatic_parameters()
    test_default_due_date_time()
    test_natural_date_parsing()
    test_natural_time_parsing()
    test_comprehensive_examples()
    test_default_scenarios()
    print("\nAll timezone tests completed!") 