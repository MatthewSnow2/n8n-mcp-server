const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// Basic routes
app.get('/', (req, res) => {
  res.send(
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
              <p>Connected to n8n instance at: </p>
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
  );
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'MCP Server is running' });
});

// Start the server
app.listen(port, () => {
  console.log(MCP Server is running on port );
  console.log(Connected to n8n instance at );
});
