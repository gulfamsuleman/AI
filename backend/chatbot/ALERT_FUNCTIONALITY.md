# Alert and Status Report Functionality Implementation

## Overview

This document describes the implementation of the QCheck_AddAlert and QStatus_AddReport functionality for the chatbot system. The alert system allows users to create tasks with automatic alerts that will be sent to specified recipients when certain conditions are met. The status report system allows users to include tasks in status reports for specific groups.

## ✅ **FIXES IMPLEMENTED**

### 1. **Alert Parameter Preservation** (FIXED)
- **Issue**: Alert parameters starting with `_` were being filtered out during parameter merging
- **Fix**: Updated `_merge_parameters()` in `ai_service.py` to preserve `_alert_*` parameters
- **Result**: Alert parameters are now correctly passed through the entire workflow

### 2. **Assignee Validation** (FIXED)
- **Issue**: Assignees were not being validated against `QCheck_Groups` table
- **Fix**: Updated `validate_assignees()` in `validation_service.py` to check against `QCheck_Groups`
- **Result**: Assignees are now properly validated against the groups table

### 3. **Name Resolution Service** (FIXED) ⭐ **NEW FIX**
- **Issue**: `NameResolutionService.resolve_assignees()` was calling `validate_and_resolve_user_name()` which checks against `QCheck_Users` table
- **Fix**: Updated `resolve_assignees()` to call `validate_group_exists()` which checks against `QCheck_Groups` table
- **Result**: Assignee name resolution now correctly validates against groups instead of users

### 4. **Alert Extraction for Individual Names** (FIXED) ⭐ **NEW FIX**
- **Issue**: Alert extraction regex was only matching all-uppercase group names (like "CLO") but not individual names (like "Ken croft")
- **Fix**: Updated regex patterns to handle both group names and individual names using `[A-Z][A-Za-z\s]+?`
- **Result**: Alert extraction now works for both group names and individual names

### 5. **Custom Alert Messages** (FIXED) ⭐ **NEW FIX**
- **Issue**: System didn't support custom alert messages specified by users
- **Fix**: Added regex pattern to extract custom messages and updated alert creation to use them
- **Result**: Users can now specify custom alert messages like `with alert message "Kabhi Kamm bhi krlia kro"`

### 6. **Group Validation Before ID Lookup** (FIXED) ⭐ **NEW FIX**
- **Issue**: Alert recipient names were not being validated against `QCheck_Groups` table before getting the ID
- **Fix**: Updated `_get_group_id_for_alert()` to first validate group exists using `CHECK_GROUP_EXISTS`, then get ID using `GET_GROUP_ID_BY_NAME`
- **Result**: Ensures data integrity by validating group names exist before using them in stored procedures

### 7. **Fuzzy Matching for Alert Recipients** (FIXED) ⭐ **NEW FIX**
- **Issue**: Alert recipient validation didn't use fuzzy matching, so "Ken" wouldn't match "Ken Croft"
- **Fix**: Enhanced `validate_group_exists()` method to use sophisticated fuzzy matching like assignee validation
- **Result**: Alert recipients now support partial names like "Ken" automatically matching "Ken Croft", and multiple matches prompt for clarification

### 8. **Status Report Functionality** (NEW) ⭐ **NEW FEATURE**
- **Feature**: Added complete status report functionality using `QStatus_AddReport` stored procedure
- **Implementation**: Added status report extraction, validation, and creation with fuzzy matching
- **Result**: Users can now include tasks in status reports with patterns like "include in IT status report under maintenance"

### 9. **Enhanced Fuzzy Matching with Context** (NEW) ⭐ **NEW FIX**
- **Issue**: Status report group matching was failing when multiple similar groups existed (e.g., "audit" matching multiple groups)
- **Fix**: Enhanced fuzzy matching to consider context (assignee groups) when selecting the best match
- **Result**: Status report groups now intelligently select the best match using context, resolving issues like "audit" → "Audit Dream team" when assignee is "Audit Dream team"

## Features Implemented

