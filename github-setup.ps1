# Script to set up GitHub repository for the MCP server

# Replace with your actual GitHub username
$GITHUB_USERNAME = "your-github-username"

# Repository name
$REPO_NAME = "n8n-mcp-server"

# GitHub repository URL
$GITHUB_URL = "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"

Write-Host "Setting up GitHub repository for MCP server..."
Write-Host "Using repository URL: $GITHUB_URL"

# Check if git is already initialized
if (Test-Path ".git") {
    Write-Host "Git repository already initialized."
} else {
    Write-Host "Initializing git repository..."
    git init
}

# Add all files to git
Write-Host "Adding files to git..."
git add .

# Commit changes
Write-Host "Committing changes..."
git commit -m "Initial commit for MCP server"

# Add GitHub as remote
Write-Host "Adding GitHub as remote..."
git remote add origin $GITHUB_URL

Write-Host "Setup complete!"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Create a repository on GitHub named '$REPO_NAME'"
Write-Host "2. Run: git push -u origin master"
Write-Host ""
Write-Host "Note: Before running this script, make sure to:"
Write-Host "- Replace 'your-github-username' with your actual GitHub username"
Write-Host "- Create the repository on GitHub at: https://github.com/new"
