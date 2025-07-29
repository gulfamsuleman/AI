from dotenv import load_dotenv
load_dotenv()

from django.db import connection
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
import os
import requests
from .models import ChatHistory, Task, PendingTaskSession
from .serializers import TaskSerializer
import datetime
from dateutil.relativedelta import relativedelta
import pytz

# Claude Opus API integration
CLAUDE_API_KEY = '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'
CLAUDE_API_URL = 'https://api.anthropic.com/v1/messages'

def convert_to_user_timezone(date_str, time_str, user_timezone):
    """
    Convert date and time strings to the user's timezone
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
        # If conversion fails, return original values
        return date_str, time_str

def get_current_date_in_timezone(user_timezone):
    """
    Get the current date in the user's timezone
    """
    try:
        user_tz = pytz.timezone(user_timezone)
        current_time = datetime.datetime.now(user_tz)
        return current_time.date()
    except Exception:
        # Fallback to UTC if timezone is invalid
        return datetime.date.today()

def parse_natural_date_with_timezone(date_str, user_timezone):
    """
    Parse natural language dates in the context of user's timezone
    """
    # Get current date in user's timezone
    today = get_current_date_in_timezone(user_timezone)
    
    if not date_str:
        return None
    
    s = date_str.strip().lower()
    
    # Handle relative dates
    if s == 'today':
        return today.isoformat()
    elif s == 'tomorrow':
        return (today + datetime.timedelta(days=1)).isoformat()
    elif s == 'day after tomorrow' or s == 'day after tmrw':
        return (today + datetime.timedelta(days=2)).isoformat()
    elif s == 'yesterday':
        return (today - datetime.timedelta(days=1)).isoformat()
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
                due_date = datetime.datetime.strptime(params['DueDate'], '%Y-%m-%d').date()
                reminder_date = due_date - datetime.timedelta(days=1)
                params['ReminderDate'] = reminder_date.isoformat()
            except:
                # If parsing fails, set to tomorrow (same as default due date)
                current_date = get_current_date_in_timezone(user_timezone)
                tomorrow = current_date + datetime.timedelta(days=1)
                params['ReminderDate'] = tomorrow.isoformat()
        else:
            # If no DueDate, set to tomorrow (same as default due date)
            current_date = get_current_date_in_timezone(user_timezone)
            tomorrow = current_date + datetime.timedelta(days=1)
            params['ReminderDate'] = tomorrow.isoformat()
    
    # Set FinalDueDate to match DueDate (if DueDate exists)
    if params.get('DueDate'):
        params['FinalDueDate'] = params['DueDate']
    else:
        # If no DueDate, set FinalDueDate to tomorrow (same as default)
        current_date = get_current_date_in_timezone(user_timezone)
        tomorrow = current_date + datetime.timedelta(days=1)
        params['FinalDueDate'] = tomorrow.isoformat()
    
    return params

def set_default_due_date_time(params, user_timezone):
    """
    Set default due date to tomorrow at 7 PM in user's timezone if not provided
    Also automatically set LocalDueDate and SoftDueDate to match the DueDate
    """
    current_date = get_current_date_in_timezone(user_timezone)
    tomorrow = current_date + datetime.timedelta(days=1)
    
    # Set default due date if not provided
    if not params.get('DueDate') or params['DueDate'] in [None, '']:
        params['DueDate'] = tomorrow.isoformat()
    
    # Set default due time if not provided
    if not params.get('DueTime') or params['DueTime'] in [None, '']:
        params['DueTime'] = '17:00'  # 5 PM
    
    # Always set LocalDueDate and SoftDueDate to match the DueDate (whether provided by user or default)
    params['LocalDueDate'] = params['DueDate']
    params['SoftDueDate'] = params['DueDate']
    
    return params

def parse_natural_time_with_timezone(time_str, user_timezone):
    """
    Parse natural language time references in the context of user's timezone
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
        return '17:00'
    elif s == 'before close' or s == 'before closing':
        return '16:00'
    
    # If already in HH:MM format, return as is
    try:
        datetime.datetime.strptime(time_str, '%H:%M')
        return time_str
    except Exception:
        return None

