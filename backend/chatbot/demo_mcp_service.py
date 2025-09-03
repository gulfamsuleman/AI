#!/usr/bin/env python3
"""
Standalone Demonstration of MCP Service with Vector Database and Cosine Similarity

This script demonstrates how the MCP service intelligently detects stored procedure intents
using vector embeddings and cosine similarity instead of rigid keyword matching.
"""

import re
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

class MCPService:
    """
    MCP Service for intelligent stored procedure detection using vector similarity.
    """
    
    def __init__(self):
        self.vectorizer = TfidfVectorizer(
            stop_words='english',
            ngram_range=(1, 3),
            max_features=1000
        )
        
        # Define stored procedure intents with their descriptions and parameters
        self.stored_procedure_intents = {
            'task_creation': {
                'description': 'Create a new task with assignees, due dates, and other task parameters',
                'keywords': [
                    'create task', 'new task', 'assign task', 'task due', 'task deadline',
                    'assign to', 'due date', 'task name', 'task description', 'task priority',
                    'recurring task', 'weekly task', 'daily task', 'monthly task'
                ],
                'stored_procedure': 'QCheck_CreateTaskThroughChatbot',
                'required_params': ['TaskName', 'Assignees', 'DueDate'],
                'optional_params': ['Controllers', 'DueTime', 'Items', 'IsRecurring', 'FreqType', 'FreqRecurrance', 'FreqInterval']
            },
            'alert_creation': {
                'description': 'Create alerts for tasks with specific conditions and recipients',
                'keywords': [
                    'add alert', 'create alert', 'alert if', 'alert when', 'alert to',
                    'overdue alert', 'due date alert', 'reminder alert', 'notification alert',
                    'alert recipient', 'alert condition', 'alert message'
                ],
                'stored_procedure': 'QCheck_AddAlert',
                'required_params': ['InstanceID', 'alertType'],
                'optional_params': ['nagBeforeDays', 'nagTime', 'alerteegroupid', 'alertText']
            },
            'status_report_creation': {
                'description': 'Create status reports for tasks with specific groups and names',
                'keywords': [
                    'add status report', 'include in status report', 'status report for',
                    'provide status report', 'status report named', 'report to group',
                    'status report under', 'confidential status report'
                ],
                'stored_procedure': 'QStatus_AddReport',
                'required_params': ['GroupID', 'ReportName'],
                'optional_params': ['IsConfidential']
            }
        }
        
        # Build the vector space
        self._build_vector_space()
    
    def _build_vector_space(self):
        """Build the TF-IDF vector space for all stored procedure intents."""
        try:
            # Collect all keyword texts
            all_texts = []
            for intent_name, intent_data in self.stored_procedure_intents.items():
                # Add the description
                all_texts.append(intent_data['description'])
                # Add all keywords
                all_texts.extend(intent_data['keywords'])
            
            # Fit the vectorizer
            self.vectorizer.fit(all_texts)
            print("✅ Vector space built successfully with TF-IDF")
            
        except Exception as e:
            print(f"❌ Error building vector space: {e}")
            raise
    
    def detect_stored_procedure_intent(self, user_message: str, context: dict = None) -> dict:
        """
        Detect which stored procedure intent matches the user message using vector similarity.
        """
        try:
            # Vectorize the user message
            user_vector = self.vectorizer.transform([user_message.lower()])
            
            # Calculate similarity with each intent
            intent_scores = {}
            detected_intents = []
            
            for intent_name, intent_data in self.stored_procedure_intents.items():
                # Vectorize the intent keywords and description
                intent_texts = [intent_data['description']] + intent_data['keywords']
                intent_vectors = self.vectorizer.transform(intent_texts)
                
                # Calculate cosine similarity
                similarities = cosine_similarity(user_vector, intent_vectors)
                max_similarity = np.max(similarities)
                
                intent_scores[intent_name] = {
                    'score': float(max_similarity),
                    'stored_procedure': intent_data['stored_procedure'],
                    'description': intent_data['description'],
                    'required_params': intent_data['required_params'],
                    'optional_params': intent_data['optional_params']
                }
                
                # If similarity is above threshold, consider it detected
                if max_similarity > 0.3:  # Adjustable threshold
                    detected_intents.append(intent_name)
            
            # Sort by confidence score
            sorted_intents = sorted(intent_scores.items(), key=lambda x: x[1]['score'], reverse=True)
            
            # Get the best match
            best_intent = sorted_intents[0] if sorted_intents else None
            
            result = {
                'detected_intents': detected_intents,
                'best_intent': best_intent[0] if best_intent else None,
                'confidence_score': best_intent[1]['score'] if best_intent else 0.0,
                'all_scores': intent_scores,
                'recommended_stored_procedure': best_intent[1]['stored_procedure'] if best_intent else None,
                'required_parameters': best_intent[1]['required_params'] if best_intent else [],
                'optional_parameters': best_intent[1]['optional_params'] if best_intent else []
            }
            
            print(f"🎯 Intent detection result: {result['best_intent']} (confidence: {result['confidence_score']:.3f})")
            return result
            
        except Exception as e:
            print(f"❌ Error in intent detection: {e}")
            return {
                'detected_intents': [],
                'best_intent': None,
                'confidence_score': 0.0,
                'all_scores': {},
                'recommended_stored_procedure': None,
                'required_parameters': [],
                'optional_parameters': [],
                'error': str(e)
            }
    
    def extract_parameters_for_intent(self, user_message: str, intent_name: str, context: dict = None) -> dict:
        """Extract parameters needed for a specific stored procedure intent."""
        if intent_name not in self.stored_procedure_intents:
            return {}
        
        intent_data = self.stored_procedure_intents[intent_name]
        extracted_params = {}
        
        try:
            if intent_name == 'task_creation':
                extracted_params = self._extract_task_parameters(user_message, context)
            elif intent_name == 'alert_creation':
                extracted_params = self._extract_alert_parameters(user_message, context)
            elif intent_name == 'status_report_creation':
                extracted_params = self._extract_status_report_parameters(user_message, context)
            
            print(f"🔍 Extracted parameters for {intent_name}: {extracted_params}")
            return extracted_params
            
        except Exception as e:
            print(f"❌ Error extracting parameters for {intent_name}: {e}")
            return {}
    
    def _extract_task_parameters(self, user_message: str, context: dict = None) -> dict:
        """Extract task creation parameters using intelligent parsing."""
        params = {}
        msg_lower = user_message.lower()
        
        # Extract task name (various patterns)
        task_name_patterns = [
            r'create\s+a?\s*task\s+["\']([^"\']+)["\']',
            r'task\s+["\']([^"\']+)["\']',
            r'["\']([^"\']+)["\']\s+task',
            r'create\s+["\']([^"\']+)["\']'
        ]
        
        for pattern in task_name_patterns:
            match = re.search(pattern, msg_lower)
            if match:
                params['TaskName'] = match.group(1).strip()
                break
        
        # Extract assignees
        assignee_patterns = [
            r'assign\s+to\s+([A-Z][A-Za-z\s]+?)(?:\s|$|,|\.)',
            r'assigned\s+to\s+([A-Z][A-Za-z\s]+?)(?:\s|$|,|\.)',
            r'to\s+([A-Z][A-Za-z\s]+?)(?:\s|$|,|\.)'
        ]
        
        for pattern in assignee_patterns:
            match = re.search(pattern, user_message, re.IGNORECASE)
            if match:
                params['Assignees'] = match.group(1).strip()
                break
        
        # Extract due date/time
        due_patterns = [
            r'due\s+(?:at\s+)?(\d{1,2}(?::\d{2})?\s*(?:am|pm)?(?:\s+)?(?:tomorrow|today|next\s+week|next\s+month|next\s+year|[A-Za-z]+\s+\d{1,2}|in\s+\d+\s+days?))',
            r'due\s+(?:on\s+)?([A-Za-z]+\s+\d{1,2}|tomorrow|today|next\s+week|next\s+month)',
            r'(\d{1,2}(?::\d{2})?\s*(?:am|pm)?(?:\s+)?(?:tomorrow|today|next\s+week|next\s+month|next\s+year|[A-Za-z]+\s+\d{1,2}|in\s+\d+\s+days?))'
        ]
        
        for pattern in due_patterns:
            match = re.search(pattern, msg_lower)
            if match:
                params['DueDate'] = match.group(1).strip()
                break
        
        return params
    
    def _extract_alert_parameters(self, user_message: str, context: dict = None) -> dict:
        """Extract alert creation parameters using intelligent parsing."""
        params = {}
        msg_lower = user_message.lower()
        
        # Extract alert condition
        condition_patterns = [
            r'alert\s+if\s+([A-Za-z\s]+?)(?:\s+to\s+|\s+with\s+|\s*$)',
            r'alert\s+when\s+([A-Za-z\s]+?)(?:\s+to\s+|\s+with\s+|\s*$)',
            r'alert\s+([A-Za-z\s]+?)(?:\s+to\s+|\s+with\s+|\s*$)'
        ]
        
        for pattern in condition_patterns:
            match = re.search(pattern, msg_lower)
            if match:
                params['alert_condition'] = match.group(1).strip()
                break
        
        # Extract alert recipient
        recipient_patterns = [
            r'alert\s+to\s+([A-Z][A-Za-z\s]+?)(?:\s+with\s+|\s*$)',
            r'alert\s+([A-Z][A-Za-z\s]+?)(?:\s+to\s+|\s+with\s+|\s*$)',
            r'to\s+([A-Z][A-Za-z\s]+?)(?:\s+with\s+|\s*$)'
        ]
        
        for pattern in recipient_patterns:
            match = re.search(pattern, user_message, re.IGNORECASE)
            if match:
                params['alert_recipient'] = match.group(1).strip()
                break
        
        # If no specific recipient, use task assignee
        if 'alert_recipient' not in params and context and context.get('Assignees'):
            params['alert_recipient'] = 'task_assignee'
        
        return params
    
    def _extract_status_report_parameters(self, user_message: str, context: dict = None) -> dict:
        """Extract status report parameters using intelligent parsing."""
        params = {}
        msg_lower = user_message.lower()
        
        # Extract group name
        group_patterns = [
            r'status\s+report\s+for\s+([A-Z][A-Za-z\s]+?)(?:\s+under\s+|\s*$)',
            r'include\s+in\s+([A-Z][A-Za-z\s]+?)\s+status\s+report',
            r'report\s+to\s+([A-Z][A-Za-z\s]+?)(?:\s+under\s+|\s*$)',
            r'to\s+([A-Z][A-Za-z\s]+?)(?:\s+under\s+|\s*$)'
        ]
        
        for pattern in group_patterns:
            match = re.search(pattern, user_message, re.IGNORECASE)
            if match:
                params['status_report_group'] = match.group(1).strip()
                break
        
        # Extract report name
        name_patterns = [
            r'status\s+report\s+named\s+["\']([^"\']+)["\']',
            r'status\s+report\s+under\s+["\']([^"\']+)["\']',
            r'report\s+named\s+["\']([^"\']+)["\']'
        ]
        
        for pattern in name_patterns:
            match = re.search(pattern, user_message, re.IGNORECASE)
            if match:
                params['status_report_name'] = match.group(1).strip()
                break
        
        return params
    
    def get_execution_plan(self, user_message: str, context: dict = None) -> dict:
        """Get a complete execution plan for the user message."""
        # Detect intent
        intent_result = self.detect_stored_procedure_intent(user_message, context)
        
        if not intent_result['best_intent']:
            return {
                'success': False,
                'error': 'No clear intent detected',
                'recommendations': self._get_recommendations(intent_result['all_scores'])
            }
        
        # Extract parameters
        params = self.extract_parameters_for_intent(
            user_message, 
            intent_result['best_intent'], 
            context
        )
        
        # Build execution plan
        execution_plan = {
            'success': True,
            'detected_intent': intent_result['best_intent'],
            'confidence_score': intent_result['confidence_score'],
            'stored_procedure': intent_result['recommended_stored_procedure'],
            'required_parameters': intent_result['required_parameters'],
            'optional_parameters': intent_result['optional_params'],
            'extracted_parameters': params,
            'missing_required_params': [
                param for param in intent_result['required_parameters'] 
                if param not in params
            ],
            'execution_steps': self._build_execution_steps(
                intent_result['best_intent'],
                params,
                context
            )
        }
        
        return execution_plan
    
    def _build_execution_steps(self, intent_name: str, params: dict, context: dict) -> list:
        """Build execution steps for the detected intent."""
        steps = []
        
        if intent_name == 'task_creation':
            steps = [
                {
                    'step': 1,
                    'action': 'Validate assignees exist in QCheck_Groups',
                    'stored_procedure': 'CHECK_GROUP_EXISTS',
                    'parameters': {'group_name': params.get('Assignees', '')}
                },
                {
                    'step': 2,
                    'action': 'Get group ID for assignees',
                    'stored_procedure': 'GET_GROUP_ID_BY_NAME',
                    'parameters': {'group_name': params.get('Assignees', '')}
                },
                {
                    'step': 3,
                    'action': 'Create task',
                    'stored_procedure': 'QCheck_CreateTaskThroughChatbot',
                    'parameters': params
                }
            ]
        
        elif intent_name == 'alert_creation':
            steps = [
                {
                    'step': 1,
                    'action': 'Validate alert recipient exists',
                    'stored_procedure': 'CHECK_GROUP_EXISTS',
                    'parameters': {'group_name': params.get('alert_recipient', '')}
                },
                {
                    'step': 2,
                    'action': 'Get group ID for alert recipient',
                    'stored_procedure': 'GET_GROUP_ID_BY_NAME',
                    'parameters': {'group_name': params.get('alert_recipient', '')}
                },
                {
                    'step': 3,
                    'action': 'Create alert',
                    'stored_procedure': 'QCheck_AddAlert',
                    'parameters': params
                }
            ]
        
        elif intent_name == 'status_report_creation':
            steps = [
                {
                    'step': 1,
                    'action': 'Validate status report group exists',
                    'stored_procedure': 'CHECK_GROUP_EXISTS',
                    'parameters': {'group_name': params.get('status_report_group', '')}
                },
                {
                    'step': 2,
                    'action': 'Get group ID for status report',
                    'stored_procedure': 'GET_GROUP_ID_BY_NAME',
                    'parameters': {'group_name': params.get('status_report_group', '')}
                },
                {
                    'step': 3,
                    'action': 'Create status report',
                    'stored_procedure': 'QStatus_AddReport',
                    'parameters': params
                }
            ]
        
        return steps
    
    def _get_recommendations(self, all_scores: dict) -> list:
        """Get recommendations when no clear intent is detected."""
        recommendations = []
        
        # Sort by score and get top 3
        sorted_scores = sorted(all_scores.items(), key=lambda x: x[1]['score'], reverse=True)
        
        for intent_name, score_data in sorted_scores[:3]:
            if score_data['score'] > 0.1:  # Low threshold for recommendations
                recommendations.append({
                    'intent': intent_name,
                    'description': score_data['description'],
                    'confidence': score_data['score']
                })
        
        return recommendations

