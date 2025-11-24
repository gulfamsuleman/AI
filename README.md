# QProcess - AI Chatbot with Task Management

A comprehensive AI-powered chatbot system with advanced task management capabilities, featuring a Django backend and modern web frontend.

## 🚀 Features

### Chatbot Functionality
- **Single-tap Toggle**: Click chat toggle or Q Bot button to open/close chat window
- **Name Resolution**: Intelligent fuzzy matching for user names with clarification prompts
- **Task Creation**: Natural language task creation with automatic parameter extraction
- **Alert System**: Automatic alerts for overdue tasks with customizable recipients
- **Status Reports**: Integration with status reporting system
- **Timezone Support**: Full timezone awareness and conversion

### Frontend Features
- **Modern UI**: Clean, responsive design with dark blue theme
- **Real-time Chat**: Instant message delivery with typing indicators
- **User Selection**: Dropdown for selecting different users
- **Mobile Responsive**: Works seamlessly on desktop and mobile devices
- **Visual Feedback**: Smooth animations and hover effects

### Backend Features
- **Django REST API**: Robust API with comprehensive error handling
- **AI Integration**: Claude Opus 4 integration for natural language processing
- **Database Integration**: SQL Server integration with QCheck system
- **Session Management**: Persistent chat sessions with context awareness
- **Logging**: Comprehensive logging for debugging and monitoring

## 📁 Project Structure

```
Final_Mix/
├── frontend/                 # ASP.NET Web Forms frontend
│   ├── Content/             # CSS and styling files
│   ├── Scripts/             # JavaScript files
│   ├── Controls/            # User controls
│   └── .gitignore           # Frontend-specific ignores
├── backend/                 # Django backend
│   ├── chatbot/            # Main Django application
│   │   ├── chatbot/        # Core chatbot logic
│   │   │   ├── services/   # Business logic services
│   │   │   ├── api/        # API views and endpoints
│   │   │   └── config/     # Configuration files
│   │   ├── requirements.txt # Python dependencies
│   │   └── manage.py       # Django management
│   └── .gitignore          # Backend-specific ignores
├── start-chatbot.bat       # Windows batch file to start backend
├── start-chatbot.ps1       # PowerShell script to start backend
├── .gitignore              # Root-level gitignore
└── README.md               # This file
```

## 🛠️ Setup Instructions

### Prerequisites
- Python 3.8+ (for backend)
- .NET Framework (for frontend)
- SQL Server (for database)
- Claude API key

### Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd backend/chatbot
   ```

2. **Create virtual environment:**
   ```bash
   python -m venv venv
   ```

3. **Activate virtual environment:**
   - Windows: `venv\Scripts\activate`
   - Linux/Mac: `source venv/bin/activate`

4. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

5. **Set environment variables:**
   Create a `.env` file in `backend/chatbot/` with:
   ```
   CLAUDE_API_KEY=your_claude_api_key_here
   DATABASE_URL=your_database_connection_string
   ```

6. **Start the backend server:**
   ```bash
   python manage.py runserver
   ```
   Or use the provided scripts:
   - Windows: `start-chatbot.bat`
   - PowerShell: `start-chatbot.ps1`

### Frontend Setup

1. **Open the frontend project** in Visual Studio or your preferred IDE
2. **Configure database connection** in web.config
3. **Build and run** the project

## 🎯 Usage

### Starting the System

1. **Start Backend:**
   ```bash
   # Using batch file (Windows)
   start-chatbot.bat
   
   # Using PowerShell
   .\start-chatbot.ps1
   
   # Or manually
   cd backend/chatbot
   python manage.py runserver
   ```

2. **Start Frontend:**
   - Open the frontend project in Visual Studio
   - Press F5 or click "Start Debugging"

### Using the Chatbot

1. **Open Chat:** Click the chat toggle button (bottom right) or Q Bot button
2. **Select User:** Choose a user from the dropdown
3. **Create Tasks:** Use natural language like:
   - "Create a task 'Prepare monthly report'"
   - "Assign 'Update website content' to CAS Internal Team, add alert if overdue to CLO"
   - "Set up 'Client presentation' for next Wednesday with Angad and Caroline"

### Name Resolution

When the chatbot encounters ambiguous names (e.g., multiple "Hayden" users), it will:
1. Show a clarification message with full names
2. Ask you to specify which person you meant
3. Continue with task creation once clarified

## 🔧 Configuration

### Backend Configuration

Key configuration files:
- `backend/chatbot/chatbot/config/settings.py` - API settings
- `backend/chatbot/chatbot/config/prompts.py` - AI prompts
- `backend/chatbot/chatbot/config/rules.py` - Business rules

### Frontend Configuration

- `frontend/Web.config` - Database connection and app settings
- `frontend/Content/ai-chat.css` - Chatbot styling
- `frontend/Scripts/ai-chatbot.js` - Chatbot functionality

## 🐛 Troubleshooting

### Common Issues

1. **Backend won't start:**
   - Check if virtual environment is activated
   - Verify CLAUDE_API_KEY is set in .env file
   - Ensure all dependencies are installed

2. **Frontend can't connect to backend:**
   - Verify backend is running on http://localhost:8000
   - Check CORS settings in backend
   - Ensure firewall isn't blocking the connection

3. **Name resolution not working:**
   - Check database connection
   - Verify user names exist in QCheck_Groups table
   - Check logs for detailed error messages

### Debug Mode

Enable debug mode by setting `debug: true` in the chat request or by modifying the backend configuration.

## 📝 API Documentation

### Chat Endpoint
- **URL:** `POST /api/chat/`
- **Request Body:**
  ```json
  {
    "message": "Create a task 'Test task'",
    "user": "John Doe",
    "timezone": "America/New_York"
  }
  ```
- **Response:**
  ```json
  {
    "reply": "✓ I've created 'Test task' assigned to John Doe.",
    "instance_id": 12345
  }
  ```

### Users Endpoint
- **URL:** `GET /api/users/`
- **Response:** List of available users

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is proprietary software. All rights reserved.

## 🆘 Support

For support and questions:
- Check the troubleshooting section above
- Review the logs in `backend/chatbot/logs/`
- Contact the development team

---

**Version:** 1.0.0  
**Last Updated:** December 2024

