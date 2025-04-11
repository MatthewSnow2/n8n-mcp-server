FROM node:18-alpine

# Create app directory
WORKDIR /app

# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
COPY package*.json ./

# Install dependencies
RUN npm install

# Bundle app source
COPY . .

# Set environment variables for marketing AI crew integration
ENV PORT=3000
ENV N8N_URL=http://n8n-app.bluegrass-aa868772.eastus.azurecontainerapps.io:5678
ENV JWT_SECRET=secure-mcp-jwt-secret-change-this-in-production
ENV LOG_LEVEL=info

# Expose the port the app runs on
EXPOSE 3000

# Command to run the application
CMD ["node", "server.js"]
