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
            saveOpenState();
        } else {
            // Open chat
            chatContainer.classList.add('open');
            saveOpenState();
            
            // Update chat header with user name if available
            const userInfo = getUserInfo();
            if (userInfo.fullName) {
                const chatHeader = document.querySelector('.chat-header h1');
                if (chatHeader) {
                    chatHeader.textContent = `Q Bot - ${userInfo.fullName}`;
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

    // Persist open/close state
    function saveOpenState() {
        try {
            const isOpenNow = chatContainer.classList.contains('open');
            localStorage.setItem('chatbot-open', isOpenNow ? 'true' : 'false');
        } catch (e) { /* no-op */ }
    }

    function loadOpenState() {
        try {
            const saved = localStorage.getItem('chatbot-open');
            if (saved === 'true') {
                // Set open state without toggling
                chatContainer.classList.add('open');
                
                // Update chat header with user name if available
                const userInfo = getUserInfo();
                if (userInfo.fullName) {
                    const chatHeader = document.querySelector('.chat-header h1');
                    if (chatHeader) {
                        chatHeader.textContent = `Q Bot - ${userInfo.fullName}`;
                    }
                }
            } else if (saved === 'false') {
                chatContainer.classList.remove('open');
            }
        } catch (e) { /* no-op */ }
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
        saveOpenState();
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
        // Reset textarea height after send
        userInput.style.height = 'auto';
        userInput.style.overflowY = 'hidden';

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
    function addMessage(text, sender, options) {
        const messageDiv = document.createElement('div');
        messageDiv.classList.add('message', `${sender}-message`);

        const now = new Date();
        const timeString = (options && options.time) ? options.time : (now.getHours() + ':' + (now.getMinutes() < 10 ? '0' : '') + now.getMinutes());

        // Decide rendering: user -> plain text; bot -> Markdown (sanitized)
        let contentHtml = '';
        if (sender === 'bot' && window.marked && window.DOMPurify) {
            try {
                // Configure marked for safe output (no header IDs, no mangle)
                if (window.marked && typeof window.marked.setOptions === 'function') {
                    window.marked.setOptions({ mangle: false, headerIds: false, breaks: true });
                }
                const rawHtml = window.marked.parse(String(text || ''));
                contentHtml = window.DOMPurify.sanitize(rawHtml, { USE_PROFILES: { html: true } });
            } catch (e) {
                contentHtml = '';
            }
        }

        // Fallback or user message: escape and wrap in <p>
        if (!contentHtml) {
            const escaped = String(text || '').replace(/[&<>]/g, function (ch) {
                return ch === '&' ? '&amp;' : ch === '<' ? '&lt;' : ch === '>' ? '&gt;' : ch;
            });
            // Minimal newline to <br> for readability in user messages
            contentHtml = `<p>${escaped.replace(/\n/g, '<br/>')}</p>`;
        }

        messageDiv.innerHTML = `
            <div class="message-content">${contentHtml}</div>
            <div class="message-actions">
                <button type="button" class="copy-btn" title="Copy message" aria-label="Copy message">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-copy-icon lucide-copy"><rect width="14" height="14" x="8" y="8" rx="2" ry="2"></rect><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"></path></svg>
                </button>
            </div>
            <span class="message-time">${timeString}</span>
        `;

        chatMessages.appendChild(messageDiv);
        scrollToBottom();
        
        // Persist to history unless explicitly skipped
        if (!options || !options.skipSave) {
            saveMessageToHistory({ text: text, sender: sender, time: timeString });
        }
        
        // Update clear button visibility
        updateClearButtonVisibility();
    }

    // Clipboard helpers and event delegation for copy buttons
    function copyTextToClipboard(text) {
        if (!text) return;
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(text).catch(function() { fallbackCopyText(text); });
        } else {
            fallbackCopyText(text);
        }
    }

    function fallbackCopyText(text) {
        const textarea = document.createElement('textarea');
        textarea.value = text;
        textarea.setAttribute('readonly', '');
        textarea.style.position = 'absolute';
        textarea.style.left = '-9999px';
        document.body.appendChild(textarea);
        textarea.select();
        try { document.execCommand('copy'); } catch (e) {}
        document.body.removeChild(textarea);
    }

    // Local storage: history key per user
    function getHistoryStorageKey() {
        const info = getUserInfo();
        const userKey = (info.fullName || info.userName || 'anonymous').toString().trim().toLowerCase();
        return `chatbot-history-${userKey}`;
    }

    function getSavedHistory() {
        try {
            const key = getHistoryStorageKey();
            const raw = localStorage.getItem(key);
            if (!raw) return [];
            const parsed = JSON.parse(raw);
            return Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            return [];
        }
    }

    function saveMessageToHistory(entry) {
        try {
            const key = getHistoryStorageKey();
            const history = getSavedHistory();
            history.push({
                text: entry.text,
                sender: entry.sender,
                time: entry.time
            });
            // Optional cap to avoid unbounded growth
            const MAX_MESSAGES = 500;
            const trimmed = history.length > MAX_MESSAGES ? history.slice(history.length - MAX_MESSAGES) : history;
            localStorage.setItem(key, JSON.stringify(trimmed));
        } catch (e) {
            // no-op
        }
    }

    function loadChatHistory() {
        const history = getSavedHistory();
        if (!history.length) {
            // Ensure clear button reflects empty state
            updateClearButtonVisibility();
            return;
        }
        // Remove any existing rendered messages (keep container)
        while (chatMessages.firstChild) {
            chatMessages.removeChild(chatMessages.firstChild);
        }
        // Render from history without re-saving
        for (let i = 0; i < history.length; i++) {
            const item = history[i];
            if (!item || typeof item.text !== 'string' || typeof item.sender !== 'string') continue;
            addMessage(item.text, item.sender, { skipSave: true, time: item.time });
        }
        updateClearButtonVisibility();
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

    // Auto-resize textarea function
    function autoResize(textarea) {
        // Reset height to auto to get the correct scrollHeight
        textarea.style.height = 'auto';
        // Set height to scrollHeight to fit content
        textarea.style.height = textarea.scrollHeight + 'px';
        
        // Limit maximum height (e.g., 120px for about 5 lines)
        const maxHeight = 120;
        if (textarea.scrollHeight > maxHeight) {
            textarea.style.height = maxHeight + 'px';
            textarea.style.overflowY = 'auto';
        } else {
            textarea.style.overflowY = 'hidden';
        }
    }

    // Event listeners
    sendBtn.addEventListener('click', sendMessage);
    
    userInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            sendMessage();
        }
    });

    // Auto-resize on input
    userInput.addEventListener('input', function() {
        autoResize(this);
    });

    // Auto-resize on paste
    userInput.addEventListener('paste', function() {
        // Use setTimeout to allow paste content to be processed
        setTimeout(() => {
            autoResize(this);
        }, 0);
    });

    // Event delegation: handle copy button clicks
    if (chatMessages) {
        chatMessages.addEventListener('click', function(e) {
            const copyButton = e.target && e.target.closest('.copy-btn');
            if (!copyButton) return;
            const messageRoot = copyButton.closest('.message');
            if (!messageRoot) return;
            const container = messageRoot.querySelector('.message-content');
            const text = container ? container.innerText : '';
            copyTextToClipboard(text);
            // brief feedback via icon swap and disabled state
            const originalHTML = copyButton.innerHTML;
            const originalTitle = copyButton.getAttribute('title') || 'Copy message';
            copyButton.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-check-icon lucide-check"><path d="M20 6 9 17l-5-5"></path></svg>';
            copyButton.setAttribute('title', 'Copied');
            copyButton.disabled = true;
            setTimeout(function() {
                copyButton.innerHTML = originalHTML;
                copyButton.setAttribute('title', originalTitle);
                copyButton.disabled = false;
            }, 1200);
        });
    }

    // Drag functionality for chat container
    let isDragging = false;
    let dragOffset = { x: 0, y: 0 };
    let currentPosition = { x: 0, y: 0 };
    let isMaximized = false;
    let previousPosition = { x: 0, y: 0 };
    let previousSize = { width: 0, height: 0 };

    // Load saved position from localStorage
    function loadSavedPosition() {
        const savedPosition = localStorage.getItem('chatbot-position');
        if (savedPosition) {
            const position = JSON.parse(savedPosition);
            currentPosition = position;
            applyPosition();
        }
    }

    // Load saved maximized state from localStorage
    function loadMaximizedState() {
        const savedMaximized = localStorage.getItem('chatbot-maximized');
        if (savedMaximized === 'true') {
            // Small delay to ensure DOM is ready
            setTimeout(() => {
                maximizeToFullScreen();
            }, 100);
        }
    }

    // Save position to localStorage
    function savePosition() {
        localStorage.setItem('chatbot-position', JSON.stringify(currentPosition));
    }

    // Apply current position to chat container
    function applyPosition() {
        chatContainer.style.left = currentPosition.x + 'px';
        chatContainer.style.top = currentPosition.y + 'px';
        chatContainer.style.right = 'auto';
        chatContainer.style.bottom = 'auto';
        chatContainer.style.transform = 'none';
    }

    // Initialize drag functionality
    function initDragFunctionality() {
        const chatHeader = document.querySelector('.chat-header');
        const resetBtn = document.getElementById('reset-position-btn');
        const clearBtn = document.getElementById('clear-chat-btn');
        const maximizeBtn = document.getElementById('maximize-btn');
        
        if (!chatHeader) return;

        // Make header draggable
        chatHeader.style.cursor = 'move';
        chatHeader.setAttribute('title', 'Drag to move chat window');

        // Mouse events for dragging
        chatHeader.addEventListener('mousedown', startDrag);
        document.addEventListener('mousemove', drag);
        document.addEventListener('mouseup', endDrag);

        // Touch events for mobile dragging
        chatHeader.addEventListener('touchstart', startDragTouch, { passive: false });
        document.addEventListener('touchmove', dragTouch, { passive: false });
        document.addEventListener('touchend', endDrag);

        // Reset button click event
        if (resetBtn) {
            resetBtn.addEventListener('click', resetPosition);
        }

        // Clear chat button click event
        if (clearBtn) {
            clearBtn.addEventListener('click', clearChatHistory);
        }

        // Maximize button click event
        if (maximizeBtn) {
            maximizeBtn.addEventListener('click', toggleMaximize);
        }

        // Modal button event listeners
        const cancelBtn = document.getElementById('cancel-clear');
        const confirmBtn = document.getElementById('confirm-clear');
        const modal = document.getElementById('confirmation-modal');

        if (cancelBtn) {
            cancelBtn.addEventListener('click', hideConfirmationModal);
        }

        if (confirmBtn) {
            confirmBtn.addEventListener('click', executeChatClearing);
        }

        // Close modal when clicking overlay
        if (modal) {
            modal.addEventListener('click', function(e) {
                if (e.target === modal || e.target.classList.contains('confirmation-overlay')) {
                    hideConfirmationModal();
                }
            });
        }

        // Close modal with Escape key
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape' && modal && modal.style.display === 'flex') {
                hideConfirmationModal();
            }
        });

        // Keyboard shortcut for maximize (F11)
        document.addEventListener('keydown', function(e) {
            if (e.key === 'F11' && chatContainer.classList.contains('open')) {
                e.preventDefault();
                toggleMaximize();
            }
        });

        // Load saved position
        loadSavedPosition();
        
        // Load saved maximized state
        loadMaximizedState();
        
        // Initialize clear button visibility
        updateClearButtonVisibility();
    }

    // Start dragging (mouse)
    function startDrag(e) {
        if (e.target.closest('.minimize-btn') || e.target.closest('.reset-position-btn') || e.target.closest('.clear-chat-btn') || e.target.closest('.maximize-btn')) return; // Don't drag when clicking buttons
        if (isMaximized) return; // Don't drag when maximized
        
        isDragging = true;
        chatContainer.classList.add('dragging');
        
        const rect = chatContainer.getBoundingClientRect();
        dragOffset.x = e.clientX - rect.left;
        dragOffset.y = e.clientY - rect.top;
        
        e.preventDefault();
    }

    // Start dragging (touch)
    function startDragTouch(e) {
        if (e.target.closest('.minimize-btn') || e.target.closest('.reset-position-btn') || e.target.closest('.clear-chat-btn') || e.target.closest('.maximize-btn')) return;
        if (isMaximized) return; // Don't drag when maximized
        
        isDragging = true;
        chatContainer.classList.add('dragging');
        
        const touch = e.touches[0];
        const rect = chatContainer.getBoundingClientRect();
        dragOffset.x = touch.clientX - rect.left;
        dragOffset.y = touch.clientY - rect.top;
        
        e.preventDefault();
    }

    // Drag (mouse)
    function drag(e) {
        if (!isDragging) return;
        
        e.preventDefault();
        
        const newX = e.clientX - dragOffset.x;
        const newY = e.clientY - dragOffset.y;
        
        // Constrain to viewport
        const maxX = window.innerWidth - chatContainer.offsetWidth;
        const maxY = window.innerHeight - chatContainer.offsetHeight;
        
        currentPosition.x = Math.max(0, Math.min(newX, maxX));
        currentPosition.y = Math.max(0, Math.min(newY, maxY));
        
        applyPosition();
    }

    // Drag (touch)
    function dragTouch(e) {
        if (!isDragging) return;
        
        e.preventDefault();
        
        const touch = e.touches[0];
        const newX = touch.clientX - dragOffset.x;
        const newY = touch.clientY - dragOffset.y;
        
        // Constrain to viewport
        const maxX = window.innerWidth - chatContainer.offsetWidth;
        const maxY = window.innerHeight - chatContainer.offsetHeight;
        
        currentPosition.x = Math.max(0, Math.min(newX, maxX));
        currentPosition.y = Math.max(0, Math.min(newY, maxY));
        
        applyPosition();
    }

    // End dragging
    function endDrag() {
        if (!isDragging) return;
        
        isDragging = false;
        chatContainer.classList.remove('dragging');
        savePosition();
    }

    // Reset position to default
    function resetPosition() {
        const resetBtn = document.getElementById('reset-position-btn');
        
        // Add visual feedback
        if (resetBtn) {
            resetBtn.style.transform = 'scale(0.9)';
            setTimeout(() => {
                resetBtn.style.transform = 'scale(1)';
            }, 150);
        }
        
        currentPosition = { x: 0, y: 0 };
        chatContainer.style.left = 'auto';
        chatContainer.style.top = 'auto';
        chatContainer.style.right = '20px';
        chatContainer.style.bottom = '80px';
        chatContainer.style.transform = 'translateY(0)';
        localStorage.removeItem('chatbot-position');
    }

    // Toggle maximize/minimize
    function toggleMaximize() {
        const maximizeBtn = document.getElementById('maximize-btn');
        
        // Add visual feedback
        if (maximizeBtn) {
            maximizeBtn.style.transform = 'scale(0.9)';
            setTimeout(() => {
                maximizeBtn.style.transform = 'scale(1)';
            }, 150);
        }
        
        if (isMaximized) {
            // Restore to previous size and position
            restoreFromMaximized();
        } else {
            // Maximize to full screen
            maximizeToFullScreen();
        }
    }

    // Maximize to full screen
    function maximizeToFullScreen() {
        // Store current position and size
        const rect = chatContainer.getBoundingClientRect();
        previousPosition = { x: rect.left, y: rect.top };
        previousSize = { width: rect.width, height: rect.height };
        
        // Add maximized class
        chatContainer.classList.add('maximized');
        isMaximized = true;
        
        // Update button tooltip
        const maximizeBtn = document.getElementById('maximize-btn');
        if (maximizeBtn) {
            maximizeBtn.setAttribute('title', 'Restore chat window');
        }
        
        // Prevent body scrolling when maximized
        document.body.style.overflow = 'hidden';
        
        // Save maximized state
        localStorage.setItem('chatbot-maximized', 'true');
    }

    // Restore from maximized state
    function restoreFromMaximized() {
        // Remove maximized class
        chatContainer.classList.remove('maximized');
        isMaximized = false;
        
        // Restore previous position
        if (previousPosition.x > 0 || previousPosition.y > 0) {
            chatContainer.style.left = previousPosition.x + 'px';
            chatContainer.style.top = previousPosition.y + 'px';
            chatContainer.style.right = 'auto';
            chatContainer.style.bottom = 'auto';
            chatContainer.style.transform = 'none';
        } else {
            // Restore to default position
            chatContainer.style.left = 'auto';
            chatContainer.style.top = 'auto';
            chatContainer.style.right = '20px';
            chatContainer.style.bottom = '80px';
            chatContainer.style.transform = 'translateY(0)';
        }
        
        // Update button tooltip
        const maximizeBtn = document.getElementById('maximize-btn');
        if (maximizeBtn) {
            maximizeBtn.setAttribute('title', 'Maximize chat window');
        }
        
        // Restore body scrolling
        document.body.style.overflow = '';
        
        // Remove maximized state from storage
        localStorage.removeItem('chatbot-maximized');
    }

    // Update clear button visibility based on message count
    function updateClearButtonVisibility() {
        const chatMessages = document.getElementById('chat-messages');
        const clearBtn = document.getElementById('clear-chat-btn');
        
        if (chatMessages && clearBtn) {
            const messages = chatMessages.querySelectorAll('.message:not(.bot-message:first-child)');
            const hasMessages = messages.length > 0;
            
            // Update button title based on whether there are messages to clear
            clearBtn.setAttribute('title', hasMessages ? 'Clear chat history' : 'No messages to clear');
            clearBtn.disabled = !hasMessages;
            
            // Update button opacity
            clearBtn.style.opacity = hasMessages ? '1' : '0.5';
        }
    }

    // Show confirmation modal
    function showConfirmationModal() {
        const modal = document.getElementById('confirmation-modal');
        if (modal) {
            modal.style.display = 'flex';
            document.body.style.overflow = 'hidden'; // Prevent background scrolling
            
            // Focus on cancel button for accessibility
            const cancelBtn = document.getElementById('cancel-clear');
            if (cancelBtn) {
                setTimeout(() => cancelBtn.focus(), 100);
            }
        }
    }

    // Hide confirmation modal
    function hideConfirmationModal() {
        const modal = document.getElementById('confirmation-modal');
        if (modal) {
            modal.style.display = 'none';
            document.body.style.overflow = ''; // Restore scrolling
        }
    }

    // Clear chat history
    function clearChatHistory() {
        const clearBtn = document.getElementById('clear-chat-btn');
        const chatMessages = document.getElementById('chat-messages');
        
        // Check if there are messages to clear
        if (chatMessages) {
            const messages = chatMessages.querySelectorAll('.message:not(.bot-message:first-child)');
            if (messages.length === 0) {
                return; // No messages to clear
            }
        }
        
        // Add visual feedback
        if (clearBtn) {
            clearBtn.style.transform = 'scale(0.9)';
            setTimeout(() => {
                clearBtn.style.transform = 'scale(1)';
            }, 150);
        }
        
        // Show custom confirmation modal
        showConfirmationModal();
    }

    // Execute chat clearing
    function executeChatClearing() {
        // Clear all messages from chat
        const chatMessages = document.getElementById('chat-messages');
        if (chatMessages) {
            // Remove all messages except the welcome message
            const messages = chatMessages.querySelectorAll('.message:not(.bot-message:first-child)');
            messages.forEach(message => message.remove());
            
            // Reset the welcome message to show it's a fresh start
            const welcomeMessage = chatMessages.querySelector('.bot-message:first-child .message-content p');
            if (welcomeMessage) {
                welcomeMessage.textContent = 'Hi there! 👋 How can I help you today?';
            }
            
            // Clear the input field
            const userInput = document.getElementById('user-input');
            if (userInput) {
                userInput.value = '';
                // Reset textarea height
                userInput.style.height = 'auto';
            }
            
            // Scroll to top
            chatMessages.scrollTop = 0;
            
            // Clear any typing indicators
            const typingIndicator = document.getElementById('typing-indicator');
            if (typingIndicator) {
                typingIndicator.remove();
            }
            
            // Update clear button visibility
            updateClearButtonVisibility();
        }
        
        // Remove persisted history
        try {
            localStorage.removeItem(getHistoryStorageKey());
        } catch (e) {
            // no-op
        }
        
        // Hide modal
        hideConfirmationModal();
    }

    // Handle window resize to keep chat container in viewport
    window.addEventListener('resize', function() {
        if (isMaximized) {
            // If maximized, ensure it stays full screen
            chatContainer.classList.add('maximized');
        } else if (currentPosition.x > 0 || currentPosition.y > 0) {
            const maxX = window.innerWidth - chatContainer.offsetWidth;
            const maxY = window.innerHeight - chatContainer.offsetHeight;
            
            currentPosition.x = Math.max(0, Math.min(currentPosition.x, maxX));
            currentPosition.y = Math.max(0, Math.min(currentPosition.y, maxY));
            
            applyPosition();
            savePosition();
        }
    });

    // Initialize drag functionality when DOM is ready
    initDragFunctionality();

    // Restore open/close state
    loadOpenState();

    // Load any saved chat history after initializing UI
    try {
        loadChatHistory();
    } catch (e) {
        // no-op
    }

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