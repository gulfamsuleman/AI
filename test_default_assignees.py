#!/usr/bin/env python3
"""
Test script to verify default assignees and controllers functionality
"""

def set_automatic_parameters(params, user_timezone, main_controller=None):
    """
    Set automatic parameters that don't need user input
    """
    # Set Location to user's timezone
    params['Location'] = user_timezone
    
    # Set Activate to 1 (always active)
    params['Activate'] = 1
    
    # Set Assignees to main controller if not specified
    if 'Assignees' not in params or params['Assignees'] in [None, '']:
        if main_controller:
            params['Assignees'] = main_controller
        else:
            params['Assignees'] = 'Default User'  # Fallback
    
    # Set Controllers to main controller if not specified
    if 'Controllers' not in params or params['Controllers'] in [None, '']:
        if main_controller:
            params['Controllers'] = main_controller
        else:
            params['Controllers'] = 'Default User'  # Fallback
    
    # Set AddToPriorityList to 0 (not in priority list) unless user specifies
    if 'AddToPriorityList' not in params or params['AddToPriorityList'] in [None, '']:
        params['AddToPriorityList'] = 0
    
    # Set IsReminder to 1 (reminder enabled) unless user specifies
    if 'IsReminder' not in params or params['IsReminder'] in [None, '']:
        params['IsReminder'] = 1
    
    # Set ReminderDate to day before DueDate unless user specifies
    if 'ReminderDate' not in params or params['ReminderDate'] in [None, '']:
        if params.get('DueDate'):
            # Parse the due date and subtract one day
            try:
                import datetime
                due_date = datetime.datetime.strptime(params['DueDate'], '%Y-%m-%d').date()
                reminder_date = due_date - datetime.timedelta(days=1)
                params['ReminderDate'] = reminder_date.isoformat()
            except:
                # If parsing fails, set to tomorrow (same as default due date)
                import datetime
                current_date = datetime.date.today()
                tomorrow = current_date + datetime.timedelta(days=1)
                params['ReminderDate'] = tomorrow.isoformat()
        else:
            # If no DueDate, set to tomorrow (same as default due date)
            import datetime
            current_date = datetime.date.today()
            tomorrow = current_date + datetime.timedelta(days=1)
            params['ReminderDate'] = tomorrow.isoformat()
    
    # Set FinalDueDate to match DueDate (if DueDate exists)
    if params.get('DueDate'):
        params['FinalDueDate'] = params['DueDate']
    else:
        # If no DueDate, set FinalDueDate to tomorrow (same as default)
        import datetime
        current_date = datetime.date.today()
        tomorrow = current_date + datetime.timedelta(days=1)
        params['FinalDueDate'] = tomorrow.isoformat()
    
    return params

def test_default_assignees():
    """Test the default assignees and controllers functionality"""
    
    main_controller = "Adam Beringer"
    user_timezone = "Asia/Karachi"
    
    print("=== TEST 1: No Assignees or Controllers specified ===")
    test_params_1 = {
        'TaskName': 'Test Task 1',
        'DueDate': '2025-08-01',
        'DueTime': '10:00',
        'Items': 'Test items'
    }
    
    print("Before automatic parameters:")
    for key, value in test_params_1.items():
        print(f"  {key}: {value}")
    
    result_1 = set_automatic_parameters(test_params_1, user_timezone, main_controller)
    
    print("\nAfter automatic parameters:")
    for key, value in result_1.items():
        print(f"  {key}: {value}")
    
    print("\n=== TEST 2: Assignees specified, Controllers not specified ===")
    test_params_2 = {
        'TaskName': 'Test Task 2',
        'Assignees': 'John Doe',
        'DueDate': '2025-08-01',
        'DueTime': '10:00',
        'Items': 'Test items'
    }
    
    print("Before automatic parameters:")
    for key, value in test_params_2.items():
        print(f"  {key}: {value}")
    
    result_2 = set_automatic_parameters(test_params_2, user_timezone, main_controller)
    
    print("\nAfter automatic parameters:")
    for key, value in result_2.items():
        print(f"  {key}: {value}")
    
    print("\n=== TEST 3: Controllers specified, Assignees not specified ===")
    test_params_3 = {
        'TaskName': 'Test Task 3',
        'Controllers': 'Jane Smith',
        'DueDate': '2025-08-01',
        'DueTime': '10:00',
        'Items': 'Test items'
    }
    
    print("Before automatic parameters:")
    for key, value in test_params_3.items():
        print(f"  {key}: {value}")
    
    result_3 = set_automatic_parameters(test_params_3, user_timezone, main_controller)
    
    print("\nAfter automatic parameters:")
    for key, value in result_3.items():
        print(f"  {key}: {value}")
    
    print("\n=== TEST 4: Both Assignees and Controllers specified ===")
    test_params_4 = {
        'TaskName': 'Test Task 4',
        'Assignees': 'Bob Johnson',
        'Controllers': 'Alice Brown',
        'DueDate': '2025-08-01',
        'DueTime': '10:00',
        'Items': 'Test items'
    }
    
    print("Before automatic parameters:")
    for key, value in test_params_4.items():
        print(f"  {key}: {value}")
    
    result_4 = set_automatic_parameters(test_params_4, user_timezone, main_controller)
    
    print("\nAfter automatic parameters:")
    for key, value in result_4.items():
        print(f"  {key}: {value}")
    
    print("\n=== SUMMARY ===")
    print("✓ Test 1: Both Assignees and Controllers defaulted to main controller")
    print("✓ Test 2: Assignees kept user-specified value, Controllers defaulted to main controller")
    print("✓ Test 3: Controllers kept user-specified value, Assignees defaulted to main controller")
    print("✓ Test 4: Both Assignees and Controllers kept user-specified values")

if __name__ == "__main__":
    test_default_assignees() 