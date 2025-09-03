#!/usr/bin/env python3
"""
QA Test Runner - Tests stored procedure execution with running chatbot

This script sends each QA test case to the running chatbot and monitors
which stored procedures actually get executed.
"""

import requests
import json
import time
from pathlib import Path

def test_qa_cases():
    """Test all QA cases against the running chatbot."""
    
    print("🧪 QA Test Runner - Stored Procedure Execution Test")
    print("=" * 70)
    
    # Test configuration
    base_url = "http://localhost:8000"
    chat_endpoint = "/api/chat/"
    
    print(f"🌐 Testing against: {base_url}{chat_endpoint}")
    print()
    
    # Test cases from the analysis
    test_cases = [
        {
            "id": 1,
            "prompt": "Create 'Review code' for Cory with checklist: Review module A, Review module B",
            "expected_sps": ["QCheck_CreateTaskThroughChatbot"],
            "description": "Review Code with Checklist"
        },
        {
            "id": 2,
            "prompt": "Set up 'Client presentation' for next Wednesday with Angad and Caroline, high priority",
            "expected_sps": ["QCheck_CreateTaskThroughChatbot", "Priority_List_SP"],
            "description": "High Priority Client Presentation"
        },
        {
            "id": 3,
            "prompt": "Recurring task 'Backup server' every Monday, include in IT status report",
            "expected_sps": ["QCheck_CreateTaskThroughChatbot", "QStatus_AddReport"],
            "description": "Recurring Backup Server with Status Report"
        },
        {
            "id": 4,
            "prompt": "Schedule 'Quarterly audit' every quarter, add to audit status report",
            "expected_sps": ["QCheck_CreateTaskThroughChatbot", "QStatus_AddReport"],
            "description": "Quarterly Audit with Status Report"
        },
        {
            "id": 5,
            "prompt": "Create confidential task 'Check legal docs' for Taylor, due 6/15",
            "expected_sps": ["QCheck_CreateTaskThroughChatbot", "Confidential_SP"],
            "description": "Confidential Legal Documents"
        },
        {
            "id": 6,
            "prompt": "Create a task 'Task 1: Tax deliverable' for Tax Reporting, controlled by Personal Assistant Tasks, due 2025-09-02, add to priority list",
            "expected_sps": ["QCheck_CreateTaskThroughChatbot", "QStatus_AddReport", "Priority_List_SP"],
            "description": "Tax Deliverable with Priority List"
        },
        {
            "id": 7,
            "prompt": "Create a task 'Task 2: Jesus deliverable' for Jesus Santos, controlled by WM Guys, due 2025-09-29, add to priority list",
            "expected_sps": ["QCheck_CreateTaskThroughChatbot", "QStatus_AddReport", "Priority_List_SP"],
            "description": "Jesus Deliverable with Priority List"
        },
        {
            "id": 8,
            "prompt": "Create a task 'Task 3: Lauryn deliverable' for Lauryn Lents, controlled by CLO, due 2025-09-10, add to priority list",
            "expected_sps": ["QCheck_CreateTaskThroughChatbot", "QStatus_AddReport", "Priority_List_SP"],
            "description": "Lauryn Deliverable with Priority List"
        },
        {
            "id": 9,
            "prompt": "Create a task 'Task 4: Workspace deliverable' for Workspace Requests, controlled by VPM Support, due 2025-09-28, add to priority list",
            "expected_sps": ["QCheck_CreateTaskThroughChatbot", "QStatus_AddReport", "Priority_List_SP"],
            "description": "Workspace Deliverable with Priority List"
        }
    ]
    
    # Test results storage
    test_results = []
    
    # Test each case
    for test_case in test_cases:
        result = test_single_case(base_url, chat_endpoint, test_case)
        test_results.append(result)
        
        # Wait between tests to avoid overwhelming the server
        if test_case["id"] < len(test_cases):
            print("⏳ Waiting 2 seconds before next test...")
            time.sleep(2)
    
    # Generate test report
    generate_test_report(test_results)

