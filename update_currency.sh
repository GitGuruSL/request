#!/bin/bash

# Files that need currency updates
files=(
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/service/create_service_request_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/service/edit_service_request_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/service/edit_service_response_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/service/create_service_response_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/rent/edit_rent_response_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/rent/create_rent_response_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/rent/edit_rent_request_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/rent/create_rent_request_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/delivery/edit_delivery_request_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/delivery/edit_delivery_response_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/delivery/create_delivery_request_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/delivery/create_delivery_response_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/item/create_item_response_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/item/edit_item_request_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/item/edit_item_response_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/ride/create_ride_response_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/ride/create_ride_request_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/ride/edit_ride_request_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/ride/edit_ride_response_screen.dart"
"/home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests/create_price_request_screen.dart"
)

echo "Updating currency imports and fields in ${#files[@]} files..."

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "Processing: $file"
        
        # Add currency_helper import if not exists
        if ! grep -q "currency_helper.dart" "$file"; then
            # Find the last import line and add after it
            sed -i "/import.*dart';$/a import '../../../utils/currency_helper.dart';" "$file" 2>/dev/null || 
            sed -i "/import.*dart';$/a import '../../utils/currency_helper.dart';" "$file" 2>/dev/null ||
            sed -i "/import.*dart';$/a import '../utils/currency_helper.dart';" "$file"
        fi
        
        # Replace hard-coded USD currency
        sed -i "s/'USD'/CurrencyHelper.instance.getCurrency()/g" "$file"
        sed -i 's/"USD"/CurrencyHelper.instance.getCurrency()/g' "$file"
        sed -i "s/'currency': 'USD'/'currency': CurrencyHelper.instance.getCurrency()/g" "$file"
        sed -i 's/"currency": "USD"/"currency": CurrencyHelper.instance.getCurrency()/g' "$file"
        sed -i "s/currency: 'USD'/currency: CurrencyHelper.instance.getCurrency()/g" "$file"
        sed -i 's/currency: "USD"/currency: CurrencyHelper.instance.getCurrency()/g' "$file"
        
        # Replace dollar prefixText
        sed -i "s/prefixText: '\\\\$ '/prefixText: CurrencyHelper.instance.getCurrencyPrefix(),/g" "$file"
        sed -i 's/prefixText: "\\$ "/prefixText: CurrencyHelper.instance.getCurrencyPrefix(),/g' "$file"
        
        # Replace Budget/Price labels with USD
        sed -i "s/'Budget (USD)'/'Budget (' + CurrencyHelper.instance.getCurrency() + ')'/g" "$file"
        sed -i 's/"Budget (USD)"/"Budget (" + CurrencyHelper.instance.getCurrency() + ")"/g' "$file"
        sed -i "s/'Price (USD)'/'Price (' + CurrencyHelper.instance.getCurrency() + ')'/g" "$file"
        sed -i 's/"Price (USD)"/"Price (" + CurrencyHelper.instance.getCurrency() + ")"/g' "$file"
        
        # More specific replacements
        sed -i "s/labelText: 'Budget (USD)'/labelText: CurrencyHelper.instance.getBudgetLabel()/g" "$file"
        sed -i 's/labelText: "Budget (USD)"/labelText: CurrencyHelper.instance.getBudgetLabel()/g' "$file"
        sed -i "s/labelText: 'Price (USD)'/labelText: CurrencyHelper.instance.getPriceLabel()/g" "$file"
        sed -i 's/labelText: "Price (USD)"/labelText: CurrencyHelper.instance.getPriceLabel()/g' "$file"
        sed -i "s/labelText: 'Rental Price (USD)'/labelText: CurrencyHelper.instance.getPriceLabel('Rental Price')/g" "$file"
        sed -i "s/labelText: 'Service Price (USD)'/labelText: CurrencyHelper.instance.getPriceLabel('Service Price')/g" "$file"
        sed -i "s/labelText: 'Offered Price (USD)'/labelText: CurrencyHelper.instance.getPriceLabel('Offered Price')/g" "$file"
        
        # Fix const decoration to non-const when using helper
        sed -i 's/decoration: const InputDecoration(/decoration: InputDecoration(/g' "$file"
        
    else
        echo "File not found: $file"
    fi
done

echo "Currency updates completed!"
