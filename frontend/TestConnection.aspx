<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="TestConnection.aspx.cs" Inherits="ChaatApp.TestConnection" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>ChatBot Connection Test</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .test-container {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        .test-button {
            background: #007bff;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 4px;
            cursor: pointer;
            margin: 5px;
        }
        .test-button:hover {
            background: #0056b3;
        }
        .test-button:disabled {
            background: #6c757d;
            cursor: not-allowed;
        }
        .result {
            margin-top: 10px;
            padding: 10px;
            border-radius: 4px;
            font-family: monospace;
            white-space: pre-wrap;
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
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="test-container">
            <h1>ChatBot Backend Connection Test</h1>
            <p>This page tests the connection between the ASP.NET frontend and Django backend.</p>
            
            <div>
                <span class="status-indicator" id="connectionStatus"></span>
                <span id="connectionText">Checking connection...</span>
            </div>
        </div>

        <div class="test-container">
            <h2>API Endpoint Tests</h2>
            
            <button type="button" class="test-button" onclick="testUsersEndpoint()">Test Users Endpoint</button>
            <button type="button" class="test-button" onclick="testChatEndpoint()">Test Chat Endpoint</button>
            <button type="button" class="test-button" onclick="testFullConnection()">Test Full Connection</button>
            
            <div id="testResults"></div>
        </div>

        <div class="test-container">
            <h2>Configuration</h2>
            <div id="configInfo"></div>
        </div>
    </form>

    <script src="Scripts/chatbot-config.js"></script>
    <script>
        // Test functions
        async function testUsersEndpoint() {
            const resultsDiv = document.getElementById('testResults');
            resultsDiv.innerHTML = '<div class="result info">Testing Users Endpoint...</div>';
            
            try {
                const response = await fetch('http://localhost:8000/api/users/', {
                    method: 'GET',
                    headers: {
                        'Accept': 'application/json',
                    }
                });
                
                if (response.ok) {
                    const users = await response.json();
                    resultsDiv.innerHTML = `
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
                resultsDiv.innerHTML = `
                    <div class="result error">
❌ Users Endpoint Test: FAILED
Error: ${error.message}
                    </div>
                `;
            }
        }

        async function testChatEndpoint() {
            const resultsDiv = document.getElementById('testResults');
            resultsDiv.innerHTML = '<div class="result info">Testing Chat Endpoint...</div>';
            
            try {
                const response = await fetch('http://localhost:8000/api/chat/', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                    },
                    body: JSON.stringify({
                        message: 'Test message from frontend',
                        user: 'Test User',
                        timezone: 'UTC'
                    })
                });
                
                if (response.ok) {
                    const data = await response.json();
                    resultsDiv.innerHTML = `
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
                resultsDiv.innerHTML = `
                    <div class="result error">
❌ Chat Endpoint Test: FAILED
Error: ${error.message}
                    </div>
                `;
            }
        }

        async function testFullConnection() {
            const resultsDiv = document.getElementById('testResults');
            resultsDiv.innerHTML = '<div class="result info">Testing Full Connection...</div>';
            
            const results = {
                users: false,
                chat: false,
                errors: []
            };
            
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
                const chatResponse = await fetch('http://localhost:8000/api/chat/', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        message: 'Test message',
                        user: 'Test User',
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
            const allSuccess = results.users && results.chat;
            const resultClass = allSuccess ? 'success' : 'error';
            const resultIcon = allSuccess ? '✅' : '❌';
            
            resultsDiv.innerHTML = `
                <div class="result ${resultClass}">
${resultIcon} Full Connection Test: ${allSuccess ? 'SUCCESS' : 'FAILED'}
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

        function displayConfig() {
            const configDiv = document.getElementById('configInfo');
            configDiv.innerHTML = `
                <div class="result info">
Configuration:
API Base URL: ${window.getChatBotConfig('API.BASE_URL')}
Debug Enabled: ${window.getChatBotConfig('DEBUG.ENABLED')}
Log Level: ${window.getChatBotConfig('DEBUG.LOG_LEVEL')}
                </div>
            `;
        }

        // Initialize page
        document.addEventListener('DOMContentLoaded', function() {
            displayConfig();
            testFullConnection();
        });
    </script>
</body>
</html>
