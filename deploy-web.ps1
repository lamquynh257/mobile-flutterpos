# PowerShell script to deploy Flutter web to GitHub Pages branch 'web'

Write-Host "🚀 Deploying Flutter web to GitHub Pages..." -ForegroundColor Cyan

# Get current branch
$currentBranch = git branch --show-current
Write-Host "Current branch: $currentBranch" -ForegroundColor Yellow

# Check if web branch exists
$webBranchExists = git show-ref --verify --quiet refs/heads/web
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Branch 'web' does not exist. Creating it..." -ForegroundColor Red
    git checkout -b web
} else {
    Write-Host "✅ Branch 'web' exists. Checking out..." -ForegroundColor Green
    git checkout web
}

# Remove all files except .git
Write-Host "🧹 Cleaning old files..." -ForegroundColor Yellow
Get-ChildItem -Exclude .git | Remove-Item -Recurse -Force

# Copy build files
Write-Host "📦 Copying build files..." -ForegroundColor Yellow
Copy-Item -Path build\web\* -Destination . -Recurse -Force

# Add, commit, and push
Write-Host "💾 Committing changes..." -ForegroundColor Yellow
git add .
git commit -m "Deploy Flutter web app with base href /mobile-flutterpos/ - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

Write-Host "📤 Pushing to origin/web..." -ForegroundColor Yellow
git push origin web

# Return to original branch
Write-Host "🔄 Returning to branch: $currentBranch" -ForegroundColor Yellow
git checkout $currentBranch

Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host "🌐 Your app will be available at: https://lamquynh257.github.io/mobile-flutterpos/" -ForegroundColor Cyan
Write-Host "⏳ Please wait 1-2 minutes for GitHub Pages to update." -ForegroundColor Yellow

