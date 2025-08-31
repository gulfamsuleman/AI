<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="DebugConnection.aspx.cs" Inherits="ChaatApp.DebugConnection" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>ChatBot Debug Connection</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 1000px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .debug-container {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        .debug-button {
            background: #007bff;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 4px;
            cursor: pointer;
            margin: 5px;
        }
        .debug-button:hover {
            background: #0056b3;
        }
        .debug-button.danger {
            background: #dc3545;
        }
        .debug-button.danger:hover {
            background: #c82333;
        }
        .debug-button.success {
            background: #28a745;
        }
        .debug-button.success:hover {
            background: #218838;
        }
        .result {
            margin-top: 10px;
            padding: 10px;
            border-radius: 4px;
            font-family: monospace;
            white-space: pre-wrap;
            max-height: 400px;
            overflow-y: auto;
        }
        .success {
            background: #d4edda;
            border: 1px solid #c3e6cb;
            color: #155724;
        }
        .error {
            background: #f8d7da;
            border: 1px solid #f5c6cb;
            color: #721c24;
        }
        .info {
            background: #d1ecf1;
            border: 1px solid #bee5eb;
            color: #0c5460;
        }
        .warning {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            color: #856404;
        }
        .status-indicator {
            display: inline-block;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            margin-right: 8px;
        }
        .status-online {
            background: #28a745;
        }
        .status-offline {
            background: #dc3545;
        }
        .status-unknown {
            background: #ffc107;
        }
        .log-entry {
            margin: 2px 0;
            padding: 2px 5px;
            border-radius: 3px;
            font-size: 12px;
        }
        .log-debug { background: #e9ecef; }
        .log-info { background: #d1ecf1; }
        .log-warn { background: #fff3cd; }
        .log-error { background: #f8d7da; }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="debug-container">
            <h1>ChatBot Debug Connection</h1>
            <p>This page helps debug connection issues between the ASP.NET frontend and Django backend.</p>
            
            <div>
                <span class="status-indicator" id="connectionStatus"></span>
                <span id="connectionText">Checking connection...</span>
            </div>
        </div>

        <div class="debug-container">
            <h2>Environment Information</h2>
            <div id="envInfo"></div>
        </div>

        <div class="debug-container">
            <h2>Configuration</h2>
            <div id="configInfo"></div>
        </div>

        <div class="debug-container">
            <h2>Connection Tests</h2>
            
            <button type="button" class="debug-button" onclick="testBasicConnection()">Test Basic Connection</button>
            <button type="button" class="debug-button" onclick="testUsersEndpoint()">Test Users Endpoint</button>
            <button type="button" class="debug-button" onclick="testChatEndpoint()">Test Chat Endpoint</button>
            <button type="button" class="debug-button success" onclick="testFullConnection()">Test Full Connection</button>
            <button type="button" class="debug-button danger" onclick="clearLogs()">Clear Logs</button>
            
            <div id="testResults"></div>
        </div>

        <div class="debug-container">
            <h2>Debug Logs</h2>
            <div id="debugLogs"></div>
        </div>

        <div class="debug-container">
            <h2>User Information</h2>
            <div id="userInfo"></div>
        </div>
    </form>

    <script src="Scripts/chatbot-config.js"></script>
    <script>
        let debugLogs = [];
        
        function addLog(level, message, data = null) {
            const timestamp = new Date().toLocaleTimeString();
            const logEntry = {
                timestamp,
                level,
                message,
                data
            };
            debugLogs.push(logEntry);
            updateDebugLogs();
        }
        
        function updateDebugLogs() {
            const logsDiv = document.getElementById('debugLogs');
            logsDiv.innerHTML = debugLogs.map(log => `
                <div class="log-entry log-${log.level}">
                    [${log.timestamp}] ${log.level.toUpperCase()}: ${log.message}
                    ${log.data ? '\n' + JSON.stringify(log.data, null, 2) : ''}
                </div>
            `).join('');
            logsDiv.scrollTop = logsDiv.scrollHeight;
        }
        
        function clearLogs() {
            debugLogs = [];
            updateDebugLogs();
        }
        
        function displayEnvironmentInfo() {
            const envDiv = document.getElementById('envInfo');
            envDiv.innerHTML = `
                <div class="result info">
Environment:
Protocol: ${window.location.protocol}
Hostname: ${window.location.hostname}
Port: ${window.location.port}
Full URL: ${window.location.href}
User Agent: ${navigator.userAgent}
                </div>
            `;
        }
        
        function displayConfig() {
            const configDiv = document.getElementById('configInfo');
            configDiv.innerHTML = `
                <div class="result info">
Configuration:
API Base URL: ${window.getChatBotConfig('API.BASE_URL')}
Debug Enabled: ${window.getChatBotConfig('DEBUG.ENABLED')}
Log Level: ${window.getChatBotConfig('DEBUG.LOG_LEVEL')}
Chat Endpoint: ${window.getChatBotConfig('API.ENDPOINTS.CHAT')}
Users Endpoint: ${window.getChatBotConfig('API.ENDPOINTS.USERS')}
                </div>
            `;
        }
        
        function displayUserInfo() {
            const userDiv = document.getElementById('userInfo');
            const userInfo = {
                userName: localStorage.getItem('userName'),
                fullName: localStorage.getItem('userFullName'),
                selectedUser: localStorage.getItem('acmeChatbotSelectedUser')
            };
            
            userDiv.innerHTML = `
                <div class="result info">
User Information:
User Name: ${userInfo.userName || 'Not set'}
Full Name: ${userInfo.fullName || 'Not set'}
Selected User: ${userInfo.selectedUser || 'Not set'}
                </div>
            `;
        }
        
        async function testBasicConnection() {
            addLog('info', 'Testing basic connection...');
            
            try {
                const response = await fetch('http://localhost:8000/api/users/', {
                    method: 'GET',
                    headers: {
                        'Accept': 'application/json',
                    }
                });
                
                if (response.ok) {
                    addLog('success', 'Basic connection successful', { status: response.status });
                    document.getElementById('testResults').innerHTML = `
                        <div class="result success">
✅ Basic Connection Test: SUCCESS
Status: ${response.status}
                        </div>
                    `;
                } else {
                    throw new Error(`HTTP ${response.status}`);
                }
            } catch (error) {
                addLog('error', 'Basic connection failed', { error: error.message });
                document.getElementById('testResults').innerHTML = `
                    <div class="result error">
❌ Basic Connection Test: FAILED
Error: ${error.message}
                        </div>
                `;
            }
        }
        
        async function testUsersEndpoint() {
            addLog('info', 'Testing users endpoint...');
            
            try {
                const response = await fetch('http://localhost:8000/api/users/', {
                    method: 'GET',
                    headers: {
                        'Accept': 'application/json',
                    }
                });
                
                if (response.ok) {
                    const users = await response.json();
                    addLog('success', 'Users endpoint successful', { users });
                    document.getElementById('testResults').innerHTML = `
                        <div class="result success">
✅ Users Endpoint Test: SUCCESS
Status: ${response.status}
Users Found: ${users.length}
Users: ${JSON.stringify(users, null, 2)}
                        </div>
                    `;
                } else {
                    throw new Error(`HTTP ${response.status}`);
                }
            } catch (error) {
                addLog('error', 'Users endpoint failed', { error: error.message });
                document.getElementById('testResults').innerHTML = `
                    <div class="result error">
❌ Users Endpoint Test: FAILED
Error: ${error.message}
                        </div>
                `;
            }
        }
        
                 async function testChatEndpoint() {
             addLog('info', 'Testing chat endpoint...');
             
             // Get user info for testing
             const userInfo = {
                 userName: localStorage.getItem('userName'),
                 fullName: localStorage.getItem('userFullName')
             };
             const testUser = userInfo.fullName || userInfo.userName || 'Debug User';
             
             addLog('info', `Using user for test: ${testUser}`, userInfo);
             
             try {
                 const response = await fetch('http://localhost:8000/api/chat/', {
                     method: 'POST',
                     headers: {
                         'Content-Type': 'application/json',
                         'Accept': 'application/json',
                     },
                     body: JSON.stringify({
                         message: 'Test message from debug page',
                         user: testUser,
                         timezone: 'UTC'
                     })
                 });
                
                if (response.ok) {
                    const data = await response.json();
                    addLog('success', 'Chat endpoint successful', { data });
                    document.getElementById('testResults').innerHTML = `
                        <div class="result success">
✅ Chat Endpoint Test: SUCCESS
Status: ${response.status}
Response: ${JSON.stringify(data, null, 2)}
                        </div>
                    `;
                } else {
                    const errorText = await response.text();
                    throw new Error(`HTTP ${response.status}: ${errorText}`);
                }
            } catch (error) {
                addLog('error', 'Chat endpoint failed', { error: error.message });
                document.getElementById('testResults').innerHTML = `
                    <div class="result error">
❌ Chat Endpoint Test: FAILED
Error: ${error.message}
                        </div>
                `;
            }
        }
        
        async function testFullConnection() {
            addLog('info', 'Testing full connection...');
            
            const results = {
                basic: false,
                users: false,
                chat: false,
                errors: []
            };
            
            // Test basic connection
            try {
                const basicResponse = await fetch('http://localhost:8000/api/users/');
                results.basic = basicResponse.ok;
                if (!basicResponse.ok) {
                    results.errors.push(`Basic connection failed: ${basicResponse.status}`);
                }
            } catch (error) {
                results.errors.push(`Basic connection error: ${error.message}`);
            }
            
            // Test users endpoint
            try {
                const usersResponse = await fetch('http://localhost:8000/api/users/');
                results.users = usersResponse.ok;
                if (!usersResponse.ok) {
                    results.errors.push(`Users endpoint failed: ${usersResponse.status}`);
                }
            } catch (error) {
                results.errors.push(`Users endpoint error: ${error.message}`);
            }
            
                         // Test chat endpoint
             try {
                 // Get user info for testing
                 const userInfo = {
                     userName: localStorage.getItem('userName'),
                     fullName: localStorage.getItem('userFullName')
                 };
                 const testUser = userInfo.fullName || userInfo.userName || 'Test User';
                 
                 addLog('info', `Using user for full connection test: ${testUser}`);
                 
                 const chatResponse = await fetch('http://localhost:8000/api/chat/', {
                     method: 'POST',
                     headers: {
                         'Content-Type': 'application/json',
                     },
                     body: JSON.stringify({
                         message: 'Test message',
                         user: testUser,
                         timezone: 'UTC'
                     })
                 });
                results.chat = chatResponse.ok;
                if (!chatResponse.ok) {
                    results.errors.push(`Chat endpoint failed: ${chatResponse.status}`);
                }
            } catch (error) {
                results.errors.push(`Chat endpoint error: ${error.message}`);
            }
            
            // Display results
            const allSuccess = results.basic && results.users && results.chat;
            const resultClass = allSuccess ? 'success' : 'error';
            const resultIcon = allSuccess ? '✅' : '❌';
            
            addLog(allSuccess ? 'success' : 'error', 'Full connection test completed', results);
            
            document.getElementById('testResults').innerHTML = `
                <div class="result ${resultClass}">
${resultIcon} Full Connection Test: ${allSuccess ? 'SUCCESS' : 'FAILED'}
Basic Connection: ${results.basic ? '✅' : '❌'}
Users Endpoint: ${results.users ? '✅' : '❌'}
Chat Endpoint: ${results.chat ? '✅' : '❌'}
${results.errors.length > 0 ? 'Errors:\n' + results.errors.join('\n') : ''}
                </div>
            `;
            
            // Update connection status
            updateConnectionStatus(allSuccess);
        }
        
        function updateConnectionStatus(isConnected) {
            const statusIndicator = document.getElementById('connectionStatus');
            const statusText = document.getElementById('connectionText');
            
            if (isConnected) {
                statusIndicator.className = 'status-indicator status-online';
                statusText.textContent = 'Backend Connected';
            } else {
                statusIndicator.className = 'status-indicator status-offline';
                statusText.textContent = 'Backend Disconnected';
            }
        }
        
        // Initialize page
        document.addEventListener('DOMContentLoaded', function() {
            addLog('info', 'Debug page loaded');
            displayEnvironmentInfo();
            displayConfig();
            displayUserInfo();
            testFullConnection();
        });
    </script>
</body>
</html>
