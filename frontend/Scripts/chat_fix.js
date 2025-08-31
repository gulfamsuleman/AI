// Chat Frontend Fix - Enhanced User Selection and Message Sending
// This script fixes the dropdown functionality and message sending issues

document.addEventListener('DOMContentLoaded', function() {
    console.log('Chat Fix Script Loaded');
    
    // Get DOM elements
    const dropdownTrigger = document.getElementById('dropdownTrigger');
    const dropdownMenu = document.getElementById('dropdownMenu');
    const dropdownText = document.getElementById('dropdownText');
    const dropdownArrow = document.querySelector('.dropdown-arrow');
    const messageInput = document.getElementById('messageInput');
    const sendButton = document.getElementById('sendButton');
    const messagesContainer = document.getElementById('messagesContainer');
    
    // Global variables
    let selectedUser = null;
    let isDropdownOpen = false;
    
    // Initialize the chat interface
    function initializeChat() {
        console.log('Initializing chat interface...');
        
        // Set up dropdown functionality
        setupDropdown();
        
        // Set up message input functionality
        setupMessageInput();
        
        // Set up send button functionality
        setupSendButton();
        
        // Load users from backend
        loadUsersFromBackend();
        
        // Restore saved user if available
        restoreSavedUser();
        
        console.log('Chat interface initialized');
    }
    
    // Set up dropdown functionality
    function setupDropdown() {
        if (!dropdownTrigger || !dropdownMenu) {
            console.error('Dropdown elements not found');
            return;
        }
        
        // Toggle dropdown on trigger click
        dropdownTrigger.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            toggleDropdown();
        });
        
        // Close dropdown when clicking outside
        document.addEventListener('click', function(e) {
            if (!dropdownTrigger.contains(e.target) && !dropdownMenu.contains(e.target)) {
                closeDropdown();
            }
        });
        
        // Handle dropdown option clicks
        dropdownMenu.addEventListener('click', function(e) {
            if (e.target.classList.contains('dropdown-option')) {
                e.preventDefault();
                e.stopPropagation();
                
                const user = e.target.getAttribute('data-user');
                if (user) {
                    selectUser(user);
                    closeDropdown();
                }
            }
        });
        
        console.log('Dropdown functionality set up');
    }
    
    // Toggle dropdown open/close
    function toggleDropdown() {
        if (isDropdownOpen) {
            closeDropdown();
        } else {
            openDropdown();
        }
    }
    
    // Open dropdown
    function openDropdown() {
        if (dropdownMenu) {
            dropdownMenu.style.display = 'block';
            if (dropdownArrow) {
                dropdownArrow.classList.add('open');
            }
            isDropdownOpen = true;
            console.log('Dropdown opened');
        }
    }
    
    // Close dropdown
    function closeDropdown() {
        if (dropdownMenu) {
            dropdownMenu.style.display = 'none';
            if (dropdownArrow) {
                dropdownArrow.classList.remove('open');
            }
            isDropdownOpen = false;
            console.log('Dropdown closed');
        }
    }
    
    // Select a user
    function selectUser(user) {
        console.log('Selecting user:', user);
        selectedUser = user;
        
        // Update dropdown text
        if (dropdownText) {
            dropdownText.textContent = `👤 ${user}`;
        }
        
        // Save to localStorage
        localStorage.setItem('acmeChatbotSelectedUser', user);
        
        // Update send button state
        updateSendButtonState();
        
        // Add system message
        addMessage(`Switched to user: ${user}`, 'system');
        
        console.log('User selected:', user);
    }
    
    // Set up message input functionality
    function setupMessageInput() {
        if (!messageInput) {
            console.error('Message input not found');
            return;
        }
        
        // Auto-resize textarea
        messageInput.addEventListener('input', function() {
            this.style.height = 'auto';
            this.style.height = Math.min(this.scrollHeight, 120) + 'px';
            updateSendButtonState();
        });
        
        // Handle Enter key
        messageInput.addEventListener('keydown', function(e) {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                sendMessage();
            }
        });
        
        console.log('Message input functionality set up');
    }
    
    // Set up send button functionality
    function setupSendButton() {
        if (!sendButton) {
            console.error('Send button not found');
            return;
        }
        
        sendButton.addEventListener('click', function(e) {
            e.preventDefault();
            sendMessage();
        });
        
        console.log('Send button functionality set up');
    }
    
    // Update send button state
    function updateSendButtonState() {
        if (!sendButton || !messageInput) {
            return;
        }
        
        const hasInput = messageInput.value.trim().length > 0;
        const hasUser = selectedUser && selectedUser.length > 0;
        const isDisabled = !hasInput || !hasUser;
        
        sendButton.disabled = isDisabled;
        
        console.log('Send button state updated:', {
            hasInput,
            hasUser,
            isDisabled,
            selectedUser,
            messageValue: messageInput.value.trim()
        });
    }
    
    // Send message
    async function sendMessage() {
        if (!messageInput || !selectedUser) {
            console.error('Cannot send message: missing input or user');
            return;
        }
        
        const message = messageInput.value.trim();
        if (!message) {
            console.log('Empty message, not sending');
            return;
        }
        
        console.log('Sending message:', message, 'for user:', selectedUser);
        
        // Add user message to chat
        addMessage(message, 'user');
        
        // Clear input
        messageInput.value = '';
        messageInput.style.height = 'auto';
        
        // Update button state
        updateSendButtonState();
        
        // Show typing indicator
        showTypingIndicator();
        
        try {
            // Send to backend
            const response = await sendMessageToBackend(message, selectedUser);
            
            // Hide typing indicator
            hideTypingIndicator();
            
            if (response.error) {
                addMessage(`Error: ${response.error}`, 'error');
            } else {
                const backendText = response.reply || response.response || response.bot_reply || response.answer || response.text || response.content || response.data || response.message;
                const finalText = typeof backendText === 'string' ? backendText : (backendText ? JSON.stringify(backendText) : '');
                addMessage(finalText || 'Unexpected server response', 'bot');
            }
        } catch (error) {
            console.error('Error sending message:', error);
            hideTypingIndicator();
            addMessage('Error: Failed to send message. Please try again.', 'error');
        }
    }
    
    // Send message to backend
    async function sendMessageToBackend(message, user) {
        const API_BASE_URL = 'http://localhost:8000';
        
        const requestData = {
            message: message,
            user: user,
            timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
        };
        
        console.log('Sending to backend:', requestData);
        console.log('Request URL:', `${API_BASE_URL}/api/test-chat/`);
        
        try {
            const response = await fetch(`${API_BASE_URL}/api/chat/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                },
                body: JSON.stringify(requestData)
            });
            
            console.log('Response status:', response.status);
            console.log('Response headers:', response.headers);
            
            if (response.ok) {
                const data = await response.json();
                console.log('Backend response:', data);
                return data;
            } else {
                const errorText = await response.text();
                console.error('Backend error response:', errorText);
                
                try {
                    const errorData = JSON.parse(errorText);
                    return { error: errorData.error || 'Failed to get response from server' };
                } catch (parseError) {
                    return { error: `Server error: ${response.status} - ${errorText}` };
                }
            }
        } catch (fetchError) {
            console.error('Fetch error:', fetchError);
            return { error: `Network error: ${fetchError.message}` };
        }
    }
    
    // Load users from backend
    async function loadUsersFromBackend() {
        try {
            console.log('Loading users from backend...');
            
            const API_BASE_URL = 'http://localhost:8000';
            const response = await fetch(`${API_BASE_URL}/api/users/`, {
                method: 'GET',
                headers: {
                    'Accept': 'application/json',
                }
            });
            
            if (response.ok) {
                const users = await response.json();
                console.log('Users loaded:', users);
                populateDropdownWithUsers(users);
                
                // Auto-select first user if available
                if (users.length > 0 && !selectedUser) {
                    setTimeout(() => {
                        selectUser(users[0].Name || users[0].name || users[0]);
                    }, 500);
                }
            } else {
                console.error('Failed to load users:', response.status);
                addMessage('Error: Failed to load users from backend', 'error');
                
                // Fallback to test users
                const testUsers = ['Abriel Vielma', 'Test User 1', 'Test User 2'];
                populateDropdownWithUsers(testUsers);
            }
        } catch (error) {
            console.error('Error loading users:', error);
            addMessage('Error: Cannot connect to backend server', 'error');
            
            // Fallback to test users
            const testUsers = ['Abriel Vielma', 'Test User 1', 'Test User 2'];
            populateDropdownWithUsers(testUsers);
        }
    }
    
    // Populate dropdown with users
    function populateDropdownWithUsers(users) {
        if (!dropdownMenu) {
            console.error('Dropdown menu not found');
            return;
        }
        
        // Clear existing options
        dropdownMenu.innerHTML = '';
        
        // Add user options
        users.forEach(user => {
            const option = document.createElement('button');
            option.type = 'button';
            option.className = 'dropdown-option';
            option.setAttribute('data-user', user.Name || user.name || user);
            option.textContent = `👤 ${user.Name || user.name || user}`;
            dropdownMenu.appendChild(option);
        });
        
        console.log('Dropdown populated with', users.length, 'users');
    }
    
    // Restore saved user
    function restoreSavedUser() {
        const savedUser = localStorage.getItem('acmeChatbotSelectedUser');
        if (savedUser) {
            console.log('Restoring saved user:', savedUser);
            selectUser(savedUser);
        }
    }
    
    // Add message to chat
    function addMessage(text, type) {
        if (!messagesContainer) {
            console.error('Messages container not found');
            return;
        }
        
        const messageDiv = document.createElement('div');
        const isUser = type === 'user';
        messageDiv.className = `message ${isUser ? 'user-msg' : 'bot-msg'}`;
        
        const now = new Date();
        const timeString = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        
        let icon = '💬';
        let senderLabel = 'Acme Bot';
        if (type === 'user') { icon = '👤'; senderLabel = 'You'; }
        else if (type === 'bot') { icon = '🤖'; senderLabel = 'Acme Bot'; }
        else if (type === 'system') { icon = 'ℹ️'; senderLabel = 'System'; }
        else if (type === 'error') { icon = '⚠️'; senderLabel = 'Error'; }
        
        messageDiv.innerHTML = `
            <div class="message-avatar">${icon}</div>
            <div class="message-content">
                <div class="message-header">
                    <span class="message-sender">${senderLabel}</span>
                    <span class="message-time">${timeString}</span>
                </div>
                <div class="message-text">${text}</div>
            </div>
        `;
        
        messagesContainer.appendChild(messageDiv);
        scrollToBottom();
        
        console.log('Message added:', { text, type, time: timeString });
    }
    
    // Show typing indicator
    function showTypingIndicator() {
        const typingDiv = document.createElement('div');
        typingDiv.className = 'message bot-msg typing-indicator';
        typingDiv.id = 'typing-indicator';
        typingDiv.innerHTML = `
            <div class="message-avatar">🤖</div>
            <div class="message-content">
                <div class="typing-text">Bot is thinking...</div>
                <div class="typing-dots"><span></span><span></span><span></span></div>
            </div>
        `;
        messagesContainer.appendChild(typingDiv);
        scrollToBottom();
    }
    
    // Hide typing indicator
    function hideTypingIndicator() {
        const typingIndicator = document.getElementById('typing-indicator');
        if (typingIndicator) {
            typingIndicator.remove();
        }
    }
    
    // Scroll to bottom
    function scrollToBottom() {
        setTimeout(() => {
            if (messagesContainer) {
                messagesContainer.scrollTop = messagesContainer.scrollHeight;
            }
        }, 100);
    }
    
    // Initialize the chat
    initializeChat();
    
    // Make functions globally available
    window.selectUser = selectUser;
    window.updateSendButtonState = updateSendButtonState;
    window.sendMessage = sendMessage;
    
    // Add test function for debugging
    window.testBackendConnection = async function() {
        console.log('Testing backend connection...');
        
        try {
            // Test health endpoint
            const healthResponse = await fetch('http://localhost:8000/api/health/');
            console.log('Health check:', healthResponse.ok ? 'SUCCESS' : 'FAILED');
            
            // Test users endpoint
            const usersResponse = await fetch('http://localhost:8000/api/users/');
            console.log('Users check:', usersResponse.ok ? 'SUCCESS' : 'FAILED');
            
            // Test chat endpoint
            const chatResponse = await fetch('http://localhost:8000/api/chat/', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    message: 'Test message',
                    user: 'Test User',
                    timezone: 'UTC'
                })
            });
            console.log('Chat check:', chatResponse.ok ? 'SUCCESS' : 'FAILED');
            
            return {
                health: healthResponse.ok,
                users: usersResponse.ok,
                chat: chatResponse.ok
            };
        } catch (error) {
            console.error('Backend test failed:', error);
            return { error: error.message };
        }
    };
    
    console.log('Chat fix script completed initialization');
    console.log('You can test the backend connection by running: window.testBackendConnection()');
});
