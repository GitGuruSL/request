#!/bin/bash

echo "Fixing budget display formats..."

# List of response screen files that need budget display fixes
files=(
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/service/create_service_response_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/item/create_item_response_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/delivery/create_delivery_response_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/rent/create_rent_response_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/ride/create_ride_response_screen.dart"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "Processing: $file"
        
        # Fix various budget display patterns
        sed -i 's/Text('\''Budget: \\\$\${widget\.request\.budget!\.toStringAsFixed(2)}/Text('\''Budget: \${CurrencyHelper.instance.formatPrice(widget.request.budget!)}/g' "$file"
        sed -i 's/Text("Budget: \\\$\${widget\.request\.budget!\.toStringAsFixed(2)}/Text("Budget: \${CurrencyHelper.instance.formatPrice(widget.request.budget!)}/g' "$file"
        sed -i 's/Text(CurrencyHelper\.instance\.formatPrice(widget\.request\.budget!))'\''),/Text('\''Budget: \${CurrencyHelper.instance.formatPrice(widget.request.budget!)}'\''),/g' "$file"
        
        # Fix specific syntax errors
        sed -i 's/Text(CurrencyHelper\.instance\.formatPrice(widget\.request\.budget!))'\'')/Text('\''Budget: \${CurrencyHelper.instance.formatPrice(widget.request.budget!)}'\''),/g' "$file"
        
    fi
done

echo "Budget display fixes completed!"
