<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ChatBot.aspx.cs" Inherits="ChaatApp.Chatpage" Async="true" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Acme Chatbot</title>
    <link href="Content/App.css" rel="stylesheet" />
    <script src="Scripts/jquery-3.7.0.min.js"></script>
    <script src="Scripts/chatbot-config.js"></script>
    <script src="Scripts/chatbot-connector.js"></script>
</head> 
<body>
    <form id="form1" runat="server">
        <asp:ScriptManager runat="server" EnablePageMethods="true" EnablePartialRendering="false" />
        <div class="app-container">
            <div class="chat-container">
                <!-- Enhanced Header -->
                <div class="chat-header">
                    <div class="header-content">
                        <div class="logo-section">
                            <div class="logo-icon">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
                                </svg>
                            </div>
                            <h1>Acme Chatbot</h1>
                        </div>
                        <div class="timezone-badge" id="timezoneBadge" style="display: none;">
                            <span class="timezone-icon">🌍</span>
                            <span class="timezone-text" id="timezoneText"></span>
                        </div>
                    </div>
                </div>

                <!-- Enhanced Chat Box -->
                <div class="chat-box" id="chatBox">
                    <div class="welcome-message" id="welcomeMessage">
                        <div class="welcome-icon">👋</div>
                        <h3>Welcome to Acme Chatbot!</h3>
                        <p>Select a user and start chatting to get started.</p>
                    </div>
                    
                    <!-- Storage Notification -->
                    <div class="storage-notification" id="storageNotification" style="display: none;">
                        <span class="storage-icon">💾</span>
                        <span>Welcome back! Your previous user selection has been restored.</span>
                    </div>
                    
                    <div id="messagesContainer"></div>
                    
                    <div class="message bot-msg typing-indicator" id="typingIndicator" style="display: none;">
                        <div class="message-avatar">🤖</div>
                        <div class="message-content">
                            <div class="typing-text" id="typingText">Bot is thinking...</div>
                            <div class="typing-dots">
                                <span></span>
                                <span></span>
                                <span></span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Success/Error Messages -->
                <div class="success-message" id="successMessage" style="display: none;">
                    <span class="success-icon">✅</span>
                    <span>Task Created Successfully!</span>
                </div>
                
                <div class="error-message" id="errorMessage" style="display: none;">
                    <span class="error-icon">⚠️</span>
                    <span id="errorText"></span>
                </div>

                <!-- Enhanced Chat Form -->
                <div class="chat-form">
                    <!-- User Selection - Custom Dropdown -->
                    <div class="user-selection-section">
                        <div class="custom-dropdown" id="userDropdown">
                            <button type="button" class="dropdown-trigger" id="dropdownTrigger">
                                <span class="dropdown-text" id="dropdownText">👤 Select User</span>
                                <span class="dropdown-indicator" id="dropdownIndicator" style="display: none;">💾</span>
                                <svg class="dropdown-arrow" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M6 9l6 6 6-6"/>
                                </svg>
                            </button>
                            
                            <div class="dropdown-menu" id="dropdownMenu" style="display: none;">
                                <asp:Repeater ID="UsersRepeater" runat="server">
                                    <ItemTemplate>
                                        <button type="button" class="dropdown-option" data-user="<%# Eval("Name") %>">
                                            👤 <%# Eval("Name") %>
                                        </button>
                                    </ItemTemplate>
                                </asp:Repeater>
                            </div>
                        </div>
                    </div>
                    
                    <div class="input-row">
                        <div class="textarea-wrapper">
                            <textarea id="messageInput" 
                                      class="message-input auto-resize" 
                                      placeholder="Type your message... (Enter to send, Shift+Enter for new line)"
                                      rows="1"></textarea>
                        </div>
                        <div class="button-group">
                            <button type="button" id="sendButton" class="send-button" disabled>
                                <span class="send-icon">📤</span>
                                <span class="send-text">Send</span>
                            </button>
                        </div>
                    </div>
                    

                </div>
            </div>
        </div>
        
        <!-- Hidden fields for server communication -->
        <asp:HiddenField ID="hdnSelectedUser" runat="server" />
        <asp:HiddenField ID="hdnUserTimezone" runat="server" />
        <asp:HiddenField ID="hdnApiBaseUrl" runat="server" />
    </form>
    <script type="text/javascript">
    (function initTimezoneBadge(){
        function setTimezone() {
            try {
                var tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
                var tzBadge = document.getElementById('timezoneBadge');
                var tzText = document.getElementById('timezoneText');
                if (tz && tzBadge && tzText) {
                    tzText.textContent = tz;
                    tzBadge.style.display = 'flex';
                    if (window.console && console.debug) {
                        console.debug('Timezone badge initialized:', tz);
                    }
                }
            } catch (e) { }
        }
        if (document.readyState !== 'loading') {
            setTimezone();
        } else {
            document.addEventListener('DOMContentLoaded', setTimezone);
        }
        window.addEventListener('load', setTimezone);
    })();
    </script>
</body>
</html>