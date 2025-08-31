/**
 * ChatBot Configuration
 * 
 * This file contains configuration settings for the chatbot frontend.
 * Modify these settings to change backend connection, UI behavior, etc.
 */

window.ChatBotConfig = {
    // Backend API Configuration
    API: {
        BASE_URL: 'http://localhost:8000',
        ENDPOINTS: {
            CHAT: '/api/chat/',
            USERS: '/api/users/',
            HEALTH: '/api/health/'
        },
        TIMEOUT: 30000, // 30 seconds
        RETRY_ATTEMPTS: 3,
        RETRY_DELAY: 1000 // 1 second
    },
    
    // UI Configuration
    UI: {
        AUTO_SELECT_FIRST_USER: true,
        SAVE_USER_PREFERENCE: true,
        SHOW_TYPING_INDICATOR: true,
        AUTO_SCROLL_TO_BOTTOM: true,
        MESSAGE_TIMESTAMP_FORMAT: 'HH:mm',
        MAX_MESSAGE_LENGTH: 1000,
        TEXTAREA_MAX_HEIGHT: 120
    },
    
    // Chat Configuration
    CHAT: {
        WELCOME_MESSAGE: 'Welcome to Acme Chatbot! Select a user and start chatting.',
        TYPING_MESSAGE: 'Bot is thinking...',
        ERROR_MESSAGE: 'Sorry, something went wrong. Please try again.',
        NETWORK_ERROR_MESSAGE: 'Cannot connect to server. Please check your connection.',
        EMPTY_MESSAGE_ERROR: 'Please enter a message.',
        NO_USER_SELECTED_ERROR: 'Please select a user first.',
        CORS_ERROR_MESSAGE: 'Cross-origin request blocked. Please check CORS settings.',
        BACKEND_OFFLINE_MESSAGE: 'Backend server is offline. Please start the Django server.'
    },
    
    // Local Storage Keys
    STORAGE: {
        SELECTED_USER: 'acmeChatbotSelectedUser',
        CHAT_HISTORY: 'acmeChatbotHistory',
        SETTINGS: 'acmeChatbotSettings',
        USER_INFO: 'userInfo'
    },
    
    // Debug Configuration
    DEBUG: {
        ENABLED: true,
        LOG_LEVEL: 'info', // 'debug', 'info', 'warn', 'error'
        SHOW_CONNECTION_STATUS: true,
        LOG_API_CALLS: true
    }
};

// Helper function to get configuration value with fallback
window.getChatBotConfig = function(path, defaultValue = null) {
    const keys = path.split('.');
    let value = window.ChatBotConfig;
    
    for (const key of keys) {
        if (value && typeof value === 'object' && key in value) {
            value = value[key];
        } else {
            return defaultValue;
        }
    }
    
    return value;
};

// Helper function to set configuration value
window.setChatBotConfig = function(path, value) {
    const keys = path.split('.');
    const lastKey = keys.pop();
    let current = window.ChatBotConfig;
    
    for (const key of keys) {
        if (!(key in current) || typeof current[key] !== 'object') {
            current[key] = {};
        }
        current = current[key];
    }
    
    current[lastKey] = value;
};

// Environment-specific overrides
(function() {
    // Check if we're in development mode
    const isDevelopment = window.location.hostname === 'localhost' || 
                         window.location.hostname === '127.0.0.1' ||
                         window.location.port === '8080' ||
                         window.location.port === '44399';
    
    if (isDevelopment) {
        // Development overrides
        window.setChatBotConfig('DEBUG.ENABLED', true);
        window.setChatBotConfig('DEBUG.LOG_LEVEL', 'debug');
        console.log('ChatBot running in development mode');
        
        // Handle HTTPS/HTTP mismatch
        if (window.location.protocol === 'https:') {
            console.warn('Frontend is running on HTTPS but backend is HTTP. This may cause CORS issues.');
            // You might want to change this to https if your Django backend supports it
            // window.setChatBotConfig('API.BASE_URL', 'https://localhost:8000');
        }
    } else {
        // Production overrides
        window.setChatBotConfig('DEBUG.ENABLED', false);
        window.setChatBotConfig('DEBUG.LOG_LEVEL', 'error');
        window.setChatBotConfig('API.BASE_URL', 'https://your-production-domain.com');
    }
    
    // Log configuration
    if (window.getChatBotConfig('DEBUG.ENABLED')) {
        console.log('ChatBot Configuration:', window.ChatBotConfig);
    }
})();

// Utility functions for better error handling
window.ChatBotUtils = {
    // Get user info from localStorage
    getUserInfo: function() {
        try {
            const userInfo = localStorage.getItem(window.getChatBotConfig('STORAGE.USER_INFO'));
            return userInfo ? JSON.parse(userInfo) : {};
        } catch (error) {
            console.error('Error parsing user info:', error);
            return {};
        }
    },
    
    // Set user info in localStorage
    setUserInfo: function(userInfo) {
        try {
            localStorage.setItem(window.getChatBotConfig('STORAGE.USER_INFO'), JSON.stringify(userInfo));
        } catch (error) {
            console.error('Error saving user info:', error);
        }
    },
    
    // Test backend connection
    testBackendConnection: async function() {
        const baseUrl = window.getChatBotConfig('API.BASE_URL');
        const usersEndpoint = window.getChatBotConfig('API.ENDPOINTS.USERS');
        
        try {
            const response = await fetch(`${baseUrl}${usersEndpoint}`, {
                method: 'GET',
                headers: {
                    'Accept': 'application/json',
                }
            });
            
            return {
                success: response.ok,
                status: response.status,
                statusText: response.statusText
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                type: 'network'
            };
        }
    },
    
    // Log messages with proper level
    log: function(level, message, data = null) {
        if (!window.getChatBotConfig('DEBUG.ENABLED')) return;
        
        const logLevel = window.getChatBotConfig('DEBUG.LOG_LEVEL');
        const levels = { 'debug': 0, 'info': 1, 'warn': 2, 'error': 3 };
        
        if (levels[level] >= levels[logLevel]) {
            const logMessage = `[ChatBot] ${message}`;
            if (data) {
                console[level](logMessage, data);
            } else {
                console[level](logMessage);
            }
        }
    }
};
