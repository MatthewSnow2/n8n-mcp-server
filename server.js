require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const axios = require('axios');
const winston = require('winston');
const jwt = require('jsonwebtoken');
const path = require('path');
const session = require('express-session');
const flash = require('connect-flash');
const moment = require('moment');
const fs = require('fs');

// Configuration
const PORT = process.env.PORT || 3000;
const N8N_URL = process.env.N8N_URL || 'http://n8n-app.bluegrass-aa868772.eastus.azurecontainerapps.io:5678';
const JWT_SECRET = process.env.JWT_SECRET || 'secure-mcp-jwt-secret';
const SESSION_SECRET = process.env.SESSION_SECRET || JWT_SECRET;

// Create logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: process.env.LOG_FILE || 'mcp-server.log' })
  ]
});

// Load users from JSON file
let users = [];
let apiUsers = [];

try {
  const usersData = JSON.parse(fs.readFileSync(path.join(__dirname, 'users.json'), 'utf8'));
  users = usersData.users || [];
  apiUsers = usersData.apiUsers || [];
  logger.info(`Loaded ${users.length} web users and ${apiUsers.length} API users`);
} catch (error) {
  logger.error('Error loading users:', error.message);
  // Create default admin user if users.json doesn't exist
  users = [
    {
      id: '1',
      username: 'admin',
      password: 'admin',
      role: 'admin',
      name: 'Administrator',
      email: 'admin@example.com',
      created: new Date().toISOString()
    }
  ];
  apiUsers = [
    {
      id: '1',
      username: 'api_user',
      password: 'api_password',
      role: 'api',
      allowedWorkflows: ['*'],
      created: new Date().toISOString()
    }
  ];
}

// User management functions
const saveUsers = () => {
  try {
    fs.writeFileSync(
      path.join(__dirname, 'users.json'),
      JSON.stringify({ users, apiUsers }, null, 2),
      'utf8'
    );
    logger.info('Users saved successfully');
    return true;
  } catch (error) {
    logger.error('Error saving users:', error.message);
    return false;
  }
};

const findUser = (username) => {
  return users.find(user => user.username === username);
};

const findApiUser = (username) => {
  return apiUsers.find(user => user.username === username);
};

const addUser = (userData) => {
  const newUser = {
    id: (users.length + 1).toString(),
    ...userData,
    created: new Date().toISOString()
  };
  users.push(newUser);
  saveUsers();
  return newUser;
};

const updateUser = (userId, userData) => {
  const index = users.findIndex(user => user.id === userId);
  if (index !== -1) {
    users[index] = { ...users[index], ...userData };
    saveUsers();
    return users[index];
  }
  return null;
};

const deleteUser = (userId) => {
  const index = users.findIndex(user => user.id === userId);
  if (index !== -1) {
    const deletedUser = users.splice(index, 1)[0];
    saveUsers();
    return deletedUser;
  }
  return null;
};

// Initialize Express app
const app = express();

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// Set up EJS as the view engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Session configuration
app.use(session({
  secret: SESSION_SECRET,
  resave: false,
  saveUninitialized: true,
  cookie: { secure: false } // Set to true in production with HTTPS
}));

// Flash messages
app.use(flash());

// Global variables for templates
app.use((req, res, next) => {
  res.locals.success_msg = req.flash('success_msg');
  res.locals.error_msg = req.flash('error_msg');
  res.locals.moment = moment;
  next();
});

// Authentication middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) return res.status(401).json({ error: 'Authentication token required' });
  
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ error: 'Invalid or expired token' });
    req.user = user;
    next();
  });
};

// Web authentication middleware for routes
const ensureAuthenticated = (req, res, next) => {
  if (req.session.isAuthenticated) {
    return next();
  }
  req.flash('error_msg', 'Please log in to access this resource');
  res.redirect('/login');
};

// Role-based authorization middleware
const authorizeRole = (roles) => {
  return (req, res, next) => {
    if (!req.session.user || !roles.includes(req.session.user.role)) {
      req.flash('error_msg', 'You do not have permission to access this resource');
      return res.redirect('/dashboard');
    }
    next();
  };
};

// Web Routes
app.get('/', (req, res) => {
  res.render('index', { 
    title: 'n8n MCP Server',
    user: req.session.user || null
  });
});

app.get('/login', (req, res) => {
  res.render('login', { title: 'Login' });
});

