#!/bin/bash

# 🌍 Centralized Country Implementation Deployment Script
# This script helps deploy the centralized country-wise filtering system

echo "🌍 Starting Centralized Country Implementation Deployment"
echo "========================================================"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -d "admin-react" ] || [ ! -d "request" ]; then
    print_error "Please run this script from the request-marketplace root directory"
    exit 1
fi

print_status "Deploying centralized country-wise implementation..."

# Step 1: Backup existing files
print_status "Creating backups of existing files..."

backup_dir="backups/$(date +%Y%m%d_%H%M%S)_country_implementation"
mkdir -p "$backup_dir"

# Backup admin React files
if [ -f "admin-react/src/pages/Dashboard.jsx" ]; then
    cp "admin-react/src/pages/Dashboard.jsx" "$backup_dir/Dashboard_old.jsx"
    print_success "Backed up Dashboard.jsx"
fi

# Backup Flutter files if they exist
if [ -f "request/lib/src/services/enhanced_request_service.dart" ]; then
    cp "request/lib/src/services/enhanced_request_service.dart" "$backup_dir/enhanced_request_service_old.dart"
    print_success "Backed up enhanced_request_service.dart"
fi

# Step 2: Deploy admin React changes
print_status "Deploying admin React changes..."

# Replace Dashboard with new version
if [ -f "admin-react/src/pages/DashboardNew.jsx" ]; then
    mv "admin-react/src/pages/Dashboard.jsx" "$backup_dir/Dashboard_original.jsx" 2>/dev/null || true
    mv "admin-react/src/pages/DashboardNew.jsx" "admin-react/src/pages/Dashboard.jsx"
    print_success "Deployed new Dashboard with country filtering"
else
    print_warning "DashboardNew.jsx not found, skipping dashboard update"
fi

# Step 3: Install admin React dependencies if needed
print_status "Checking admin React dependencies..."
cd admin-react

if [ ! -d "node_modules" ]; then
    print_status "Installing admin React dependencies..."
    npm install
    print_success "Installed admin React dependencies"
else
    print_status "Admin React dependencies already installed"
fi

cd ..

# Step 4: Firebase configuration
print_status "Setting up Firebase indexes..."

# Backup existing firestore.indexes.json
if [ -f "firestore.indexes.json" ]; then
    cp "firestore.indexes.json" "$backup_dir/firestore.indexes_old.json"
    print_success "Backed up existing Firestore indexes"
fi

# Merge new indexes with existing ones
if [ -f "firestore.indexes.country.json" ]; then
    print_status "New country-specific indexes are available in firestore.indexes.country.json"
    print_warning "Please manually merge these indexes with your existing firestore.indexes.json"
    print_warning "Or replace firestore.indexes.json with firestore.indexes.country.json if you don't have custom indexes"
fi

# Step 5: Run database migration if script exists
print_status "Checking for database migration scripts..."

if [ -f "add_country_support.js" ]; then
    print_status "Found country support migration script"
    print_warning "Run 'node add_country_support.js' to migrate existing data"
else
    print_warning "Country support migration script not found"
fi

# Step 6: Flutter dependencies
print_status "Checking Flutter dependencies..."
cd request

if [ -f "pubspec.yaml" ]; then
    print_status "Getting Flutter dependencies..."
    flutter pub get
    print_success "Flutter dependencies updated"
else
    print_warning "pubspec.yaml not found, skipping Flutter dependencies"
fi

cd ..

# Step 7: Build admin React app
print_status "Building admin React app..."
cd admin-react

npm run build
if [ $? -eq 0 ]; then
    print_success "Admin React app built successfully"
else
    print_error "Failed to build admin React app"
fi

cd ..

# Step 8: Provide deployment instructions
echo ""
echo "🎯 Deployment Summary"
echo "===================="
print_success "Centralized country system files have been deployed"
print_success "Backups created in: $backup_dir"

echo ""
echo "📋 Next Steps:"
echo "1. 📊 Deploy Firestore indexes:"
echo "   firebase deploy --only firestore:indexes"
echo ""
echo "2. 🗄️  Run database migration (if needed):"
echo "   node add_country_support.js"
echo ""
echo "3. 🧪 Test the system:"
echo "   - Test super admin access (global data)"
echo "   - Test country admin access (country-specific data)"
echo "   - Test Flutter app country filtering"
echo ""
echo "4. 🚀 Deploy admin panel:"
echo "   firebase deploy --only hosting"
echo ""
echo "5. 📱 Build and deploy Flutter app:"
echo "   cd request && flutter build apk"

echo ""
echo "🔧 Configuration Files Created:"
echo "- admin-react/src/services/CountryDataService.js"
echo "- admin-react/src/hooks/useCountryFilter.js"  
echo "- request/lib/src/services/country_filtered_data_service.dart"
echo "- request/lib/src/services/centralized_request_service.dart"
echo "- firestore.indexes.country.json"
echo "- CENTRALIZED_COUNTRY_IMPLEMENTATION.md (detailed guide)"

echo ""
echo "📖 Documentation:"
echo "Read CENTRALIZED_COUNTRY_IMPLEMENTATION.md for detailed usage instructions"

echo ""
echo "⚠️  Important Reminders:"
echo "1. Update your existing admin pages to use useCountryFilter hook"
echo "2. Update Flutter screens to use CentralizedRequestService" 
echo "3. Test thoroughly with different user roles and countries"
echo "4. Deploy Firestore indexes before going live"

print_success "Centralized country implementation deployment completed!"

echo ""
echo "🆘 If you need help:"
echo "1. Check the logs for any errors"
echo "2. Refer to CENTRALIZED_COUNTRY_IMPLEMENTATION.md"
echo "3. Test with different user accounts and countries"
echo "4. Verify Firebase security rules allow country-based access"
