import 'api_client.dart';

/// Service to handle image URLs, especially S3 signed URLs for AWS images
class ImageUrlService {
  ImageUrlService._();
  static final instance = ImageUrlService._();

  /// Get a signed URL for S3 images using AWS API
  Future<String?> getSignedUrl(String s3Url) async {
    try {
      final resp =
          await ApiClient.instance.post<dynamic>('/api/s3/signed-url', data: {
        'url': s3Url,
      });

      if (resp.data is Map && resp.data['success'] == true) {
        return resp.data['signedUrl'] as String?;
      }
    } catch (e) {
      print('Error getting AWS signed URL for $s3Url: $e');
    }
    return null;
  }

  /// Check if URL is an S3 URL that needs signing
  bool isS3Url(String url) {
    return url.contains('requestappbucket.s3') ||
        url.contains('s3.amazonaws.com') ||
        url.contains('.s3.us-east-1.amazonaws.com');
  }

  /// Process image URL - convert S3 URLs to signed URLs, handle localhost/dev URLs
  Future<String> processImageUrl(String imageUrl) async {
    final base = ApiClient.baseUrlPublic;

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // Check if it's an S3 URL that needs signing
      if (isS3Url(imageUrl)) {
        final signedUrl = await getSignedUrl(imageUrl);
        return signedUrl ?? imageUrl; // Use signed URL or fallback to original
      } else {
        // Normalize developer/private hosts (localhost, 127.0.0.1, 10.0.2.2, 192.168.x.x, 172.16-31.x.x)
        // to the public API host for assets under /uploads so they load on devices.
        try {
          final u = Uri.parse(imageUrl);
          if (_isDevOrPrivateHost(u.host) && u.path.startsWith('/uploads')) {
            final b = Uri.parse(base);
            final rebuilt = Uri(
              scheme: b.scheme,
              host: b.host,
              port: b.hasPort ? b.port : null,
              path: u.path.startsWith('/') ? u.path : '/${u.path}',
              query: u.hasQuery ? u.query : null,
              fragment: u.fragment.isNotEmpty ? u.fragment : null,
            );
            // Debug log in debug/profile builds only
            // ignore: avoid_print
            if (const bool.fromEnvironment('dart.vm.product') == false) {
              print(
                  '[ImageUrlService] Rewriting dev host ${u.host} -> ${b.host} for ${u.path}');
            }
            return rebuilt.toString();
          }
        } catch (_) {}
        return imageUrl;
      }
    } else {
      // Relative URL - prepend base URL
      return '$base${imageUrl.startsWith('/') ? '' : '/'}$imageUrl';
    }
  }

  bool _isDevOrPrivateHost(String host) {
    if (host.isEmpty) return false;
    if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
      return true;
    }
    if (host == '::1') return true; // IPv6 localhost
    // 10.0.0.0/8
    if (host.startsWith('10.')) return true;
    // 192.168.0.0/16
    if (host.startsWith('192.168.')) return true;
    // 172.16.0.0/12
    final parts = host.split('.');
    if (parts.length == 4) {
      final p0 = int.tryParse(parts[0]);
      final p1 = int.tryParse(parts[1]);
      if (p0 == 172 && p1 != null && p1 >= 16 && p1 <= 31) {
        return true;
      }
    }
    return false;
  }

  /// Process multiple image URLs in parallel
  Future<List<String>> processImageUrls(List<String> imageUrls) async {
    final futures = imageUrls.map((url) => processImageUrl(url));
    return await Future.wait(futures);
  }
}