app.post('/login', (req, res) => {
  const { username, password } = req.body;
  
  const user = findUser(username);
  
  if (user && user.password === password) {
    req.session.isAuthenticated = true;
    req.session.user = {
      id: user.id,
      username: user.username,
      role: user.role,
      name: user.name
    };
    req.flash('success_msg', 'You are now logged in');
    res.redirect('/dashboard');
  } else {
    req.flash('error_msg', 'Invalid credentials');
    res.redirect('/login');
  }
});

app.get('/logout', (req, res) => {
  req.session.destroy((err) => {
    if (err) {
      logger.error('Error destroying session:', err);
    }
    res.redirect('/login');
  });
});

app.get('/dashboard', ensureAuthenticated, async (req, res) => {
  try {
    // Get workflows from n8n
    const workflowsResponse = await axios.get(`${N8N_URL}/api/v1/workflows`, {
      headers: {
        'X-N8N-API-KEY': process.env.N8N_API_KEY || ''
      }
    });
    
    const workflows = workflowsResponse.data.data || [];
    
    res.render('dashboard', { 
      title: 'Dashboard',
      user: req.session.user,
      workflows
    });
  } catch (error) {
    logger.error('Error fetching workflows:', error.message);
    res.render('dashboard', { 
      title: 'Dashboard',
      user: req.session.user,
      workflows: [],
      error: 'Unable to fetch workflows from n8n'
    });
  }
});

app.get('/workflows/:id', ensureAuthenticated, async (req, res) => {
  try {
    const workflowId = req.params.id;
    
    // Get workflow details from n8n
    const workflowResponse = await axios.get(`${N8N_URL}/api/v1/workflows/${workflowId}`, {
      headers: {
        'X-N8N-API-KEY': process.env.N8N_API_KEY || ''
      }
    });
    
    const workflow = workflowResponse.data;
    
    res.render('workflow-detail', { 
      title: workflow.name,
      user: req.session.user,
      workflow
    });
  } catch (error) {
    logger.error(`Error fetching workflow ${req.params.id}:`, error.message);
    req.flash('error_msg', 'Unable to fetch workflow details');
    res.redirect('/dashboard');
  }
});

// User management routes (admin only)
app.get('/users', ensureAuthenticated, authorizeRole(['admin']), (req, res) => {
  res.render('users', {
    title: 'User Management',
    user: req.session.user,
    users: users
  });
});

app.get('/users/new', ensureAuthenticated, authorizeRole(['admin']), (req, res) => {
  res.render('user-form', {
    title: 'Add New User',
    user: req.session.user,
    userData: {},
    isNew: true
  });
});

app.post('/users/new', ensureAuthenticated, authorizeRole(['admin']), (req, res) => {
  const { username, password, role, name, email } = req.body;
  
  // Check if username already exists
  if (findUser(username)) {
    req.flash('error_msg', 'Username already exists');
    return res.redirect('/users/new');
  }
  
  // Add new user
  addUser({ username, password, role, name, email });
  
  req.flash('success_msg', 'User added successfully');
  res.redirect('/users');
});

app.get('/users/edit/:id', ensureAuthenticated, authorizeRole(['admin']), (req, res) => {
  const userId = req.params.id;
  const userData = users.find(user => user.id === userId);
  
  if (!userData) {
    req.flash('error_msg', 'User not found');
    return res.redirect('/users');
  }
  
  res.render('user-form', {
    title: 'Edit User',
    user: req.session.user,
    userData,
    isNew: false
  });
});

app.post('/users/edit/:id', ensureAuthenticated, authorizeRole(['admin']), (req, res) => {
  const userId = req.params.id;
  const { username, password, role, name, email } = req.body;
  
  // Update user
  const updatedUser = updateUser(userId, { username, password, role, name, email });
  
  if (!updatedUser) {
    req.flash('error_msg', 'User not found');
    return res.redirect('/users');
  }
  
  req.flash('success_msg', 'User updated successfully');
  res.redirect('/users');
});

app.post('/users/delete/:id', ensureAuthenticated, authorizeRole(['admin']), (req, res) => {
  const userId = req.params.id;
  
  // Prevent deleting own account
  if (userId === req.session.user.id) {
    req.flash('error_msg', 'You cannot delete your own account');
    return res.redirect('/users');
  }
  
  // Delete user
  const deletedUser = deleteUser(userId);
  
  if (!deletedUser) {
    req.flash('error_msg', 'User not found');
    return res.redirect('/users');
  }
  
  req.flash('success_msg', 'User deleted successfully');
  res.redirect('/users');
});

