# MCP Service: Intelligent Stored Procedure Detection

## Overview

The MCP (Model Context Protocol) Service replaces rigid keyword matching with intelligent vector database and cosine similarity techniques to determine which stored procedures to execute based on user intent.

## 🚀 Key Features

- **Vector Database**: Uses TF-IDF vectorization for semantic understanding
- **Cosine Similarity**: Intelligent matching based on semantic similarity, not exact keywords
- **Intent Detection**: Automatically detects user intent (task creation, alerts, status reports)
- **Parameter Extraction**: Smart extraction of required parameters
- **Execution Planning**: Generates step-by-step execution plans
- **Confidence Scoring**: Provides confidence scores for all detected intents

## 🔧 How It Works

### 1. Vector Space Construction
- Builds TF-IDF vector space from stored procedure descriptions and keywords
- Supports n-grams (unigrams, bigrams, trigrams) for better context understanding
- Automatically handles stop words and feature selection

### 2. Intent Detection
- Converts user message to vector representation
- Calculates cosine similarity with all stored procedure intents
- Returns confidence scores and recommended stored procedures

### 3. Parameter Extraction
- Uses intelligent regex patterns to extract parameters
- Context-aware parameter resolution (e.g., task assignee for alerts)
- Handles various natural language patterns

### 4. Execution Planning
- Generates step-by-step execution plans
- Includes validation and lookup steps
- Provides missing parameter analysis

## 📋 Supported Intents

### Task Creation
- **Description**: Create new tasks with assignees, due dates, and parameters
- **Keywords**: "create task", "new task", "assign task", "task due", "recurring task"
- **Stored Procedure**: `QCheck_CreateTaskThroughChatbot`
- **Required Parameters**: TaskName, Assignees, DueDate

### Alert Creation
- **Description**: Create alerts with conditions and recipients
- **Keywords**: "add alert", "create alert", "alert if", "overdue alert", "reminder"
- **Stored Procedure**: `QCheck_AddAlert`
- **Required Parameters**: InstanceID, alertType

### Status Report Creation
- **Description**: Create status reports for specific groups
- **Keywords**: "add status report", "include in status report", "status report for"
- **Stored Procedure**: `QStatus_AddReport`
- **Required Parameters**: GroupID, ReportName

## 🛠️ Installation

### 1. Install Dependencies
```bash
pip install -r requirements_mcp.txt
```

### 2. Core Dependencies
- `scikit-learn>=1.3.0` - For TF-IDF vectorization and cosine similarity
- `numpy>=1.21.0` - For numerical operations
- `scipy>=1.7.0` - For scientific computing

### 3. Optional Dependencies
- `faiss-cpu>=1.7.0` - For advanced vector similarity search
- `sentence-transformers>=2.2.0` - For advanced embeddings

## 📖 Usage Examples

### Basic Intent Detection
```python
from chatbot.services.mcp_service import MCPService

# Initialize the service
mcp_service = MCPService()

# Detect intent
user_message = "create a task 'Project Alpha' assign to John due tomorrow"
intent_result = mcp_service.detect_stored_procedure_intent(user_message)

print(f"Detected intent: {intent_result['best_intent']}")
print(f"Confidence: {intent_result['confidence_score']:.3f}")
print(f"Stored procedure: {intent_result['recommended_stored_procedure']}")
```

### Parameter Extraction
```python
# Extract parameters for the detected intent
params = mcp_service.extract_parameters_for_intent(
    user_message, 
    intent_result['best_intent']
)

print(f"Extracted parameters: {params}")
# Output: {'TaskName': 'Project Alpha', 'Assignees': 'John', 'DueDate': 'tomorrow'}
```

### Complete Execution Plan
```python
# Get complete execution plan
execution_plan = mcp_service.get_execution_plan(user_message)

if execution_plan['success']:
    print(f"Intent: {execution_plan['detected_intent']}")
    print(f"Stored procedure: {execution_plan['stored_procedure']}")
    print(f"Parameters: {execution_plan['extracted_parameters']}")
    print(f"Execution steps: {execution_plan['execution_steps']}")
```

## 🔍 Advanced Configuration

### Vector Similarity Thresholds
```python
# In mcp_config.py
SIMILARITY_THRESHOLD = 0.3  # Minimum similarity for intent detection
RECOMMENDATION_THRESHOLD = 0.1  # Minimum similarity for recommendations
```

### TF-IDF Settings
```python
TFIDF_CONFIG = {
    'max_features': 1000,
    'ngram_range': (1, 3),  # Unigrams, bigrams, trigrams
    'stop_words': 'english',
    'min_df': 1,
    'max_df': 0.95
}
```

