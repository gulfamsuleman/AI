# ChatBot Frontend-Backend Integration Setup

This guide explains how to connect the ASP.NET frontend with the Django backend for the Acme Chatbot.

## Overview

The integration consists of:
- **Frontend**: ASP.NET Web Forms application
- **Backend**: Django REST API
- **Communication**: HTTP REST API calls from JavaScript

## Backend API Endpoints

The Django backend provides the following endpoints:

### 1. Chat Endpoint
- **URL**: `POST /api/chat/`
- **Purpose**: Send chat messages and receive bot responses
- **Request Body**:
  ```json
  {
    "message": "User's message",
    "user": "Username",
    "timezone": "User's timezone (optional)"
  }
  ```
- **Response**:
  ```json
  {
    "reply": "Bot's response message"
  }
  ```

### 2. Users Endpoint
- **URL**: `GET /api/users/`
- **Purpose**: Get list of active users
- **Response**:
  ```json
  ["User1", "User2", "User3"]
  ```

## Frontend Files

### Core Files
1. **`ChatBot.aspx`** - Main chat interface
2. **`ChatBot.aspx.cs`** - Server-side code-behind
3. **`Scripts/chatbot-config.js`** - Configuration settings
4. **`Scripts/chatbot-connector.js`** - Main JavaScript connector
5. **`TestConnection.aspx`** - Connection testing page

### Key Features
- **User Selection**: Dropdown to select users from backend
- **Real-time Chat**: Send messages and receive responses
- **Error Handling**: Comprehensive error handling and user feedback
- **Configuration**: Easy-to-modify configuration system
- **Testing**: Built-in connection testing tools

## Setup Instructions

### 1. Start the Django Backend

```bash
cd backend/chatbot
python manage.py runserver
```

The backend will be available at `http://localhost:8000`

### 2. Configure Frontend

Edit `Scripts/chatbot-config.js` to match your backend settings:

```javascript
API: {
    BASE_URL: 'http://localhost:8000',  // Change if backend runs on different port
    ENDPOINTS: {
        CHAT: '/api/chat/',
        USERS: '/api/users/',
        HEALTH: '/api/health/'
    }
}
```

### 3. Test the Connection

1. Navigate to `TestConnection.aspx` in your browser
2. Click "Test Full Connection" to verify both endpoints work
3. Check that both Users and Chat endpoints return success

### 4. Use the Chat Interface

1. Navigate to `ChatBot.aspx`
2. Select a user from the dropdown
3. Type a message and press Enter or click Send
4. The bot will respond with task creation or other relevant information

## Configuration Options

### API Configuration
- `API.BASE_URL`: Backend server URL
- `API.TIMEOUT`: Request timeout in milliseconds
- `API.RETRY_ATTEMPTS`: Number of retry attempts for failed requests

### UI Configuration
- `UI.AUTO_SELECT_FIRST_USER`: Automatically select first user in list
- `UI.SAVE_USER_PREFERENCE`: Save selected user in localStorage
- `UI.SHOW_TYPING_INDICATOR`: Show typing indicator while waiting for response

### Debug Configuration
- `DEBUG.ENABLED`: Enable debug logging
- `DEBUG.LOG_LEVEL`: Log level (debug, info, warn, error)
- `DEBUG.LOG_API_CALLS`: Log all API calls to console

## Troubleshooting

### Common Issues

1. **CORS Errors**
   - Ensure Django backend has CORS properly configured
   - Check that `corsheaders` is in `INSTALLED_APPS`
   - Verify `CORS_ALLOW_ALL_ORIGINS = True` in development
   - **HTTPS/HTTP Mismatch**: If frontend runs on HTTPS but backend on HTTP, you may get CORS errors

2. **Connection Refused**
   - Verify Django server is running on correct port
   - Check firewall settings
   - Ensure backend URL in config matches actual server
   - **Port 44399**: If your ASP.NET app runs on port 44399, make sure Django runs on port 8000

3. **Users Not Loading**
   - Check Django database connection
   - Verify users exist in the database
   - Check Django logs for errors

4. **Chat Messages Not Working**
   - Verify chat endpoint is accessible
   - Check request format matches expected format
   - Review Django logs for processing errors

5. **JavaScript Syntax Errors**
   - Check browser console for syntax errors
   - Ensure all JavaScript files are properly loaded
   - Verify no HTML tags in JavaScript files

6. **500 Internal Server Error**
   - This usually indicates the old ASMX service is being called instead of Django
   - Ensure `ai-chatbot.js` is updated to use Django endpoints
   - Check that the correct JavaScript files are being loaded

### Debug Steps

1. **Check Browser Console**
   - Open Developer Tools (F12)
   - Look for JavaScript errors
   - Check Network tab for failed requests
   - Look for CORS errors or 500 Internal Server Errors

2. **Use Debug Pages**
   - Navigate to `DebugConnection.aspx` for comprehensive debugging
   - Use `TestConnection.aspx` for basic connection testing
   - Check environment information and configuration

3. **Test Individual Endpoints**
   - Use the debug pages to test each endpoint separately
   - Check response status codes and content
   - Verify request/response format

4. **Verify Backend Logs**
   - Check Django console output
   - Review log files in `backend/chatbot/logs/`
   - Look for CORS-related errors

5. **Test with curl**
   ```bash
   # Test users endpoint
   curl http://localhost:8000/api/users/
   
   # Test chat endpoint
   curl -X POST http://localhost:8000/api/chat/ \
     -H "Content-Type: application/json" \
     -d '{"message":"test","user":"testuser","timezone":"UTC"}'
   ```

6. **Check File References**
   - Ensure `ai-chatbot.js` is updated (not using old ASMX service)
   - Verify `chatbot-config.js` is loaded before other scripts
   - Check that the correct JavaScript files are referenced in your pages

## Development Workflow

### Making Changes

1. **Frontend Changes**
   - Edit JavaScript files in `Scripts/` directory
   - Test changes in browser
   - Use browser console for debugging

2. **Backend Changes**
   - Modify Django views in `backend/chatbot/api/views/`
   - Test API endpoints directly
   - Check Django logs for errors

3. **Configuration Changes**
   - Edit `chatbot-config.js` for frontend settings
   - Modify Django settings for backend configuration

### Testing

1. **Unit Tests**: Test individual components
2. **Integration Tests**: Test frontend-backend communication
3. **Manual Testing**: Use the chat interface and test page

## Security Considerations

### Development
- CORS is enabled for all origins in development
- Debug mode is enabled
- Detailed error messages are shown

### Production
- Configure specific CORS origins
- Disable debug mode
- Use HTTPS for all communications
- Implement proper authentication if needed
- Sanitize user inputs

## File Structure

```
frontend/
├── ChatBot.aspx              # Main chat interface
├── ChatBot.aspx.cs           # Server-side code
├── TestConnection.aspx       # Connection testing page
├── TestConnection.aspx.cs    # Test page code-behind
├── Scripts/
│   ├── chatbot-config.js     # Configuration settings
│   ├── chatbot-connector.js  # Main connector logic
│   └── jquery-3.7.0.min.js   # jQuery library
└── CHATBOT_SETUP.md          # This file
```

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review browser console and Django logs
3. Use the test connection page to isolate issues
4. Verify all configuration settings are correct