### 1. Alert Pattern Recognition
The system can detect alert requirements in user messages using various patterns:

- **Pattern 1**: `"add alert if overdue to [RECIPIENT]"` (supports both groups and individuals)
- **Pattern 2**: `"alert me"`
- **Pattern 3**: `"alert [amount] [unit] before"`
- **Pattern 4**: `"add alert" with recipient`
- **Pattern 5**: `"with alert message 'custom text'"`

### 2. Status Report Pattern Recognition
The system can detect status report requirements in user messages using various patterns:

- **Pattern 1**: `"include in [GROUP] status report"` (supports both groups and individuals)
- **Pattern 2**: `"status report for [GROUP]"`
- **Pattern 3**: `"report to [GROUP]"`
- **Pattern 4**: `"status report under [CUSTOM_NAME]"`

### 3. Alert Parameter Extraction
The system extracts the following alert parameters:
- `_alert_required`: Boolean indicating if alert is needed
- `_alert_recipient`: The group/recipient for the alert
- `_alert_condition`: When the alert should trigger (overdue, at_due, etc.)
- `_alert_type`: Type of alert (email, SMS, Overdue, etc.)
- `_alert_custom_message`: Custom alert message specified by user

### 4. Status Report Parameter Extraction
The system extracts the following status report parameters:
- `_status_report_required`: Boolean indicating if status report is needed
- `_status_report_group`: The group for the status report
- `_status_report_name`: Custom report name (optional, defaults to task name)

### 5. Database Integration
- **Alert Stored Procedure**: `QCheck_AddAlert`
- **Status Report Stored Procedure**: `QStatus_AddReport`
- **Group ID Lookup**: Automatic resolution of group names to IDs with fuzzy matching
- **Console Logging**: Comprehensive logging of all operations

## Implementation Details

### Files Modified

1. **`chatbot/config/queries.py`**
   - Added `ADD_ALERT_PROCEDURE` query
   - Added `ADD_STATUS_REPORT_PROCEDURE` query
   - Added `GET_GROUP_ID_BY_NAME` query

2. **`chatbot/services/parameter_extractor.py`**
   - Added `extract_alert_requirements()` method
   - Added `extract_status_report_requirements()` method
   - Integrated both extractions into `pre_extract_parameters()`
   - Updated regex patterns to handle individual names and custom messages

3. **`chatbot/services/database_service.py`**
   - Added `create_alert_for_task()` method
   - Added `create_status_report_for_task()` method
   - Added `_get_group_id_for_alert()` helper method with fuzzy matching
   - Added `_get_group_id_for_status_report()` helper method with fuzzy matching
   - Enhanced `validate_group_exists()` with sophisticated fuzzy matching
   - Updated to handle custom alert messages

4. **`chatbot/services/task_service.py`**
   - Added alert creation logic to `_create_single_task()`
   - Added status report creation logic to `_create_single_task()`
   - Updated to pass custom alert messages

5. **`chatbot/services/ai_service.py`** ⭐ **FIXED**
   - Updated `_merge_parameters()` to preserve `_alert_*` and `_status_report_*` parameters

6. **`chatbot/services/validation_service.py`** ⭐ **FIXED**
   - Updated `validate_assignees()` to check against `QCheck_Groups` table

7. **`chatbot/services/name_resolution_service.py`** ⭐ **FIXED**
   - Updated `resolve_assignees()` to call `validate_group_exists()` instead of `validate_and_resolve_user_name()`

### Example Usage

#### User Input (Alert)
```
Assign "Never take content" to Ken croft due tomorrow at 5 PM , add alert if overdue to CLO with alert message "Kabhi Kamm bhi krlia kro"
```

#### User Input (Status Report)
```
Recurring task "Backup server" every Monday, include in IT status report under maintenance
```

#### System Processing
1. **Pattern Detection**: Recognizes alert/status report patterns
2. **Parameter Extraction**: 
   - Alert: `_alert_required`, `_alert_recipient`, `_alert_condition`, `_alert_type`, `_alert_custom_message`
   - Status Report: `_status_report_required`, `_status_report_group`, `_status_report_name`
