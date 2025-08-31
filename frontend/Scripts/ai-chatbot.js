/**
 * AI Chatbot with Single-Tap Toggle Functionality
 * 
 * Features:
 * - Single tap on chat toggle button: Toggles chat window (open/close)
 * - Single tap on Q Bot button: Toggles chat window (open/close)
 * - Automatic input focus when chat opens
 * - Backward compatibility with minimize button
 */

document.addEventListener('DOMContentLoaded', function() {
    const chatToggle = document.getElementById('chat-toggle');
    const chatContainer = document.querySelector('.chat-container');
    const minimizeBtn = document.querySelector('.minimize-btn');
    const chatMessages = document.getElementById('chat-messages');
    const userInput = document.getElementById('user-input');
    const sendBtn = document.getElementById('send-btn');

    // Get user information from local storage
    function getUserInfo() {
        // Try to get from ChatBotUtils first, then fallback to legacy storage
        const userInfo = window.ChatBotUtils ? window.ChatBotUtils.getUserInfo() : {};
        if (userInfo.userName || userInfo.fullName) {
            return userInfo;
        }
        
        // Legacy fallback
        return {
            userName: localStorage.getItem('userName') || '',
            fullName: localStorage.getItem('userFullName') || ''
        };
    }

    // Toggle chat window function
    function toggleChat() {
        const isOpen = chatContainer.classList.contains('open');
        
        if (isOpen) {
            // Close chat
            chatContainer.classList.remove('open');
        } else {
            // Open chat
            chatContainer.classList.add('open');
            
            // Update chat header with user name if available
            const userInfo = getUserInfo();
            if (userInfo.fullName) {
                const chatHeader = document.querySelector('.chat-header h1');
                if (chatHeader) {
                    chatHeader.textContent = `AI Assistant - ${userInfo.fullName}`;
                }
            }
            
            // Focus input when chat is opened
            setTimeout(() => {
                if (userInput) {
                    userInput.focus();
                }
            }, 300);
        }
    }

    // Single-tap toggle handler for chat toggle button
    chatToggle.addEventListener('click', function(e) {
        e.preventDefault();
        toggleChat();
    });

    // Single-tap toggle handler for Q Bot button
    const qBotButton = document.querySelector('.aiButton');
    if (qBotButton) {
        qBotButton.addEventListener('click', function(e) {
            e.preventDefault();
            toggleChat();
        });
    }

    // Keep the original minimize button functionality as backup
    minimizeBtn.addEventListener('click', function() {
        chatContainer.classList.remove('open');
    });

    // Make toggleChat function globally available for legacy compatibility
    window.toggleChat = toggleChat;

    // Send message function
    function sendMessage() {
        const message = userInput.value.trim();
        if (message === '') return;

        // Add user message to chat
        addMessage(message, 'user');
        userInput.value = '';

        // Show typing indicator
        showTypingIndicator();

        // Send message to backend service
        sendMessageToBackend(message);
    }

    // Send message to Django backend service
    async function sendMessageToBackend(message) {
        const userInfo = getUserInfo();
        // Use fullName instead of userName for the Django backend
        const userFullName = userInfo.fullName || userInfo.userName || 'Unknown User';
        
        const baseUrl = window.getChatBotConfig ? window.getChatBotConfig('API.BASE_URL') : 'http://localhost:8000';
        const chatEndpoint = window.getChatBotConfig ? window.getChatBotConfig('API.ENDPOINTS.CHAT') : '/api/chat/';
        
        const requestData = {
            message: message,
            user: userFullName, // Send full name instead of username
            timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
        };

        // Log the request if debugging is enabled
        if (window.ChatBotUtils) {
            window.ChatBotUtils.log('debug', 'Sending chat request', { requestData, url: `${baseUrl}${chatEndpoint}` });
        } else {
            console.log('ChatBot Debug: Sending request with user:', userFullName, 'Request data:', requestData);
        }

        try {
            const response = await fetch(`${baseUrl}${chatEndpoint}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                },
                body: JSON.stringify(requestData)
            });

            removeTypingIndicator();

            if (response.ok) {
                const data = await response.json();
                if (window.ChatBotUtils) {
                    window.ChatBotUtils.log('debug', 'Django API Response', data);
                }
                
                // Extract the response text from various possible fields
                const responseText = data.reply || data.response || data.bot_reply || 
                                   data.answer || data.text || data.content || 
                                   data.data || data.message || 'No response received';
                
                addMessage(responseText, 'bot');
            } else {
                const errorText = await response.text();
                if (window.ChatBotUtils) {
                    window.ChatBotUtils.log('error', 'Django API Error', { status: response.status, error: errorText });
                }
                
                let errorMessage = window.getChatBotConfig ? window.getChatBotConfig('CHAT.ERROR_MESSAGE') : 
                                 "I'm sorry, there was an error processing your request. Please try again.";
                
                if (response.status === 0) {
                    errorMessage = window.getChatBotConfig ? window.getChatBotConfig('CHAT.BACKEND_OFFLINE_MESSAGE') : 
                                 "Backend server is offline. Please start the Django server.";
                } else if (response.status === 403) {
                    errorMessage = window.getChatBotConfig ? window.getChatBotConfig('CHAT.CORS_ERROR_MESSAGE') : 
                                 "Cross-origin request blocked. Please check CORS settings.";
                }
                
                addMessage(errorMessage, 'bot');
            }
        } catch (error) {
            if (window.ChatBotUtils) {
                window.ChatBotUtils.log('error', 'Network error', error);
            }
            removeTypingIndicator();
            
            let errorMessage = window.getChatBotConfig ? window.getChatBotConfig('CHAT.NETWORK_ERROR_MESSAGE') : 
                             "I'm sorry, I couldn't connect to the server. Please check your connection and try again.";
            
            if (error.name === 'TypeError' && error.message.includes('fetch')) {
                errorMessage = window.getChatBotConfig ? window.getChatBotConfig('CHAT.BACKEND_OFFLINE_MESSAGE') : 
                             "Backend server is offline. Please start the Django server.";
            }
            
            addMessage(errorMessage, 'bot');
        }
    }

    // Add message to chat
    function addMessage(text, sender) {
        const messageDiv = document.createElement('div');
        messageDiv.classList.add('message', `${sender}-message`);

        const now = new Date();
        const timeString = now.getHours() + ':' + (now.getMinutes() < 10 ? '0' : '') + now.getMinutes();

        messageDiv.innerHTML = `
            <div class="message-content">
                <p>${text}</p>
            </div>
            <span class="message-time">${timeString}</span>
        `;

        chatMessages.appendChild(messageDiv);
        scrollToBottom();
    }

    // Show typing indicator
    function showTypingIndicator() {
        const typingDiv = document.createElement('div');
        typingDiv.classList.add('typing-indicator');
        typingDiv.id = 'typing-indicator';
        typingDiv.innerHTML = `
            <div class="typing-dot"></div>
            <div class="typing-dot"></div>
            <div class="typing-dot"></div>
        `;
        chatMessages.appendChild(typingDiv);
        scrollToBottom();
    }

    // Remove typing indicator
    function removeTypingIndicator() {
        const typingIndicator = document.getElementById('typing-indicator');
        if (typingIndicator) {
            typingIndicator.remove();
        }
    }

    // Scroll to bottom of chat
    function scrollToBottom() {
        chatMessages.scrollTop = chatMessages.scrollHeight;
    }

    // Event listeners
    sendBtn.addEventListener('click', sendMessage);
    
    userInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            sendMessage();
        }
    });


});

// Legacy variables and functions for compatibility
let chatbotText = "";
let chatHistory = [];

function showBot() {
    const chatContainer = document.querySelector('.chat-container');
    if (chatContainer) {
        // Use the toggle function if available, otherwise just open
        if (typeof toggleChat === 'function') {
            toggleChat();
        } else {
            chatContainer.classList.add('open');
        }
    }
}

function showBotMobile() {
    const chatContainer = document.querySelector('.chat-container');
    if (chatContainer) {
        // Use the toggle function if available, otherwise just open
        if (typeof toggleChat === 'function') {
            toggleChat();
        } else {
            chatContainer.classList.add('open');
        }
    }
}

function sendChatMessage() {
    const userInput = document.getElementById('user-input');
    if (userInput) {
        const message = userInput.value.trim();
        if (message !== '') {
            // Trigger the send button click
            const sendBtn = document.getElementById('send-btn');
            if (sendBtn) {
                sendBtn.click();
            }
        }
    }
}

function resetChatbot() {
    const userInput = document.getElementById('user-input');
    if (userInput) {
        userInput.value = '';
    }
    chatbotText = "";
    chatHistory = [];
}