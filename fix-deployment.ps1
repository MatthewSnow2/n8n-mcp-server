# Script to fix the MCP server deployment on Azure

# Configuration
$ACR_NAME = "n8nregistry631383"
$ACR_LOGIN_SERVER = "$ACR_NAME.azurecr.io"
$IMAGE_NAME = "mcp-server"
$IMAGE_TAG = "v2"  # Use a new tag to avoid caching issues
$FULL_IMAGE_NAME = "$ACR_LOGIN_SERVER/$IMAGE_NAME`:$IMAGE_TAG"
$RESOURCE_GROUP = "n8n-resources-container-apps"
$CONTAINER_APP_NAME = "n8n-mcp-server"

Write-Host "Fixing MCP server deployment on Azure..."

# Step 1: Create a simple server.js file that will definitely work
$simpleServerContent = @"
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// Basic routes
app.get('/', (req, res) => {
  res.send(`
    <html>
      <head>
        <title>n8n MCP Server</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
      </head>
      <body>
        <div class="container mt-5">
          <div class="card">
            <div class="card-header bg-primary text-white">
              <h2>n8n MCP Server</h2>
            </div>
            <div class="card-body">
              <h4>Server is running!</h4>
              <p>The MCP server is successfully deployed and running.</p>
              <p>Connected to n8n instance at: ${process.env.N8N_URL || 'Not configured'}</p>
              <hr>
              <h5>Login</h5>
              <form>
                <div class="mb-3">
                  <label for="username" class="form-label">Username</label>
                  <input type="text" class="form-control" id="username">
                </div>
                <div class="mb-3">
                  <label for="password" class="form-label">Password</label>
                  <input type="password" class="form-control" id="password">
                </div>
                <button type="submit" class="btn btn-primary">Login</button>
              </form>
            </div>
            <div class="card-footer text-muted">
              <p>For testing purposes only. Full functionality coming soon.</p>
            </div>
          </div>
        </div>
      </body>
    </html>
  `);
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'MCP Server is running' });
});

// Start the server
app.listen(port, () => {
  console.log(`MCP Server is running on port ${port}`);
  console.log(`Connected to n8n instance at ${process.env.N8N_URL || 'Not configured'}`);
});
"@

# Create a temporary directory for the simplified deployment
$tempDir = "simple-mcp-server"
if (Test-Path $tempDir) {
    Remove-Item -Recurse -Force $tempDir
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Create the simplified files
Set-Content -Path "$tempDir/server.js" -Value $simpleServerContent

# Create package.json
$packageJsonContent = @"
{
  "name": "simple-mcp-server",
  "version": "1.0.0",
  "description": "Simple MCP server for n8n instance",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
"@
Set-Content -Path "$tempDir/package.json" -Value $packageJsonContent

# Create Dockerfile
$dockerfileContent = @"
FROM node:18-alpine

# Create app directory
WORKDIR /app

# Install app dependencies
COPY package*.json ./
RUN npm install

# Bundle app source
COPY . .

# Expose the port the app runs on
EXPOSE 3000

# Command to run the application
CMD ["node", "server.js"]
"@
Set-Content -Path "$tempDir/Dockerfile" -Value $dockerfileContent

# Change to the temporary directory
Push-Location $tempDir

# Step 2: Build the image in ACR using ACR Tasks
Write-Host "Building simplified Docker image in Azure Container Registry..."
az acr build --registry $ACR_NAME --image $IMAGE_NAME`:$IMAGE_TAG .

# Step 3: Update the Container App to use the new image
Write-Host "Updating Container App to use the new image..."
az containerapp update `
  --name $CONTAINER_APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --image $FULL_IMAGE_NAME `
  --set-env-vars `
    PORT=3000 `
    N8N_URL="http://n8n-app.bluegrass-aa868772.eastus.azurecontainerapps.io:5678" `
    JWT_SECRET="secure-mcp-jwt-secret-change-this-in-production" `
    LOG_LEVEL="info"

# Return to the original directory
Pop-Location

# Step 4: Get the URL of the deployed Container App
$FQDN = az containerapp show --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --query properties.configuration.ingress.fqdn -o tsv
Write-Host "Deployment fix complete!"
Write-Host "Your simplified MCP Server should now be available at: https://$FQDN"
Write-Host ""
Write-Host "This is a simplified version to verify the deployment works."
Write-Host "Once this is working, we can deploy the full version with all features."
