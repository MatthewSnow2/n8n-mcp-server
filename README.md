# n8n MCP Server

This is a Message Control Protocol (MCP) server for your n8n instance. It provides a secure intermediary layer between client applications and your n8n workflows.

## What is an MCP Server?

An MCP (Message Control Protocol) server acts as a middleware between your clients and your n8n instance. It provides:

1. **Authentication & Authorization**: Secure access to your n8n workflows
2. **Message Transformation**: Standardize data formats between clients and n8n
3. **Rate Limiting**: Protect your n8n instance from excessive requests
4. **Logging & Monitoring**: Track usage and troubleshoot issues
5. **Client Management**: Control which clients can access which workflows

## Setup Instructions

### Local Development

1. **Install dependencies**:
   ```
   npm install
   ```

2. **Configure environment variables**:
   Edit the `.env` file with your n8n instance details.

3. **Start the server**:
   ```
   npm start
   ```
   
   For development with auto-reload:
   ```
   npm run dev
   ```

### Deploying to Azure

1. **Run the deployment script**:
   ```
   .\deploy-mcp.ps1
   ```

2. **Follow the git deployment instructions** provided by the script.

## Connecting to Your n8n Instance

1. **Enable the n8n API**:
   Run the following command to enable the n8n API:
   ```
   az containerapp update --name n8n-app --resource-group n8n-resources-container-apps --set-env-vars N8N_PUBLIC_API_ENABLED=true N8N_PUBLIC_API_DISABLED_METHODS="" N8N_PUBLIC_API_SWAGGERUI_DISABLED=false
   ```

2. **Create an API Key in n8n**:
   - Log in to your n8n instance
   - Go to Settings > API
   - Create a new API Key
   - Copy the key to your MCP server's `.env` file (N8N_API_KEY)

## Using the MCP Server

### Authentication

Clients must authenticate to get a token:

```
POST /auth/token
Content-Type: application/json

{
  "clientId": "your-client-id",
  "clientSecret": "your-client-secret"
}
```

Response:
```
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Triggering Workflows

Use the token to trigger workflows:

```
POST /webhook/{workflowId}
Authorization: Bearer {token}
Content-Type: application/json

{
  "data": "your workflow data here"
}
```

### Listing Workflows

Get a list of available workflows:

```
GET /workflows
Authorization: Bearer {token}
```

## Security Considerations

1. **Change JWT_SECRET**: Update the JWT_SECRET in the `.env` file to a strong, unique value
2. **Implement proper client authentication**: In production, validate client credentials against a database
3. **Use HTTPS**: Always use HTTPS in production environments
4. **Restrict access**: Consider implementing IP restrictions for additional security

## Integration with Marketing AI Crew

This MCP server can be used to securely connect your marketing AI crew workflows in n8n to client applications. It provides:

1. A secure way for clients to trigger marketing automation workflows
2. Authentication to ensure only authorized clients can access your marketing AI services
3. A standardized API for client applications to interact with your marketing AI crew
