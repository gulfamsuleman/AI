#!/usr/bin/env python3
"""
QA Test Script - Reads Prompts from Excel File

This script:
1. Reads prompts from QA_Test_Cases.xlsx Prompt column
2. Runs QA tests on those actual prompts
3. Queries SQL Server database for actual results
4. Saves comprehensive results in Excel format
5. Verifies stored procedure execution: QCheck_CreateTaskThroughChatbot, QStatus_AddReport, QCheck_AddAlert
"""

import requests
import json
import time
import pyodbc
import pandas as pd
from pathlib import Path
from datetime import datetime
import os

def read_prompts_from_excel():
    """Read prompts from the Excel file."""
    
    print("📖 Reading prompts from Excel file...")
    
    # Path to the Excel file
    excel_file = Path(__file__).parent / "QA_Test_Cases.xlsx"
    
    if not excel_file.exists():
        print(f"❌ Excel file not found: {excel_file}")
        return []
    
    try:
        # Read the Excel file
        df = pd.read_excel(excel_file)
        
        # Check if 'Prompt' column exists
        if 'Prompt' not in df.columns:
            print("❌ 'Prompt' column not found in Excel file")
            print(f"Available columns: {list(df.columns)}")
            return []
        
        # Extract prompts and create test cases
        test_cases = []
        for index, row in df.iterrows():
            prompt = row['Prompt']
            if pd.notna(prompt) and str(prompt).strip():
                test_case = {
                    "id": index + 1,
                    "prompt": str(prompt).strip(),
                    "description": f"Test Case {index + 1}",
                    "expected_sps": analyze_expected_stored_procedures(str(prompt).strip()),
                    "task_name": extract_task_name(str(prompt).strip()),
                    "status_report_name": extract_status_report_name(str(prompt).strip())
                }
                test_cases.append(test_case)
                print(f"📝 Loaded Test Case {index + 1}: {str(prompt).strip()[:50]}...")
        
        print(f"✅ Successfully loaded {len(test_cases)} test cases from Excel file")
        return test_cases
        
    except Exception as e:
        print(f"❌ Failed to read Excel file: {e}")
        return []

def analyze_expected_stored_procedures(prompt):
    """Analyze which stored procedures should be called based on the prompt."""
    
    expected_sps = []
    prompt_lower = prompt.lower()
    
    # Task Creation SP
    if any(word in prompt_lower for word in ['create', 'set up', 'schedule', 'add']):
        expected_sps.append('QCheck_CreateTaskThroughChatbot')
    
    # Status Report SP
    if any(word in prompt_lower for word in ['status report', 'include in', 'add to', 'report']):
        expected_sps.append('QStatus_AddReport')
    
    # Alert SP
    if any(word in prompt_lower for word in ['alert', 'reminder', 'notify']):
        expected_sps.append('QCheck_AddAlert')
    
    # If no specific SPs detected, assume task creation
    if not expected_sps:
        expected_sps.append('QCheck_CreateTaskThroughChatbot')
    
    return expected_sps

def extract_task_name(prompt):
    """Extract task name from prompt."""
    
    # Look for task names in quotes
    import re
    quote_match = re.search(r"'([^']+)'", prompt)
    if quote_match:
        return quote_match.group(1)
    
    # Look for task names after "Create" or "Set up"
    create_match = re.search(r'(?:create|set up|schedule)\s+(?:a\s+)?(?:task\s+)?["\']?([^"\']+?)["\']?(?:\s+for|\s+due|\s+with|$)', prompt, re.IGNORECASE)
    if create_match:
        return create_match.group(1).strip()
    
    # Look for task names before "for" or "due"
    for_match = re.search(r'([^for]+?)\s+for\s+', prompt, re.IGNORECASE)
    if for_match:
        return for_match.group(1).strip()
    
    return "Unknown Task"

def extract_status_report_name(prompt):
    """Extract status report name from prompt."""
    
    import re
    
    # Look for status report mentions
    status_match = re.search(r'(?:include in|add to|status report)\s+([^,\s]+(?:\s+[^,\s]+)*?)(?:\s+status report|$)', prompt, re.IGNORECASE)
    if status_match:
        return status_match.group(1).strip()
    
    return None

