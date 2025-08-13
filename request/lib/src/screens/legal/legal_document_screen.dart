import 'package:flutter/material.dart';
import '../../services/legal_documents_service.dart';
import '../../services/country_service.dart';
import '../../theme/app_theme.dart';

class LegalDocumentScreen extends StatefulWidget {
  final String documentType; // 'privacy' or 'terms'
  final String? countryCode; // Optional, uses user's country if not provided

  const LegalDocumentScreen({
    super.key,
    required this.documentType,
    this.countryCode,
  });

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  final LegalDocumentsService _legalService = LegalDocumentsService();
  final CountryService _countryService = CountryService.instance;
  
  LegalDocument? _document;
  bool _isLoading = true;
  String? _error;
  String? _userCountry;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final countryCode = widget.countryCode ?? _countryService.countryCode;
      _userCountry = _countryService.countryName;

      LegalDocument? document;
      if (widget.documentType == 'privacy') {
        document = await _legalService.getPrivacyPolicy(countryCode: countryCode);
      } else if (widget.documentType == 'terms') {
        document = await _legalService.getTermsAndConditions(countryCode: countryCode);
      }

      setState(() {
        _document = document;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load document: $e';
        _isLoading = false;
      });
    }
  }

  String get _screenTitle {
    switch (widget.documentType) {
      case 'privacy':
        return 'Privacy Policy';
      case 'terms':
        return 'Terms & Conditions';
      default:
        return 'Legal Document';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        title: Text(_screenTitle),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading document...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(
                  color: AppTheme.errorColor,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadDocument,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_document == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.description_outlined,
                size: 64,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'No ${widget.documentType == 'privacy' ? 'privacy policy' : 'terms and conditions'} available for your region.',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              if (_userCountry != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Country: $_userCountry',
                  style: const TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: AppTheme.cardDecoration,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document Header
            Text(
              _document!.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            
            // Document Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.public,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Country: ${_userCountry ?? _document!.countryCode}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Last updated: ${_formatDate(_document!.lastUpdated)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Version: ${_document!.version}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Document Content
            Text(
              _document!.content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: AppTheme.textPrimary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'This document is specific to your selected country and may differ from versions in other regions. If you have questions about these terms, please contact our support team.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Convenience widgets for specific document types
class PrivacyPolicyScreen extends StatelessWidget {
  final String? countryCode;
  
  const PrivacyPolicyScreen({super.key, this.countryCode});

  @override
  Widget build(BuildContext context) {
    return LegalDocumentScreen(
      documentType: 'privacy',
      countryCode: countryCode,
    );
  }
}

class TermsAndConditionsScreen extends StatelessWidget {
  final String? countryCode;
  
  const TermsAndConditionsScreen({super.key, this.countryCode});

  @override
  Widget build(BuildContext context) {
    return LegalDocumentScreen(
      documentType: 'terms',
      countryCode: countryCode,
    );
  }
}
