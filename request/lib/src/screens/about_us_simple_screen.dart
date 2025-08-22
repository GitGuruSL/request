import 'package:flutter/material.dart';
import '../services/content_service.dart';
import 'content_page_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsSimpleScreen extends StatefulWidget {
  const AboutUsSimpleScreen({super.key});

  @override
  State<AboutUsSimpleScreen> createState() => _AboutUsSimpleScreenState();
}

class _AboutUsSimpleScreenState extends State<AboutUsSimpleScreen> {
  final ContentService _contentService = ContentService.instance;
  List<ContentPage> _pages = [];
  bool _loading = true;
  String? _appVersion;

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
      if (mounted) {
        _loading = false;
        setState(() {});
      }
    }
  }

  ContentPage? _findPageByKeywords(List<String> keywords) {
    for (final p in _pages) {
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
                // Header logo (optional via metadata.logoUrl)
                if (_getMeta<String>('logoUrl')?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Center(
                      child: Image.network(
                        _getMeta<String>('logoUrl')!,
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                // About text
                if (_getMeta<String>('aboutText')?.isNotEmpty == true)
                  _sectionCard(
                    child: Text(
                      _getMeta<String>('aboutText')!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),

                // Address
                if (_getMeta<String>('hqTitle') != null ||
                    _getMeta<String>('hqAddress') != null)
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_getMeta<String>('hqTitle')?.isNotEmpty == true)
                          Text(_getMeta<String>('hqTitle')!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16)),
                        if (_getMeta<String>('hqAddress')?.isNotEmpty == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(_getMeta<String>('hqAddress')!,
                                style: const TextStyle(fontSize: 16)),
                          ),
                      ],
                    ),
                  ),

                // Support numbers row
                if (_getMeta<String>('supportPassenger')?.isNotEmpty == true ||
                    _getMeta<String>('hotline')?.isNotEmpty == true)
                  _sectionCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _contactColumn('Support - Passenger',
                            _getMeta<String>('supportPassenger')),
                        _contactColumn('Hotline', _getMeta<String>('hotline')),
                      ],
                    ),
                  ),

                // Website link
                if (_getMeta<String>('websiteUrl')?.isNotEmpty == true)
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Website',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () =>
                              _launchUrl(_getMeta<String>('websiteUrl')!),
                          child: Text(
                            _getMeta<String>('websiteUrl')!,
                            style: const TextStyle(
                                color: Colors.indigo, fontSize: 16),
                          ),
                        )
                      ],
                    ),
                  ),

                // Feedback blurb
                if (_getMeta<String>('feedbackText')?.isNotEmpty == true)
                  _sectionCard(
                    child: Text(_getMeta<String>('feedbackText')!,
                        style: const TextStyle(fontSize: 16)),
                  ),

                // Legal and Privacy links
                _sectionCard(
                  child: Column(
                    children: [
                      _tile(
                        icon: Icons.gavel_outlined,
                        title: 'Legal',
                        onTap: () {
                          final preferred = _findPageByKeywords(
                              ['terms', 'legal', 'conditions']);
                          if (preferred != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ContentPageScreen(
                                    slug: preferred.slug,
                                    title: preferred.title),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ContentPageScreen(
                                    slug: 'terms-conditions',
                                    title: 'Terms & Conditions'),
                              ),
                            );
                          }
                        },
                      ),
                      _divider(),
                      _tile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () {
                          final preferred =
                              _findPageByKeywords(['privacy', 'policy']);
                          if (preferred != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ContentPageScreen(
                                    slug: preferred.slug,
                                    title: preferred.title),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ContentPageScreen(
                                    slug: 'privacy-policy',
                                    title: 'Privacy Policy'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Socials row (optional)
                if (_getMeta<String>('facebookUrl')?.isNotEmpty == true ||
                    _getMeta<String>('xUrl')?.isNotEmpty == true)
                  _sectionCard(
                    child: Row(
                      children: [
                        const Text('Follow Us',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(width: 12),
                        if (_getMeta<String>('facebookUrl')?.isNotEmpty == true)
                          IconButton(
                            icon:
                                const Icon(Icons.facebook, color: Colors.blue),
                            onPressed: () =>
                                _launchUrl(_getMeta<String>('facebookUrl')!),
                          ),
                        if (_getMeta<String>('xUrl')?.isNotEmpty == true)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: IconButton(
                              icon: const Icon(Icons.public,
                                  color: Colors.black87),
                              onPressed: () =>
                                  _launchUrl(_getMeta<String>('xUrl')!),
                            ),
                          ),
                      ],
                    ),
                  ),

                // App version footer
                if (_appVersion != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Center(
                      child: Text('App version $_appVersion',
                          style: TextStyle(color: Colors.grey[600])),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
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

  // Helpers to build sections from metadata
  T? _getMeta<T>(String key) {
    // Prefer About Us page metadata; else search other pages
    final page = _findPageByKeywords(['about', 'company']);
    final meta = page?.metadata ?? {};
    final v = meta[key];
    if (v is T) return v;
    if (v is String && T == String) return v as T;
    return null;
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _contactColumn(String label, String? value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 6),
          if (value != null && value.isNotEmpty)
            InkWell(
              onTap: () => _launchUrl('tel:$value'),
              child: Text(value,
                  style: const TextStyle(color: Colors.indigo, fontSize: 16)),
            )
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}
