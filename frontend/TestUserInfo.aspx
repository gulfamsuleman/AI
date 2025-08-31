<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="TestUserInfo.aspx.cs" Inherits="ChaatApp.TestUserInfo" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Test User Information</title>
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
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="test-container">
            <h1>Test User Information</h1>
            <p>This page tests that the correct user information is being sent to the Django backend.</p>
        </div>

        <div class="test-container">
            <h2>Current User Information</h2>
            <div id="userInfo"></div>
        </div>

        <div class="test-container">
            <h2>Test Chat with Current User</h2>
            <button type="button" class="test-button" onclick="testChatWithCurrentUser()">Test Chat with Current User</button>
            <div id="testResults"></div>
        </div>
    </form>

    <script src="Scripts/chatbot-config.js"></script>
    <script>
        function displayUserInfo() {
            const userDiv = document.getElementById('userInfo');
            const userInfo = {
                userName: localStorage.getItem('userName'),
                fullName: localStorage.getItem('userFullName')
            };
            
            userDiv.innerHTML = `
                <div class="result info">
Current User Information:
User Name: ${userInfo.userName || 'Not set'}
Full Name: ${userInfo.fullName || 'Not set'}

This information will be used to determine which name is sent to the Django backend.
                </div>
            `;
        }
        
        async function testChatWithCurrentUser() {
            const resultsDiv = document.getElementById('testResults');
            resultsDiv.innerHTML = '<div class="result info">Testing chat with current user...</div>';
            
            // Get user info
            const userInfo = {
                userName: localStorage.getItem('userName'),
                fullName: localStorage.getItem('userFullName')
            };
            
            // Determine which name will be sent (should be fullName)
            const userToSend = userInfo.fullName || userInfo.userName || 'Unknown User';
            
            console.log('User info from localStorage:', userInfo);
            console.log('User that will be sent to backend:', userToSend);
            
            try {
                const response = await fetch('http://localhost:8000/api/chat/', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                    },
                    body: JSON.stringify({
                        message: 'Test message to verify user information',
                        user: userToSend,
                        timezone: 'UTC'
                    })
                });
                
                if (response.ok) {
                    const data = await response.json();
                    resultsDiv.innerHTML = `
                        <div class="result success">
✅ Chat Test: SUCCESS
Status: ${response.status}
User Sent: "${userToSend}"
Response: ${JSON.stringify(data, null, 2)}

User Information Used:
- User Name: ${userInfo.userName || 'Not set'}
- Full Name: ${userInfo.fullName || 'Not set'}
- Sent to Backend: ${userToSend}
                        </div>
                    `;
                } else {
                    const errorText = await response.text();
                    resultsDiv.innerHTML = `
                        <div class="result error">
❌ Chat Test: FAILED
Status: ${response.status}
User Sent: "${userToSend}"
Error: ${errorText}

User Information Used:
- User Name: ${userInfo.userName || 'Not set'}
- Full Name: ${userInfo.fullName || 'Not set'}
- Sent to Backend: ${userToSend}
                        </div>
                    `;
                }
            } catch (error) {
                resultsDiv.innerHTML = `
                    <div class="result error">
❌ Chat Test: FAILED
Error: ${error.message}

User Information Used:
- User Name: ${userInfo.userName || 'Not set'}
- Full Name: ${userInfo.fullName || 'Not set'}
- Sent to Backend: ${userToSend}
                    </div>
                `;
            }
        }
        
        // Initialize page
        document.addEventListener('DOMContentLoaded', function() {
            displayUserInfo();
        });
    </script>
</body>
</html>
