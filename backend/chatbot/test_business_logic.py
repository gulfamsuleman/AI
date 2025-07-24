#!/usr/bin/env python
"""
Test script to verify business logic implementation.
Run this to check if all the specified business rules are being followed.
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from chatbot.task_utils import apply_task_defaults, parse_recurrence_from_user_input, describe_recurrence
from datetime import datetime

def test_basic_defaults():
    """Test basic parameter defaulting."""
    print("=== Testing Basic Defaults ===")
    
    # Test with minimal input
    params = {'user': 'John Smith'}
    params_with_defaults, fields_to_prompt = apply_task_defaults(params, user_timezone='America/New_York')
    
    print(f"TaskName: {params_with_defaults.get('TaskName')} (should be 'New Task')")
    print(f"Controllers: {params_with_defaults.get('Controllers')} (should be 'John Smith')")
    print(f"Assignees: {params_with_defaults.get('Assignees')} (should be 'John Smith')")
    print(f"DueDate: {params_with_defaults.get('DueDate')} (should be tomorrow at 7pm UTC)")
    print(f"LocalDueDate: {params_with_defaults.get('LocalDueDate')} (should be tomorrow at 7pm local)")
    print(f"Location: {params_with_defaults.get('Location')} (should be 'America/New_York')")
    print(f"IsRecurring: {params_with_defaults.get('IsRecurring')} (should be 0)")
    print(f"Activate: {params_with_defaults.get('Activate')} (should be 1)")
    print(f"AddToPriorityList: {params_with_defaults.get('AddToPriorityList')} (should be 0)")
    print(f"Fields to prompt: {fields_to_prompt}")
    print()

def test_recurrence_parsing():
    """Test recurrence parsing from user input."""
    print("=== Testing Recurrence Parsing ===")
    
    test_cases = [
        "Create a daily task",
        "Make this weekly",
        "Monthly report",
        "Annual review",
        "Daily task Monday through Friday",
        "Weekly task on Monday and Wednesday"
    ]
    
    for user_input in test_cases:
        print(f"Input: '{user_input}'")
        params = parse_recurrence_from_user_input(user_input)
        print(f"  IsRecurring: {params.get('IsRecurring')}")
        print(f"  FreqType: {params.get('FreqType')}")
        print(f"  BusinessDayBehavior: {params.get('BusinessDayBehavior')}")
        if params.get('FreqInterval'):
            print(f"  FreqInterval: {params.get('FreqInterval')}")
        print()

def test_recurrence_descriptions():
    """Test human-readable recurrence descriptions."""
    print("=== Testing Recurrence Descriptions ===")
    
    test_cases = [
        (1, 1, None, "One Time"),
        (2, 1, None, "Every 1 Day(s)"),
        (3, 2, 34, "Every 2 Week(s) on Tuesday, Friday"),  # 34 = 2 + 32
        (4, 1, None, "Every 1 Month(s)"),
        (5, 1, 4, "Yearly in Mar"),  # 4 = March
    ]
    
    for freq_type, freq_recurrance, freq_interval, expected in test_cases:
        desc = describe_recurrence(freq_type, freq_recurrance, freq_interval)
        print(f"FreqType={freq_type}, FreqRecurrance={freq_recurrance}, FreqInterval={freq_interval}")
        print(f"  Description: {desc}")
        print(f"  Expected: {expected}")
        print(f"  Match: {'✓' if desc == expected else '✗'}")
        print()

def test_advanced_field_detection():
    """Test detection of advanced fields based on user input."""
    print("=== Testing Advanced Field Detection ===")
    
    test_cases = [
        ("Create a task", []),
        ("Create a task with soft due date", ['SoftDueDate']),
        ("Add to priority list", ['AddToPriorityList']),
        ("Set reminder", ['IsReminder']),
        ("Add checklist items", ['Items']),
        ("Make it recurring", ['IsRecurring']),
    ]
    
    for user_input, expected_fields in test_cases:
        params = {'user_input': user_input, 'user': 'Test User'}
        params_with_defaults, fields_to_prompt = apply_task_defaults(params)
        
        # Check if expected advanced fields are in the prompt list
        missing_advanced = [f for f in expected_fields if f in fields_to_prompt]
        print(f"Input: '{user_input}'")
        print(f"  Expected advanced fields: {expected_fields}")
        print(f"  Fields to prompt: {fields_to_prompt}")
        print(f"  Advanced fields detected: {'✓' if not missing_advanced else '✗'}")
        print()

if __name__ == "__main__":
    print("Testing Business Logic Implementation")
    print("=" * 50)
    print()
    
    test_basic_defaults()
    test_recurrence_parsing()
    test_recurrence_descriptions()
    test_advanced_field_detection()
    
    print("=" * 50)
    print("Testing complete!") 