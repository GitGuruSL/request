import 'package:flutter/material.dart';
import '../services/content_service.dart';
import 'content_page_screen.dart';

class AboutUsSimpleScreen extends StatefulWidget {
  const AboutUsSimpleScreen({super.key});

  @override
  State<AboutUsSimpleScreen> createState() => _AboutUsSimpleScreenState();
}

class _AboutUsSimpleScreenState extends State<AboutUsSimpleScreen> {
  final ContentService _contentService = ContentService.instance;
  List<ContentPage> _pages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  Future<void> _loadPages() async {
    try {
      final pages = await _contentService.getPages(status: 'published');
      if (mounted)
        setState(() {
          _pages = pages;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  ContentPage? _findPageByKeywords(List<String> keywords) {
    final lower = _pages;
    for (final p in lower) {
      final title = p.title.toLowerCase();
      final cat = (p.category ?? '').toLowerCase();
      if (keywords.any((k) => title.contains(k) || cat.contains(k))) {
        return p;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('About Us'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _tile(
                        icon: Icons.gavel_outlined,
                        title: 'Legal',
                        subtitle: 'Terms and legal information',
                        onTap: () {
                          showLicensePage(
                            context: context,
                            applicationName: 'Request Marketplace',
                            applicationVersion: '1.0.0',
                            applicationLegalese: '© 2025 Request Marketplace',
                          );
                        },
                      ),
                      _divider(),
                      _tile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        subtitle: 'How we handle your data',
                        onTap: () {
                          final preferred =
                              _findPageByKeywords(['privacy', 'policy']);
                          if (preferred != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ContentPageScreen(
                                  slug: preferred.slug,
                                  title: preferred.title,
                                ),
                              ),
                            );
                            return;
                          }
                          // fallback by slug
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ContentPageScreen(
                                slug: 'privacy-policy',
                                title: 'Privacy Policy',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: Colors.blueGrey, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: Colors.grey[200]);
}
