#!/bin/bash

# Package backend for AWS deployment
echo "📦 Packaging Request Backend for AWS deployment..."

# Create deployment directory
mkdir -p deploy-package

echo "📁 Copying runtime backend files..."

# Entry file (prefer app.js, fallback to server.js)
if [ -f app.js ]; then
	cp app.js deploy-package/
elif [ -f server.js ]; then
	cp server.js deploy-package/
else
	echo "❌ No entry file (app.js/server.js) found" && exit 1
fi

# Package manifests
cp package.json deploy-package/
[ -f package-lock.json ] && cp package-lock.json deploy-package/

# Runtime folders only
for d in routes services middleware utils config database; do
	[ -d "$d" ] && cp -r "$d" deploy-package/ && echo "✅ Copied $d" || echo "⚠️  $d not found"
done

# Optional: include migrations if explicitly requested
if [ "$INCLUDE_MIGRATIONS" = "1" ] && [ -d migrations ]; then
	cp -r migrations deploy-package/
	echo "✅ Included migrations/ (requested)"
fi

# Do NOT include node_modules, tests, mock data, scripts, deploy docs, uploads, etc.
rm -rf deploy-package/node_modules 2>/dev/null || true

# Create archive
echo "🗜️ Creating deployment archive..."
cd deploy-package
tar -czf ../request-backend-deploy.tar.gz .
cd ..

echo "✅ Deployment package created: request-backend-deploy.tar.gz"
echo "📤 Upload this file to your EC2 instance using:"
echo "   scp -i your-key.pem request-backend-deploy.tar.gz ubuntu@YOUR-EC2-IP:~/"

# Clean up
rm -rf deploy-package

echo "🚀 Ready for AWS deployment!"
