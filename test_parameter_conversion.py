#!/usr/bin/env python3
"""
Test script to verify parameter conversion functions
"""

def convert_freq_type_to_int(freq_type):
    """Convert text-based frequency types to integers"""
    if isinstance(freq_type, int):
        return freq_type
    if isinstance(freq_type, str):
        freq_lower = freq_type.lower().strip()
        if freq_lower in ['daily', 'day', '1']:
            return 1
        elif freq_lower in ['weekly', 'week', '2']:
            return 2
        elif freq_lower in ['monthly', 'month', '3']:
            return 3
        elif freq_lower in ['yearly', 'year', '4']:
            return 4
    return 1  # Default to Daily

def convert_to_int(value, param_name):
    """Convert value to integer with proper handling for boolean-like strings"""
    if isinstance(value, int):
        return value
    if isinstance(value, str):
        value_lower = value.lower().strip()
        # Handle boolean-like strings
        if value_lower in ['yes', 'true', '1', 'on']:
            return 1
        elif value_lower in ['no', 'false', '0', 'off']:
            return 0
        # Try direct conversion
        try:
            return int(value)
        except ValueError:
            pass
    # Set default values if conversion fails
    if param_name == 'IsRecurring':
        return 0
    elif param_name == 'FreqRecurrance':
        return 1
    elif param_name == 'FreqInterval':
        return 1
    elif param_name == 'BusinessDayBehavior':
        return 0
    elif param_name == 'Activate':
        return 1
    elif param_name == 'IsReminder':
        return 1
    elif param_name == 'AddToPriorityList':
        return 0
    return 0

def test_parameter_conversion():
    """Test the parameter conversion functions"""
    
    # Test data from your conversation
    test_params = {
        'TaskName': 'party on france',
        'Controllers': 'Chandler',
        'Assignees': 'Gulfam',
        'DueDate': '2025-07-30',
        'DueTime': '19:00',
        'Items': 'radiowave, controleer',
        'IsRecurring': 'Yes',  # This should be converted to 1
        'FreqType': 'Daily',   # This should be converted to 1
        'FreqRecurrance': '1',
        'FreqInterval': '1',
        'BusinessDayBehavior': '0'
    }
    
    print("=== ORIGINAL PARAMETERS ===")
    for key, value in test_params.items():
        print(f"{key}: {value} (type: {type(value).__name__})")
    
    print("\n=== CONVERTING PARAMETERS ===")
    
    # Convert FreqType
    if 'FreqType' in test_params:
        test_params['FreqType'] = convert_freq_type_to_int(test_params['FreqType'])
        print(f"FreqType converted: {test_params['FreqType']}")
    
    # Convert integer parameters
    integer_params = ['IsRecurring', 'FreqRecurrance', 'FreqInterval', 'BusinessDayBehavior']
    for param in integer_params:
        if param in test_params:
            original_value = test_params[param]
            test_params[param] = convert_to_int(test_params[param], param)
            print(f"{param} converted: {original_value} -> {test_params[param]}")
    
    print("\n=== FINAL PARAMETERS ===")
    for key, value in test_params.items():
        print(f"{key}: {value} (type: {type(value).__name__})")
    
    print("\n=== STORED PROCEDURE PARAMETERS ===")
    # Simulate the stored procedure parameter list
    stored_proc_params = [
        test_params['TaskName'],
        'Adam Beringer',  # user_fullname
        test_params['Controllers'],
        test_params['Assignees'],
        f"{test_params['DueDate']} {test_params['DueTime']}:00",  # DueDate
        f"{test_params['DueDate']} {test_params['DueTime']}:00",  # LocalDueDate
        'Asia/Karachi',  # Location
        1900,  # DueTime (19:00 -> 1900)
        f"{test_params['DueDate']} {test_params['DueTime']}:00",  # SoftDueDate
        f"{test_params['DueDate']} {test_params['DueTime']}:00",  # FinalDueDate
        test_params['Items'],
        test_params['IsRecurring'],
        test_params['FreqType'],
        test_params['FreqRecurrance'],
        test_params['FreqInterval'],
        test_params['BusinessDayBehavior'],
        1,  # Activate
        1,  # IsReminder
        '2025-07-29 19:00:00',  # ReminderDate
        0   # AddToPriorityList
    ]
    
    param_names = [
        'TaskName', 'MainController', 'Controllers', 'Assignees', 'DueDate',
        'LocalDueDate', 'Location', 'DueTime', 'SoftDueDate', 'FinalDueDate',
        'Items', 'IsRecurring', 'FreqType', 'FreqRecurrance', 'FreqInterval',
        'BusinessDayBehavior', 'Activate', 'IsReminder', 'ReminderDate', 'AddToPriorityList'
    ]
    
    for i, (name, value) in enumerate(zip(param_names, stored_proc_params)):
        print(f"{name}: {value} (type: {type(value).__name__})")

if __name__ == "__main__":
    test_parameter_conversion() 