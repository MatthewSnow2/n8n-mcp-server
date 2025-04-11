# n8n Message Control Protocol (MCP) Server

This server provides a secure gateway for client applications to access n8n workflows, with a focus on marketing AI crew integration.

## Deployment to Render.com

1. Create a free account on [Render.com](https://render.com)
2. Connect your GitHub repository or upload the code directly
3. Create a new Web Service with the following settings:
   - **Name**: n8n-mcp-server
   - **Environment**: Node
   - **Build Command**: npm install
   - **Start Command**: node server.js
   - **Environment Variables**:
     - PORT: 10000
     - N8N_URL: http://n8n-app.bluegrass-aa868772.eastus.azurecontainerapps.io:5678
     - JWT_SECRET: secure-mcp-jwt-secret-change-this-in-production
     - LOG_LEVEL: info

## Features

- User management with multiple roles (admin, marketing, client)
- Integration with marketing AI crew agents
- Secure API access to n8n workflows
- Dashboard for monitoring campaigns and workflows

## Default Login Credentials

- **Admin**: username: admin, password: admin
- **API Access**: username: api_user, password: api_password