def run_qa_tests_and_verify():
    """Run QA tests and verify results in database."""
    
    print("🧪 QA Test Execution with Database Verification")
    print("=" * 70)
    
    # Read prompts from Excel file
    test_cases = read_prompts_from_excel()
    
    if not test_cases:
        print("❌ No test cases loaded. Exiting.")
        return []
    
    print(f"\n📋 Loaded {len(test_cases)} test cases from Excel file")
    print()
    
    # Test configuration
    base_url = "http://localhost:8000"
    chat_endpoint = "/api/chat/"
    
    print(f"🌐 Testing against: {base_url}{chat_endpoint}")
    print()
    
    # Test results storage
    test_results = []
    
    # Test each case
    for test_case in test_cases:
        print(f"🧪 Test Case {test_case['id']}: {test_case['description']}")
        print(f"   Prompt: {test_case['prompt']}")
        print(f"   Expected SPs: {', '.join(test_case['expected_sps'])}")
        print(f"   Task Name: {test_case['task_name']}")
        if test_case['status_report_name']:
            print(f"   Status Report: {test_case['status_report_name']}")
        print("-" * 60)
        
        # Execute test
        result = execute_test_case(base_url, chat_endpoint, test_case)
        
        # Wait between tests
        if test_case["id"] < len(test_cases):
            print("⏳ Waiting 3 seconds before next test...")
            time.sleep(3)
        
        test_results.append(result)
    
    # Verify results in database
    print("\n🔍 Verifying results in SQL Server database...")
    verified_results = verify_database_results(test_results)
    
    # Generate Excel report
    generate_excel_report(verified_results)
    
    return verified_results

