# Script to prepare the MCP server for deployment to Render.com
# Render.com offers free hosting for Node.js applications

Write-Host "Preparing MCP server for deployment to Render.com..."

# Step 1: Create a render.yaml file for easy deployment
$renderYamlContent = @"
services:
  - type: web
    name: n8n-mcp-server
    env: node
    buildCommand: npm install
    startCommand: node server.js
    envVars:
      - key: PORT
        value: 10000
      - key: N8N_URL
        value: http://n8n-app.bluegrass-aa868772.eastus.azurecontainerapps.io:5678
      - key: JWT_SECRET
        value: secure-mcp-jwt-secret-change-this-in-production
      - key: LOG_LEVEL
        value: info
"@
Set-Content -Path "render.yaml" -Value $renderYamlContent

# Step 2: Create a start script for Render
$startScriptContent = @"
#!/bin/bash
# This script is used by Render to start the application
node server.js
"@
Set-Content -Path "start.sh" -Value $startScriptContent

# Step 3: Update package.json for Render
$packageJsonContent = Get-Content -Path "package.json" -Raw | ConvertFrom-Json
$packageJsonContent.engines = @{
    "node" = ">=18.0.0"
}
$packageJsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path "package.json"

# Step 4: Create a README.md with deployment instructions
$readmeContent = @"
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
"@
Set-Content -Path "README.md" -Value $readmeContent

# Step 5: Create a .gitignore file
$gitignoreContent = @"
node_modules/
.env
*.log
.DS_Store
"@
Set-Content -Path ".gitignore" -Value $gitignoreContent

Write-Host "Preparation complete!"
Write-Host "To deploy your MCP server to Render.com:"
Write-Host "1. Create a free account on Render.com"
Write-Host "2. Create a new Web Service and point it to your GitHub repository or upload the code directly"
Write-Host "3. Use the settings in the README.md file"
Write-Host ""
Write-Host "Your MCP Server will be available at a URL provided by Render.com after deployment"
Write-Host "This will be accessible to clients from anywhere with internet access"
