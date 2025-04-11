# Azure deployment script for MCP Server

# Configuration variables - change these as needed
$RESOURCE_GROUP = "n8n-resources-container-apps"  # Use the same resource group as n8n
$LOCATION = "eastus"  # Use the same location as n8n
$APP_NAME = "n8n-mcp-server"
$APP_SERVICE_PLAN = "n8n-app-plan"  # Use existing app plan if available
$SKU = "B1"  # Basic tier

# Check if resource group exists
$rgExists = az group exists --name $RESOURCE_GROUP
if ($rgExists -eq "false") {
    Write-Host "Creating resource group $RESOURCE_GROUP..."
    az group create --name $RESOURCE_GROUP --location $LOCATION
} else {
    Write-Host "Resource group $RESOURCE_GROUP already exists."
}

# Check if App Service Plan exists
$appPlanExists = az appservice plan show --name $APP_SERVICE_PLAN --resource-group $RESOURCE_GROUP
if ($appPlanExists -eq $null) {
    Write-Host "Creating App Service Plan..."
    az appservice plan create `
      --name $APP_SERVICE_PLAN `
      --resource-group $RESOURCE_GROUP `
      --location $LOCATION `
      --sku $SKU
} else {
    Write-Host "App Service Plan $APP_SERVICE_PLAN already exists."
}

# Create Web App
Write-Host "Creating Web App for MCP Server..."
az webapp create `
  --resource-group $RESOURCE_GROUP `
  --plan $APP_SERVICE_PLAN `
  --name $APP_NAME `
  --runtime "NODE:18-lts"

# Configure environment variables
Write-Host "Configuring environment variables..."
az webapp config appsettings set `
  --resource-group $RESOURCE_GROUP `
  --name $APP_NAME `
  --settings `
    PORT=8080 `
    N8N_URL="http://n8n-app.bluegrass-aa868772.eastus.azurecontainerapps.io:5678" `
    JWT_SECRET="secure-mcp-jwt-secret-change-this-in-production" `
    LOG_LEVEL="info"

# Deploy code from local directory
Write-Host "Deploying code to Web App..."
az webapp deployment source config-local-git `
  --resource-group $RESOURCE_GROUP `
  --name $APP_NAME

Write-Host "Deployment configuration complete!"
Write-Host "To deploy your code, run the following commands:"
Write-Host "git init"
Write-Host "git add ."
Write-Host "git commit -m 'Initial commit'"
Write-Host "git remote add azure [URL from the output above]"
Write-Host "git push azure master"
Write-Host ""
Write-Host "Your MCP Server will be available at: https://$APP_NAME.azurewebsites.net"