3. **Parameter Merging**: ✅ Alert and status report parameters are preserved
4. **Assignee Validation**: ✅ Validates against `QCheck_Groups`
5. **Name Resolution**: ✅ Resolves using `validate_group_exists()`
6. **Task Creation**: Creates the main task
7. **Alert Creation**: Calls `QCheck_AddAlert` stored procedure with custom message
8. **Status Report Creation**: Calls `QStatus_AddReport` stored procedure

#### Stored Procedure Calls
```sql
-- Alert
EXEC dbo.QCheck_AddAlert
    @InstanceID = 101,          -- the task instance ID
    @nagBeforeDays = 0,         -- 0 means on due date
    @nagTime = 9.30,            -- 9:30 AM reminder
    @alerteegroupid = 3,        -- group ID of the recipients (CLO)
    @alertType = 'Overdue',     -- alert type
    @alertText = 'Kabhi Kamm bhi krlia kro';  -- custom message

-- Status Report
EXEC dbo.QStatus_AddReport
    @GroupID = 5,               -- group ID for IT
    @ReportName = 'maintenance'; -- custom report name
```

## Console Logging

The system provides comprehensive logging for debugging and monitoring:

```
[INFO] ALERT REQUIREMENTS DETECTED:
[INFO]   Alert required: True
[INFO]   Alert recipient: CLO
[INFO]   Alert condition: overdue
[INFO]   Alert type: email
[INFO]   Custom alert message: Kabhi Kamm bhi krlia kro

[INFO] STATUS REPORT REQUIREMENTS DETECTED:
[INFO]   Status report required: True
[INFO]   Status report group: IT
[INFO]   Status report name: maintenance

[INFO] ALERT CREATION STARTED for task 2074134
[INFO] Alert parameters received: {'_alert_recipient': 'CLO', '_alert_condition': 'overdue', '_alert_type': 'email', '_alert_custom_message': 'Kabhi Kamm bhi krlia kro'}
[INFO] Validated group 'CLO' exists in QCheck_Groups table with ID 1468
[INFO] Creating alert for group ID 1468 (group: CLO)
[INFO] ALERT STORED PROCEDURE PARAMETERS:
[INFO]   @InstanceID = 2074134
[INFO]   @nagBeforeDays = 0
[INFO]   @nagTime = 9.0
[INFO]   @alerteegroupid = 1468
[INFO]   @alertType = 'Overdue'
[INFO]   @alertText = 'Kabhi Kamm bhi krlia kro'
[INFO]   Custom message: 'Kabhi Kamm bhi krlia kro'
[INFO] Successfully created alert for task 2074134 to CLO

[INFO] STATUS REPORT CREATION STARTED for task 2074134
[INFO] Status report parameters received: {'_status_report_group': 'IT', '_status_report_name': 'maintenance', 'TaskName': 'Backup server'}
[INFO] Validated group 'IT' exists in QCheck_Groups table with ID 1234
[INFO] Creating status report for group ID 1234 (group: IT)
[INFO] STATUS REPORT STORED PROCEDURE PARAMETERS:
[INFO]   @GroupID = 1234
[INFO]   @ReportName = 'maintenance'
[INFO]   Group: 'IT'
[INFO] Successfully created status report for task 2074134 to IT
```

## Supported Patterns

### Alert Patterns
1. **Overdue Alerts**: `"add alert if overdue to [RECIPIENT]"`
2. **Due Date Alerts**: `"add alert" with recipient`
3. **Time-based Alerts**: `"alert [amount] [unit] before"`
4. **Simple Alerts**: `"alert me"`
5. **Custom Alert Messages**: `"with alert message 'custom text'"`

### Status Report Patterns
1. **Include in Group**: `"include in [GROUP] status report"`
2. **Status Report for Group**: `"status report for [GROUP]"`
3. **Report to Group**: `"report to [GROUP]"`
4. **Custom Report Name**: `"status report under [CUSTOM_NAME]"`

