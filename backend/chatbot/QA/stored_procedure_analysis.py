#!/usr/bin/env python3
"""
Stored Procedure Execution Analysis for QA Test Cases

This script analyzes which stored procedures were called and executed successfully
for each prompt in the QA test cases.
"""

import pandas as pd
import re
from pathlib import Path

def analyze_stored_procedure_execution():
    """Analyze stored procedure execution for each test case."""
    
    print("🔍 Stored Procedure Execution Analysis")
    print("=" * 70)
    
    # File paths
    qa_dir = Path(__file__).parent
    test_cases_file = qa_dir / "QA_Test_Cases.xlsx"
    results_file = qa_dir / "qa_results" / "chatbot_qa_report.xlsx"
    
    try:
        # Load data
        test_cases_df = pd.read_excel(test_cases_file)
        results_df = pd.read_excel(results_file)
        
        print(f"✅ Loaded {len(test_cases_df)} test cases")
        print(f"✅ Loaded {len(results_df)} result entries")
        print()
        
        # Analyze each test case
        for i, (_, test_case) in enumerate(test_cases_df.iterrows()):
            analyze_single_test_case(i + 1, test_case, results_df.iloc[i] if i < len(results_df) else None)
        
        # Generate summary report
        generate_summary_report(test_cases_df, results_df)
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

def analyze_single_test_case(case_number, test_case, result):
    """Analyze a single test case and its stored procedure execution."""
    
    prompt = test_case['Prompt']
    expected_task_name = test_case.get('Expected Task Name', 'N/A')
    assignees = test_case.get('Assignees', 'N/A')
    controllers = test_case.get('Controllers', 'N/A')
    due_date = test_case.get('Due Date', 'N/A')
    special_notes = test_case.get('Special Notes', 'N/A')
    
    print(f"🧪 Test Case {case_number}")
    print(f"   Prompt: {prompt}")
    print(f"   Expected Task: {expected_task_name}")
    print(f"   Assignees: {assignees}")
    print(f"   Controllers: {controllers}")
    print(f"   Due Date: {due_date}")
    print(f"   Special Notes: {special_notes}")
    print("-" * 60)
    
    # Analyze expected stored procedures based on prompt
    expected_sps = analyze_expected_stored_procedures(prompt)
    print("📋 Expected Stored Procedures:")
    for sp, reason in expected_sps.items():
        print(f"   ✅ {sp}: {reason}")
    
    # Analyze actual execution results
    if result is not None:
        print("\n📊 Actual Execution Results:")
        print(f"   API Success: {result.get('API_Success', 'N/A')}")
        print(f"   Execution Time: {result.get('Execution_Time_Seconds', 'N/A')} seconds")
        print(f"   Instance ID: {result.get('Instance_ID', 'N/A')}")
        
        # Stored procedure execution status
        sp_status = {
            'Task Creation SP': result.get('Task_Creation_SP_Executed', False),
            'Alert SP': result.get('Alert_SP_Executed', False),
            'Status Report SP': result.get('Status_Report_SP_Executed', False),
            'Priority List SP': result.get('Priority_List_SP_Executed', False),
            'Confidential SP': result.get('Confidential_SP_Executed', False)
        }
        
        for sp_name, executed in sp_status.items():
            status = "✅ EXECUTED" if executed else "❌ NOT EXECUTED"
            print(f"   {sp_name}: {status}")
        
        # Validation scores
        sp_score = result.get('SP_Validation_Score', 'N/A')
        overall_score = result.get('Overall_Validation_Score', 'N/A')
        print(f"   SP Validation Score: {sp_score}")
        print(f"   Overall Validation Score: {overall_score}")
        
        # Errors and details
        errors = result.get('Errors', 'N/A')
        if errors and str(errors) != 'nan':
            print(f"   ❌ Errors: {errors}")
        
        validation_details = result.get('Validation_Details', 'N/A')
        if validation_details and str(validation_details) != 'nan':
            print(f"   📋 Validation Details: {validation_details}")
        
        # Compare expected vs actual
        print("\n🔍 Expected vs Actual Analysis:")
        compare_expected_vs_actual(expected_sps, sp_status)
        
    else:
        print("   ❌ No execution results found for this test case")
    
    print("\n" + "=" * 70)