def test_single_case(base_url, chat_endpoint, test_case):
    """Test a single QA case against the chatbot."""
    
    case_id = test_case["id"]
    prompt = test_case["prompt"]
    expected_sps = test_case["expected_sps"]
    description = test_case["description"]
    
    print(f"🧪 Test Case {case_id}: {description}")
    print(f"   Prompt: {prompt}")
    print(f"   Expected SPs: {', '.join(expected_sps)}")
    print("-" * 60)
    
    # Prepare the request with correct API format
    payload = {
        "message": prompt,
        "user": "QA_Test_User",  # Changed from user_id to user
        "timezone": "UTC"  # Added timezone parameter
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
        result = analyze_response(case_id, response, expected_sps, response_time)
        
        print(f"📊 Response Status: {response.status_code}")
        print(f"📊 Response Time: {response_time:.2f} seconds")
        
        if result.get('success'):
            print(f"✅ Test Case {case_id} - SUCCESS")
            response_text = result.get('response_text', 'N/A')
            if len(response_text) > 100:
                print(f"   Response: {response_text[:100]}...")
            else:
                print(f"   Response: {response_text}")
        else:
            print(f"❌ Test Case {case_id} - FAILED")
            print(f"   Error: {result.get('error', 'N/A')}")
        
        # Check stored procedure execution
        response_text = result.get('response_text', '')
        if response_text and isinstance(response_text, str):
            if any(sp.lower() in response_text.lower() for sp in ['stored procedure', 'qcheck', 'qstatus', 'exec']):
                print(f"🔍 Stored Procedure Mentioned: Yes")
            else:
                print(f"🔍 Stored Procedure Mentioned: No")
        
    except requests.exceptions.ConnectionError:
        result = {
            "case_id": case_id,
            "success": False,
            "error": "Connection refused - server not running on localhost:8000",
            "response_time": None,
            "response_text": None
        }
        print(f"❌ Connection Error: Server not accessible on {base_url}")
        
    except requests.exceptions.Timeout:
        result = {
            "case_id": case_id,
            "success": False,
            "error": "Request timeout - server not responding",
            "response_time": None,
            "response_text": None
        }
        print(f"❌ Timeout Error: Server not responding")
        
    except Exception as e:
        result = {
            "case_id": case_id,
            "success": False,
            "error": f"Unexpected error: {str(e)}",
            "response_time": None,
            "response_text": None
        }
        print(f"❌ Unexpected Error: {str(e)}")
    
    print("=" * 70)
    return result

def analyze_response(case_id, response, expected_sps, response_time):
    """Analyze the chatbot response for stored procedure execution."""
    
    result = {
        "case_id": case_id,
        "success": False,
        "response_time": response_time,
        "response_text": None,
        "error": None
    }
    
    try:
        if response.status_code == 200:
            result["success"] = True
            result["response_text"] = response.text
            
            # Try to parse JSON response
            try:
                response_data = response.json()
                if isinstance(response_data, dict):
                    result["response_text"] = json.dumps(response_data, indent=2)
            except:
                pass
                
        else:
            result["error"] = f"HTTP {response.status_code}: {response.text}"
            
    except Exception as e:
        result["error"] = f"Response parsing error: {str(e)}"
    
    return result

def generate_test_report(test_results):
    """Generate a comprehensive test report."""
    
    print("\n📊 QA TEST EXECUTION REPORT")
    print("=" * 70)
    
    total_cases = len(test_results)
    successful_cases = sum(1 for result in test_results if result.get('success'))
    failed_cases = total_cases - successful_cases
    
    print(f"📈 Test Execution Summary:")
    print(f"   Total Test Cases: {total_cases}")
    print(f"   Successful Executions: {successful_cases}")
    print(f"   Failed Executions: {failed_cases}")
    print(f"   Success Rate: {(successful_cases/total_cases)*100:.1f}%")
    
    # Detailed results
    print(f"\n🔍 Detailed Results:")
    for result in test_results:
        case_id = result["case_id"]
        status = "✅ SUCCESS" if result.get('success') else "❌ FAILED"
        print(f"   Test Case {case_id}: {status}")
        
        if not result.get('success'):
            print(f"      Error: {result.get('error', 'N/A')}")
    
    # Recommendations
    print(f"\n💡 Recommendations:")
    if failed_cases > 0:
        print(f"   1. Check chatbot server status and connectivity")
        print(f"   2. Verify API endpoints are accessible")
        print(f"   3. Check server logs for errors")
        print(f"   4. Ensure database connections are working")
    else:
        print(f"   1. All tests successful - good baseline")
        print(f"   2. Monitor stored procedure execution in logs")
        print(f"   3. Validate parameter extraction accuracy")
    
    print(f"\n   5. Test MCP service integration for better intent detection")
    print(f"   6. Compare expected vs actual stored procedure calls")
    
    # Save results to file
    save_results_to_file(test_results)

def save_results_to_file(test_results):
    """Save test results to a JSON file."""
    
    output_file = Path(__file__).parent / "qa_test_results.json"
    
    try:
        with open(output_file, 'w') as f:
            json.dump(test_results, f, indent=2)
        print(f"\n💾 Test results saved to: {output_file}")
    except Exception as e:
        print(f"\n❌ Could not save results: {e}")

if __name__ == "__main__":
    print("🚀 Starting QA Test Execution...")
    print("Make sure your chatbot server is running on localhost:8000")
    print()
    
    try:
        test_qa_cases()
        print("\n🎯 QA Test Execution Complete!")
    except KeyboardInterrupt:
        print("\n⏹️  Test execution interrupted by user")
    except Exception as e:
        print(f"\n❌ Test execution failed: {e}")
        import traceback
        traceback.print_exc()
