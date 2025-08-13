import 'package:flutter/material.dart';
import '../utils/currency_helper.dart';

class PriceComparisonScreen extends StatefulWidget {
  const PriceComparisonScreen({super.key});

  @override
  State<PriceComparisonScreen> createState() => _PriceComparisonScreenState();
}

class _PriceComparisonScreenState extends State<PriceComparisonScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All Categories';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Comparison'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddPriceDialog,
            tooltip: 'Add Price Data',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products or services...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All Categories', child: Text('All Categories')),
                    DropdownMenuItem(value: 'Electronics', child: Text('Electronics')),
                    DropdownMenuItem(value: 'Groceries', child: Text('Groceries')),
                    DropdownMenuItem(value: 'Services', child: Text('Services')),
                    DropdownMenuItem(value: 'Vehicles', child: Text('Vehicles')),
                    DropdownMenuItem(value: 'Real Estate', child: Text('Real Estate')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value ?? 'All Categories';
                    });
                  },
                ),
              ],
            ),
          ),
          // Popular Comparisons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Popular Comparisons',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
          // Price Comparison List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 8,
              itemBuilder: (context, index) {
                return _buildPriceComparisonCard(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceComparisonCard(int index) {
    final products = [
      {'name': 'iPhone 15 Pro', 'category': 'Electronics', 'icon': Icons.phone_iphone},
      {'name': 'Toyota Camry', 'category': 'Vehicles', 'icon': Icons.directions_car},
      {'name': 'House Cleaning', 'category': 'Services', 'icon': Icons.cleaning_services},
      {'name': 'Monthly Groceries', 'category': 'Groceries', 'icon': Icons.local_grocery_store},
      {'name': 'Laptop Repair', 'category': 'Services', 'icon': Icons.laptop_mac},
      {'name': 'Apartment Rent', 'category': 'Real Estate', 'icon': Icons.home},
      {'name': 'Hair Salon', 'category': 'Services', 'icon': Icons.content_cut},
      {'name': 'Pizza Delivery', 'category': 'Food', 'icon': Icons.local_pizza},
    ];

    final product = products[index % products.length];
    final basePrice = (index + 1) * 100;
    final prices = [
      basePrice,
      (basePrice * 0.85).round(),
      (basePrice * 1.15).round(),
      (basePrice * 0.95).round(),
    ];
    prices.sort();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(
            product['icon'] as IconData,
            color: Colors.blue[600],
          ),
        ),
        title: Text(product['name'] as String),
        subtitle: Text(
          '${product['category']} • ${prices.length} prices available',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              CurrencyHelper.instance.formatPrice(prices.first.toDouble()),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              'Best Price',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Price Range: ${CurrencyHelper.instance.formatPrice(prices.first.toDouble())} - ${CurrencyHelper.instance.formatPrice(prices.last.toDouble())}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      'Savings: ${CurrencyHelper.instance.formatPrice((prices.last - prices.first).toDouble())}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...prices.map((price) => _buildPriceRow(price, index)).toList(),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('View detailed comparison for ${product['name']}'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(int price, int providerIndex) {
    final providers = ['Store A', 'Store B', 'Store C', 'Store D'];
    final provider = providers[providerIndex % providers.length];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(provider),
          Row(
            children: [
              Text(
                '\$$price',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.star,
                size: 16,
                color: Colors.amber[600],
              ),
              Text(
                '4.${(providerIndex % 5) + 3}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddPriceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Price Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Product/Service Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: CurrencyHelper.instance.getPriceLabel(),
                border: const OutlineInputBorder(),
                prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Store/Provider',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Price data added successfully!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