def analyze_expected_stored_procedures(prompt):
    """Analyze which stored procedures should be called based on the prompt."""
    
    expected_sps = {}
    prompt_lower = prompt.lower()
    
    # Task Creation SP
    if any(word in prompt_lower for word in ['create', 'set up', 'schedule']):
        expected_sps['QCheck_CreateTaskThroughChatbot'] = 'Task creation detected'
    
    # Alert SP
    if any(word in prompt_lower for word in ['alert', 'reminder', 'notify']):
        expected_sps['QCheck_AddAlert'] = 'Alert/reminder functionality detected'
    
    # Status Report SP
    if any(word in prompt_lower for word in ['status report', 'include in', 'add to']):
        expected_sps['QStatus_AddReport'] = 'Status report inclusion detected'
    
    # Priority List SP
    if any(word in prompt_lower for word in ['high priority', 'priority', 'urgent']):
        expected_sps['Priority_List_SP'] = 'Priority handling detected'
    
    # Confidential SP
    if 'confidential' in prompt_lower:
        expected_sps['Confidential_SP'] = 'Confidential task detected'
    
    # Recurring task patterns
    if any(word in prompt_lower for word in ['every', 'recurring', 'weekly', 'monthly', 'quarterly']):
        expected_sps['QCheck_CreateTaskThroughChatbot'] = 'Recurring task creation detected'
    
    # Checklist items
    if 'checklist' in prompt_lower:
        expected_sps['QCheck_CreateTaskThroughChatbot'] = 'Task with checklist items detected'
    
    return expected_sps

def compare_expected_vs_actual(expected_sps, actual_status):
    """Compare expected stored procedures with actual execution status."""
    
    # Map expected SPs to actual status keys
    sp_mapping = {
        'QCheck_CreateTaskThroughChatbot': 'Task Creation SP',
        'QCheck_AddAlert': 'Alert SP',
        'QStatus_AddReport': 'Status Report SP',
        'Priority_List_SP': 'Priority List SP',
        'Confidential_SP': 'Confidential SP'
    }
    
    for expected_sp, reason in expected_sps.items():
        if expected_sp in sp_mapping:
            actual_key = sp_mapping[expected_sp]
            actual_executed = actual_status.get(actual_key, False)
            
            if actual_executed:
                print(f"   ✅ {expected_sp}: Expected and EXECUTED - {reason}")
            else:
                print(f"   ❌ {expected_sp}: Expected but NOT EXECUTED - {reason}")
        else:
            print(f"   ⚠️  {expected_sp}: Expected but no mapping found - {reason}")
    
    # Check for unexpected executions
    for sp_name, executed in actual_status.items():
        if executed and sp_name not in [sp_mapping.get(sp, '') for sp in expected_sps.keys()]:
            print(f"   🔍 {sp_name}: Unexpected execution")

def generate_summary_report(test_cases_df, results_df):
    """Generate a summary report of all test cases."""
    
    print("\n📊 SUMMARY REPORT")
    print("=" * 70)
    
    total_cases = len(test_cases_df)
    successful_api_calls = sum(1 for _, row in results_df.iterrows() if row.get('API_Success') == True)
    failed_api_calls = total_cases - successful_api_calls
    
    print(f"📈 Overall Statistics:")
    print(f"   Total Test Cases: {total_cases}")
    print(f"   Successful API Calls: {successful_api_calls}")
    print(f"   Failed API Calls: {failed_api_calls}")
    print(f"   Success Rate: {(successful_api_calls/total_cases)*100:.1f}%")
    
    # Stored procedure execution summary
    print(f"\n🔍 Stored Procedure Execution Summary:")
    sp_columns = ['Task_Creation_SP_Executed', 'Alert_SP_Executed', 'Status_Report_SP_Executed', 
                  'Priority_List_SP_Executed', 'Confidential_SP_Executed']
    
    for sp_col in sp_columns:
        if sp_col in results_df.columns:
            executed_count = sum(1 for _, row in results_df.iterrows() if row.get(sp_col) == True)
            sp_name = sp_col.replace('_', ' ').replace('SP', 'Stored Procedure')
            print(f"   {sp_name}: {executed_count}/{total_cases} ({executed_count/total_cases*100:.1f}%)")
    
    # Common issues
    print(f"\n⚠️  Common Issues:")
    error_patterns = {}
    for _, row in results_df.iterrows():
        errors = row.get('Errors', '')
        if errors and str(errors) != 'nan':
            error_text = str(errors).lower()
            if 'httpconnectionpool' in error_text:
                error_patterns['Connection Issues'] = error_patterns.get('Connection Issues', 0) + 1
            elif 'timeout' in error_text:
                error_patterns['Timeout Issues'] = error_patterns.get('Timeout Issues', 0) + 1
            else:
                error_patterns['Other Errors'] = error_patterns.get('Other Errors', 0) + 1
    
    for issue, count in error_patterns.items():
        print(f"   {issue}: {count} occurrences")
    
    # Recommendations
    print(f"\n💡 Recommendations:")
    if failed_api_calls > 0:
        print(f"   1. Investigate connection issues (localhost:8000)")
        print(f"   2. Check chatbot server status")
        print(f"   3. Verify stored procedure availability")
    else:
        print(f"   1. All API calls successful - good baseline")
        print(f"   2. Focus on stored procedure execution validation")
        print(f"   3. Check parameter extraction accuracy")
    
    print(f"\n   4. Review MCP service integration for better intent detection")
    print(f"   5. Validate stored procedure parameter mapping")

if __name__ == "__main__":
    analyze_stored_procedure_execution()
    
    print("\n🎯 Analysis Complete!")
    print("Check the detailed output above for each test case.")
    print("The summary report shows overall execution statistics.")
