import 'package:flutter/material.dart';
import '../../models/driver_model.dart';
import '../../services/ride_tracking_service.dart';

class DriverReviewScreen extends StatefulWidget {
  final String rideTrackingId;
  final DriverModel driver;

  const DriverReviewScreen({
    super.key,
    required this.rideTrackingId,
    required this.driver,
  });

  @override
  State<DriverReviewScreen> createState() => _DriverReviewScreenState();
}

class _DriverReviewScreenState extends State<DriverReviewScreen> {
  final RideTrackingService _rideTrackingService = RideTrackingService();
  final TextEditingController _commentController = TextEditingController();

  int _overallRating = 0;
  final List<String> _selectedEmojis = [];
  final Map<String, int> _categoryRatings = {
    'Driving': 0,
    'Punctuality': 0,
    'Cleanliness': 0,
    'Communication': 0,
    'Safety': 0,
  };

  bool _isSubmitting = false;

  // Available emoji reactions
  final List<String> _availableEmojis = [
    '😊',
    '🚗',
    '⭐',
    '👍',
    '💯',
    '🎉',
    '👌',
    '✨',
    '🙌',
    '❤️',
    '😍',
    '🤩',
    '💪',
    '🔥',
    '⚡',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Your Driver'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver info header
            _buildDriverHeader(),

            const SizedBox(height: 32),

            // Overall rating
            _buildOverallRating(),

            const SizedBox(height: 32),

            // Category ratings
            _buildCategoryRatings(),

            const SizedBox(height: 32),

            // Emoji reactions
            _buildEmojiReactions(),

            const SizedBox(height: 32),

            // Written review
            _buildWrittenReview(),

            const SizedBox(height: 32),

            // Submit button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          // Driver photo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.shade200, width: 2),
            ),
            child: ClipOval(
              child: widget.driver.photoUrl.isNotEmpty
                  ? Image.network(
                      widget.driver.photoUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDriverAvatar(),
                    )
                  : _buildDriverAvatar(),
            ),
          ),

          const SizedBox(width: 16),

          // Driver details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.driver.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.driver.vehicleColor} ${widget.driver.vehicleModel}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  widget.driver.vehicleNumber,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: 30,
        color: Colors.blue.shade400,
      ),
    );
  }

  Widget _buildOverallRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overall Rating',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'How would you rate your overall experience?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),

        // Star rating
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _overallRating = index + 1;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  index < _overallRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 40,
                ),
              ),
            );
          }),
        ),

        if (_overallRating > 0)
          Center(
            child: Text(
              _getRatingText(_overallRating),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryRatings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rate Different Aspects',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Help other passengers by rating specific areas',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        ..._categoryRatings.keys.map((category) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildCategoryRating(category),
          );
        }),
      ],
    );
  }

  Widget _buildCategoryRating(String category) {
    final rating = _categoryRatings[category]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getCategoryIcon(category),
              size: 20,
              color: Colors.blue.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              category,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _categoryRatings[category] = index + 1;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEmojiReactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Express Your Feelings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select emojis that represent your experience',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),

        // Selected emojis
        if (_selectedEmojis.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedEmojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEmojis.remove(emoji);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade300),
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Available emojis
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableEmojis.map((emoji) {
              final isSelected = _selectedEmojis.contains(emoji);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedEmojis.remove(emoji);
                    } else if (_selectedEmojis.length < 5) {
                      _selectedEmojis.add(emoji);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade100 : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        if (_selectedEmojis.length >= 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Maximum 5 emojis can be selected',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWrittenReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Written Review (Optional)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Share details about your experience',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _commentController,
          decoration: InputDecoration(
            hintText: 'Tell other passengers about your ride...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade400),
            ),
          ),
          maxLines: 4,
          maxLength: 500,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _overallRating > 0 && !_isSubmitting;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canSubmit ? _submitReview : null,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.send),
        label: Text(_isSubmitting ? 'Submitting...' : 'Submit Review'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: Colors.grey.shade300,
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide an overall rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _rideTrackingService.submitDriverReview(
        rideTrackingId: widget.rideTrackingId,
        driverId: widget.driver.id,
        rating: _overallRating,
        emojiReactions: _selectedEmojis,
        categoryRatings: Map.from(_categoryRatings),
        comment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your review! 🌟'),
            backgroundColor: Colors.green,
          ),
        );

        // Go back to previous screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Driving':
        return Icons.drive_eta;
      case 'Punctuality':
        return Icons.access_time;
      case 'Cleanliness':
        return Icons.cleaning_services;
      case 'Communication':
        return Icons.chat;
      case 'Safety':
        return Icons.security;
      default:
        return Icons.star;
    }
  }
}