### Custom Intent Addition
```python
# Add new stored procedure intent
mcp_service.stored_procedure_intents['custom_operation'] = {
    'description': 'Custom operation description',
    'keywords': ['custom', 'operation', 'specific', 'action'],
    'stored_procedure': 'CustomStoredProcedure',
    'required_params': ['param1', 'param2'],
    'optional_params': ['param3']
}

# Rebuild vector space
mcp_service._build_vector_space()
```

## 📊 Performance and Scalability

### Vector Operations
- **TF-IDF Vectorization**: O(n*m) where n = number of documents, m = vocabulary size
- **Cosine Similarity**: O(d) where d = vector dimensionality
- **Memory Usage**: Approximately 1-5 MB for typical intent sets

### Optimization Tips
1. **Limit max_features** in TF-IDF to reduce memory usage
2. **Use ngram_range** (1,2) for faster processing
3. **Cache vectorized intents** for repeated operations
4. **Batch process** multiple messages when possible

## 🧪 Testing

### Run Test Suite
```bash
python test_mcp_service.py
```

### Test Coverage
- Intent detection accuracy
- Parameter extraction quality
- Execution plan generation
- Vector similarity calculations
- Edge case handling

## 🔄 Integration with Existing System

### Replace Keyword Matching
```python
# Old approach (keyword matching)
if 'create task' in user_message.lower():
    # Handle task creation

# New approach (MCP service)
intent_result = mcp_service.detect_stored_procedure_intent(user_message)
if intent_result['best_intent'] == 'task_creation':
    # Handle task creation with confidence scoring
```

### Enhanced Parameter Extraction
```python
# Old approach (rigid patterns)
task_name_match = re.search(r'create\s+task\s+["\']([^"\']+)["\']', user_message)

# New approach (intelligent extraction)
params = mcp_service.extract_parameters_for_intent(user_message, 'task_creation')
task_name = params.get('TaskName')
```

## 🎯 Benefits Over Keyword Matching

### 1. **Semantic Understanding**
- Understands "make a new task" as equivalent to "create task"
- Handles synonyms and variations naturally
- Context-aware intent detection

### 2. **Confidence Scoring**
- Provides confidence scores for all intents
- Helps identify ambiguous requests
- Enables fallback strategies

### 3. **Flexibility**
- Easy to add new intents and patterns
- Configurable similarity thresholds
- Extensible parameter extraction

### 4. **Maintainability**
- Centralized intent definitions
- Consistent parameter extraction
- Easy to test and debug

## 🚨 Troubleshooting

### Common Issues

#### 1. **Low Confidence Scores**
- Check if keywords are too specific
- Verify TF-IDF configuration
- Consider adding more training examples

#### 2. **Intent Misclassification**
- Review similarity threshold settings
- Check for keyword conflicts
- Verify intent descriptions

#### 3. **Parameter Extraction Failures**
- Review regex patterns
- Check message format
- Verify context availability

### Debug Mode
```python
# Enable detailed logging
import logging
logging.getLogger('chatbot.services.mcp_service').setLevel(logging.DEBUG)

# Enable vector debug in config
LOGGING_CONFIG['enable_vector_debug'] = True
LOGGING_CONFIG['enable_similarity_debug'] = True
```

## 🔮 Future Enhancements

### 1. **Advanced Embeddings**
- Sentence transformers for better semantic understanding
- Domain-specific embeddings for business terminology
- Multi-language support

### 2. **Machine Learning**
- Intent classification models
- Parameter extraction with NER
- Confidence calibration

### 3. **Vector Database**
- FAISS for faster similarity search
- Persistent vector storage
- Real-time updates

### 4. **Context Awareness**
- Conversation history integration
- User preference learning
- Dynamic threshold adjustment

## 📚 References

- [scikit-learn TF-IDF](https://scikit-learn.org/stable/modules/generated/sklearn.feature_extraction.text.TfidfVectorizer.html)
- [Cosine Similarity](https://en.wikipedia.org/wiki/Cosine_similarity)
- [Vector Space Model](https://en.wikipedia.org/wiki/Vector_space_model)
- [Model Context Protocol](https://modelcontextprotocol.io/)

## 🤝 Contributing

1. Follow the existing code style
2. Add tests for new features
3. Update documentation
4. Ensure backward compatibility
5. Test with various user message formats

---

**Note**: This MCP service represents a significant improvement over traditional keyword matching, providing intelligent, scalable, and maintainable stored procedure detection for the chatbot system.
