# Script to run the MCP server locally
Write-Host "Starting MCP server locally on port 3001..."
Write-Host "This will allow you to access the web interface at http://localhost:3001"
Write-Host "Press Ctrl+C to stop the server"
Write-Host ""

# Set environment variables
$env:PORT = 3001
$env:N8N_URL = "http://n8n-app.bluegrass-aa868772.eastus.azurecontainerapps.io:5678"
$env:JWT_SECRET = "secure-mcp-jwt-secret-change-this-in-production"
$env:LOG_LEVEL = "debug"

# Run the server
node server.js