## Group ID Resolution with Fuzzy Matching

The system validates and resolves group names to their corresponding IDs using sophisticated fuzzy matching:

### Step 1: Fuzzy Match and Validate Group
```python
# Uses validate_group_exists() with fuzzy matching
group_exists, resolved_name, similar_groups = DatabaseService.validate_group_exists(group_name)
```

### Step 2: Get Group ID
```sql
SELECT ID FROM QCheck_Groups WHERE Name = 'IT Team'
```

This fuzzy matching ensures:
1. **Partial Names**: "IT" automatically matches "IT Team"
2. **Multiple Matches**: If multiple "IT" groups exist, system asks for clarification
3. **Spelling Mistakes**: Handles minor spelling errors
4. **Case Insensitive**: Works regardless of case

## Assignee Validation

Assignees are now validated against the `QCheck_Groups` table:

```sql
SELECT Name FROM [QTasks].[dbo].[QCheck_Groups] WHERE Name = %s
```

This ensures that only valid groups can be assigned to tasks.

## Error Handling

The alert and status report systems include comprehensive error handling:

1. **Group Not Found**: Logs warning and continues without alert/report
2. **Multiple Matches**: Logs available options for clarification
3. **Database Errors**: Logs error details and continues task creation
4. **Invalid Parameters**: Validates parameters before stored procedure call
5. **Assignee Validation**: Validates assignees against `QCheck_Groups` table

## Testing Results

✅ **Alert Parameter Extraction**: Working correctly for both groups and individuals
✅ **Alert Parameter Merging**: Fixed and working
✅ **Status Report Parameter Extraction**: Working correctly for all patterns
✅ **Status Report Parameter Merging**: Fixed and working
✅ **Assignee Validation**: Updated to use `QCheck_Groups`
✅ **Name Resolution**: Fixed to use `validate_group_exists()`
✅ **Custom Alert Messages**: Working correctly
✅ **Custom Status Report Names**: Working correctly
✅ **Group Validation**: Two-step validation working correctly
✅ **Fuzzy Matching**: Enhanced with sophisticated matching logic and context awareness
✅ **Context-Aware Matching**: Status report groups now consider assignee context for better matching
✅ **Stored Procedure Integration**: Ready for use
✅ **Console Logging**: Comprehensive logging implemented

## Integration with Existing System

The alert and status report functionality integrates seamlessly with the existing task creation workflow:

1. **Pre-extraction**: Alert and status report requirements are detected during parameter extraction
2. **Parameter Merging**: ✅ Alert and status report parameters are preserved through the merge process
3. **Validation**: ✅ Assignees are validated against `QCheck_Groups`
4. **Name Resolution**: ✅ Assignees are resolved using group validation
5. **Task Creation**: Main task is created using existing stored procedure
6. **Alert Creation**: Alert is created after successful task creation with fuzzy matching
7. **Status Report Creation**: Status report is created after successful task creation with fuzzy matching
8. **Logging**: All operations are logged for monitoring

This ensures that alerts and status reports are only created for successfully created tasks and provides a complete audit trail.

## Status: ✅ **READY FOR PRODUCTION**

The alert and status report functionality is now fully implemented and tested. It will correctly:
- Detect alert patterns in user messages (both groups and individuals)
- Detect status report patterns in user messages (both groups and individuals)
- Extract and preserve alert parameters including custom messages
- Extract and preserve status report parameters including custom names
- Validate assignees against the correct table (`QCheck_Groups`)
- Resolve assignee names using group validation
- Validate alert recipient groups exist before getting IDs
- Validate status report groups exist before getting IDs
- Use fuzzy matching to handle partial names like "IT" → "IT Team"
- Handle multiple matches by prompting for clarification
- Create alerts using the `QCheck_AddAlert` stored procedure with custom messages
- Create status reports using the `QStatus_AddReport` stored procedure with custom names
- Provide comprehensive logging for monitoring
