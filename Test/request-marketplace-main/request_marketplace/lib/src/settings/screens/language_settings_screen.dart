import 'package:flutter/material.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = 'English';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'es', 'name': 'Spanish', 'nativeName': 'Español'},
    {'code': 'fr', 'name': 'French', 'nativeName': 'Français'},
    {'code': 'de', 'name': 'German', 'nativeName': 'Deutsch'},
    {'code': 'it', 'name': 'Italian', 'nativeName': 'Italiano'},
    {'code': 'pt', 'name': 'Portuguese', 'nativeName': 'Português'},
    {'code': 'zh', 'name': 'Chinese', 'nativeName': '中文'},
    {'code': 'ja', 'name': 'Japanese', 'nativeName': '日本語'},
    {'code': 'ko', 'name': 'Korean', 'nativeName': '한국어'},
    {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية'},
    {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिन्दी'},
    {'code': 'ru', 'name': 'Russian', 'nativeName': 'Русский'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Language Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1D1B20),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Info Section
          Container(
            margin: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    'Language Support',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Color(0xFF666666),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Select your preferred language for the app interface. Some content may still appear in English if translations are not available.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Languages Section
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'Available Languages',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: _languages
                            .map((language) => _buildLanguageItem(language))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const Spacer(),
          
          // Save Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _saveLanguageSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Save Language',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageItem(Map<String, String> language) {
    final isSelected = _selectedLanguage == language['name'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: () => _selectLanguage(language['name']!),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFF1976D2)
                        : const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.language,
                    color: isSelected 
                        ? Colors.white 
                        : const Color(0xFF666666),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language['name']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isSelected 
                              ? const Color(0xFF1976D2) 
                              : const Color(0xFF1D1B20),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        language['nativeName']!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF1976D2),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
  }

  void _saveLanguageSettings() {
    // TODO: Save language preference and apply to app
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Language Changed'),
        content: Text(
          'Your language has been changed to $_selectedLanguage. The app will restart to apply changes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement language change and app restart
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Language changed to $_selectedLanguage'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
