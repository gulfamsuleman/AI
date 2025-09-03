"""
Configuration file for MCP Service
"""

# Vector similarity thresholds
SIMILARITY_THRESHOLD = 0.3  # Minimum similarity score to consider intent detected
RECOMMENDATION_THRESHOLD = 0.1  # Minimum similarity for recommendations

# TF-IDF vectorizer settings
TFIDF_CONFIG = {
    'max_features': 1000,
    'ngram_range': (1, 3),  # Unigrams, bigrams, and trigrams
    'stop_words': 'english',
    'min_df': 1,  # Minimum document frequency
    'max_df': 0.95,  # Maximum document frequency (ignore terms that appear in >95% of docs)
    'analyzer': 'word'
}

# Intent detection settings
INTENT_DETECTION_CONFIG = {
    'enable_fuzzy_matching': True,
    'enable_semantic_similarity': True,
    'max_intents_per_message': 3,
    'confidence_boost_for_exact_matches': 0.2
}

# Stored procedure mapping
STORED_PROCEDURE_MAPPING = {
    'task_creation': {
        'primary': 'QCheck_CreateTaskThroughChatbot',
        'validation': 'CHECK_GROUP_EXISTS',
        'lookup': 'GET_GROUP_ID_BY_NAME'
    },
    'alert_creation': {
        'primary': 'QCheck_AddAlert',
        'validation': 'CHECK_GROUP_EXISTS',
        'lookup': 'GET_GROUP_ID_BY_NAME'
    },
    'status_report_creation': {
        'primary': 'QStatus_AddReport',
        'validation': 'CHECK_GROUP_EXISTS',
        'lookup': 'GET_GROUP_ID_BY_NAME'
    }
}

# Parameter extraction patterns
PARAMETER_PATTERNS = {
    'task_name': [
        r'create\s+a?\s*task\s+["\']([^"\']+)["\']',
        r'task\s+["\']([^"\']+)["\']',
        r'["\']([^"\']+)["\']\s+task',
        r'create\s+["\']([^"\']+)["\']'
    ],
    'assignees': [
        r'assign\s+to\s+([A-Z][A-Za-z\s]+?)(?:\s|$|,|\.)',
        r'assigned\s+to\s+([A-Z][A-Za-z\s]+?)(?:\s|$|,|\.)',
        r'to\s+([A-Z][A-Za-z\s]+?)(?:\s|$|,|\.)'
    ],
    'due_date': [
        r'due\s+(?:at\s+)?(\d{1,2}(?::\d{2})?\s*(?:am|pm)?(?:\s+)?(?:tomorrow|today|next\s+week|next\s+month|next\s+year|[A-Za-z]+\s+\d{1,2}|in\s+\d+\s+days?))',
        r'due\s+(?:on\s+)?([A-Za-z]+\s+\d{1,2}|tomorrow|today|next\s+week|next\s+month)',
        r'(\d{1,2}(?::\d{2})?\s*(?:am|pm)?(?:\s+)?(?:tomorrow|today|next\s+week|next\s+month|next\s+year|[A-Za-z]+\s+\d{1,2}|in\s+\d+\s+days?))'
    ]
}

# Logging configuration
LOGGING_CONFIG = {
    'level': 'INFO',
    'format': '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    'enable_vector_debug': False,  # Set to True for detailed vector operations logging
    'enable_similarity_debug': False  # Set to True for detailed similarity calculation logging
}
