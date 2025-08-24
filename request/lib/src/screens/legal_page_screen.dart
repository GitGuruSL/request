import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../services/content_service.dart';

class LegalPageScreen extends StatefulWidget {
  final String pageSlug;
  final String pageTitle;

  const LegalPageScreen({
    super.key,
    required this.pageSlug,
    required this.pageTitle,
  });

  @override
  State<LegalPageScreen> createState() => _LegalPageScreenState();
}

class _LegalPageScreenState extends State<LegalPageScreen> {
  final ContentService _contentService = ContentService.instance;
  ContentPage? _page;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final page = await _contentService.getPageBySlug(widget.pageSlug);

      if (mounted) {
        setState(() {
          _page = page;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load page: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pageTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Page',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPage,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_page == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The requested page could not be found.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[50]!,
                  Colors.white,
                ],
              ),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _page!.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                ),
                const SizedBox(height: 8),
                if (_page!.metadata?['metaDescription'] != null)
                  Text(
                    _page!.metadata!['metaDescription']!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                const SizedBox(height: 16),
                _buildPageInfo(),
              ],
            ),
          ),

          // Page Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Page Information',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Category', _page!.category ?? 'Legal'),
          _buildInfoRow('Type', _page!.type.replaceAll('_', ' ').toUpperCase()),
          _buildInfoRow('Status', _page!.status.toUpperCase()),
          if (_page!.targetCountry != null)
            _buildInfoRow('Country', _page!.targetCountry!.toUpperCase()),
          _buildInfoRow('Last Updated', _formatDate(_page!.updatedAt)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final content = _page!.content;

    // Check if content looks like HTML
    if (content.contains('<') && content.contains('>')) {
      return Html(
        data: content,
        style: {
          "body": Style(
            fontSize: FontSize(16.0),
            lineHeight: LineHeight(1.6),
            color: Colors.grey[800],
          ),
          "h1": Style(
            fontSize: FontSize(24.0),
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
            margin: Margins.only(top: 24, bottom: 16),
          ),
          "h2": Style(
            fontSize: FontSize(20.0),
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
            margin: Margins.only(top: 20, bottom: 12),
          ),
          "h3": Style(
            fontSize: FontSize(18.0),
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
            margin: Margins.only(top: 16, bottom: 8),
          ),
          "p": Style(
            margin: Margins.only(bottom: 16),
          ),
          "ul": Style(
            margin: Margins.only(bottom: 16),
          ),
          "ol": Style(
            margin: Margins.only(bottom: 16),
          ),
          "li": Style(
            margin: Margins.only(bottom: 4),
          ),
        },
      );
    } else {
      // Plain text content with basic formatting
      return Text(
        content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              height: 1.6,
              color: Colors.grey[800],
            ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
