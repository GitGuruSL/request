#!/bin/bash

echo "Fixing currency syntax errors..."

# Find all dart files in requests directory
find /home/cyberexpert/Dev/request-marketplace/request/lib/src/screens/requests -name "*.dart" | while read -r file; do
    echo "Fixing: $file"
    
    # Fix double commas
    sed -i 's/,,/,/g' "$file"
    
    # Fix string concatenation syntax for labels
    sed -i "s/'Budget (' + CurrencyHelper.instance.getCurrency() + ')'/CurrencyHelper.instance.getBudgetLabel()/g" "$file"
    sed -i 's/"Budget (" + CurrencyHelper.instance.getCurrency() + ")"/CurrencyHelper.instance.getBudgetLabel()/g' "$file"
    sed -i "s/'Price (' + CurrencyHelper.instance.getCurrency() + ')'/CurrencyHelper.instance.getPriceLabel()/g" "$file"
    sed -i 's/"Price (" + CurrencyHelper.instance.getCurrency() + ")"/CurrencyHelper.instance.getPriceLabel()/g' "$file"
    sed -i "s/'Rental Price (' + CurrencyHelper.instance.getCurrency() + ')'/CurrencyHelper.instance.getPriceLabel('Rental Price')/g" "$file"
    sed -i "s/'Service Price (' + CurrencyHelper.instance.getCurrency() + ')'/CurrencyHelper.instance.getPriceLabel('Service Price')/g" "$file"
    sed -i "s/'Offered Price (' + CurrencyHelper.instance.getCurrency() + ')'/CurrencyHelper.instance.getPriceLabel('Offered Price')/g" "$file"
    
    # Fix specific variations
    sed -i "s/labelText: 'Budget (' + CurrencyHelper.instance.getCurrency() + ')'/labelText: CurrencyHelper.instance.getBudgetLabel()/g" "$file"
    sed -i 's/labelText: "Budget (" + CurrencyHelper.instance.getCurrency() + ")"/labelText: CurrencyHelper.instance.getBudgetLabel()/g' "$file"
    sed -i "s/labelText: 'Price (' + CurrencyHelper.instance.getCurrency() + ')'/labelText: CurrencyHelper.instance.getPriceLabel()/g" "$file"
    sed -i 's/labelText: "Price (" + CurrencyHelper.instance.getCurrency() + ")"/labelText: CurrencyHelper.instance.getPriceLabel()/g' "$file"
    
done

echo "Syntax fixes completed!"
