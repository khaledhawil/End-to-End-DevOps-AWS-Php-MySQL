import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'

function Dashboard({ setAuth, user }) {
  const [tasks, setTasks] = useState([])
  const [newTask, setNewTask] = useState({ title: '', description: '', priority: 'medium' })
  const [editingTask, setEditingTask] = useState(null)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [username, setUsername] = useState(user?.username || '')
  const [filter, setFilter] = useState('all') // all, pending, completed
  const [sortBy, setSortBy] = useState('created') // created, priority
  const navigate = useNavigate()

  useEffect(() => {
    fetchTasks()
    if (!username) {
      fetchUserProfile()
    }
  }, [])

  const fetchUserProfile = async () => {
    try {
      const token = localStorage.getItem('token')
      const response = await axios.get('/api/auth/profile', {
        headers: { Authorization: `Bearer ${token}` }
      })
      setUsername(response.data.username)
    } catch (err) {
      console.error('Failed to fetch profile:', err)
    }
  }

  const fetchTasks = async () => {
    setLoading(true)
    try {
      const token = localStorage.getItem('token')
      if (!token) {
        handleLogout()
        return
      }
      
      console.log('Fetching tasks with token:', token.substring(0, 20) + '...')
      const response = await axios.get('/api/tasks', {
        headers: { Authorization: `Bearer ${token}` }
      })
      console.log('Tasks fetched:', response.data)
      setTasks(response.data)
      setError('')
    } catch (err) {
      console.error('Fetch tasks error:', err.response || err)
      if (err.response?.status === 401) {
        setError('Session expired. Please login again.')
        setTimeout(handleLogout, 2000)
      } else {
        setError('Failed to fetch tasks: ' + (err.response?.data?.error || err.message))
      }
    } finally {
      setLoading(false)
    }
  }

  const handleAddTask = async (e) => {
    e.preventDefault()
    if (!newTask.title.trim() || !newTask.description.trim()) {
      setError('Title and description are required')
      return
    }
    
    setLoading(true)
    try {
      const token = localStorage.getItem('token')
      console.log('Adding task:', newTask)
      const response = await axios.post('/api/tasks', newTask, {
        headers: { 
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      })
      console.log('Task added:', response.data)
      setNewTask({ title: '', description: '', priority: 'medium' })
      setError('')
      await fetchTasks()
    } catch (err) {
      console.error('Add task error:', err.response || err)
      setError('Failed to add task: ' + (err.response?.data?.error || err.message))
    } finally {
      setLoading(false)
    }
  }

  const handleDeleteTask = async (id) => {
    if (!window.confirm('Are you sure you want to delete this task?')) {
      return
    }
    
    setLoading(true)
    try {
      const token = localStorage.getItem('token')
      await axios.delete(`/api/tasks/${id}`, {
        headers: { Authorization: `Bearer ${token}` }
      })
      setError('')
      await fetchTasks()
    } catch (err) {
      console.error('Delete task error:', err)
      setError('Failed to delete task: ' + (err.response?.data?.error || err.message))
    } finally {
      setLoading(false)
    }
  }

  const handleToggleStatus = async (id) => {
    setLoading(true)
    try {
      const token = localStorage.getItem('token')
      await axios.patch(`/api/tasks/${id}/status`, {}, {
        headers: { Authorization: `Bearer ${token}` }
      })
      setError('')
      await fetchTasks()
    } catch (err) {
      console.error('Toggle status error:', err)
      setError('Failed to update task status')
    } finally {
      setLoading(false)
    }
  }

  const handleEditTask = (task) => {
    setEditingTask({ ...task })
  }

  const handleUpdateTask = async (e) => {
    e.preventDefault()
    setLoading(true)
    try {
      const token = localStorage.getItem('token')
      await axios.put(`/api/tasks/${editingTask.id}`, {
        title: editingTask.title,
        description: editingTask.description,
        priority: editingTask.priority
      }, {
        headers: { Authorization: `Bearer ${token}` }
      })
      setEditingTask(null)
      setError('')
      await fetchTasks()
    } catch (err) {
      console.error('Update task error:', err)
      setError('Failed to update task')
    } finally {
      setLoading(false)
    }
  }

  const handleLogout = () => {
    localStorage.removeItem('token')
    setAuth(false)
    navigate('/login')
  }

  // Filter and sort tasks
  const getFilteredAndSortedTasks = () => {
    let filtered = [...tasks]
    
    // Apply filter
    if (filter === 'pending') {
      filtered = filtered.filter(task => task.status === 'pending')
    } else if (filter === 'completed') {
      filtered = filtered.filter(task => task.status === 'completed')
    }
    
    // Apply sorting
    if (sortBy === 'priority') {
      const priorityOrder = { high: 3, medium: 2, low: 1 }
      filtered.sort((a, b) => priorityOrder[b.priority || 'medium'] - priorityOrder[a.priority || 'medium'])
    } else {
      filtered.sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
    }
    
    return filtered
  }

  // Calculate statistics
  const getStats = () => {
    const total = tasks.length
    const completed = tasks.filter(t => t.status === 'completed').length
    const pending = tasks.filter(t => t.status === 'pending').length
    const high = tasks.filter(t => t.priority === 'high' && t.status === 'pending').length
    const completionRate = total > 0 ? Math.round((completed / total) * 100) : 0
    
    return { total, completed, pending, high, completionRate }
  }

  const stats = getStats()
  const filteredTasks = getFilteredAndSortedTasks()

  return (
    <div className="dashboard">
      <header>
        <div className="header-content">
          <h1>🎯 Task Manager {username && `- ${username}`}</h1>
          <button onClick={handleLogout} disabled={loading} className="btn-logout">
            Logout
          </button>
        </div>
      </header>
      
      {/* Statistics Dashboard */}
      <div className="stats-grid">
        <div className="stat-card total">
          <div className="stat-icon">📊</div>
          <div className="stat-content">
            <h3>{stats.total}</h3>
            <p>Total Tasks</p>
          </div>
        </div>
        <div className="stat-card pending">
          <div className="stat-icon">⏳</div>
          <div className="stat-content">
            <h3>{stats.pending}</h3>
            <p>Pending</p>
          </div>
        </div>
        <div className="stat-card completed">
          <div className="stat-icon">✅</div>
          <div className="stat-content">
            <h3>{stats.completed}</h3>
            <p>Completed</p>
          </div>
        </div>
        <div className="stat-card high-priority">
          <div className="stat-icon">🔥</div>
          <div className="stat-content">
            <h3>{stats.high}</h3>
            <p>High Priority</p>
          </div>
        </div>
        <div className="stat-card completion-rate">
          <div className="stat-icon">📈</div>
          <div className="stat-content">
            <h3>{stats.completionRate}%</h3>
            <p>Completion Rate</p>
          </div>
        </div>
      </div>

      {error && <div className="error-message">{error}</div>}
      {loading && <div className="loading-message">Loading...</div>}
      
      {editingTask ? (
        <div className="edit-task card-premium">
          <h2>✏️ Edit Task</h2>
          <form onSubmit={handleUpdateTask}>
            <input
              type="text"
              placeholder="Task Title"
              value={editingTask.title}
              onChange={(e) => setEditingTask({ ...editingTask, title: e.target.value })}
              required
            />
            <textarea
              placeholder="Task Description"
              value={editingTask.description}
              onChange={(e) => setEditingTask({ ...editingTask, description: e.target.value })}
              required
            />
            <select
              value={editingTask.priority}
              onChange={(e) => setEditingTask({ ...editingTask, priority: e.target.value })}
            >
              <option value="low">🔵 Low Priority</option>
              <option value="medium">🟠 Medium Priority</option>
              <option value="high">🔴 High Priority</option>
            </select>
            <div className="button-group">
              <button type="submit" disabled={loading} className="btn-primary">
                Update Task
              </button>
              <button type="button" onClick={() => setEditingTask(null)} disabled={loading} className="btn-secondary">
                Cancel
              </button>
            </div>
          </form>
        </div>
      ) : (
        <div className="add-task card-premium">
          <h2>➕ Add New Task</h2>
          <form onSubmit={handleAddTask}>
            <input
              type="text"
              placeholder="Task Title"
              value={newTask.title}
              onChange={(e) => setNewTask({ ...newTask, title: e.target.value })}
              required
              disabled={loading}
            />
            <textarea
              placeholder="Task Description"
              value={newTask.description}
              onChange={(e) => setNewTask({ ...newTask, description: e.target.value })}
              required
              disabled={loading}
            />
            <select
              value={newTask.priority}
              onChange={(e) => setNewTask({ ...newTask, priority: e.target.value })}
              disabled={loading}
            >
              <option value="low">🔵 Low Priority</option>
              <option value="medium">🟠 Medium Priority</option>
              <option value="high">🔴 High Priority</option>
            </select>
            <button type="submit" disabled={loading} className="btn-primary">
              Add Task
            </button>
          </form>
        </div>
      )}

      <div className="tasks-list">
        <div className="tasks-header">
          <h2>📋 Your Tasks</h2>
          <div className="controls">
            <div className="filter-controls">
              <button 
                className={filter === 'all' ? 'active' : ''}
                onClick={() => setFilter('all')}
              >
                All
              </button>
              <button 
                className={filter === 'pending' ? 'active' : ''}
                onClick={() => setFilter('pending')}
              >
                Pending
              </button>
              <button 
                className={filter === 'completed' ? 'active' : ''}
                onClick={() => setFilter('completed')}
              >
                Completed
              </button>
            </div>
            <div className="sort-controls">
              <label>Sort by:</label>
              <select value={sortBy} onChange={(e) => setSortBy(e.target.value)}>
                <option value="created">Date Created</option>
                <option value="priority">Priority</option>
              </select>
            </div>
          </div>
        </div>

        {filteredTasks.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">📝</div>
            <p>No tasks yet. Add one above!</p>
          </div>
        ) : (
          <div className="tasks">
            {filteredTasks.map((task) => (
              <div 
                key={task.id} 
                className={`task-card ${task.status} priority-${task.priority || 'medium'}`}
              >
                <div className="task-header">
                  <h3>{task.title}</h3>
                  <span className={`priority-badge ${task.priority || 'medium'}`}>
                    {task.priority === 'high' ? '🔴' : task.priority === 'low' ? '🔵' : '🟠'} 
                    {(task.priority || 'medium').toUpperCase()}
                  </span>
                </div>
                <p>{task.description}</p>
                <div className="task-meta">
                  <span className={`status-badge ${task.status}`}>
                    {task.status === 'completed' ? '✓ Completed' : '○ Pending'}
                  </span>
                  <small>📅 {new Date(task.created_at).toLocaleDateString()}</small>
                </div>
                <div className="task-actions">
                  <button 
                    onClick={() => handleToggleStatus(task.id)}
                    className="btn-status"
                    disabled={loading}
                    title={task.status === 'completed' ? 'Mark as Pending' : 'Mark as Complete'}
                  >
                    {task.status === 'completed' ? '↩️' : '✓'}
                  </button>
                  <button 
                    onClick={() => handleEditTask(task)}
                    className="btn-edit"
                    disabled={loading}
                    title="Edit Task"
                  >
                    ✏️
                  </button>
                  <button 
                    onClick={() => handleDeleteTask(task.id)}
                    className="btn-delete"
                    disabled={loading}
                    title="Delete Task"
                  >
                    🗑️
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

export default Dashboard
