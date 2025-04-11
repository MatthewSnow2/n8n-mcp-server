# Script to deploy the full MCP server to Azure App Service

# Configuration
$RESOURCE_GROUP = "n8n-resources-container-apps"
$APP_SERVICE_PLAN = "n8n-mcp-plan"
$APP_NAME = "n8n-mcp-server-app"
$LOCATION = "eastus"

Write-Host "Deploying full MCP server to Azure App Service..."

# Step 1: Create App Service Plan if it doesn't exist
$planExists = az appservice plan show --name $APP_SERVICE_PLAN --resource-group $RESOURCE_GROUP 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating App Service Plan..."
    az appservice plan create --name $APP_SERVICE_PLAN --resource-group $RESOURCE_GROUP --sku B1 --is-linux
} else {
    Write-Host "App Service Plan already exists."
}

# Step 2: Create Web App if it doesn't exist
$appExists = az webapp show --name $APP_NAME --resource-group $RESOURCE_GROUP 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating Web App..."
    az webapp create --name $APP_NAME --resource-group $RESOURCE_GROUP --plan $APP_SERVICE_PLAN --runtime "NODE:18-lts"
} else {
    Write-Host "Web App already exists."
}

# Step 3: Configure App Settings
Write-Host "Configuring App Settings..."
az webapp config appsettings set --name $APP_NAME --resource-group $RESOURCE_GROUP --settings `
    PORT=8080 `
    N8N_URL="http://n8n-app.bluegrass-aa868772.eastus.azurecontainerapps.io:5678" `
    JWT_SECRET="secure-mcp-jwt-secret-change-this-in-production" `
    LOG_LEVEL="debug" `
    WEBSITE_NODE_DEFAULT_VERSION="~18" `
    SCM_DO_BUILD_DURING_DEPLOYMENT="true"

# Step 4: Configure for deployment
Write-Host "Configuring local Git deployment..."
az webapp deployment source config-local-git --name $APP_NAME --resource-group $RESOURCE_GROUP

# Step 5: Get the deployment URL and credentials
$deploymentUrl = az webapp deployment source config-local-git --name $APP_NAME --resource-group $RESOURCE_GROUP --query url -o tsv
$publishProfile = [xml](az webapp deployment list-publishing-profiles --name $APP_NAME --resource-group $RESOURCE_GROUP --xml)
$username = $publishProfile.SelectSingleNode("//publishProfile[@publishMethod='MSDeploy']").userName
$password = $publishProfile.SelectSingleNode("//publishProfile[@publishMethod='MSDeploy']").userPWD

# Step 6: Create a web.config file for Node.js
$webConfigContent = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <webSocket enabled="false" />
    <handlers>
      <add name="iisnode" path="server.js" verb="*" modules="iisnode"/>
    </handlers>
    <rewrite>
      <rules>
        <rule name="StaticContent">
          <action type="Rewrite" url="public{REQUEST_URI}"/>
        </rule>
        <rule name="DynamicContent">
          <conditions>
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="True"/>
          </conditions>
          <action type="Rewrite" url="server.js"/>
        </rule>
      </rules>
    </rewrite>
    <iisnode watchedFiles="web.config;*.js"/>
  </system.webServer>
</configuration>
"@
Set-Content -Path "web.config" -Value $webConfigContent

# Step 7: Initialize Git repository if not already initialized
if (-not (Test-Path ".git")) {
    Write-Host "Initializing Git repository..."
    git init
    git add .
    git commit -m "Initial commit for Azure App Service deployment"
}

# Step 8: Add Azure as a remote
$remoteExists = git remote -v | Select-String -Pattern "azure"
if (-not $remoteExists) {
    Write-Host "Adding Azure as a remote..."
    git remote add azure $deploymentUrl
} else {
    Write-Host "Azure remote already exists."
    git remote set-url azure $deploymentUrl
}

# Step 9: Instructions for deployment
Write-Host ""
Write-Host "Deployment configuration complete!"
Write-Host "Your MCP Server will be available at: https://$APP_NAME.azurewebsites.net"
Write-Host ""
Write-Host "To deploy your code, run the following commands:"
Write-Host "git add ."
Write-Host "git commit -m 'Deploy to Azure'"
Write-Host "git push azure master"
Write-Host ""
Write-Host "When prompted, use these credentials:"
Write-Host "Username: $username"
Write-Host "Password: $password"