def execute_test_case(base_url, chat_endpoint, test_case):
    """Execute a single test case."""
    
    case_id = test_case["id"]
    prompt = test_case["prompt"]
    expected_sps = test_case["expected_sps"]
    task_name = test_case.get("task_name", "")
    status_report_name = test_case.get("status_report_name", "")
    
    # Prepare the request
    payload = {
        "message": prompt,
        "user": "QA_Test_User",
        "timezone": "UTC"
    }
    
    result = {
        "case_id": case_id,
        "description": test_case["description"],
        "prompt": prompt,
        "expected_sps": expected_sps,
        "task_name": task_name,
        "status_report_name": status_report_name,
        "success": False,
        "response_time": None,
        "response_text": None,
        "error": None,
        "database_results": {}
    }
    
    try:
        # Send request to chatbot
        print("📤 Sending request to chatbot...")
        start_time = time.time()
        
        response = requests.post(
            f"{base_url}{chat_endpoint}",
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        
        response_time = time.time() - start_time
        
        # Analyze response
        if response.status_code == 200:
            result["success"] = True
            result["response_text"] = response.text
            result["response_time"] = response_time
            
            # Try to parse JSON response
            try:
                response_data = response.json()
                if isinstance(response_data, dict):
                    result["response_text"] = json.dumps(response_data, indent=2)
            except:
                pass
                
            print(f"✅ Test Case {case_id} - SUCCESS")
            print(f"   Response Time: {response_time:.2f} seconds")
        else:
            result["error"] = f"HTTP {response.status_code}: {response.text}"
            print(f"❌ Test Case {case_id} - FAILED")
            print(f"   Error: {result['error']}")
        
    except Exception as e:
        result["error"] = f"Request failed: {str(e)}"
        print(f"❌ Test Case {case_id} - FAILED")
        print(f"   Error: {result['error']}")
    
    print("=" * 70)
    return result

def verify_database_results(test_results):
    """Verify test results by querying the SQL Server database."""
    
    print("🔍 Connecting to SQL Server database...")
    
    try:
        # Database connection parameters
        server = "DESKTOP-BIP1CP7\\SQLEXPRESS"
        database = "QTasks"
        trusted_connection = "yes"
        
        # Create connection string
        conn_str = f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={server};DATABASE={database};Trusted_Connection={trusted_connection};"
        
        # Connect to database
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()
        
        print("✅ Connected to SQL Server database successfully")
        
        # Verify each test result
        for result in test_results:
            if result["success"] and result["task_name"]:
                print(f"\n🔍 Verifying Test Case {result['case_id']}: {result['task_name']}")
                
                # Query for task in QCheck_Checklists
                task_results = query_tasks(cursor, result["task_name"])
                result["database_results"]["tasks"] = task_results
                
                # Query for status report if expected
                if "QStatus_AddReport" in result["expected_sps"] and result["status_report_name"]:
                    status_results = query_status_reports(cursor, result["status_report_name"])
                    result["database_results"]["status_reports"] = status_results
                
                # Query for alerts (check if any alerts were created)
                alert_results = query_alerts(cursor, result["task_name"])
                result["database_results"]["alerts"] = alert_results
        
        cursor.close()
        conn.close()
        print("✅ Database verification completed")
        
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        # Add empty database results if connection fails
        for result in test_results:
            result["database_results"] = {
                "tasks": [],
                "status_reports": [],
                "alerts": []
            }
    
    return test_results

def query_tasks(cursor, task_name):
    """Query for tasks in QCheck_Checklists table."""
    
    try:
        query = """
        SELECT 
            [Name],
            [IsDeleted],
            [Owner],
            [Template],
            [CreateDate]
        FROM [Qtasks].[dbo].[QCheck_Checklists] 
        WHERE [Name] LIKE ?
        ORDER BY [CreateDate] DESC
        """
        
        cursor.execute(query, f"%{task_name}%")
        rows = cursor.fetchall()
        
        results = []
        for row in rows:
            results.append({
                "Name": row[0],
                "IsDeleted": row[1],
                "Owner": row[2],
                "Template": row[3],
                "CreateDate": str(row[4]) if row[4] else None
            })
        
        print(f"   📋 Tasks found: {len(results)}")
        return results
        
    except Exception as e:
        print(f"   ❌ Task query failed: {e}")
        return []

def query_status_reports(cursor, status_report_name):
    """Query for status reports in QStatus_Report table."""
    
    try:
        query = """
        SELECT
            [Name],
            [IsConfidential],
            [LastReportDate],
            [IsDeleted],
            [IsDirty],
            [IsViewTv]
        FROM [Qtasks].[dbo].[QStatus_Report] 
        WHERE [Name] LIKE ?
        ORDER BY [LastReportDate] DESC
        """
        
        cursor.execute(query, f"%{status_report_name}%")
        rows = cursor.fetchall()
        
        results = []
        for row in rows:
            results.append({
                "Name": row[0],
                "IsConfidential": row[1],
                "LastReportDate": str(row[2]) if row[2] else None,
                "IsDeleted": row[3],
                "IsDirty": row[4],
                "IsViewTv": row[5]
            })
        
        print(f"   📊 Status Reports found: {len(results)}")
        return results
        
    except Exception as e:
        print(f"   ❌ Status report query failed: {e}")
        return []

def query_alerts(cursor, task_name):
    """Query for alerts in QCheck_Alerts table."""
    
    try:
        query = """
        SELECT 
            [InstanceID],
            [DaysBefore],
            [AlertTime],
            [AlertType],
            [AlertText],
            [SentTime],
            [IsDeleted],
            [AlerteeGroupID]
        FROM [Qtasks].[dbo].[QCheck_Alerts] 
        WHERE [AlertText] LIKE ?
        ORDER BY [AlertTime] DESC
        """
        
        cursor.execute(query, f"%{task_name}%")
        rows = cursor.fetchall()
        
        results = []
        for row in rows:
            results.append({
                "InstanceID": row[0],
                "DaysBefore": row[1],
                "AlertTime": str(row[2]) if row[2] else None,
                "AlertType": row[3],
                "AlertText": row[4],
                "SentTime": str(row[5]) if row[5] else None,
                "IsDeleted": row[6],
                "AlerteeGroupID": row[7]
            })
        
        print(f"   🚨 Alerts found: {len(results)}")
        return results
        
    except Exception as e:
        print(f"   ❌ Alert query failed: {e}")
        return []

def generate_excel_report(verified_results):
    """Generate comprehensive Excel report with all results."""
    
    print("\n📊 Generating Excel report...")
    
    # Create output directory if it doesn't exist
    output_dir = Path(__file__).parent / "qa_results"
    output_dir.mkdir(exist_ok=True)
    
    # Generate timestamp for filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    excel_file = output_dir / f"qa_excel_prompts_report_{timestamp}.xlsx"
    
    try:
        # Create Excel writer
        with pd.ExcelWriter(excel_file, engine='openpyxl') as writer:
            
            # 1. Test Execution Summary
            create_test_summary_sheet(verified_results, writer)
            
            # 2. Detailed Test Results
            create_detailed_results_sheet(verified_results, writer)
            
            # 3. Database Verification Results
            create_database_verification_sheet(verified_results, writer)
            
            # 4. Stored Procedure Analysis
            create_stored_procedure_analysis_sheet(verified_results, writer)
        
        print(f"✅ Excel report generated successfully: {excel_file}")
        
    except Exception as e:
        print(f"❌ Failed to generate Excel report: {e}")

def create_test_summary_sheet(results, writer):
    """Create test execution summary sheet."""
    
    summary_data = []
    for result in results:
        summary_data.append({
            "Test Case ID": result["case_id"],
            "Description": result["description"],
            "Task Name": result["task_name"],
            "Status": "✅ SUCCESS" if result["success"] else "❌ FAILED",
            "Response Time (s)": f"{result['response_time']:.2f}" if result["response_time"] else "N/A",
            "Expected SPs": ", ".join(result["expected_sps"]),
            "Tasks Found": len(result["database_results"].get("tasks", [])),
            "Status Reports Found": len(result["database_results"].get("status_reports", [])),
            "Alerts Found": len(result["database_results"].get("alerts", []))
        })
    
    df = pd.DataFrame(summary_data)
    df.to_excel(writer, sheet_name="Test Summary", index=False)
    
    # Auto-adjust column widths
    worksheet = writer.sheets["Test Summary"]
    for column in worksheet.columns:
        max_length = 0
        column_letter = column[0].column_letter
        for cell in column:
            try:
                if len(str(cell.value)) > max_length:
                    max_length = len(str(cell.value))
            except:
                pass
        adjusted_width = min(max_length + 2, 50)
        worksheet.column_dimensions[column_letter].width = adjusted_width

def create_detailed_results_sheet(results, writer):
    """Create detailed test results sheet."""
    
    detailed_data = []
    for result in results:
        detailed_data.append({
            "Test Case ID": result["case_id"],
            "Description": result["description"],
            "Prompt": result["prompt"],
            "Expected SPs": ", ".join(result["expected_sps"]),
            "Success": result["success"],
            "Response Time (s)": f"{result['response_time']:.2f}" if result["response_time"] else "N/A",
            "Response Text": result["response_text"][:500] + "..." if result["response_text"] and len(result["response_text"]) > 500 else result["response_text"],
            "Error": result["error"] or "None"
        })
    
    df = pd.DataFrame(detailed_data)
    df.to_excel(writer, sheet_name="Detailed Results", index=False)
    
    # Auto-adjust column widths
    worksheet = writer.sheets["Detailed Results"]
    for column in worksheet.columns:
        max_length = 0
        column_letter = column[0].column_letter
        for cell in column:
            try:
                if len(str(cell.value)) > max_length:
                    max_length = len(str(cell.value))
            except:
                pass
        adjusted_width = min(max_length + 2, 50)
        worksheet.column_dimensions[column_letter].width = adjusted_width

def create_database_verification_sheet(results, writer):
    """Create database verification results sheet."""
    
    # Tasks
    tasks_data = []
    for result in results:
        for task in result["database_results"].get("tasks", []):
            tasks_data.append({
                "Test Case ID": result["case_id"],
                "Task Name": task["Name"],
                "IsDeleted": task["IsDeleted"],
                "Owner": task["Owner"],
                "Template": task["Template"],
                "CreateDate": task["CreateDate"]
            })
    
    if tasks_data:
        df_tasks = pd.DataFrame(tasks_data)
        df_tasks.to_excel(writer, sheet_name="Database Tasks", index=False)
    
    # Status Reports
    status_data = []
    for result in results:
        for status in result["database_results"].get("status_reports", []):
            status_data.append({
                "Test Case ID": result["case_id"],
                "Status Report Name": status["Name"],
                "IsConfidential": status["IsConfidential"],
                "LastReportDate": status["LastReportDate"],
                "IsDeleted": status["IsDeleted"],
                "IsDirty": status["IsDirty"],
                "IsViewTv": status["IsViewTv"]
            })
    
    if status_data:
        df_status = pd.DataFrame(status_data)
        df_status.to_excel(writer, sheet_name="Database Status Reports", index=False)
    
    # Alerts
    alerts_data = []
    for result in results:
        for alert in result["database_results"].get("alerts", []):
            alerts_data.append({
                "Test Case ID": result["case_id"],
                "InstanceID": alert["InstanceID"],
                "DaysBefore": alert["DaysBefore"],
                "AlertTime": alert["AlertTime"],
                "AlertType": alert["AlertType"],
                "AlertText": alert["AlertText"],
                "SentTime": alert["SentTime"],
                "IsDeleted": alert["IsDeleted"],
                "AlerteeGroupID": alert["AlerteeGroupID"]
            })
    
    if alerts_data:
        df_alerts = pd.DataFrame(alerts_data)
        df_alerts.to_excel(writer, sheet_name="Database Alerts", index=False)

def create_stored_procedure_analysis_sheet(results, writer):
    """Create stored procedure analysis sheet."""
    
    # Count stored procedure execution
    sp_counts = {
        "QCheck_CreateTaskThroughChatbot": {"expected": 0, "tasks_found": 0},
        "QStatus_AddReport": {"expected": 0, "status_reports_found": 0},
        "QCheck_AddAlert": {"expected": 0, "alerts_found": 0}
    }
    
    for result in results:
        for sp in result["expected_sps"]:
            if sp in sp_counts:
                sp_counts[sp]["expected"] += 1
        
        # Count actual database results
        sp_counts["QCheck_CreateTaskThroughChatbot"]["tasks_found"] += len(result["database_results"].get("tasks", []))
        sp_counts["QStatus_AddReport"]["status_reports_found"] += len(result["database_results"].get("status_reports", []))
        sp_counts["QCheck_AddAlert"]["alerts_found"] += len(result["database_results"].get("alerts", []))
    
    # Create analysis data
    analysis_data = []
    for sp_name, counts in sp_counts.items():
        if sp_name == "QCheck_CreateTaskThroughChatbot":
            actual_results = counts["tasks_found"]
        elif sp_name == "QStatus_AddReport":
            actual_results = counts["status_reports_found"]
        elif sp_name == "QCheck_AddAlert":
            actual_results = counts["alerts_found"]
        else:
            actual_results = 0
            
        success_rate = (actual_results / counts["expected"] * 100) if counts["expected"] > 0 else 0
        analysis_data.append({
            "Stored Procedure": sp_name,
            "Expected Calls": counts["expected"],
            "Actual Results Found": actual_results,
            "Success Rate (%)": f"{success_rate:.1f}%",
            "Status": "✅ WORKING" if success_rate > 0 else "❌ NOT WORKING"
        })
    
    df = pd.DataFrame(analysis_data)
    df.to_excel(writer, sheet_name="Stored Procedure Analysis", index=False)
    
    # Auto-adjust column widths
    worksheet = writer.sheets["Stored Procedure Analysis"]
    for column in worksheet.columns:
        max_length = 0
        column_letter = column[0].column_letter
        for cell in column:
            try:
                if len(str(cell.value)) > max_length:
                    max_length = len(str(cell.value))
            except:
                pass
        adjusted_width = min(max_length + 2, 50)
        worksheet.column_dimensions[column_letter].width = adjusted_width

if __name__ == "__main__":
    print("🚀 Starting QA Test Execution with Excel Prompts...")
    print("Make sure your chatbot server is running on localhost:8000")
    print("Make sure SQL Server is accessible")
    print()
    
    try:
        results = run_qa_tests_and_verify()
        print("\n🎯 QA Test Execution and Database Verification Complete!")
        print("Check the generated Excel file for comprehensive results.")
    except KeyboardInterrupt:
        print("\n⏹️  Test execution interrupted by user")
    except Exception as e:
        print(f"\n❌ Test execution failed: {e}")
        import traceback
        traceback.print_exc()
