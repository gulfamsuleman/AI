/**
 * ChatBot Connector - Django Backend Integration
 * 
 * This script handles the communication between the ASP.NET frontend
 * and the Django backend API for the Acme Chatbot.
 */

class ChatBotConnector {
    constructor() {
        this.API_BASE_URL = window.getChatBotConfig('API.BASE_URL', 'http://localhost:8000');
        this.selectedUser = null;
        this.isConnected = false;
        this.retryAttempts = 0;
        this.maxRetries = window.getChatBotConfig('API.RETRY_ATTEMPTS', 3);
        
        // DOM elements
        this.elements = {
            dropdownTrigger: null,
            dropdownMenu: null,
            dropdownText: null,
            messageInput: null,
            sendButton: null,
            messagesContainer: null,
            typingIndicator: null,
            errorMessage: null,
            successMessage: null
        };
        
        this.init();
    }
    
    /**
     * Initialize the chatbot connector
     */
    init() {
        console.log('Initializing ChatBot Connector...');
        
        // Wait for DOM to be ready
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this.setupConnector());
        } else {
            this.setupConnector();
        }
    }
    
    /**
     * Setup the connector after DOM is ready
     */
    setupConnector() {
        this.getDOMElements();
        this.setupEventListeners();
        this.loadUsers();
        this.restoreSavedUser();
        this.testBackendConnection();
        
        console.log('ChatBot Connector initialized successfully');
    }
    
    /**
     * Get all required DOM elements
     */
    getDOMElements() {
        this.elements = {
            dropdownTrigger: document.getElementById('dropdownTrigger'),
            dropdownMenu: document.getElementById('dropdownMenu'),
            dropdownText: document.getElementById('dropdownText'),
            messageInput: document.getElementById('messageInput'),
            sendButton: document.getElementById('sendButton'),
            messagesContainer: document.getElementById('messagesContainer'),
            typingIndicator: document.getElementById('typingIndicator'),
            errorMessage: document.getElementById('errorMessage'),
            successMessage: document.getElementById('successMessage')
        };
        
        // Validate required elements
        const requiredElements = ['dropdownTrigger', 'dropdownMenu', 'messageInput', 'sendButton', 'messagesContainer'];
        const missingElements = requiredElements.filter(id => !this.elements[id]);
        
        if (missingElements.length > 0) {
            console.error('Missing required DOM elements:', missingElements);
            this.showError('Required UI elements not found. Please refresh the page.');
        }
    }
    
    /**
     * Setup event listeners
     */
    setupEventListeners() {
        // Dropdown functionality
        if (this.elements.dropdownTrigger) {
            this.elements.dropdownTrigger.addEventListener('click', (e) => {
                e.preventDefault();
                e.stopPropagation();
                this.toggleDropdown();
            });
        }
        
        // Close dropdown when clicking outside
        document.addEventListener('click', (e) => {
            if (this.elements.dropdownMenu && 
                !this.elements.dropdownTrigger.contains(e.target) && 
                !this.elements.dropdownMenu.contains(e.target)) {
                this.closeDropdown();
            }
        });
        
        // Handle dropdown option clicks
        if (this.elements.dropdownMenu) {
            this.elements.dropdownMenu.addEventListener('click', (e) => {
                if (e.target.classList.contains('dropdown-option')) {
                    e.preventDefault();
                    e.stopPropagation();
                    
                    const user = e.target.getAttribute('data-user');
                    if (user) {
                        this.selectUser(user);
                        this.closeDropdown();
                    }
                }
            });
        }
        
        // Message input functionality
        if (this.elements.messageInput) {
            this.elements.messageInput.addEventListener('input', () => {
                this.autoResizeTextarea();
                this.updateSendButtonState();
            });
            
            this.elements.messageInput.addEventListener('keydown', (e) => {
                if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    this.sendMessage();
                }
            });
        }
        
        // Send button functionality
        if (this.elements.sendButton) {
            this.elements.sendButton.addEventListener('click', (e) => {
                e.preventDefault();
                this.sendMessage();
            });
        }
    }
    
    /**
     * Test backend connection
     */
    async testBackendConnection() {
        try {
            console.log('Testing backend connection...');
            
            const response = await fetch(`${this.API_BASE_URL}/api/users/`, {
                method: 'GET',
                headers: {
                    'Accept': 'application/json',
                }
            });
            
            if (response.ok) {
                this.isConnected = true;
                console.log('✅ Backend connection successful');
                this.hideError();
            } else {
                throw new Error(`HTTP ${response.status}`);
            }
        } catch (error) {
            console.error('❌ Backend connection failed:', error);
            this.isConnected = false;
            this.showError('Cannot connect to backend server. Please check if the Django server is running.');
        }
    }
    
    /**
     * Load users from backend
     */
    async loadUsers() {
        try {
            console.log('Loading users from backend...');
            
            const response = await fetch(`${this.API_BASE_URL}/api/users/`, {
                method: 'GET',
                headers: {
                    'Accept': 'application/json',
                }
            });
            
            if (response.ok) {
                const users = await response.json();
                console.log('Users loaded:', users);
                this.populateDropdownWithUsers(users);
                
                // Auto-select first user if available
                if (users.length > 0 && !this.selectedUser) {
                    setTimeout(() => {
                        this.selectUser(users[0].Name || users[0].name || users[0]);
                    }, 500);
                }
            } else {
                throw new Error(`HTTP ${response.status}`);
            }
        } catch (error) {
            console.error('Error loading users:', error);
            this.showError('Failed to load users from backend');
            
            // Fallback to test users
            const testUsers = ['Abriel Vielma', 'Test User 1', 'Test User 2'];
            this.populateDropdownWithUsers(testUsers);
        }
    }
    
    /**
     * Populate dropdown with users
     */
    populateDropdownWithUsers(users) {
        if (!this.elements.dropdownMenu) {
            console.error('Dropdown menu not found');
            return;
        }
        
        // Clear existing options
        this.elements.dropdownMenu.innerHTML = '';
        
        // Add user options
        users.forEach(user => {
            const option = document.createElement('button');
            option.type = 'button';
            option.className = 'dropdown-option';
            option.setAttribute('data-user', user.Name || user.name || user);
            option.textContent = `👤 ${user.Name || user.name || user}`;
            this.elements.dropdownMenu.appendChild(option);
        });
        
        console.log('Dropdown populated with', users.length, 'users');
    }
    
    /**
     * Toggle dropdown open/close
     */
    toggleDropdown() {
        if (this.elements.dropdownMenu.style.display === 'block') {
            this.closeDropdown();
        } else {
            this.openDropdown();
        }
    }
    
    /**
     * Open dropdown
     */
    openDropdown() {
        if (this.elements.dropdownMenu) {
            this.elements.dropdownMenu.style.display = 'block';
            const dropdownArrow = document.querySelector('.dropdown-arrow');
            if (dropdownArrow) {
                dropdownArrow.classList.add('open');
            }
            console.log('Dropdown opened');
        }
    }
    
    /**
     * Close dropdown
     */
    closeDropdown() {
        if (this.elements.dropdownMenu) {
            this.elements.dropdownMenu.style.display = 'none';
            const dropdownArrow = document.querySelector('.dropdown-arrow');
            if (dropdownArrow) {
                dropdownArrow.classList.remove('open');
            }
            console.log('Dropdown closed');
        }
    }
    
    /**
     * Select a user
     */
    selectUser(user) {
        console.log('Selecting user:', user);
        this.selectedUser = user;
        
        // Update dropdown text
        if (this.elements.dropdownText) {
            this.elements.dropdownText.textContent = `👤 ${user}`;
        }
        
        // Save to localStorage
        localStorage.setItem('acmeChatbotSelectedUser', user);
        
        // Update send button state
        this.updateSendButtonState();
        
        // Add system message
        this.addMessage(`Switched to user: ${user}`, 'system');
        
        // Add a demo message to show copy/select functionality
        setTimeout(() => {
            this.addMessage('This is a demo message to show the copy and select functionality. You can click the 📋 button to copy this message or the 📝 button to select all the text.', 'bot');
        }, 1000);
        
        console.log('User selected:', user);
    }
    
    /**
     * Restore saved user from localStorage
     */
    restoreSavedUser() {
        const savedUser = localStorage.getItem('acmeChatbotSelectedUser');
        if (savedUser) {
            console.log('Restoring saved user:', savedUser);
            this.selectUser(savedUser);
        }
    }
    
    /**
     * Auto-resize textarea
     */
    autoResizeTextarea() {
        if (this.elements.messageInput) {
            this.elements.messageInput.style.height = 'auto';
            this.elements.messageInput.style.height = Math.min(this.elements.messageInput.scrollHeight, 120) + 'px';
        }
    }
    
    /**
     * Update send button state
     */
    updateSendButtonState() {
        if (!this.elements.sendButton || !this.elements.messageInput) {
            return;
        }
        
        const hasInput = this.elements.messageInput.value.trim().length > 0;
        const hasUser = this.selectedUser && this.selectedUser.length > 0;
        const isDisabled = !hasInput || !hasUser;
        
        this.elements.sendButton.disabled = isDisabled;
        
        console.log('Send button state updated:', {
            hasInput,
            hasUser,
            isDisabled,
            selectedUser: this.selectedUser,
            messageValue: this.elements.messageInput.value.trim()
        });
    }
    
    /**
     * Send message
     */
    async sendMessage() {
        if (!this.elements.messageInput || !this.selectedUser) {
            console.error('Cannot send message: missing input or user');
            return;
        }
        
        const message = this.elements.messageInput.value.trim();
        if (!message) {
            console.log('Empty message, not sending');
            return;
        }
        
        console.log('Sending message:', message, 'for user:', this.selectedUser);
        
        // Add user message to chat
        this.addMessage(message, 'user');
        
        // Clear input
        this.elements.messageInput.value = '';
        this.elements.messageInput.style.height = 'auto';
        
        // Update button state
        this.updateSendButtonState();
        
        // Show typing indicator
        this.showTypingIndicator();
        
        try {
            // Send to backend
            const response = await this.sendMessageToBackend(message, this.selectedUser);
            
            // Hide typing indicator
            this.hideTypingIndicator();
            
            if (response.error) {
                this.addMessage(`Error: ${response.error}`, 'error');
            } else {
                const backendText = response.reply || response.response || response.bot_reply || 
                                   response.answer || response.text || response.content || 
                                   response.data || response.message;
                const finalText = typeof backendText === 'string' ? backendText : 
                                 (backendText ? JSON.stringify(backendText) : '');
                this.addMessage(finalText || 'Unexpected server response', 'bot');
            }
        } catch (error) {
            console.error('Error sending message:', error);
            this.hideTypingIndicator();
            this.addMessage('Error: Failed to send message. Please try again.', 'error');
        }
    }
    
    /**
     * Send message to backend
     */
    async sendMessageToBackend(message, user) {
        // Get user info to use full name instead of username
        const userInfo = window.ChatBotUtils ? window.ChatBotUtils.getUserInfo() : {};
        const userFullName = userInfo.fullName || user || 'Unknown User';
        
        const requestData = {
            message: message,
            user: userFullName, // Use full name instead of username
            timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
        };
        
        console.log('Sending to backend:', requestData);
        console.log('Request URL:', `${this.API_BASE_URL}/api/chat/`);
        
        try {
            const response = await fetch(`${this.API_BASE_URL}/api/chat/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                },
                body: JSON.stringify(requestData)
            });
            
            console.log('Response status:', response.status);
            
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
    
    /**
     * Add message to chat
     */
    addMessage(text, type) {
        if (!this.elements.messagesContainer) {
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
        if (type === 'user') { 
            icon = '👤'; 
            senderLabel = 'You'; 
        } else if (type === 'bot') { 
            icon = '🤖'; 
            senderLabel = 'Acme Bot'; 
        } else if (type === 'system') { 
            icon = 'ℹ️'; 
            senderLabel = 'System'; 
        } else if (type === 'error') { 
            icon = '⚠️'; 
            senderLabel = 'Error'; 
        }
        
        // Create a unique ID for this message
        const messageId = `msg-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
        
        messageDiv.innerHTML = `
            <div class="message-avatar">${icon}</div>
            <div class="message-content">
                <div class="message-header">
                    <span class="message-sender">${senderLabel}</span>
                    <div class="message-actions">
                        <button class="copy-button" onclick="chatbotConnector.copyMessage('${messageId}')" title="Copy message">
                            <span class="copy-icon">📋</span>
                        </button>
                        <button class="select-button" onclick="chatbotConnector.selectMessage('${messageId}')" title="Select message text">
                            <span class="select-icon">📝</span>
                        </button>
                        <span class="message-time">${timeString}</span>
                    </div>
                </div>
                <div class="message-text selectable-text" id="${messageId}">${text}</div>
            </div>
        `;
        
        this.elements.messagesContainer.appendChild(messageDiv);
        this.scrollToBottom();
        
        console.log('Message added:', { text, type, time: timeString, messageId });
    }
    
    /**
     * Show typing indicator
     */
    showTypingIndicator() {
        if (this.elements.typingIndicator) {
            this.elements.typingIndicator.style.display = 'block';
        } else {
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
            this.elements.messagesContainer.appendChild(typingDiv);
        }
        this.scrollToBottom();
    }
    
    /**
     * Hide typing indicator
     */
    hideTypingIndicator() {
        if (this.elements.typingIndicator) {
            this.elements.typingIndicator.style.display = 'none';
        } else {
            const typingIndicator = document.getElementById('typing-indicator');
            if (typingIndicator) {
                typingIndicator.remove();
            }
        }
    }
    
    /**
     * Scroll to bottom
     */
    scrollToBottom() {
        setTimeout(() => {
            if (this.elements.messagesContainer) {
                this.elements.messagesContainer.scrollTop = this.elements.messagesContainer.scrollHeight;
            }
        }, 100);
    }
    
    /**
     * Show error message
     */
    showError(message) {
        if (this.elements.errorMessage) {
            this.elements.errorMessage.textContent = message;
            this.elements.errorMessage.style.display = 'block';
        }
        console.error('Error:', message);
    }
    
    /**
     * Hide error message
     */
    hideError() {
        if (this.elements.errorMessage) {
            this.elements.errorMessage.style.display = 'none';
        }
    }
    
    /**
     * Show success message
     */
    showSuccess(message) {
        if (this.elements.successMessage) {
            this.elements.successMessage.textContent = message;
            this.elements.successMessage.style.display = 'block';
            setTimeout(() => {
                this.elements.successMessage.style.display = 'none';
            }, 3000);
        }
    }
    
    /**
     * Copy message to clipboard
     */
    async copyMessage(messageId) {
        try {
            const messageElement = document.getElementById(messageId);
            if (!messageElement) {
                console.error('Message element not found:', messageId);
                return;
            }
            
            const messageText = messageElement.textContent || messageElement.innerText;
            
            // Use the modern Clipboard API if available
            if (navigator.clipboard && window.isSecureContext) {
                await navigator.clipboard.writeText(messageText);
                this.showCopyFeedback(messageId, true);
            } else {
                // Fallback for older browsers or non-secure contexts
                const textArea = document.createElement('textarea');
                textArea.value = messageText;
                textArea.style.position = 'fixed';
                textArea.style.left = '-999999px';
                textArea.style.top = '-999999px';
                document.body.appendChild(textArea);
                textArea.focus();
                textArea.select();
                
                try {
                    const successful = document.execCommand('copy');
                    if (successful) {
                        this.showCopyFeedback(messageId, true);
                    } else {
                        this.showCopyFeedback(messageId, false);
                    }
                } catch (err) {
                    console.error('Fallback copy failed:', err);
                    this.showCopyFeedback(messageId, false);
                } finally {
                    document.body.removeChild(textArea);
                }
            }
        } catch (error) {
            console.error('Copy failed:', error);
            this.showCopyFeedback(messageId, false);
        }
    }
    
    /**
     * Select message text
     */
    selectMessage(messageId) {
        try {
            const messageElement = document.getElementById(messageId);
            if (!messageElement) {
                console.error('Message element not found:', messageId);
                return;
            }
            
            // Create a range and select the text
            const range = document.createRange();
            range.selectNodeContents(messageElement);
            
            const selection = window.getSelection();
            selection.removeAllRanges();
            selection.addRange(range);
            
            // Show feedback
            this.showSelectFeedback(messageId);
            
            // Focus the element to ensure selection is visible
            messageElement.focus();
            
        } catch (error) {
            console.error('Select failed:', error);
        }
    }
    
    /**
     * Show copy feedback
     */
    showCopyFeedback(messageId, success) {
        const messageElement = document.getElementById(messageId);
        if (!messageElement) return;
        
        const copyButton = messageElement.closest('.message').querySelector('.copy-button');
        if (!copyButton) return;
        
        const originalIcon = copyButton.querySelector('.copy-icon');
        const originalText = originalIcon.textContent;
        
        if (success) {
            originalIcon.textContent = '✅';
            copyButton.classList.add('copy-success');
            setTimeout(() => {
                originalIcon.textContent = originalText;
                copyButton.classList.remove('copy-success');
            }, 2000);
        } else {
            originalIcon.textContent = '❌';
            copyButton.classList.add('copy-error');
            setTimeout(() => {
                originalIcon.textContent = originalText;
                copyButton.classList.remove('copy-error');
            }, 2000);
        }
    }
    
    /**
     * Show select feedback
     */
    showSelectFeedback(messageId) {
        const messageElement = document.getElementById(messageId);
        if (!messageElement) return;
        
        const selectButton = messageElement.closest('.message').querySelector('.select-button');
        if (!selectButton) return;
        
        const originalIcon = selectButton.querySelector('.select-icon');
        const originalText = originalIcon.textContent;
        
        originalIcon.textContent = '✓';
        selectButton.classList.add('select-success');
        setTimeout(() => {
            originalIcon.textContent = originalText;
            selectButton.classList.remove('select-success');
        }, 1500);
    }
    
    /**
     * Test backend connection (public method)
     */
    async testConnection() {
        console.log('Testing backend connection...');
        
        try {
            // Test users endpoint
            const usersResponse = await fetch(`${this.API_BASE_URL}/api/users/`);
            console.log('Users check:', usersResponse.ok ? 'SUCCESS' : 'FAILED');
            
            // Test chat endpoint
            const chatResponse = await fetch(`${this.API_BASE_URL}/api/chat/`, {
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
                users: usersResponse.ok,
                chat: chatResponse.ok
            };
        } catch (error) {
            console.error('Backend test failed:', error);
            return { error: error.message };
        }
    }
}

// Initialize the chatbot connector when the script loads
const chatbotConnector = new ChatBotConnector();

// Make it globally available
window.chatbotConnector = chatbotConnector;

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ChatBotConnector;
}
