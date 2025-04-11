# Script to build, push, and deploy the MCP server Docker image

# Configuration
$ACR_NAME = "n8nregistry631383"
$ACR_LOGIN_SERVER = "$ACR_NAME.azurecr.io"
$IMAGE_NAME = "mcp-server"
$IMAGE_TAG = "latest"
$FULL_IMAGE_NAME = "$ACR_LOGIN_SERVER/$IMAGE_NAME`:$IMAGE_TAG"
$RESOURCE_GROUP = "n8n-resources-container-apps"
$CONTAINER_APP_NAME = "n8n-mcp-server"

# Step 1: Login to Azure Container Registry
Write-Host "Logging in to Azure Container Registry..."
az acr login --name $ACR_NAME

# Step 2: Build the Docker image
Write-Host "Building Docker image..."
docker build -t $FULL_IMAGE_NAME .

# Step 3: Push the image to ACR
Write-Host "Pushing image to Azure Container Registry..."
docker push $FULL_IMAGE_NAME

# Step 4: Update the Container App to use the new image
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

# Step 5: Get the URL of the deployed Container App
$FQDN = az containerapp show --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP --query properties.configuration.ingress.fqdn -o tsv
Write-Host "Deployment complete!"
Write-Host "Your MCP Server is available at: https://$FQDN"
Write-Host ""
Write-Host "This MCP server is configured to work with your marketing AI crew n8n instance."
Write-Host "It provides secure API endpoints for clients to interact with your marketing automation workflows."
