import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import '../services/content_service.dart';
import '../services/api_client.dart';
import 'content_page_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/glass_theme.dart';

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
  String? _resolvedLogoUrl;

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  Future<void> _loadPages() async {
    try {
      // Prefer published pages; if none, fall back to approved so global
      // admin content is visible prior to publishing.
      var pages = await _contentService.getPages(status: 'published');
      if (pages.isEmpty) {
        final approved = await _contentService.getPages(status: 'approved');
        if (approved.isNotEmpty) pages = approved;
      }
      // Resolve a displayable logo URL from the freshly fetched pages
      final rawLogo = _getMetaFromPages<String>(pages, 'logoUrl');
      String? logoToUse;
      if (rawLogo != null && rawLogo.isNotEmpty) {
        logoToUse = await _resolveDisplayUrl(rawLogo);
      }
      if (mounted)
        setState(() {
          _pages = pages;
          _loading = false;
          _resolvedLogoUrl = logoToUse ?? rawLogo;
        });
    } catch (_) {
      if (mounted) {
        _loading = false;
        setState(() {});
      }
    }
  }

  // Minimal API base resolver mirroring ContentService logic
  String get _apiBaseUrl {
    if (kIsWeb) return 'http://localhost:3001';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  Future<String?> _resolveDisplayUrl(String url) async {
    try {
      final lower = url.toLowerCase();
      final isS3 = lower.contains('amazonaws.com') || lower.contains('.s3.');
      final alreadySigned = lower.contains('x-amz-signature');
      if (!isS3 || alreadySigned) return url;
      final token = await ApiClient.instance.getToken();
      final resp = await http.post(
        Uri.parse('$_apiBaseUrl/api/s3/signed-url'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: '{"url":"${url.replaceAll('"', '\\"')}"}',
      );
      if (resp.statusCode == 200) {
        final data = convert.jsonDecode(resp.body) as Map<String, dynamic>;
        final signed = (data['signedUrl'] as String?)?.trim();
        if (signed != null && signed.isNotEmpty) return signed;
      }
    } catch (_) {}
    return url; // fallback to original
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
    String? aboutTextFallback() {
      // Use metadata.aboutText when available, otherwise use the content
      // body of the About Us page (plain text fallback).
      final metaText = _getMeta<String>('aboutText');
      if (metaText != null && metaText.trim().isNotEmpty) return metaText;
      final aboutPage = _findPageByKeywords(['about', 'company']);
      if (aboutPage != null) {
        final body = aboutPage.content.trim();
        if (body.isNotEmpty) return body;
      }
      return null;
    }

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
                // Header logo + title (optional via metadata.logoUrl)
                if ((_resolvedLogoUrl ?? _getMeta<String>('logoUrl'))
                        ?.isNotEmpty ==
                    true)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Image.network(
                            _resolvedLogoUrl ?? _getMeta<String>('logoUrl')!,
                            height: 72,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stack) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Request',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                // About text (metadata or page content fallback)
                if (aboutTextFallback()?.isNotEmpty == true)
                  _sectionCard(
                    child: Text(
                      aboutTextFallback()!,
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

  // Read metadata from a provided pages list (used before setState updates _pages)
  T? _getMetaFromPages<T>(List<ContentPage> pages, String key) {
    ContentPage? about;
    for (final p in pages) {
      final title = p.title.toLowerCase();
      final cat = (p.category ?? '').toLowerCase();
      if (title.contains('about') ||
          title.contains('company') ||
          cat.contains('about') ||
          cat.contains('company')) {
        about = p;
        break;
      }
    }
    final meta = about?.metadata ?? {};
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
