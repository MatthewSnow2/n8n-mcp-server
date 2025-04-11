# Azure Container Apps deployment script for MCP Server

# Configuration variables - change these as needed
$RESOURCE_GROUP = "n8n-resources-container-apps"  # Use the same resource group as n8n
$LOCATION = "eastus"  # Use the same location as n8n
$ENVIRONMENT_NAME = "n8n-environment"  # Use existing environment from n8n deployment
$APP_NAME = "n8n-mcp-server"
$IMAGE_NAME = "node:18-alpine"  # Base Node.js image

# Check if resource group exists
$rgExists = az group exists --name $RESOURCE_GROUP
if ($rgExists -eq "false") {
    Write-Host "Creating resource group $RESOURCE_GROUP..."
    az group create --name $RESOURCE_GROUP --location $LOCATION
} else {
    Write-Host "Resource group $RESOURCE_GROUP already exists."
}

# Create a Dockerfile for the MCP server
Write-Host "Creating Dockerfile..."
@"
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
"@ | Out-File -FilePath "Dockerfile" -Encoding utf8

# Build and push the Docker image to Azure Container Registry
Write-Host "Creating Container App..."
az containerapp create `
  --name $APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --environment $ENVIRONMENT_NAME `
  --image $IMAGE_NAME `
  --target-port 3000 `
  --ingress external `
  --min-replicas 1 `
  --max-replicas 1 `
  --cpu 0.5 `
  --memory 1.0Gi `
  --env-vars `
    PORT=3000 `
    N8N_URL="http://n8n-app.bluegrass-aa868772.eastus.azurecontainerapps.io:5678" `
    JWT_SECRET="secure-mcp-jwt-secret-change-this-in-production" `
    LOG_LEVEL="info"

# Get the FQDN of the Container App
$FQDN = az containerapp show --name $APP_NAME --resource-group $RESOURCE_GROUP --query properties.configuration.ingress.fqdn -o tsv

Write-Host "Deployment configuration complete!"
Write-Host "Your MCP Server will be available at: https://$FQDN"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Build a Docker image with your MCP server code"
Write-Host "2. Push it to a container registry"
Write-Host "3. Update the Container App to use your image"
Write-Host ""
Write-Host "For local testing, you can run your MCP server with:"
Write-Host "npm install"
Write-Host "npm start"
