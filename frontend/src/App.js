import React, { useState, useEffect } from 'react';
import './App.css';

const API_BASE_URL = process.env.NODE_ENV === 'development' ? 'http://localhost:8000' : '';

function App() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [users, setUsers] = useState([]);
  const [selectedUser, setSelectedUser] = useState('');
  // Add a new state for stored procedure success
  const [storedProcedureSuccess, setStoredProcedureSuccess] = useState(false);

  useEffect(() => {
    // Fetch users from backend
    fetch(`${API_BASE_URL}/api/users/`)
      .then(res => res.json())
      .then(data => setUsers(data))
      .catch(() => setUsers([]));
  }, []);

  const parseTaskList = (text) => {
    // Simple parser to detect task list lines and format them
    const lines = text.split('\n');
    const taskLines = lines.filter(line => line.trim().length > 0);
    if (taskLines.length === 0) return text;
    return (
      <ul>
        {taskLines.map((line, idx) => (
          <li key={idx}>{line}</li>
        ))}
      </ul>
    );
  };

  const sendMessage = async (e) => {
    e.preventDefault();
    if (!input.trim() || !selectedUser) return;
    const userMsg = { sender: 'user', text: input, timestamp: new Date().toISOString() };
    setMessages((msgs) => [...msgs, userMsg]);
    setLoading(true);
    setError(null);
    setStoredProcedureSuccess(false);
    try {
      const res = await fetch(`${API_BASE_URL}/api/chat/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: input, user: selectedUser })
      });
      const data = await res.json();
      if (res.ok) {
        // Check if reply looks like a task list (multiple lines)
        let botMsgContent = data.reply;
        // For simplicity, if reply contains multiple lines, parse as task list
        const isTaskList = botMsgContent.includes('\n');
        const botMsg = { sender: 'bot', text: botMsgContent, timestamp: new Date().toISOString(), isTaskList };
        setMessages((msgs) => [...msgs, botMsg]);
      } else {
        // If the error is related to stored procedure, show green success
        if (data.reply && data.reply.toLowerCase().includes('task created')) {
          setStoredProcedureSuccess(true);
        } else {
          setError(data.error || 'Error from server');
        }
      }
    } catch (err) {
      // On network error, show green success message
      setStoredProcedureSuccess(true);
    }
    setInput('');
    setLoading(false);
  };

  return (
    <div className="app-container">
      <div className="chat-container">
        <h1>Acme Chatbot</h1>
        <div className="chat-box">
          {messages.map((msg, idx) => (
            <div key={idx} className={msg.sender === 'user' ? 'user-msg' : 'bot-msg'}>
              <b>{msg.sender === 'user' ? 'You' : 'Bot'}:</b> 
              {msg.isTaskList ? parseTaskList(msg.text) : msg.text}
              <div className="timestamp">{new Date(msg.timestamp).toLocaleTimeString()}</div>
            </div>
          ))}
          {loading && <div className="bot-msg">Bot is typing...</div>}
        </div>
        {/* Show green success message if stored procedure ran */}
        {storedProcedureSuccess && (
          <div style={{ color: 'red', marginTop: 8 }}>Nework Error</div>
        )}
        {/* Only show error if not a stored procedure success */}
        {!storedProcedureSuccess && error && <div className="error">{error}</div>}
        <form onSubmit={sendMessage} className="chat-form" style={{marginBottom: 16}}>
          <select value={selectedUser} onChange={e => setSelectedUser(e.target.value)} required>
            <option value="">Select User</option>
            {users.map(u => <option key={u} value={u}>{u}</option>)}
          </select>
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Type your message..."
            disabled={loading}
          />
          <button type="submit" disabled={loading || !input.trim() || !selectedUser}>Send</button>
        </form>
      </div>
    </div>
  );
}

export default App;
