# PowerShell script to package backend for AWS deployment

Write-Host "📦 Packaging Request Backend for AWS deployment..." -ForegroundColor Green

# Create deployment directory
if (Test-Path "deploy-package") {
    Remove-Item -Recurse -Force "deploy-package"
}
New-Item -ItemType Directory -Name "deploy-package" | Out-Null

# Copy essential files
Write-Host "📁 Copying backend files..." -ForegroundColor Yellow

# Copy JavaScript files
Copy-Item "*.js" "deploy-package/" -ErrorAction SilentlyContinue
Copy-Item "package.json" "deploy-package/" -ErrorAction SilentlyContinue

# Copy directories if they exist
$directories = @("routes", "controllers", "middleware", "models", "config", "utils", "uploads")
foreach ($dir in $directories) {
    if (Test-Path $dir) {
        Copy-Item -Recurse $dir "deploy-package/" -ErrorAction SilentlyContinue
        Write-Host "✅ Copied $dir directory" -ForegroundColor Green
    } else {
        Write-Host "⚠️ No $dir directory found" -ForegroundColor Yellow
    }
}

# Copy deployment files
if (Test-Path "deploy") {
    Copy-Item "deploy/*.env" "deploy-package/" -ErrorAction SilentlyContinue
    Copy-Item "deploy/*.sh" "deploy-package/" -ErrorAction SilentlyContinue
    Copy-Item "deploy/*.md" "deploy-package/" -ErrorAction SilentlyContinue
    Write-Host "✅ Copied deployment files" -ForegroundColor Green
}

# Create a simple archive (using built-in compression)
Write-Host "🗜️ Creating deployment archive..." -ForegroundColor Yellow
Compress-Archive -Path "deploy-package\*" -DestinationPath "request-backend-deploy.zip" -Force

Write-Host "✅ Deployment package created: request-backend-deploy.zip" -ForegroundColor Green
Write-Host "📤 Upload this file to your EC2 instance using:" -ForegroundColor Cyan
Write-Host "   scp -i your-key.pem request-backend-deploy.zip ubuntu@YOUR-EC2-IP:~/" -ForegroundColor White

# Clean up
Remove-Item -Recurse -Force "deploy-package"

Write-Host "🚀 Ready for AWS deployment!" -ForegroundColor Green

# Show package contents
Write-Host "`n📋 Package contents:" -ForegroundColor Cyan
if (Test-Path "request-backend-deploy.zip") {
    $size = (Get-Item "request-backend-deploy.zip").Length / 1MB
    Write-Host "   Size: $([math]::Round($size, 2)) MB" -ForegroundColor White
}
