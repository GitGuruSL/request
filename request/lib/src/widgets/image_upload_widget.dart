import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_upload_service.dart';

class ImageUploadWidget extends StatefulWidget {
  final List<String> initialImages;
  final int maxImages;
  final Function(List<String>) onImagesChanged;
  final String uploadPath;
  final bool isRequired;
  final String label;

  const ImageUploadWidget({
    super.key,
    this.initialImages = const [],
    this.maxImages = 4,
    required this.onImagesChanged,
    required this.uploadPath,
    this.isRequired = false,
    this.label = 'Upload Images',
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImageUploadService _imageService = ImageUploadService();
  List<String> _imageUrls = [];
  List<XFile> _pendingImages = [];
  bool _isUploading = false;
  // Maintain a mapping of uploaded image URLs to their original local files
  // so we can show a reliable preview even if the returned URL is a placeholder
  // or not immediately accessible.
  final Map<String, XFile> _localPreviewFiles = {};

  @override
  void initState() {
    super.initState();
    _imageUrls = List.from(widget.initialImages);
  }

  Future<void> _pickImages() async {
    try {
      final availableSlots =
          widget.maxImages - _imageUrls.length - _pendingImages.length;
      if (availableSlots <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Maximum ${widget.maxImages} images allowed')),
        );
        return;
      }

      final List<XFile>? images = await _imageService.pickMultipleImages(
        maxImages: availableSlots,
      );

      if (images != null && images.isNotEmpty) {
        setState(() {
          _pendingImages.addAll(images);
        });
        await _uploadPendingImages();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting images: $e')),
      );
    }
  }

  Future<void> _uploadPendingImages() async {
    if (_pendingImages.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    try {
      for (final XFile image in _pendingImages) {
        final String? url = await _imageService.uploadImage(
          image,
          '${widget.uploadPath}/${DateTime.now().millisecondsSinceEpoch}',
        );

        if (url != null) {
          setState(() {
            _imageUrls.add(url);
            _localPreviewFiles[url] = image; // keep local fallback
          });
        }
      }

      _pendingImages.clear();
      widget.onImagesChanged(_imageUrls);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading images: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _removeImage(int index) async {
    final String imageUrl = _imageUrls[index];

    setState(() {
      _imageUrls.removeAt(index);
      _localPreviewFiles.remove(imageUrl);
    });

    widget.onImagesChanged(_imageUrls);

    // Delete from Firebase Storage
    await _imageService.deleteImage(imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Upload Area
              if (_imageUrls.length + _pendingImages.length < widget.maxImages)
                InkWell(
                  onTap: _isUploading ? null : _pickImages,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isUploading
                              ? 'Uploading...'
                              : 'Tap to upload images',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Maximum ${widget.maxImages} images',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Images Grid
              if (_imageUrls.isNotEmpty || _pendingImages.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: _imageUrls.length + _pendingImages.length,
                    itemBuilder: (context, index) {
                      if (index < _imageUrls.length) {
                        // Uploaded images
                        return _buildImageItem(_imageUrls[index], index, true);
                      } else {
                        // Pending images
                        final pendingIndex = index - _imageUrls.length;
                        return _buildPendingImageItem(
                            _pendingImages[pendingIndex]);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),

        // Progress indicator
        if (_isUploading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildImageItem(String imageUrl, int index, bool isUploaded) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImagePreview(imageUrl),
          ),
        ),

        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingImageItem(XFile imageFile) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? FutureBuilder<Uint8List>(
                    future: imageFile.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image.memory(
                          snapshot.data!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        );
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  )
                : Image.file(
                    File(imageFile.path),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
        ),

        // Uploading indicator
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black.withOpacity(0.3),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isNetworkUrl(String url) =>
      url.startsWith('http://') || url.startsWith('https://');

  Widget _buildImagePreview(String imageUrl) {
    // If it's a network URL, try network first with fallback to local file if available
    if (_isNetworkUrl(imageUrl)) {
      final localFile = _localPreviewFiles[imageUrl];
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stack) {
          if (localFile != null) {
            return _localFileWidget(localFile);
          }
          return Container(
            alignment: Alignment.center,
            color: Colors.grey.shade200,
            child: Icon(
              Icons.error,
              color: Colors.grey.shade400,
            ),
          );
        },
      );
    }

    // Treat as local path
    return _localPathWidget(imageUrl);
  }

  Widget _localFileWidget(XFile localFile) {
    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: localFile.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
    return Image.file(
      File(localFile.path),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    );
  }

  Widget _localPathWidget(String path) {
    final cleaned = path.startsWith('file://') ? path.substring(7) : path;
    try {
      if (!kIsWeb && File(cleaned).existsSync()) {
        return Image.file(
          File(cleaned),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        );
      }
    } catch (_) {}
    return Container(
      alignment: Alignment.center,
      color: Colors.grey.shade200,
      child: Icon(
        Icons.image_not_supported,
        color: Colors.grey.shade400,
      ),
    );
  }
}
