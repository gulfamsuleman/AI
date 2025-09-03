#!/usr/bin/env python3
"""
Simple MCP Service Demo
"""

import re
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

class MCPService:
    def __init__(self):
        self.vectorizer = TfidfVectorizer(
            stop_words='english',
            ngram_range=(1, 3),
            max_features=1000
        )
        
        self.stored_procedure_intents = {
            'task_creation': {
                'description': 'Create a new task with assignees, due dates, and other task parameters',
                'keywords': [
                    'create task', 'new task', 'assign task', 'task due', 'task deadline',
                    'assign to', 'due date', 'task name', 'task description', 'task priority',
                    'recurring task', 'weekly task', 'daily task', 'monthly task'
                ],
                'stored_procedure': 'QCheck_CreateTaskThroughChatbot',
                'required_params': ['TaskName', 'Assignees', 'DueDate']
            },
            'alert_creation': {
                'description': 'Create alerts for tasks with specific conditions and recipients',
                'keywords': [
                    'add alert', 'create alert', 'alert if', 'alert when', 'alert to',
                    'overdue alert', 'due date alert', 'reminder alert', 'notification alert',
                    'alert recipient', 'alert condition', 'alert message'
                ],
                'stored_procedure': 'QCheck_AddAlert',
                'required_params': ['InstanceID', 'alertType']
            },
            'status_report_creation': {
                'description': 'Create status reports for tasks with specific groups and names',
                'keywords': [
                    'add status report', 'include in status report', 'status report for',
                    'provide status report', 'status report named', 'report to group',
                    'status report under', 'confidential status report'
                ],
                'stored_procedure': 'QStatus_AddReport',
                'required_params': ['GroupID', 'ReportName']
            }
        }
        
        self._build_vector_space()
    
    def _build_vector_space(self):
        all_texts = []
        for intent_name, intent_data in self.stored_procedure_intents.items():
            all_texts.append(intent_data['description'])
            all_texts.extend(intent_data['keywords'])
        
        self.vectorizer.fit(all_texts)
        print("✅ Vector space built successfully with TF-IDF")
    
    def detect_stored_procedure_intent(self, user_message: str) -> dict:
        try:
            user_vector = self.vectorizer.transform([user_message.lower()])
            
            intent_scores = {}
            detected_intents = []
            
            for intent_name, intent_data in self.stored_procedure_intents.items():
                intent_texts = [intent_data['description']] + intent_data['keywords']
                intent_vectors = self.vectorizer.transform(intent_texts)
                
                similarities = cosine_similarity(user_vector, intent_vectors)
                max_similarity = np.max(similarities)
                
                intent_scores[intent_name] = {
                    'score': float(max_similarity),
                    'stored_procedure': intent_data['stored_procedure'],
                    'description': intent_data['description'],
                    'required_params': intent_data['required_params']
                }
                
                if max_similarity > 0.3:
                    detected_intents.append(intent_name)
            
            sorted_intents = sorted(intent_scores.items(), key=lambda x: x[1]['score'], reverse=True)
            best_intent = sorted_intents[0] if sorted_intents else None
            
            result = {
                'detected_intents': detected_intents,
                'best_intent': best_intent[0] if best_intent else None,
                'confidence_score': best_intent[1]['score'] if best_intent else 0.0,
                'all_scores': intent_scores,
                'recommended_stored_procedure': best_intent[1]['stored_procedure'] if best_intent else None,
                'required_parameters': best_intent[1]['required_params'] if best_intent else []
            }
            
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
                'error': str(e)
            }

def main():
    print("🚀 MCP Service: Intelligent Stored Procedure Detection")
    print("=" * 60)
    
    try:
        mcp_service = MCPService()
        
        # Test the original user message
        test_message = "create a task 'wORK fORCE' assign to Hayden due 5 PM tomorrow also add alert if work is overdue"
        
        print(f"\n🧪 Testing: {test_message}")
        print("-" * 50)
        
        intent_result = mcp_service.detect_stored_procedure_intent(test_message)
        
        if intent_result['best_intent']:
            print(f"✅ Intent detected: {intent_result['best_intent']}")
            print(f"✅ Confidence score: {intent_result['confidence_score']:.3f}")
            print(f"✅ Stored procedure: {intent_result['recommended_stored_procedure']}")
            
            print(f"\n📊 All confidence scores:")
            for intent_name, score_data in intent_result['all_scores'].items():
                status = "🎯" if intent_name == intent_result['best_intent'] else "  "
                print(f"   {status} {intent_name}: {score_data['score']:.3f}")
            
            print(f"\n📋 Required parameters: {intent_result['required_parameters']}")
            
        else:
            print("❌ No intent detected")
        
        # Test semantic variations
        print(f"\n🧪 Testing semantic variations:")
        variations = [
            "I need to make a new task for project Alpha",
            "send me a reminder when the deadline approaches",
            "add status report named 'Quarterly Review' for IT team"
        ]
        
        for i, variation in enumerate(variations, 1):
            print(f"\n{i}. '{variation}'")
            result = mcp_service.detect_stored_procedure_intent(variation)
            if result['best_intent']:
                print(f"   ✅ Detected: {result['best_intent']} (confidence: {result['confidence_score']:.3f})")
            else:
                print(f"   ❌ No intent detected")
        
    except Exception as e:
        print(f"❌ Failed to run demo: {e}")

if __name__ == "__main__":
    main()
