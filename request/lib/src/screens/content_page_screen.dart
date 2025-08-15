import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/content_service.dart';

class ContentPageScreen extends StatefulWidget {
  final String slug;
  final String? title;

  const ContentPageScreen({
    super.key,
    required this.slug,
    this.title,
  });

  @override
  State<ContentPageScreen> createState() => _ContentPageScreenState();
}

class _ContentPageScreenState extends State<ContentPageScreen> {
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
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final page = await _contentService.getPageBySlug(widget.slug);
      
      if (mounted) {
        setState(() {
          _page = page;
          _isLoading = false;
          if (page == null) {
            _error = 'Page not found';
          }
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
        title: Text(widget.title ?? _page?.title ?? 'Loading...'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
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
              _error!,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPage,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_page == null) {
      return const Center(
        child: Text('Page not found'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPage,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page title
            Text(
              _page!.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Page metadata
            if (_page!.metadata != null) ...[
              _buildMetadata(),
              const SizedBox(height: 16),
            ],
            
            // Page content
            Html(
              data: _page!.content,
              onLinkTap: (url, attributes, element) {
                if (url != null) {
                  _launchUrl(url);
                }
              },
              style: {
                "body": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                ),
                "p": Style(
                  fontSize: FontSize(16),
                  lineHeight: const LineHeight(1.6),
                  margin: Margins.only(bottom: 16),
                ),
                "h1": Style(
                  fontSize: FontSize(24),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(top: 24, bottom: 16),
                  color: Theme.of(context).colorScheme.primary,
                ),
                "h2": Style(
                  fontSize: FontSize(20),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(top: 20, bottom: 12),
                  color: Theme.of(context).colorScheme.primary,
                ),
                "h3": Style(
                  fontSize: FontSize(18),
                  fontWeight: FontWeight.bold,
                  margin: Margins.only(top: 16, bottom: 8),
                  color: Theme.of(context).colorScheme.primary,
                ),
                "a": Style(
                  color: Theme.of(context).colorScheme.secondary,
                  textDecoration: TextDecoration.underline,
                ),
                "ul": Style(
                  margin: Margins.only(bottom: 16),
                ),
                "ol": Style(
                  margin: Margins.only(bottom: 16),
                ),
                "li": Style(
                  margin: Margins.only(bottom: 8),
                ),
                "blockquote": Style(
                  border: Border(
                    left: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 4,
                    ),
                  ),
                  padding: HtmlPaddings.only(left: 16),
                  margin: Margins.only(bottom: 16),
                  backgroundColor: Colors.grey[50],
                ),
                "code": Style(
                  backgroundColor: Colors.grey[100],
                  padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
                  fontFamily: 'monospace',
                ),
                "pre": Style(
                  backgroundColor: Colors.grey[100],
                  padding: HtmlPaddings.all(12),
                  margin: Margins.only(bottom: 16),
                  fontFamily: 'monospace',
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadata() {
    if (_page?.metadata == null) return const SizedBox.shrink();
    
    final metadata = _page!.metadata!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Page Information',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...metadata.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${entry.key}: ${entry.value}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $url')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: $e')),
        );
      }
    }
  }
}
