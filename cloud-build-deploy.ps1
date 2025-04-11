# Script to build and deploy the MCP server using Azure Container Registry Tasks
# This script doesn't require Docker to be installed locally

# Configuration
$ACR_NAME = "n8nregistry631383"
$ACR_LOGIN_SERVER = "$ACR_NAME.azurecr.io"
$IMAGE_NAME = "mcp-server"
$IMAGE_TAG = "latest"
$FULL_IMAGE_NAME = "$ACR_LOGIN_SERVER/$IMAGE_NAME`:$IMAGE_TAG"
$RESOURCE_GROUP = "n8n-resources-container-apps"
$CONTAINER_APP_NAME = "n8n-mcp-server"

# Step 1: Build the image in ACR using ACR Tasks
Write-Host "Building Docker image in Azure Container Registry..."
az acr build --registry $ACR_NAME --image $IMAGE_NAME`:$IMAGE_TAG .

# Step 2: Update the Container App to use the new image
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

# Step 3: Get the URL of the deployed Container App
$FQDN = az containerapp show --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --query properties.configuration.ingress.fqdn -o tsv
Write-Host "Deployment complete!"
Write-Host "Your MCP Server is available at: https://$FQDN"
Write-Host ""
Write-Host "This MCP server is configured to work with your marketing AI crew n8n instance."
Write-Host "It provides secure API endpoints for clients to interact with your marketing automation workflows."
