// AI Integration Service for Product Management
// Handles AI-powered product data extraction and categorization

import 'dart:convert';
import 'dart:math';
import '../models/product_models.dart';

class AIService {
  // Simulated AI service - in production, integrate with actual AI APIs
  // like OpenAI GPT, Google Vision API, or custom ML models

  /// Extract product information from text description
  Future<Map<String, dynamic>> extractProductFromText(String description) async {
    // Simulate AI processing delay
    await Future.delayed(const Duration(seconds: 2));

    final words = description.toLowerCase().split(' ');
    final random = Random();

    // Simple keyword-based extraction (replace with actual AI)
    final extractedData = {
      'name': _extractProductName(description),
      'brand': _extractBrand(words),
      'category': _extractCategory(words),
      'specifications': _extractSpecifications(words),
      'keywords': _generateKeywords(words),
      'confidence': 0.7 + (random.nextDouble() * 0.3), // 70-100% confidence
      'description': _generateDescription(description),
    };

    return extractedData;
  }

  /// Extract product information from URL (web scraping simulation)
  Future<Map<String, dynamic>> extractProductFromUrl(String url) async {
    // Simulate web scraping and AI processing
    await Future.delayed(const Duration(seconds: 3));

    final random = Random();
    
    // Simulate extracted data from website
    return {
      'name': _generateRandomProductName(),
      'brand': _getRandomBrand(),
      'category': _getRandomCategory(),
      'price': random.nextDouble() * 50000 + 1000, // LKR 1,000 - 51,000
      'specifications': _generateRandomSpecs(),
      'imageUrls': _generateProductImages(),
      'keywords': _generateRandomKeywords(),
      'confidence': 0.8 + (random.nextDouble() * 0.2), // 80-100% confidence
      'description': 'AI-generated product description from web scraping',
      'source': url,
    };
  }

  /// Extract product information from image
  Future<Map<String, dynamic>> extractProductFromImage(String imagePath) async {
    // Simulate image recognition and AI processing
    await Future.delayed(const Duration(seconds: 4));

    final random = Random();

    return {
      'name': _generateRandomProductName(),
      'brand': 'Unknown', // Often harder to detect from images
      'category': _getRandomCategory(),
      'specifications': _generateBasicSpecs(),
      'keywords': _generateImageKeywords(),
      'confidence': 0.6 + (random.nextDouble() * 0.3), // 60-90% confidence
      'description': 'AI-generated description from image analysis',
      'needsVerification': true, // Image analysis often needs human verification
    };
  }

  /// Suggest category for a product
  Future<String> suggestCategory(String productName, String description) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final text = '$productName $description'.toLowerCase();
    
