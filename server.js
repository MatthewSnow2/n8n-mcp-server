require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const axios = require('axios');
const winston = require('winston');
const jwt = require('jsonwebtoken');

// Configuration
const PORT = process.env.PORT || 3000;
const N8N_URL = process.env.N8N_URL || 'http://n8n-app.bluegrass-aa868772.eastus.azurecontainerapps.io:5678';
const JWT_SECRET = process.env.JWT_SECRET || 'secure-mcp-jwt-secret';

// Create logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'mcp-server.log' })
  ]
});

// Initialize Express app
const app = express();

// Middleware
app.use(cors());
app.use(bodyParser.json());

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

// Routes

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', message: 'MCP Server is running' });
});

// Generate token for clients
app.post('/auth/token', (req, res) => {
  const { clientId, clientSecret } = req.body;
  
  // In production, validate clientId and clientSecret against a database
  if (!clientId || !clientSecret) {
    return res.status(400).json({ error: 'Client ID and Client Secret are required' });
  }
  
  // Create token
  const token = jwt.sign({ clientId }, JWT_SECRET, { expiresIn: '24h' });
  res.json({ token });
});

// Proxy endpoint to forward requests to n8n
app.post('/webhook/:workflowId', authenticateToken, async (req, res) => {
  const { workflowId } = req.params;
  const payload = req.body;
  
  try {
    logger.info(`Forwarding request to workflow ${workflowId}`);
    
    // Forward the request to n8n webhook
    const response = await axios.post(
      `${N8N_URL}/webhook/${workflowId}`,
      payload,
      { headers: { 'Content-Type': 'application/json' } }
    );
    
    logger.info(`Response received from n8n for workflow ${workflowId}`);
    res.status(response.status).json(response.data);
  } catch (error) {
    logger.error(`Error forwarding request to n8n: ${error.message}`);
    res.status(error.response?.status || 500).json({
      error: 'Error processing request',
      details: error.message
    });
  }
});

// API endpoint to list available workflows
app.get('/workflows', authenticateToken, async (req, res) => {
  try {
    // This requires n8n API to be enabled
    const response = await axios.get(
      `${N8N_URL}/api/v1/workflows`,
      { 
        headers: { 
          'Content-Type': 'application/json',
          'X-N8N-API-KEY': process.env.N8N_API_KEY || ''
        } 
      }
    );
    
    // Return a simplified list of workflows
    const workflows = response.data.data.map(workflow => ({
      id: workflow.id,
      name: workflow.name,
      active: workflow.active
    }));
    
    res.json({ workflows });
  } catch (error) {
    logger.error(`Error fetching workflows: ${error.message}`);
    res.status(error.response?.status || 500).json({
      error: 'Error fetching workflows',
      details: error.message
    });
  }
});

// Start server
app.listen(PORT, () => {
  logger.info(`MCP Server running on port ${PORT}`);
  logger.info(`Connected to n8n at ${N8N_URL}`);
});