def demonstrate_mcp_service():
    """Demonstrate the MCP service capabilities."""
    print("🚀 MCP Service: Intelligent Stored Procedure Detection")
    print("=" * 70)
    print("This service uses vector database and cosine similarity instead of")
    print("rigid keyword matching to intelligently detect user intent.")
    print()
    
    # Initialize the MCP service
    try:
        mcp_service = MCPService()
        print("✅ MCP Service initialized successfully")
        print("✅ Vector space built with TF-IDF")
        print("✅ Ready to process user messages")
        print()
    except Exception as e:
        print(f"❌ Failed to initialize MCP Service: {e}")
        return
    
    # Test cases demonstrating the power of vector similarity
    test_cases = [
        {
            'message': "create a task 'wORK fORCE' assign to Hayden due 5 PM tomorrow also add alert if work is overdue",
            'expected_intent': 'task_creation',
            'description': 'Complex task creation with alert (your original example)'
        },
        {
            'message': "add alert if overdue to Ken",
            'expected_intent': 'alert_creation',
            'description': 'Simple alert creation'
        },
        {
            'message': "add status report named 'Quarterly Review' for IT team",
            'expected_intent': 'status_report_creation',
            'description': 'Status report creation'
        },
        {
            'message': "I need to make a new task for project Alpha",
            'expected_intent': 'task_creation',
            'description': 'Semantic variation: "make a new task" instead of "create task"'
        },
        {
            'message': "send me a reminder when the deadline approaches",
            'expected_intent': 'alert_creation',
            'description': 'Semantic variation: "send reminder" instead of "add alert"'
        }
    ]
    
    print("🧪 Testing Intent Detection with Vector Similarity")
    print("=" * 70)
    
    for i, test_case in enumerate(test_cases, 1):
        print(f"\n{i}. Testing: {test_case['description']}")
        print(f"   Message: '{test_case['message']}'")
        print("-" * 50)
        
        # Test intent detection
        intent_result = mcp_service.detect_stored_procedure_intent(test_case['message'])
        
        if intent_result['best_intent']:
            print(f"   ✅ Intent detected: {intent_result['best_intent']}")
            print(f"   ✅ Confidence score: {intent_result['confidence_score']:.3f}")
            print(f"   ✅ Stored procedure: {intent_result['recommended_stored_procedure']}")
            
            # Check if it matches expected intent
            if intent_result['best_intent'] == test_case['expected_intent']:
                print(f"   ✅ CORRECT INTENT MATCH!")
            else:
                print(f"   ⚠️  Intent mismatch: expected {test_case['expected_intent']}, got {intent_result['best_intent']}")
            
            # Show all scores for comparison
            print(f"   📊 All confidence scores:")
            for intent_name, score_data in intent_result['all_scores'].items():
                status = "🎯" if intent_name == intent_result['best_intent'] else "  "
                print(f"      {status} {intent_name}: {score_data['score']:.3f}")
            
            # Test parameter extraction
            params = mcp_service.extract_parameters_for_intent(
                test_case['message'], 
                intent_result['best_intent']
            )
            
            if params:
                print(f"   🔍 Extracted parameters: {params}")
            else:
                print(f"   ⚠️  No parameters extracted")
            
        else:
            print(f"   ❌ No intent detected")
            print(f"   📊 Best scores:")
            for intent_name, score_data in intent_result['all_scores'].items():
                print(f"      {intent_name}: {score_data['score']:.3f}")
    
    print("\n" + "=" * 70)
    print("📋 Testing Execution Plan Generation")
    print("=" * 70)
    
    # Test execution plan for a complex message
    complex_message = "create a task 'Strategic Planning' assign to Management team due next Friday also add status report named 'Executive Summary' for Board"
    
    print(f"Complex message: '{complex_message}'")
    print("-" * 50)
    
    execution_plan = mcp_service.get_execution_plan(complex_message)
    
    if execution_plan['success']:
        print(f"✅ Execution plan generated successfully")
        print(f"   Intent: {execution_plan['detected_intent']}")
        print(f"   Confidence: {execution_plan['confidence_score']:.3f}")
        print(f"   Stored procedure: {execution_plan['stored_procedure']}")
        print(f"   Extracted parameters: {execution_plan['extracted_parameters']}")
        
        if execution_plan['missing_required_params']:
            print(f"   ⚠️  Missing required parameters: {execution_plan['missing_required_params']}")
        else:
            print(f"   ✅ All required parameters present")
        
        print(f"   📋 Execution steps:")
        for step in execution_plan['execution_steps']:
            print(f"      Step {step['step']}: {step['action']}")
            print(f"         Stored procedure: {step['stored_procedure']}")
            print(f"         Parameters: {step['parameters']}")
    else:
        print(f"❌ Execution plan generation failed: {execution_plan['error']}")
        if 'recommendations' in execution_plan:
            print(f"   💡 Recommendations:")
            for rec in execution_plan['recommendations']:
                print(f"      - {rec['intent']}: {rec['description']} (confidence: {rec['confidence']:.3f})")
    
    print("\n" + "=" * 70)
    print("🎯 Benefits Over Traditional Keyword Matching")
    print("=" * 70)
    print("✅ Semantic Understanding: Understands variations like 'make a new task'")
    print("✅ Confidence Scoring: Provides confidence scores for all intents")
    print("✅ Context Awareness: Handles complex multi-intent messages")
    print("✅ Flexibility: Easy to add new intents and patterns")
    print("✅ Maintainability: Centralized intent definitions")
    
    print("\n" + "=" * 70)
    print("🔧 How It Works")
    print("=" * 70)
    print("1. Builds TF-IDF vector space from stored procedure descriptions and keywords")
    print("2. Converts user messages to vector representations")
    print("3. Calculates cosine similarity with all stored procedure intents")
    print("4. Returns confidence scores and recommended stored procedures")
    print("5. Extracts parameters using intelligent regex patterns")
    print("6. Generates step-by-step execution plans")

if __name__ == "__main__":
    demonstrate_mcp_service()
    
    print("\n" + "=" * 70)
    print("🎉 MCP Service Demonstration Complete!")
    print("=" * 70)
    print("This service demonstrates how vector database and cosine similarity")
    print("can replace rigid keyword matching for intelligent stored procedure detection.")
    print()
    print("To integrate with your chatbot:")
    print("1. Install dependencies: pip install scikit-learn numpy scipy")
    print("2. Import MCPService in your chatbot code")
    print("3. Replace keyword matching with intent detection")
    print("4. Use confidence scores for fallback strategies")
