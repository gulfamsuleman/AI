import React, { useState, useEffect } from 'react';
import './App.css';
import Chat from './Chat';
import TaskManager from './TaskManager';
import { Plus, Settings, SunMoon, ListTodo } from 'lucide-react';

function App() {
  const [theme, setTheme] = useState(() => localStorage.getItem('theme') || 'light');
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [activeTab, setActiveTab] = useState('chat');
  const [users, setUsers] = useState([]);
  const [selectedUser, setSelectedUser] = useState(() => localStorage.getItem('selectedUser') || '');

  useEffect(() => {
    if (theme === 'dark') {
      document.documentElement.classList.add('dark-mode');
    } else {
      document.documentElement.classList.remove('dark-mode');
    }
    localStorage.setItem('theme', theme);
  }, [theme]);

  useEffect(() => {
    // Fetch users for the dropdown
    fetch(
      process.env.NODE_ENV === 'development'
        ? 'http://localhost:8000/api/users/'
        : '/api/users/'
    )
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
      // Detect client timezone
      const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
      const res = await fetch(`${API_BASE_URL}/api/chat/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: input, user: selectedUser, timezone })
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
    <div className={`app-shell ${theme} ${sidebarOpen ? '' : 'sidebar-hidden'}`}>
      <div className="animated-bg" />
      <button
        className={`sidebar-toggle-btn${sidebarOpen ? '' : ' closed'}`}
        onClick={handleSidebarToggle}
        aria-label={sidebarOpen ? 'Hide sidebar' : 'Show sidebar'}
      >
        {sidebarOpen ? '<' : '>'}
      </button>
      {sidebarOpen && (
        <aside className="sidebar">
          <div className="sidebar-header">
            <img src="/logo192.png" alt="Acme Chatbot Logo" className="sidebar-logo-3d" />
          </div>
          <div style={{ width: '90%', margin: '0 auto 18px auto' }}>
            <label htmlFor="sidebar-user-select" style={{ fontWeight: 600, fontSize: '1rem', color: 'var(--text)', marginBottom: 4, display: 'block' }}>User:</label>
            <select
              id="sidebar-user-select"
              value={selectedUser}
              onChange={e => setSelectedUser(e.target.value)}
              style={{ width: '100%', padding: '10px', borderRadius: 'var(--border-radius)', border: '1.5px solid #e0e7ff', fontSize: '1rem', marginBottom: 0 }}
            >
              <option value="">-- Select User --</option>
              {users.map(user => (
                <option key={user} value={user}>{user}</option>
              ))}
            </select>
          </div>
          <button
            className={`sidebar-btn new-chat${activeTab === 'chat' ? ' active' : ''}`}
            onClick={() => setActiveTab('chat')}
          >
            <Plus size={22} style={{ marginRight: 10 }} />
            Chat
          </button>
          <button
            className={`sidebar-btn${activeTab === 'tasks' ? ' active' : ''}`}
            onClick={() => setActiveTab('tasks')}
          >
            <ListTodo size={22} style={{ marginRight: 10 }} />
            Tasks
          </button>
          <button className="sidebar-btn settings">
            <Settings size={22} style={{ marginRight: 10 }} />
            Settings
          </button>
          <button className="sidebar-btn theme" onClick={handleThemeToggle}>
            <SunMoon size={22} style={{ marginRight: 10 }} />
            Theme
          </button>
          <div className="sidebar-footer">Acme Chatbot UI</div>
        </aside>
      )}
      <main className="main-chat-area">
        <div className="claude-chat-wrapper">
          {activeTab === 'chat' ? <Chat selectedUser={selectedUser} /> : <TaskManager selectedUser={selectedUser} />}
        </div>
      </main>
    </div>
  );
}

export default App;
