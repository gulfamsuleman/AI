#!/usr/bin/env python3
"""
Test script to verify SQL query generation for stored procedure
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

def escape_sql_string(s):
    """Helper function to safely escape strings for SQL"""
    if s is None:
        return "NULL"
    return str(s).replace("'", "''")

def test_sql_generation():
    """Test the SQL query generation"""
    
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
    
    # Generate the SQL query
    sql_query = f"""
        DECLARE @NewInstanceId INT;
        EXEC [QTasks].[dbo].[QCheck_CreateTaskThroughChatbot]
            @TaskName=N'{escape_sql_string(stored_proc_params[0])}',
            @MainController=N'{escape_sql_string(stored_proc_params[1])}',
            @Controllers=N'{escape_sql_string(stored_proc_params[2])}',
            @Assignees=N'{escape_sql_string(stored_proc_params[3])}',
            @DueDate='{escape_sql_string(stored_proc_params[4])}',
            @LocalDueDate='{escape_sql_string(stored_proc_params[5])}',
            @Location=N'{escape_sql_string(stored_proc_params[6])}',
            @DueTime={stored_proc_params[7]},
            @SoftDueDate='{escape_sql_string(stored_proc_params[8])}',
            @FinalDueDate='{escape_sql_string(stored_proc_params[9])}',
            @Items=N'{escape_sql_string(stored_proc_params[10])}',
            @IsRecurring={stored_proc_params[11]},
            @FreqType={stored_proc_params[12]},
            @FreqRecurrance={stored_proc_params[13]},
            @FreqInterval={stored_proc_params[14]},
            @BusinessDayBehavior={stored_proc_params[15]},
            @Activate={stored_proc_params[16]},
            @IsReminder={stored_proc_params[17]},
            @ReminderDate='{escape_sql_string(stored_proc_params[18])}',
            @AddToPriorityList={stored_proc_params[19]},
            @NewInstanceId=@NewInstanceId OUTPUT;
        SELECT @NewInstanceId;
    """
    
    print("=== GENERATED SQL QUERY ===")
    print(sql_query)
    
    print("\n=== PARAMETERS ===")
    param_names = [
        'TaskName', 'MainController', 'Controllers', 'Assignees', 'DueDate',
        'LocalDueDate', 'Location', 'DueTime', 'SoftDueDate', 'FinalDueDate',
        'Items', 'IsRecurring', 'FreqType', 'FreqRecurrance', 'FreqInterval',
        'BusinessDayBehavior', 'Activate', 'IsReminder', 'ReminderDate', 'AddToPriorityList'
    ]
    
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

if __name__ == "__main__":
    test_sql_generation() 