import React, { useState, useEffect } from 'react';

const USER_NAME = 'demo_user'; // Replace with actual logged-in user logic
const API_BASE_URL = process.env.NODE_ENV === 'development' ? 'http://localhost:8000' : '';

const styles = {
  container: {
    maxWidth: '900px',
    margin: '20px auto',
    fontFamily: "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif",
    color: '#333',
    padding: '10px',
  },
  header: {
    textAlign: 'center',
    marginBottom: '20px',
    color: '#2c3e50',
  },
  chatbotContainer: {
    border: '1px solid #ddd',
    borderRadius: '8px',
    padding: '15px',
    marginBottom: '30px',
    backgroundColor: '#f9f9f9',
  },
  chatbotHeader: {
    marginBottom: '10px',
    fontSize: '1.2rem',
    fontWeight: '600',
    color: '#34495e',
  },
  chatForm: {
    display: 'flex',
    marginBottom: '10px',
  },
  chatInput: {
    flexGrow: 1,
    padding: '10px',
    fontSize: '1rem',
    borderRadius: '4px 0 0 4px',
    border: '1px solid #ccc',
    outline: 'none',
  },
  chatButton: {
    padding: '10px 20px',
    fontSize: '1rem',
    borderRadius: '0 4px 4px 0',
    border: '1px solid #2980b9',
    backgroundColor: '#2980b9',
    color: 'white',
    cursor: 'pointer',
    transition: 'background-color 0.3s ease',
  },
  chatButtonDisabled: {
    backgroundColor: '#95a5a6',
    borderColor: '#95a5a6',
    cursor: 'not-allowed',
  },
  chatMessages: {
    maxHeight: '200px',
    overflowY: 'auto',
    padding: '10px',
    backgroundColor: 'white',
    borderRadius: '4px',
    border: '1px solid #ccc',
  },
  chatMessageUser: {
    textAlign: 'right',
    margin: '8px 0',
    color: '#2c3e50',
  },
  chatMessageBot: {
    textAlign: 'left',
    margin: '8px 0',
    color: '#34495e',
  },
  taskForm: {
    border: '1px solid #ddd',
    borderRadius: '8px',
    padding: '15px',
    backgroundColor: '#fefefe',
    marginBottom: '30px',
  },
  input: {
    width: '100%',
    padding: '8px 10px',
    marginBottom: '12px',
    fontSize: '1rem',
    borderRadius: '4px',
    border: '1px solid #ccc',
    outline: 'none',
  },
  select: {
    width: '100%',
    padding: '8px 10px',
    marginBottom: '12px',
    fontSize: '1rem',
    borderRadius: '4px',
    border: '1px solid #ccc',
    outline: 'none',
  },
  checkboxLabel: {
    display: 'inline-block',
    marginRight: '15px',
    fontSize: '0.9rem',
    color: '#555',
  },
  button: {
    padding: '10px 20px',
    fontSize: '1rem',
    borderRadius: '4px',
    border: 'none',
    backgroundColor: '#2980b9',
    color: 'white',
    cursor: 'pointer',
    transition: 'background-color 0.3s ease',
    marginRight: '10px',
  },
  buttonDisabled: {
    backgroundColor: '#95a5a6',
    cursor: 'not-allowed',
  },
  taskList: {
    listStyle: 'none',
    padding: 0,
  },
  taskItem: {
    backgroundColor: 'white',
    borderRadius: '6px',
    padding: '15px',
    marginBottom: '12px',
    boxShadow: '0 2px 5px rgba(0,0,0,0.1)',
    transition: 'box-shadow 0.3s ease',
  },
  taskItemHover: {
    boxShadow: '0 4px 10px rgba(0,0,0,0.15)',
  },
  confidentialTask: {
    opacity: 0.5,
  },
  error: {
    color: 'red',
    marginTop: '10px',
    fontWeight: '600',
  }
};

