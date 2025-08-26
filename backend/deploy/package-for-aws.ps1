# PowerShell script to package backend for AWS deployment

Write-Host "📦 Packaging Request Backend for AWS deployment..." -ForegroundColor Green

# Create deployment directory
if (Test-Path "deploy-package") {
    Remove-Item -Recurse -Force "deploy-package"
}
New-Item -ItemType Directory -Name "deploy-package" | Out-Null

Write-Host "📁 Copying runtime backend files..." -ForegroundColor Yellow

# Entry file (prefer app.js, fallback to server.js)
if (Test-Path "app.js") {
    Copy-Item "app.js" "deploy-package/"
} elseif (Test-Path "server.js") {
    Copy-Item "server.js" "deploy-package/"
} else {
    Write-Error "❌ No entry file (app.js/server.js) found"; exit 1
}

# Package manifests
Copy-Item "package.json" "deploy-package/" -ErrorAction SilentlyContinue
if (Test-Path "package-lock.json") { Copy-Item "package-lock.json" "deploy-package/" }

# Runtime folders only
$runtimeDirs = @("routes", "services", "middleware", "utils", "config", "database")
foreach ($dir in $runtimeDirs) {
    if (Test-Path $dir) {
        Copy-Item -Recurse $dir "deploy-package/" -ErrorAction SilentlyContinue
        Write-Host "✅ Copied $dir" -ForegroundColor Green
    } else {
        Write-Host "⚠️  $dir not found" -ForegroundColor Yellow
    }
}

# Optionally include migrations
if ($env:INCLUDE_MIGRATIONS -eq "1" -and (Test-Path "migrations")) {
    Copy-Item -Recurse "migrations" "deploy-package/"
    Write-Host "✅ Included migrations/ (requested)" -ForegroundColor Green
}

# Exclude heavy/unnecessary content
if (Test-Path "deploy-package/node_modules") { Remove-Item -Recurse -Force "deploy-package/node_modules" }

# Create a simple archive (using built-in compression)
Write-Host "🗜️ Creating deployment archive..." -ForegroundColor Yellow
Compress-Archive -Path "deploy-package\*" -DestinationPath "request-backend-deploy.zip" -Force

Write-Host "✅ Deployment package created: request-backend-deploy.zip" -ForegroundColor Green
Write-Host "📤 Upload this file to your EC2 instance using:" -ForegroundColor Cyan
Write-Host "   scp -i your-key.pem request-backend-deploy.zip ubuntu@YOUR-EC2-IP:~/" -ForegroundColor White

# Clean up
Remove-Item -Recurse -Force "deploy-package"

Write-Host "🚀 Ready for AWS deployment!" -ForegroundColor Green

# Show package size
Write-Host "`n📋 Package created:" -ForegroundColor Cyan
if (Test-Path "request-backend-deploy.zip") {
    $size = (Get-Item "request-backend-deploy.zip").Length / 1MB
    Write-Host ("   Size: {0} MB" -f ([math]::Round($size, 2))) -ForegroundColor White
}
