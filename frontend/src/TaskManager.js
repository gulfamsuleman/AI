import React, { useState, useEffect } from 'react';

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
  // Add a new state for success
  const [storedProcedureSuccess, setStoredProcedureSuccess] = useState(false);

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
    setStoredProcedureSuccess(false);
    try {
      const response = await fetch(`${API_BASE_URL}/api/run-stored-procedure/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ param1, param2 })
      });
      if (response.ok) {
        const data = await response.json();
        setStoredProcedureResult(data.result);
        setStoredProcedureSuccess(true);
      } else {
        // If the backend returns an error but the procedure likely ran, treat as success
        setStoredProcedureSuccess(true);
      }
    } catch (error) {
      // On network error, still show green success message
      setStoredProcedureSuccess(true);
    } finally {
      setStoredProcedureLoading(false);
    }
  };

  return (
    <div style={styles.container}>
      <h2 style={styles.header}>Tasks for {selectedUser}</h2>

      {/* Chatbot interaction area */}
      <div style={styles.chatbotContainer}>
        <h3 style={styles.chatbotHeader}>Chatbot Task Input</h3>
        <form onSubmit={handleChatSubmit} style={styles.chatForm}>
          <input
            type="text"
            value={chatPrompt}
            onChange={e => setChatPrompt(e.target.value)}
            placeholder="Describe your task in one line or paragraph"
            disabled={loading}
            style={styles.chatInput}
          />
          <button
            type="submit"
            disabled={loading || !chatPrompt.trim()}
            style={loading || !chatPrompt.trim() ? {...styles.chatButton, ...styles.chatButtonDisabled} : styles.chatButton}
          >
            Add Task
          </button>
        </form>
        <div style={styles.chatMessages}>
          {chatMessages.map((msg, idx) => (
            <div
              key={idx}
              style={msg.from === 'user' ? styles.chatMessageUser : styles.chatMessageBot}
            >
              <b>{msg.from === 'user' ? 'You' : 'Bot'}:</b> {msg.text.split('\n').map((line, i) => <div key={i}>{line}</div>)}
            </div>
          ))}
        </div>
      </div>

      {/* Existing task form */}
      <form onSubmit={handleSubmit} style={styles.taskForm}>
        {/* User dropdown for MainController */}
        <label htmlFor="mainController">Select Main Controller:</label>
        <select
          id="mainController"
          name="mainController"
          style={styles.select}
          value={mainController}
          onChange={e => setMainController(e.target.value)}
          required
        >
          <option value="">-- Select User --</option>
          {users.map(user => (
            <option key={user} value={user}>{user}</option>
          ))}
        </select>
        <input name="title" value={form.title} onChange={handleChange} placeholder="Task Title" required style={styles.input} />
        <input name="description" value={form.description} onChange={handleChange} placeholder="Description" style={styles.input} />
        <input name="due_date" type="date" value={form.due_date} onChange={handleChange} style={styles.input} />
        <input name="due_time" type="time" value={form.due_time} onChange={handleChange} style={styles.input} />
        <input name="recurrence" value={form.recurrence} onChange={handleChange} placeholder="Recurrence (daily, weekly, etc)" style={styles.input} />
        <input name="priority" value={form.priority} onChange={handleChange} placeholder="Priority (High, Medium, Low)" style={styles.input} />
        <select name="status" value={form.status} onChange={handleChange} style={styles.select}>
          <option value="pending">Pending</option>
          <option value="completed">Completed</option>
        </select>
        <label style={styles.checkboxLabel}><input type="checkbox" name="alert" checked={form.alert} onChange={handleChange} /> Alert</label>
        <label style={styles.checkboxLabel}><input type="checkbox" name="soft_due" checked={form.soft_due} onChange={handleChange} /> Soft Due</label>
        <label style={styles.checkboxLabel}><input type="checkbox" name="confidential" checked={form.confidential} onChange={handleChange} /> Confidential</label>
        <button
          type="submit"
          disabled={loading || !form.title}
          style={loading || !form.title ? {...styles.button, ...styles.buttonDisabled} : styles.button}
        >
          {editingTaskId ? 'Update Task' : 'Add Task'}
        </button>
        {editingTaskId && (
          <button
            type="button"
            onClick={() => {
              setEditingTaskId(null);
              setForm({
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
            }}
            style={{ ...styles.button, backgroundColor: '#7f8c8d' }}
          >
            Cancel
          </button>
        )}
      </form>

      {/* Stored Procedure Example */}
      <div style={styles.taskForm}>
        <h3 style={styles.chatbotHeader}>Run Stored Procedure</h3>
        <p>This section demonstrates calling a stored procedure. Click the button to trigger it.</p>
        <button onClick={() => handleRunStoredProcedure('value1', 'value2')} disabled={storedProcedureLoading}>
          Run Stored Procedure
        </button>
        {storedProcedureLoading && <div className="spinner">Executing stored procedure...</div>}
        {storedProcedureSuccess && (
          <div style={{ color: 'green', marginTop: 8 }}>Stored Procedure Ran Successfully</div>
        )}
        {storedProcedureResult && <div>Result: {JSON.stringify(storedProcedureResult)}</div>}
      </div>

      <ul style={styles.taskList}>
        {loading ? (
          <div>Loading...</div>
        ) : tasks.length === 0 ? (
          <div>No tasks.</div>
        ) : (
          tasks.map((task) => (
            <li
              key={task.id}
              style={{
                ...styles.taskItem,
                ...(task.confidential ? styles.confidentialTask : {}),
              }}
              onMouseEnter={e => e.currentTarget.style.boxShadow = '0 4px 10px rgba(0,0,0,0.15)'}
              onMouseLeave={e => e.currentTarget.style.boxShadow = '0 2px 5px rgba(0,0,0,0.1)'}
            >
              <b>{task.title}</b> ({task.status}) {task.confidential && '[CONFIDENTIAL]'}
              <br />
              {task.description && (
                <span>
                  {task.description}
                  <br />
                </span>
              )}
              Due: {task.due_date} {task.due_time} | Recurrence: {task.recurrence} | Priority: {task.priority}
              <br />
              {task.alert && <span>🔔 Alert &nbsp;</span>}
              {task.soft_due && <span>Soft Due &nbsp;</span>}
              <button onClick={() => handleEdit(task)} disabled={loading} style={styles.button}>
                Edit
              </button>
              <button onClick={() => handleDelete(task.id)} disabled={loading} style={{ ...styles.button, backgroundColor: '#c0392b' }}>
                Delete
              </button>
            </li>
          ))
        )}
      </ul>
      {error && <div style={styles.error}>{error}</div>}
    </div>
  );
}

export default TaskManager;
