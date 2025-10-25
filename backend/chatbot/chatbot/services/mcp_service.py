"""
MCP (Model Context Protocol) Service for Intelligent Stored Procedure Detection

This service uses vector embeddings and cosine similarity to intelligently determine
which stored procedures to execute based on user intent, rather than rigid keyword matching.
"""

import logging
import numpy as np
from typing import Dict, List, Tuple, Optional, Any
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import json
import re

logger = logging.getLogger(__name__)

class MCPService:
    """
    MCP Service for intelligent stored procedure detection using vector similarity.
    """
    
    @staticmethod
    def _extract_individual_names_from_sentence(sentence: str) -> List[str]:
        """
        Extract individual names from a sentence, filtering out common words.
        
        Args:
            sentence: Input sentence like "Sameer the controller being Ken"
            
        Returns:
            List of potential names like ["Sameer", "Ken"]
        """
        if not sentence or not sentence.strip():
            return []
        
        # Common words to filter out
        filter_words = {
            'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 
            'of', 'with', 'by', 'from', 'up', 'about', 'into', 'through', 'during',
            'before', 'after', 'above', 'below', 'between', 'among', 'under', 'over',
            'controller', 'being', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
            'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should',
            'may', 'might', 'must', 'can', 'shall', 'this', 'that', 'these', 'those'
        }
        
        # Split sentence into words and filter
        words = sentence.split()
        potential_names = []
        
        for word in words:
            # Clean the word (remove punctuation)
            clean_word = re.sub(r'[^\w]', '', word)
            
            # Skip if it's a common word or too short
            if (clean_word.lower() in filter_words or 
                len(clean_word) < 2 or 
                clean_word.isdigit()):
                continue
                
            # Check if it looks like a name (starts with capital letter)
            if clean_word and clean_word[0].isupper():
                potential_names.append(clean_word)
        
        logger.info(f"Extracted potential names from '{sentence}': {potential_names}")
        return potential_names
    
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
                    'alert recipient', 'alert condition', 'alert message',
                    'overdue alert to', 'alert to', 'alert for', 'send alert', 'notify',
                    'remind', 'reminder', 'warning', 'notification'
                ],
                'stored_procedure': 'QCheck2_AddAlert',
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
    
    def detect_stored_procedure_intent(self, user_message: str, context: Dict[str, Any] = None) -> Dict[str, Any]:
        """
        Detect which stored procedure intent matches the user message using vector similarity.
        
        Args:
            user_message: The user's input message
            context: Additional context (e.g., current task parameters)
            
        Returns:
            Dictionary containing detected intent and confidence scores
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
            
            logger.info(f"Intent detection result: {result['best_intent']} (confidence: {result['confidence_score']:.3f})")
            return result
            
        except Exception as e:
            logger.error(f"Error in intent detection: {e}")
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
            logger.info("Vector space built successfully with TF-IDF")
            
        except Exception as e:
            logger.error(f"Error building vector space: {e}")
            raise
    
    def extract_parameters_for_intent(self, user_message: str, intent_name: str, context: Dict[str, Any] = None) -> Dict[str, Any]:
        """
        Extract parameters needed for a specific stored procedure intent.
        
        Args:
            user_message: The user's input message
            intent_name: The detected intent name
            context: Additional context from previous processing
            
        Returns:
            Dictionary containing extracted parameters
        """
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
            
            logger.info(f"Extracted parameters for {intent_name}: {extracted_params}")
            return extracted_params
            
        except Exception as e:
            logger.error(f"Error extracting parameters for {intent_name}: {e}")
            return {}
    
    def _extract_task_parameters(self, user_message: str, context: Dict[str, Any] = None) -> Dict[str, Any]:
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
    
    def _extract_alert_parameters(self, user_message: str, context: Dict[str, Any] = None) -> Dict[str, Any]:
        """Extract alert creation parameters using intelligent parsing."""
        params = {}
        msg_lower = user_message.lower()
        
        # Enhanced alert condition detection
        condition_patterns = [
            r'alert\s+if\s+([A-Za-z\s]+?)(?:\s+to\s+|\s+with\s+|\s*$)',
            r'alert\s+when\s+([A-Za-z\s]+?)(?:\s+to\s+|\s+with\s+|\s*$)',
            r'alert\s+([A-Za-z\s]+?)(?:\s+to\s+|\s+with\s+|\s*$)',
            r'overdue\s+alert\s+to\s+([A-Z][A-Za-z\s]+?)(?:\s+with\s+|\s*$)',  # Your pattern
            r'alert\s+to\s+([A-Z][A-Za-z\s]+?)(?:\s+with\s+|\s*$)'  # General alert to
        ]
        
        # First, try to extract recipient from specific patterns
        recipient_patterns = [
            r'alert\s+to\s+([A-Z][A-Za-z\s]+?)(?:\s+in\s+case\s+|\s+with\s+|\s*$)',  # "alert to Ken in case work is overdue"
            r'overdue\s+alert\s+to\s+([A-Z][A-Za-z\s]+?)(?:\s+with\s+|\s+in\s+case\s+|\s*$)',  # "overdue alert to Credit Research"
            r'alert\s+for\s+([A-Z][A-Za-z\s]+?)(?:\s+with\s+|\s+in\s+case\s+|\s*$)',  # "alert for Credit Research"
            r'alert\s+([A-Z][A-Za-z\s]+?)(?:\s+to\s+|\s+with\s+|\s+in\s+case\s+|\s*$)',  # "alert Credit Research"
            r'to\s+([A-Z][A-Za-z\s]+?)(?:\s+with\s+|\s+in\s+case\s+|\s*$)'  # "to Credit Research"
        ]
        
        for pattern in recipient_patterns:
            match = re.search(pattern, user_message, re.IGNORECASE)
            if match:
                raw_recipient = match.group(1).strip()
                
                # Extract individual names from the sentence
                potential_names = self._extract_individual_names_from_sentence(raw_recipient)
                
                # Use the first extracted name as the recipient, or fall back to raw recipient
                if potential_names:
                    params['alert_recipient'] = potential_names[0]  # Use first name found
                    logger.info(f"Extracted individual name '{params['alert_recipient']}' from sentence '{raw_recipient}'")
                else:
                    params['alert_recipient'] = raw_recipient
                    logger.info(f"Could not extract individual names from '{raw_recipient}', using as-is")
                
                # If we found a recipient, set default condition
                if 'overdue' in pattern.lower():
                    params['alert_condition'] = 'overdue'
                else:
                    params['alert_condition'] = 'overdue'  # Default condition
                break
        
        # If no recipient found, try to extract condition
        if 'alert_recipient' not in params:
            for pattern in condition_patterns:
                match = re.search(pattern, msg_lower)
                if match:
                    params['alert_condition'] = match.group(1).strip()
                break
        
        # If no specific recipient, use task assignee
        if 'alert_recipient' not in params and context and context.get('Assignees'):
            params['alert_recipient'] = 'task_assignee'
        
        return params
    
    def _extract_status_report_parameters(self, user_message: str, context: Dict[str, Any] = None) -> Dict[str, Any]:
        """Extract status report parameters using intelligent parsing."""
        params = {}
        msg_lower = user_message.lower()
        
        # Extract group name with more flexible patterns
        group_patterns = [
            r'status\s+report\s+for\s+([A-Z][A-Za-z\s]+?)(?:\s+under\s+|\s*$)',
            r'include\s+in\s+([A-Z][A-Za-z\s]+?)\s+status\s+report',
            r'report\s+to\s+([A-Z][A-Za-z\s]+?)(?:\s+under\s+|\s*$)',
            r'to\s+([A-Z][A-Za-z\s]+?)(?:\s+under\s+|\s*$)',
            r'status\s+report\s+under\s+([A-Z][A-Za-z\s]+?)(?:\s*$)',
            r'status\s+report\s+([A-Z][A-Za-z\s]+?)(?:\s*$)'
        ]
        
        for pattern in group_patterns:
            match = re.search(pattern, user_message, re.IGNORECASE)
            if match:
                params['status_report_group'] = match.group(1).strip()
                break
        
        # If no specific group found, try to infer from context or use default
        if 'status_report_group' not in params:
            if context and context.get('Assignees'):
                # Use the task assignee's group as default
                params['status_report_group'] = context.get('Assignees')
                logger.info(f"No status report group specified, using task assignee: {params['status_report_group']}")
            elif context and context.get('MainController'):
                # Use the main controller as default
                params['status_report_group'] = context.get('MainController')
                logger.info(f"No status report group specified, using main controller: {params['status_report_group']}")
            else:
                # Set a default group that should exist in the system
                params['status_report_group'] = 'General'
                logger.info("No status report group specified, using default group: General")
        
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
        
        # If no specific name, generate a default one based on task
        if 'status_report_name' not in params and context and context.get('TaskName'):
            task_name = context.get('TaskName')
            params['status_report_name'] = f"Status Report - {task_name}"
            logger.info(f"Generated default status report name: {params['status_report_name']}")
        
        return params
    
    def get_execution_plan(self, user_message: str, context: Dict[str, Any] = None) -> Dict[str, Any]:
        """
        Get a complete execution plan for the user message.
        
        Args:
            user_message: The user's input message
            context: Additional context
            
        Returns:
            Dictionary containing execution plan with stored procedures and parameters
        """
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
            'optional_parameters': intent_result['optional_parameters'],
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
    
    def _build_execution_steps(self, intent_name: str, params: Dict[str, Any], context: Dict[str, Any]) -> List[Dict[str, Any]]:
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
                    'stored_procedure': 'QCheck2_AddAlert',
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
    
    def _get_recommendations(self, all_scores: Dict[str, Any]) -> List[str]:
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