function TaskManager({ selectedUser }) {
  const [tasks, setTasks] = React.useState([]);
  const [loading, setLoading] = React.useState(false);
  const [error, setError] = React.useState(null);
  const [form, setForm] = React.useState({
    title: '',
    description: '',
    due_date: '',
    due_time: '',
    recurrence: '',
    priority: '',
    status: 'pending',
    alert: false,
    soft_due: false,
    confidential: false
  });
  const [editingTaskId, setEditingTaskId] = React.useState(null);

  // New state for user dropdown
  const [users, setUsers] = React.useState([]);
  const [mainController, setMainController] = React.useState('');

  // New state for chatbot prompt and messages
  const [chatPrompt, setChatPrompt] = React.useState('');
  const [chatMessages, setChatMessages] = React.useState([]);

  // New state for loading and result for stored procedure
  const [storedProcedureLoading, setStoredProcedureLoading] = useState(false);
  const [storedProcedureResult, setStoredProcedureResult] = useState(null);
  const [storedProcedureError, setStoredProcedureError] = useState(null);
  const [storedProcedureExecuted, setStoredProcedureExecuted] = useState(false);

  // Chat session state
  const [sessions, setSessions] = useState([]);
  const [selectedSession, setSelectedSession] = useState(null);
  const [sessionMessages, setSessionMessages] = useState([]);
  const [loadingSessions, setLoadingSessions] = useState(false);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [creatingSession, setCreatingSession] = useState(false);

  React.useEffect(() => {
    if (!selectedUser) return;
    setLoading(true);
    fetch(`${API_BASE_URL}/api/tasks/?user=${selectedUser}`)
      .then(res => res.json())
      .then(data => setTasks(data))
      .catch(() => setTasks([]))
      .finally(() => setLoading(false));
  }, [selectedUser]);

  // Fetch users for dropdown
  React.useEffect(() => {
    fetch(`${API_BASE_URL}/api/users/`)
      .then(res => res.json())
      .then(data => setUsers(data))
      .catch(() => setUsers([]));
  }, []);

  // Fetch sessions on mount
  useEffect(() => {
    fetchSessions();
  }, []);

  const fetchSessions = async () => {
    setLoadingSessions(true);
    try {
      const res = await fetch(`${API_BASE_URL}/api/sessions/?user=${USER_NAME}`);
      const data = await res.json();
      setSessions(data);
    } catch (e) {
      setSessions([]);
    } finally {
      setLoadingSessions(false);
    }
  };

  const fetchSessionMessages = async (sessionId) => {
    setLoadingMessages(true);
    try {
      const res = await fetch(`${API_BASE_URL}/api/sessions/${sessionId}/messages/`);
      const data = await res.json();
      setSessionMessages(data);
    } catch (e) {
      setSessionMessages([]);
    } finally {
      setLoadingMessages(false);
    }
  };

  const handleSelectSession = (session) => {
    setSelectedSession(session);
    fetchSessionMessages(session.id);
  };

  const handleCreateSession = async () => {
    setCreatingSession(true);
    try {
      const res = await fetch(`${API_BASE_URL}/api/sessions/create/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user: USER_NAME, title: '' })
      });
      const data = await res.json();
      await fetchSessions();
      setSelectedSession(data);
      setSessionMessages([]);
    } catch (e) {
      // handle error
    } finally {
      setCreatingSession(false);
    }
  };

  const handleChange = e => {
    const { name, value, type, checked } = e.target;
    setForm(f => ({ ...f, [name]: type === 'checkbox' ? checked : value }));
  };

  const handleSubmit = async e => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      let res;
      if (editingTaskId) {
        res = await fetch(`${API_BASE_URL}/api/tasks/${editingTaskId}/`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ ...form, user: selectedUser })
        });
      } else {
        res = await fetch(`${API_BASE_URL}/api/tasks/`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ ...form, user: selectedUser })
        });
      }
      const data = await res.json();
      if (res.ok) {
        if (editingTaskId) {
          setTasks(tsk => tsk.map(t => (t.id === editingTaskId ? data : t)));
          setEditingTaskId(null);
        } else {
          setTasks(tsk => [...tsk, data]);
        }
        setForm({
          title: '', description: '', due_date: '', due_time: '', recurrence: '', priority: '', status: 'pending', alert: false, soft_due: false, confidential: false
        });
      } else {
        setError(data.error || 'Error from server');
      }
    } catch (err) {
      setError('Network error');
    }
    setLoading(false);
  };

  const handleEdit = task => {
    setForm({
      title: task.title,
      description: task.description,
      due_date: task.due_date || '',
      due_time: task.due_time || '',
      recurrence: task.recurrence,
      priority: task.priority,
      status: task.status,
      alert: task.alert,
      soft_due: task.soft_due,
      confidential: task.confidential
    });
    setEditingTaskId(task.id);
  };

  const handleDelete = async (taskId) => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`${API_BASE_URL}/api/tasks/${taskId}/`, {
        method: 'DELETE'
      });
      if (res.ok) {
        setTasks(tsk => tsk.filter(t => t.id !== taskId));
      } else {
        const data = await res.json();
        setError(data.error || 'Error deleting task');
      }
    } catch (err) {
      setError('Network error');
    }
    setLoading(false);
  };

  // New handler for chatbot prompt submission
  const handleChatSubmit = async (e) => {
    e.preventDefault();
    if (!chatPrompt.trim()) return;
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`${API_BASE_URL}/api/tasks/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ prompt: chatPrompt, user: selectedUser })
      });
      const data = await res.json();
      if (res.ok) {
        setTasks(tsk => [...tsk, data]);
        // Compose task details string
        const taskDetails = "Task Details:\n" +
          "Title: " + (data.title || '') + "\n" +
          "Description: " + (data.description || 'N/A') + "\n" +
          "Due Date: " + (data.due_date || 'N/A') + "\n" +
          "Due Time: " + (data.due_time || 'N/A') + "\n" +
          "Recurrence: " + (data.recurrence || 'N/A') + "\n" +
          "Priority: " + (data.priority || 'Medium') + "\n" +
          "Status: " + (data.status || 'pending') + "\n" +
          "Alert: " + (data.alert ? 'Yes' : 'No') + "\n" +
          "Soft Due: " + (data.soft_due ? 'Yes' : 'No') + "\n" +
          "Confidential: " + (data.confidential ? 'Yes' : 'No');
        setChatMessages(msgs => [...msgs, { from: 'user', text: chatPrompt }, { from: 'bot', text: data.message || 'Task saved.' }, { from: 'bot', text: taskDetails }]);
        setChatPrompt('');
      } else {
        setError(data.error || 'Error from server');
      }
    } catch (err) {
      setError('Network error');
    }
    setLoading(false);
  };

  // New handler for stored procedure
  const handleRunStoredProcedure = async (param1, param2) => {
    setStoredProcedureLoading(true);
    setStoredProcedureResult(null);
    setStoredProcedureError(null);
    setStoredProcedureExecuted(false);
    try {
      const response = await fetch(`${API_BASE_URL}/api/run-stored-procedure/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ param1, param2 })
      });
      const data = await response.json();
      setStoredProcedureResult(data.result);
      setStoredProcedureError(data.error);
    } catch (error) {
      setStoredProcedureError('Network or server error');
    } finally {
      setStoredProcedureLoading(false);
      setStoredProcedureExecuted(true);
    }
  };

  return (
    <div style={{ display: 'flex', height: '100vh' }}>
      {/* Sidebar for chat sessions */}
      <div style={{ width: 250, borderRight: '1px solid #ccc', padding: 16, background: '#f9f9f9' }}>
        <h3>Chat History</h3>
        <button onClick={handleCreateSession} disabled={creatingSession} style={{ marginBottom: 12 }}>
          {creatingSession ? 'Creating...' : 'New Chat'}
        </button>
        {loadingSessions ? (
          <div>Loading sessions...</div>
        ) : (
          <ul style={{ listStyle: 'none', padding: 0 }}>
            {sessions.map((s) => (
              <li key={s.id} style={{ marginBottom: 8 }}>
                <button
                  style={{
                    background: selectedSession && selectedSession.id === s.id ? '#e0e0e0' : 'white',
                    border: '1px solid #bbb',
                    width: '100%',
                    textAlign: 'left',
                    padding: 8,
                    borderRadius: 4,
                    cursor: 'pointer'
                  }}
                  onClick={() => handleSelectSession(s)}
                >
                  {s.title || `Session ${s.id}`}
                  <br />
                  <span style={{ fontSize: 12, color: '#888' }}>{new Date(s.created_at).toLocaleString()}</span>
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
      {/* Main area for chat messages */}
      <div style={{ flex: 1, padding: 24 }}>
        <h2>Chat</h2>
        {selectedSession ? (
          <div>
            <h4>Session: {selectedSession.title || `Session ${selectedSession.id}`}</h4>
            {loadingMessages ? (
              <div>Loading messages...</div>
            ) : (
              <ul style={{ listStyle: 'none', padding: 0 }}>
                {sessionMessages.map((msg) => (
                  <li key={msg.id} style={{ marginBottom: 16 }}>
                    <div><b>You:</b> {msg.user_message}</div>
                    <div><b>Bot:</b> {msg.bot_reply}</div>
                    <div style={{ fontSize: 12, color: '#888' }}>{new Date(msg.timestamp).toLocaleString()}</div>
                  </li>
                ))}
              </ul>
            )}
          </div>
        ) : (
          <div>Select a chat session or start a new one.</div>
        )}
      </div>
    </div>
  );
}

export default TaskManager;
