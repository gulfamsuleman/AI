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

  useEffect(() => {
    localStorage.setItem('selectedUser', selectedUser);
  }, [selectedUser]);

  const handleThemeToggle = () => setTheme(theme === 'light' ? 'dark' : 'light');
  const handleSidebarToggle = () => setSidebarOpen((open) => !open);

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