    // Simple keyword matching (replace with ML classification)
    if (text.contains(RegExp(r'phone|mobile|smartphone|tablet'))) {
      return 'electronics_mobile';
    } else if (text.contains(RegExp(r'laptop|computer|pc|desktop'))) {
      return 'electronics_computers';
    } else if (text.contains(RegExp(r'tv|television|monitor|screen'))) {
      return 'electronics_tv';
    } else if (text.contains(RegExp(r'shoe|shoes|sneaker|boot'))) {
      return 'fashion_footwear';
    } else if (text.contains(RegExp(r'shirt|t-shirt|dress|pant|jean'))) {
      return 'fashion_clothing';
    } else if (text.contains(RegExp(r'book|novel|magazine'))) {
      return 'books_literature';
    } else if (text.contains(RegExp(r'car|vehicle|auto|motor'))) {
      return 'automotive_vehicles';
    } else if (text.contains(RegExp(r'home|furniture|chair|table'))) {
      return 'home_furniture';
    } else {
      return 'general_other';
    }
  }

  /// Enhance product description using AI
  Future<String> enhanceProductDescription(String originalDescription) async {
    await Future.delayed(const Duration(seconds: 1));

    // Simulate AI enhancement
    return '''$originalDescription

Enhanced with AI features:
• High-quality construction and materials
• Competitive pricing in the market
• Suitable for various user needs
• Reliable performance and durability
• Easy to use and maintain

*This description has been enhanced with AI assistance*''';
  }

  /// Generate SEO-friendly keywords
  Future<List<String>> generateSEOKeywords(String productName, String category) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final baseKeywords = productName.toLowerCase().split(' ');
    final categoryKeywords = _getCategoryKeywords(category);
    
    return [
      ...baseKeywords,
      ...categoryKeywords,
      'best price',
      'buy online',
      'sri lanka',
      'delivery',
      'warranty',
      'quality',
      'affordable',
      'genuine',
    ];
  }

  /// Validate product data quality
  Future<Map<String, dynamic>> validateProductData(Map<String, dynamic> productData) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final validationResults = <String, dynamic>{
      'isValid': true,
      'confidence': productData['confidence'] ?? 0.5,
      'issues': <String>[],
      'suggestions': <String>[],
    };

    // Check required fields
    if (productData['name'] == null || productData['name'].toString().trim().isEmpty) {
      validationResults['isValid'] = false;
      validationResults['issues'].add('Product name is required');
    }

    if (productData['category'] == null || productData['category'].toString().trim().isEmpty) {
      validationResults['issues'].add('Product category is missing');
      validationResults['suggestions'].add('Consider categorizing as "General"');
    }

    // Check description quality
    final description = productData['description']?.toString() ?? '';
    if (description.length < 20) {
      validationResults['suggestions'].add('Product description could be more detailed');
    }

    // Check image availability
    final imageUrls = productData['imageUrls'] as List<String>? ?? [];
    if (imageUrls.isEmpty) {
      validationResults['suggestions'].add('Adding product images would improve visibility');
    }

    return validationResults;
  }

  // Helper methods for AI simulation

  String _extractProductName(String description) {
    // Simple extraction - take first few meaningful words
    final words = description.split(' ');
    return words.take(3).join(' ').trim();
  }

  String _extractBrand(List<String> words) {
    final commonBrands = [
      'apple', 'samsung', 'sony', 'lg', 'hp', 'dell', 'lenovo',
      'nike', 'adidas', 'puma', 'under armour', 'levi\'s',
      'toyota', 'honda', 'nissan', 'bmw', 'mercedes'
    ];

    for (final word in words) {
      if (commonBrands.contains(word.toLowerCase())) {
        return word.toLowerCase();
      }
    }
    return 'Generic';
  }

  String _extractCategory(List<String> words) {
    final text = words.join(' ');
    
    if (text.contains(RegExp(r'phone|mobile'))) return 'electronics_mobile';
    if (text.contains(RegExp(r'laptop|computer'))) return 'electronics_computers';
    if (text.contains(RegExp(r'shoe|sneaker'))) return 'fashion_footwear';
    if (text.contains(RegExp(r'shirt|dress'))) return 'fashion_clothing';
    
    return 'general_other';
  }

  Map<String, dynamic> _extractSpecifications(List<String> words) {
    final specs = <String, dynamic>{};
    
    // Look for size mentions
    for (final word in words) {
      if (RegExp(r'\d+(\.\d+)?\s*(inch|gb|mb|kg|cm)').hasMatch(word)) {
        specs['size'] = word;
        break;
      }
    }
    
    // Look for color mentions
    final colors = ['black', 'white', 'red', 'blue', 'green', 'yellow', 'silver', 'gold'];
    for (final word in words) {
      if (colors.contains(word.toLowerCase())) {
        specs['color'] = word.toLowerCase();
        break;
      }
    }
    
    return specs;
  }

  List<String> _generateKeywords(List<String> words) {
    return words.where((word) => word.length > 3).take(10).toList();
  }

  String _generateDescription(String originalDescription) {
    if (originalDescription.length > 50) {
      return originalDescription;
    }
    return '$originalDescription - Enhanced with AI-generated details for better product understanding.';
  }

  String _generateRandomProductName() {
    final adjectives = ['Premium', 'Professional', 'Advanced', 'Smart', 'Ultra', 'Pro'];
    final nouns = ['Device', 'Product', 'Item', 'Gadget', 'Tool', 'Accessory'];
    final random = Random();
    
    return '${adjectives[random.nextInt(adjectives.length)]} ${nouns[random.nextInt(nouns.length)]}';
  }

  String _getRandomBrand() {
    final brands = ['Samsung', 'Apple', 'Sony', 'LG', 'HP', 'Dell', 'Nike', 'Generic'];
    return brands[Random().nextInt(brands.length)];
  }

  String _getRandomCategory() {
    final categories = [
      'electronics_mobile',
      'electronics_computers',
      'fashion_clothing',
      'fashion_footwear',
      'home_furniture',
      'books_literature'
    ];
    return categories[Random().nextInt(categories.length)];
  }

  Map<String, dynamic> _generateRandomSpecs() {
    final random = Random();
    return {
      'color': ['Black', 'White', 'Silver', 'Blue'][random.nextInt(4)],
      'weight': '${random.nextInt(1000) + 100}g',
      'dimensions': '${random.nextInt(20) + 10}x${random.nextInt(15) + 5}x${random.nextInt(5) + 1}cm',
    };
  }

  Map<String, dynamic> _generateBasicSpecs() {
    return {
      'color': 'Various',
      'material': 'Standard',
    };
  }

  List<String> _generateProductImages() {
    final random = Random();
    final imageCount = random.nextInt(3) + 1; // 1-3 images
    
    return List.generate(imageCount, (index) => 
        'https://via.placeholder.com/400x400?text=Product+Image+${index + 1}');
  }

  List<String> _generateRandomKeywords() {
    final keywords = [
      'quality', 'durable', 'reliable', 'affordable', 'premium',
      'modern', 'stylish', 'functional', 'efficient', 'popular'
    ];
    
    final random = Random();
    return keywords..shuffle(random);
  }

  List<String> _generateImageKeywords() {
    return ['visual', 'image-based', 'photo', 'picture', 'appearance'];
  }

  List<String> _getCategoryKeywords(String category) {
    switch (category) {
      case 'electronics_mobile':
        return ['smartphone', 'mobile phone', 'android', 'ios', 'cellular'];
      case 'electronics_computers':
        return ['laptop', 'desktop', 'computer', 'pc', 'technology'];
      case 'fashion_clothing':
        return ['clothing', 'apparel', 'fashion', 'wear', 'style'];
      case 'fashion_footwear':
        return ['shoes', 'footwear', 'sneakers', 'boots', 'sandals'];
      case 'home_furniture':
        return ['furniture', 'home', 'decor', 'interior', 'living'];
      default:
        return ['product', 'item', 'goods', 'merchandise'];
    }
  }

  /// Bulk process products from CSV data
  Future<List<Map<String, dynamic>>> processBulkProducts(List<Map<String, dynamic>> csvData) async {
    final processedProducts = <Map<String, dynamic>>[];
    
    for (final row in csvData) {
      try {
        // Simulate AI processing for each product
        await Future.delayed(const Duration(milliseconds: 100));
        
        final processed = await extractProductFromText(row['description'] ?? row['name'] ?? '');
        processed['originalData'] = row;
        processed['bulkImport'] = true;
        
        processedProducts.add(processed);
      } catch (e) {
        print('Error processing product: $e');
        // Continue with next product
      }
    }
    
    return processedProducts;
  }

  /// Get price suggestions based on market data
  Future<Map<String, dynamic>> getPriceSuggestions(String productName, String category) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final random = Random();
    final basePrice = random.nextDouble() * 20000 + 5000; // LKR 5,000 - 25,000
    
    return {
      'suggestedPrice': basePrice,
      'priceRange': {
        'min': basePrice * 0.8,
        'max': basePrice * 1.3,
      },
      'marketAverage': basePrice * 1.1,
      'competitorPrices': List.generate(5, (index) => 
          basePrice + (random.nextDouble() - 0.5) * basePrice * 0.4),
      'confidence': 0.7,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
}