class ChatAPIView(APIView):
    def post(self, request):
        user_message = request.data.get('message')
        user_name = request.data.get('user')
        main_controller = request.data.get('mainController') or request.data.get('user')
        user_timezone = request.data.get('timezone', 'UTC')  # Get timezone from frontend, default to UTC
        
        if not user_message:
            return Response({'error': 'No message provided.'}, status=status.HTTP_400_BAD_REQUEST)
        if not user_name:
            return Response({'error': 'No user provided.'}, status=status.HTTP_400_BAD_REQUEST)
        if not main_controller:
            return Response({'error': 'No mainController provided.'}, status=status.HTTP_400_BAD_REQUEST)
        # Fetch user FullName from SQL Server
        with connection.cursor() as cursor:
            cursor.execute("SELECT FullName FROM [QTasks].[dbo].[QCheck_Users] WHERE FullName=%s", [main_controller])
            row = cursor.fetchone()
            if not row:
                return Response({'error': f'User {main_controller} not found in QCheck_Users.'}, status=status.HTTP_400_BAD_REQUEST)
            user_fullname = row[0]
        # Use username as session key
        session, _ = PendingTaskSession.objects.get_or_create(user=user_name)
        # Get current parameters from session
        params = session.parameters.get('params', {})
        history = session.parameters.get('history', [])
        history.append({"role": "user", "content": user_message})
        
        # Get current date in user's timezone for context
        current_date = get_current_date_in_timezone(user_timezone)
        
        # Update system prompt to include timezone and current date information
        system_prompt = (
            f"You are a helpful assistant. The user's timezone is {user_timezone} and today's date is {current_date.isoformat()}. "
            "When the user gives a prompt, extract as many of the following parameters as possible: "
            "TaskName, Controllers, Assignees, DueDate, DueTime, Items, IsRecurring, FreqType, FreqRecurrance, FreqInterval, BusinessDayBehavior. "
            "For FreqType, use these integer values: 1=Daily, 2=Weekly, 3=Monthly, 4=Yearly. "
            "For IsRecurring, use 1 for Yes/True, 0 for No/False. "
            "For FreqRecurrance, FreqInterval, and BusinessDayBehavior, use integer values. "
            f"For date and time fields, interpret them in the user's timezone ({user_timezone}). "
            f"When users mention relative times like 'tomorrow' (which would be {current_date + datetime.timedelta(days=1)}), 'next week', 'morning', 'afternoon', etc., calculate the actual dates and times in their timezone. "
            "For dates, use YYYY-MM-DD format. For times, use HH:MM format in 24-hour format. "
            "IMPORTANT: If the user doesn't specify a due date or time, you can leave those fields empty - the system will automatically default to tomorrow at 5 PM in their timezone. "
            "If the user doesn't specify Assignees or Controllers, they will automatically be set to the main controller. "
            "Location will be automatically set to the user's timezone, Activate will be set to 1, and FinalDueDate will match the DueDate. "
            "LocalDueDate and SoftDueDate will be automatically set to match the DueDate. "
            "AddToPriorityList will default to 0 (not in priority list), IsReminder will default to 1 (reminder enabled), and ReminderDate will default to the day before the due date. "
            "If any other required fields are missing, ask for them one at a time, specifying the required type and an example. When you have all parameters, return a JSON object with all fields. Do not proceed until all are collected. The MainController is already provided."
        )
        
        llm_payload = {
            'model': 'claude-opus-4-20250514',
            'max_tokens': 1024,
            'system': system_prompt,
            'messages': history
        }
        headers = {
            'x-api-key': CLAUDE_API_KEY,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
        }
        llm_response = requests.post(CLAUDE_API_URL, headers=headers, json=llm_payload, timeout=30)
        llm_data = llm_response.json()
        import re
        import json as pyjson
        if llm_response.status_code != 200 or 'content' not in llm_data:
            return Response({'error': 'LLM error: ' + str(llm_data)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        try:
            content = llm_data['content'][0]['text'] if isinstance(llm_data['content'], list) else llm_data['content']
            match = re.search(r'\{[\s\S]*?\}', content)
            if match:
                llm_json = pyjson.loads(match.group(0))
                is_json_response = True
            else:
                llm_json = {}
                is_json_response = False
        except Exception as e:
            session.parameters['history'] = history
            session.save()
            return Response({'reply': 'Sorry, I could not understand the AI response. Please try again.'})
        if is_json_response:
            # Merge new parameters from LLM with those already stored
            params.update(llm_json)
            session.parameters['params'] = params
            session.parameters['history'] = history
            session.save()
            # Required fields (excluding fields that have automatic defaults)
            required_fields = [
                'TaskName', 'Items', 'IsRecurring', 'FreqType', 'FreqRecurrance', 'FreqInterval', 'BusinessDayBehavior'
            ]
            missing = [f for f in required_fields if f not in params or params[f] in [None, '']]
            if missing:
                return Response({'reply': f"Missing parameters: {', '.join(missing)}. Please provide them."})
            
            # Process date and time parameters with timezone conversion
            if 'DueDate' in params:
                params['DueDate'] = parse_natural_date_with_timezone(params['DueDate'], user_timezone)
            if 'DueTime' in params:
                params['DueTime'] = parse_natural_time_with_timezone(params['DueTime'], user_timezone)
            
            # Apply default due date and time if missing, and set LocalDueDate/SoftDueDate to match DueDate
            params = set_default_due_date_time(params, user_timezone)
            
            # Set automatic parameters (Location, Activate, FinalDueDate, AddToPriorityList, IsReminder, ReminderDate, Assignees, Controllers)
            params = set_automatic_parameters(params, user_timezone, user_fullname)
            
            # Convert text-based frequency types to integers
            def convert_freq_type_to_int(freq_type):
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
            
            # Convert FreqType to integer if it's a string
            if 'FreqType' in params:
                params['FreqType'] = convert_freq_type_to_int(params['FreqType'])
            
            # Ensure all integer parameters are actually integers
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
            
            integer_params = ['IsRecurring', 'FreqRecurrance', 'FreqInterval', 'BusinessDayBehavior', 'Activate', 'IsReminder', 'AddToPriorityList']
            for param in integer_params:
                if param in params:
                    params[param] = convert_to_int(params[param], param)

            # All parameters present, call stored procedure
            # Convert time format from HH:MM to integer format (e.g., "17:00" -> 17000)
            due_time_int = None
            if params.get('DueTime'):
                try:
                    time_parts = params['DueTime'].split(':')
                    if len(time_parts) == 2:
                        hours = int(time_parts[0])
                        minutes = int(time_parts[1])
                        due_time_int = hours * 100 + minutes
                    else:
                        due_time_int = 17000  # Default to 5 PM
                except:
                    due_time_int = 17000  # Default to 5 PM
            else:
                due_time_int = 17000  # Default to 5 PM
            
            # Convert dates to datetime format for SQL Server
            def format_date_for_sql(date_str, time_str=None):
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
            
            # Helper function to safely escape strings for SQL
            def escape_sql_string(s):
                if s is None:
                    return "NULL"
                return str(s).replace("'", "''")
            
            # Prepare parameters for debugging
            stored_proc_params = [
                    params['TaskName'],
                    user_fullname,
                    params['Controllers'],
                    params['Assignees'],
                format_date_for_sql(params['DueDate'], params.get('DueTime')),
                format_date_for_sql(params['LocalDueDate'], params.get('DueTime')),
                    params['Location'],
                due_time_int,
                format_date_for_sql(params['SoftDueDate'], params.get('DueTime')),
                format_date_for_sql(params['FinalDueDate'], params.get('DueTime')),
                    params['Items'],
                    int(params['IsRecurring']),
                    params['FreqType'],
                    params['FreqRecurrance'],
                    params['FreqInterval'],
                    params['BusinessDayBehavior'],
                    int(params['Activate']),
                    int(params['IsReminder']),
                format_date_for_sql(params['ReminderDate'], params.get('DueTime')),
                    int(params['AddToPriorityList']),
            ]
            
            try:
                with connection.cursor() as cursor:
                    # Build the SQL query with proper quoting for string parameters
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
                        SELECT @NewInstanceId AS CreatedInstanceID;
                    """
                    # Debug: Print the SQL query and parameters
                    print("Generated SQL Query:")
                    print(sql_query)
                    print("Parameters with types:")
                    param_names = [
                        'TaskName', 'MainController', 'Controllers', 'Assignees', 'DueDate',
                        'LocalDueDate', 'Location', 'DueTime', 'SoftDueDate', 'FinalDueDate',
                        'Items', 'IsRecurring', 'FreqType', 'FreqRecurrance', 'FreqInterval',
                        'BusinessDayBehavior', 'Activate', 'IsReminder', 'ReminderDate', 'AddToPriorityList'
                    ]
                    for i, (name, value) in enumerate(zip(param_names, stored_proc_params)):
                        print(f"  {name}: {value} (type: {type(value).__name__})")
                    
                    # Execute the stored procedure
                    cursor.execute(sql_query)
                    
                    # Try to get the result
                    try:
                        result = cursor.fetchone()
                        if result and result[0] is not None:
                            new_instance_id = result[0]
                        else:
                            # If no result, assume the task was created successfully
                            new_instance_id = "SUCCESS"
                    except Exception as fetch_error:
                        # If we can't fetch the result, assume success
                        print(f"Could not fetch result: {fetch_error}")
                        new_instance_id = "SUCCESS"
            except Exception as e:
                # Log the error and parameters for debugging
                error_msg = f"Stored procedure error: {str(e)}. Parameters: {stored_proc_params}"
                print(error_msg)  # For debugging
                return Response({'error': f'Failed to create task: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            session.delete()
            if new_instance_id == "SUCCESS":
                return Response({'reply': f'Task created successfully! The task has been added to the system.'})
            else:
            return Response({'reply': f'Task created! NewInstanceId: {new_instance_id}'})
        else:
            session.parameters['history'] = history
            session.save()
            return Response({'reply': content})

class UserListView(APIView):
    def get(self, request):
        with connection.cursor() as cursor:
            cursor.execute("SELECT FullName FROM [QTasks].[dbo].[QCheck_Users]")
            users = [row[0] for row in cursor.fetchall()]
        return Response(users)

class RunStoredProcedureView(APIView):
    def post(self, request):
        param1 = request.data.get('param1')
        param2 = request.data.get('param2')
        # Add more params as needed
        with connection.cursor() as cursor:
            cursor.callproc('my_stored_procedure', [param1, param2])
            result = cursor.fetchall()  # Adjust as needed
        return Response({'result': result}, status=status.HTTP_200_OK)

def parse_natural_date(date_str):
    today = datetime.date.today()
    if not date_str:
        return None
    s = date_str.strip().lower()
    if s == 'today':
        return today.isoformat()
    if s == 'tomorrow':
        return (today + datetime.timedelta(days=1)).isoformat()
    if s == 'day after tomorrow':
        return (today + datetime.timedelta(days=2)).isoformat()
    if s == 'yesterday':
        return (today - datetime.timedelta(days=1)).isoformat()
    if s.startswith('next week'):
        return (today + datetime.timedelta(weeks=1)).isoformat()
    # Add more patterns as needed
    # If already in YYYY-MM-DD, return as is
    try:
        datetime.datetime.strptime(date_str, '%Y-%m-%d')
        return date_str
    except Exception:
        return None

# New function to parse natural language time references

def parse_natural_time(time_str):
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