// API Routes

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'MCP Server is running' });
});

// Get auth token
app.post('/api/auth/token', (req, res) => {
  const { username, password } = req.body;
  
  const apiUser = findApiUser(username);
  
  if (apiUser && apiUser.password === password) {
    const token = jwt.sign({ 
      id: apiUser.id,
      username: apiUser.username, 
      role: apiUser.role,
      allowedWorkflows: apiUser.allowedWorkflows
    }, JWT_SECRET, { expiresIn: '1h' });
    res.json({ token });
  } else {
    res.status(401).json({ error: 'Invalid credentials' });
  }
});

// Protected API route to trigger n8n workflow
app.post('/api/workflows/:id/trigger', authenticateToken, async (req, res) => {
  try {
    const workflowId = req.params.id;
    const payload = req.body;
    
    // Check if user has access to this workflow
    if (req.user.allowedWorkflows !== '*' && 
        !req.user.allowedWorkflows.includes(workflowId)) {
      return res.status(403).json({ error: 'You do not have permission to access this workflow' });
    }
    
    logger.info(`Triggering workflow ${workflowId} with payload:`, payload);
    
    // Trigger the workflow in n8n
    const response = await axios.post(`${N8N_URL}/api/v1/workflows/${workflowId}/trigger`, payload, {
      headers: {
        'X-N8N-API-KEY': process.env.N8N_API_KEY || ''
      }
    });
    
    res.status(200).json(response.data);
  } catch (error) {
    logger.error(`Error triggering workflow ${req.params.id}:`, error.message);
    res.status(500).json({ error: 'Failed to trigger workflow', details: error.message });
  }
});

// Get all workflows
app.get('/api/workflows', authenticateToken, async (req, res) => {
  try {
    // Get workflows from n8n
    const response = await axios.get(`${N8N_URL}/api/v1/workflows`, {
      headers: {
        'X-N8N-API-KEY': process.env.N8N_API_KEY || ''
      }
    });
    
    // Filter workflows based on user permissions if needed
    let workflows = response.data.data || [];
    
    if (req.user.allowedWorkflows !== '*') {
      workflows = workflows.filter(workflow => 
        req.user.allowedWorkflows.includes(workflow.id)
      );
    }
    
    res.status(200).json({ data: workflows });
  } catch (error) {
    logger.error('Error fetching workflows:', error.message);
    res.status(500).json({ error: 'Failed to fetch workflows', details: error.message });
  }
});

// Marketing AI Crew specific endpoints
app.post('/api/marketing/campaign', authenticateToken, async (req, res) => {
  try {
    const campaignData = req.body;
    
    // Find the marketing campaign workflow in n8n
    const workflowsResponse = await axios.get(`${N8N_URL}/api/v1/workflows`, {
      headers: {
        'X-N8N-API-KEY': process.env.N8N_API_KEY || ''
      }
    });
    
    const workflows = workflowsResponse.data.data || [];
    const marketingWorkflow = workflows.find(w => w.name.toLowerCase().includes('marketing') || w.name.toLowerCase().includes('campaign'));
    
    if (!marketingWorkflow) {
      return res.status(404).json({ error: 'Marketing campaign workflow not found' });
    }
    
    // Check if user has access to this workflow
    if (req.user.allowedWorkflows !== '*' && 
        !req.user.allowedWorkflows.includes(marketingWorkflow.id)) {
      return res.status(403).json({ error: 'You do not have permission to access this workflow' });
    }
    
    // Trigger the marketing workflow
    const response = await axios.post(`${N8N_URL}/api/v1/workflows/${marketingWorkflow.id}/trigger`, campaignData, {
      headers: {
        'X-N8N-API-KEY': process.env.N8N_API_KEY || ''
      }
    });
    
    res.status(200).json(response.data);
  } catch (error) {
    logger.error('Error creating marketing campaign:', error.message);
    res.status(500).json({ error: 'Failed to create marketing campaign', details: error.message });
  }
});

// Start the server
app.listen(PORT, () => {
  logger.info(`MCP Server is running on port ${PORT}`);
  logger.info(`Connected to n8n instance at ${N8N_URL}`);
});
