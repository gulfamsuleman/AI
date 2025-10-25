<%@ Page Title="Home Page" Language="C#" MasterPageFile="Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="QProcess._Default" %>

<asp:Content runat="server" ID="BodyContent" ContentPlaceHolderID="MainContent">
 <!-- Chatbot Widget Start -->
    <link rel="stylesheet" href="Content/App.css" />
    <div class="chat-container" id="home-chatbot-widget">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap" rel="stylesheet" />

<div class="chat-container" id="chatContainer" runat="server">
    <div class="chat-header">
        <div class="chat-header-title">
            <div class="avatar">
                <div class="avatar-status online"></div>
            </div>
            <div>
                <h1>Q Bot</h1>
                <p class="status">Online</p>
                <p class="timezone" id="widgetTimezone" style="margin-top: 2px; font-size: 12px; color: #6b7280; display: none;">
                    🌍 <span id="widgetTimezoneText"></span>
                </p>
                <select id="userSelect" class="user-select" style="margin-top: 5px; padding: 2px 5px; font-size: 12px; border: 1px solid #e5e7eb; border-radius: 4px; background: white;">
                    <option value="">Loading users...</option>
                </select>
            </div>
        </div>
        <button type="button" class="minimize-btn" id="minimizeBtn" runat="server" aria-label="Minimize chat" onclick="return false;">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
        </button>
    </div>
    
    <div class="chat-messages" id="chatMessages" runat="server">
        <div class="message bot-message">
            <div class="message-content">
                <p>Hi there! 👋 How can I help you today?</p>
            </div>
            <span class="message-time">Just now</span>
        </div>
    </div>
    
    <div class="chat-input-container">
        <div class="input-wrapper">
            <input type="text" id="userInput" runat="server" placeholder="Type your message..." aria-label="Type your message" />
            <button type="button" id="sendBtn" runat="server" aria-label="Send message" onclick="return false;">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor"
                 stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-arrow-up-icon lucide-arrow-up">
                 <path d="m5 12 7-7 7 7"/><path d="M12 19V5"/>
                </svg>
            </button>
        </div>

    </div>
</div>

<button type="button" class="chat-toggle" id="chatToggle" runat="server" aria-label="Toggle chat" title="Click to toggle chat window" onclick="return false;">
    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
    </svg>
</button>

<script type="text/javascript">
(function () {
    try {
        var timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
        var tzContainer = document.getElementById('widgetTimezone');
        var tzText = document.getElementById('widgetTimezoneText');
        if (timezone && tzContainer && tzText) {
            tzText.textContent = timezone;
            tzContainer.style.display = 'block';
        }
    } catch (e) { /* noop */ }
})();
</script>


    </div>
    <button class="chat-toggle" id="chat-toggle" aria-label="Toggle chat" title="Click to toggle chat window">
        <!-- ...icon SVG... -->
    </button>
    <!-- Chatbot Widget End -->

    <script src="Scripts/chat_fix.js"></script>
    <!-- Copyright � 2024 Renegade Swish, LLC -->
</asp:Content>

