#!/usr/bin/env python3
"""
Test script to verify stored procedure parameter formatting
"""

def format_date_for_sql(date_str, time_str=None):
    """Convert date string to SQL Server datetime format"""
    if not date_str:
        return None
    try:
        # If it's already in datetime format, return as is
        if ' ' in date_str or 'T' in date_str:
            return date_str
        # If it's just a date, add time from DueTime parameter or default
        if time_str:
            return f"{date_str} {time_str}:00"
        else:
            return f"{date_str} 00:00:00"
    except:
        return None

def convert_time_to_int(time_str):
    """Convert HH:MM format to integer format (e.g., '17:00' -> 1700)"""
    if not time_str:
        return 1700  # Default to 5 PM
    
    try:
        time_parts = time_str.split(':')
        if len(time_parts) == 2:
            hours = int(time_parts[0])
            minutes = int(time_parts[1])
            return hours * 100 + minutes
        else:
            return 1700  # Default to 5 PM
    except:
        return 1700  # Default to 5 PM

def test_parameter_formatting():
    """Test the parameter formatting functions"""
    
    # Test data similar to what the chatbot would generate
    test_params = {
        'TaskName': 'Work Load Offloadedv2',
        'Controllers': 'Chandler',
        'Assignees': 'Gulfam',
        'DueDate': '2025-08-01',
        'DueTime': '10:00',
        'Location': 'Asia/Karachi',
        'Items': 'Create Agenda,Invite Members,Book Room',
        'IsRecurring': 1,
        'FreqType': 1,
        'FreqRecurrance': 1,
        'FreqInterval': 1,
        'BusinessDayBehavior': 0,
        'Activate': 1,
        'IsReminder': 0,
        'AddToPriorityList': 0
    }
    
    # Apply the same transformations as in the API
    user_fullname = 'Adam Beringer'
    
    # Set automatic parameters
    test_params['LocalDueDate'] = test_params['DueDate']
    test_params['SoftDueDate'] = test_params['DueDate']
    test_params['FinalDueDate'] = test_params['DueDate']
    test_params['ReminderDate'] = '2025-07-31'  # Day before due date
    
    # Format parameters for stored procedure
    stored_proc_params = [
        test_params['TaskName'],
        user_fullname,
        test_params['Controllers'],
        test_params['Assignees'],
        format_date_for_sql(test_params['DueDate'], test_params.get('DueTime')),
        format_date_for_sql(test_params['LocalDueDate'], test_params.get('DueTime')),
        test_params['Location'],
        convert_time_to_int(test_params['DueTime']),
        format_date_for_sql(test_params['SoftDueDate'], test_params.get('DueTime')),
        format_date_for_sql(test_params['FinalDueDate'], test_params.get('DueTime')),
        test_params['Items'],
        int(test_params['IsRecurring']),
        test_params['FreqType'],
        test_params['FreqRecurrance'],
        test_params['FreqInterval'],
        test_params['BusinessDayBehavior'],
        int(test_params['Activate']),
        int(test_params['IsReminder']),
        format_date_for_sql(test_params['ReminderDate'], test_params.get('DueTime')),
        int(test_params['AddToPriorityList']),
    ]
    
    # Print the formatted parameters
    param_names = [
        'TaskName', 'MainController', 'Controllers', 'Assignees', 'DueDate',
        'LocalDueDate', 'Location', 'DueTime', 'SoftDueDate', 'FinalDueDate',
        'Items', 'IsRecurring', 'FreqType', 'FreqRecurrance', 'FreqInterval',
        'BusinessDayBehavior', 'Activate', 'IsReminder', 'ReminderDate', 'AddToPriorityList'
    ]
    
    print("=== STORED PROCEDURE PARAMETERS ===")
    for i, (name, value) in enumerate(zip(param_names, stored_proc_params)):
        print(f"{name}: {value} (type: {type(value).__name__})")
    
    print("\n=== COMPARISON WITH WORKING SQL ===")
    print("Your working SQL:")
    print("DECLARE @NewInstanceId INT;")
    print("EXEC [QTasks].[dbo].[QCheck_CreateTaskThroughChatbot]")
    print("    @TaskName = N'Work Load Offloadedv2',")
    print("    @MainController = N'Adam Beringer',")
    print("    @Controllers = N'Chandler',")
    print("    @Assignees = N'Gulfam',")
    print("    @DueDate = '2025-08-01 10:00:00',")
    print("    @LocalDueDate = '2025-08-01 10:00:00',")
    print("    @Location = N'Asia/Karachi',")
    print("    @DueTime = 17000,")
    print("    @SoftDueDate = '2025-08-01 10:00:00',")
    print("    @FinalDueDate = '2025-08-01 10:00:00',")
    print("    @Items = N'Create Agenda,Invite Members,Book Room',")
    print("    @IsRecurring = 1,")
    print("    @FreqType = 1,")
    print("    @FreqRecurrance = 1,")
    print("    @FreqInterval = 1,")
    print("    @BusinessDayBehavior = 0,")
    print("    @Activate = 1,")
    print("    @IsReminder = 0,")
    print("    @ReminderDate = '2025-07-31 10:00:00',")
    print("    @AddToPriorityList = 0,")
    print("    @NewInstanceId = @NewInstanceId OUTPUT;")
    
    print("\n=== DIFFERENCES TO CHECK ===")
    print("1. DueTime: Your SQL uses 17000, our code generates:", convert_time_to_int('10:00'))
    print("2. DueDate format: Your SQL uses '2025-08-01 10:00:00', our code generates:", format_date_for_sql('2025-08-01', '10:00'))
    print("3. ReminderDate: Your SQL uses '2025-07-31 10:00:00', our code generates:", format_date_for_sql('2025-07-31', '10:00'))
    
    print("\n=== NOTE ===")
    print("There's still a mismatch in DueTime:")
    print("- Your SQL uses 17000 (17:00)")
    print("- Our code generates 1000 (10:00) from the input '10:00'")
    print("- This suggests the input time should be '17:00' to match your SQL")

if __name__ == "__main__":
    test_parameter_formatting() 