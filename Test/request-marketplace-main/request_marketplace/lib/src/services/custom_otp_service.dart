import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomOtpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate a 6-digit OTP
  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Send OTP to phone number for verification (custom implementation)
  /// This doesn't create a new Firebase user account
  Future<String> sendCustomOtp(String phoneNumber) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to add phone numbers');
    }

    // Clean phone number format
    String cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleanedPhone.startsWith('+')) {
      cleanedPhone = '+94$cleanedPhone'; // Default to Sri Lanka if no country code
    }

    // Generate OTP
    final otp = _generateOtp();
    final otpExpiry = DateTime.now().add(const Duration(minutes: 10));

    try {
      // Store OTP in Firestore with expiry
      await _firestore
          .collection('phone_otp_verifications')
          .doc('${user.uid}_$cleanedPhone')
          .set({
        'userId': user.uid,
        'phoneNumber': cleanedPhone,
        'otp': otp,
        'expiresAt': Timestamp.fromDate(otpExpiry),
        'verified': false,
        'attempts': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // In a real app, you would integrate with an SMS service like:
      // - Twilio
      // - AWS SNS
      // - Dialog SMS API (Sri Lankan provider)
      // - Mobitel SMS API
      
      // For development/testing, we'll simulate SMS sending
      print('🔐 Custom OTP for $cleanedPhone: $otp (expires in 10 minutes)');
      
      // TODO: Replace with actual SMS service
      await _simulateSmsDelay();
      
      return 'OTP sent successfully to $cleanedPhone';
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  /// Verify the custom OTP
  Future<bool> verifyCustomOtp(String phoneNumber, String enteredOtp) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated');
    }

    // Clean phone number format
    String cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleanedPhone.startsWith('+')) {
      cleanedPhone = '+94$cleanedPhone';
    }

    try {
      final docId = '${user.uid}_$cleanedPhone';
      final otpDoc = await _firestore
          .collection('phone_otp_verifications')
          .doc(docId)
          .get();

      if (!otpDoc.exists) {
        throw Exception('No OTP found for this phone number');
      }

      final data = otpDoc.data()!;
      final storedOtp = data['otp'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final attempts = (data['attempts'] as int? ?? 0);
      final isVerified = data['verified'] as bool? ?? false;

      // Check if already verified
      if (isVerified) {
        throw Exception('This phone number is already verified');
      }

      // Check attempts limit
      if (attempts >= 3) {
        throw Exception('Too many failed attempts. Please request a new OTP');
      }

      // Check expiry
      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('OTP has expired. Please request a new one');
      }

      // Verify OTP
      if (storedOtp != enteredOtp.trim()) {
        // Increment attempts
        await _firestore
            .collection('phone_otp_verifications')
            .doc(docId)
            .update({
          'attempts': attempts + 1,
        });
        throw Exception('Invalid OTP. ${2 - attempts} attempts remaining');
      }

      // OTP is correct - mark as verified
      await _firestore
          .collection('phone_otp_verifications')
          .doc(docId)
          .update({
        'verified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to verify OTP: $e');
    }
  }

  /// Check if phone number is verified via custom OTP
  Future<bool> isPhoneVerifiedCustom(String phoneNumber) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    String cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleanedPhone.startsWith('+')) {
      cleanedPhone = '+94$cleanedPhone';
    }

    try {
      final docId = '${user.uid}_$cleanedPhone';
      final otpDoc = await _firestore
          .collection('phone_otp_verifications')
          .doc(docId)
          .get();

      if (!otpDoc.exists) return false;

      final data = otpDoc.data()!;
      return data['verified'] as bool? ?? false;
    } catch (e) {
      print('Error checking phone verification: $e');
      return false;
    }
  }

  /// Resend OTP (with rate limiting)
  Future<String> resendCustomOtp(String phoneNumber) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated');
    }

    String cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleanedPhone.startsWith('+')) {
      cleanedPhone = '+94$cleanedPhone';
    }

    try {
      final docId = '${user.uid}_$cleanedPhone';
      final otpDoc = await _firestore
          .collection('phone_otp_verifications')
          .doc(docId)
          .get();

      if (otpDoc.exists) {
        final data = otpDoc.data()!;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        
        // Rate limiting - only allow resend after 2 minutes
        if (createdAt != null && 
            DateTime.now().difference(createdAt).inMinutes < 2) {
          final waitTime = 2 - DateTime.now().difference(createdAt).inMinutes;
          throw Exception('Please wait $waitTime minute(s) before requesting another OTP');
        }
      }

      // Generate new OTP
      return await sendCustomOtp(phoneNumber);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to resend OTP: $e');
    }
  }

  /// Clean up expired OTP records (should be called periodically)
  Future<void> cleanupExpiredOtps() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final expiredQuery = await _firestore
          .collection('phone_otp_verifications')
          .where('userId', isEqualTo: user.uid)
          .where('expiresAt', isLessThan: Timestamp.now())
          .where('verified', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in expiredQuery.docs) {
        batch.delete(doc.reference);
      }
      
      if (expiredQuery.docs.isNotEmpty) {
        await batch.commit();
        print('Cleaned up ${expiredQuery.docs.length} expired OTP records');
      }
    } catch (e) {
      print('Error cleaning up expired OTPs: $e');
    }
  }

  /// Simulate SMS sending delay (for development)
  Future<void> _simulateSmsDelay() async {
    await Future.delayed(const Duration(milliseconds: 1500));
  }

  /// Get SMS service configuration instructions
  static String getSmsServiceInstructions() {
    return '''
🔧 SMS Service Integration Required:

To enable actual SMS sending, integrate with one of these services:

1. TWILIO (International):
   - Add dependency: twilio_flutter
   - Get Account SID and Auth Token
   - Use Twilio Messaging API

2. DIALOG SMS API (Sri Lanka):
   - Register with Dialog Ideamart
   - Get API credentials
   - Use HTTP requests to send SMS

3. AWS SNS:
   - Add dependency: aws_sns_api
   - Configure AWS credentials
   - Use SNS publish API

4. MOBITEL SMS API (Sri Lanka):
   - Register with Mobitel
   - Get API credentials
   - Use their SMS gateway

Replace the _simulateSmsDelay() method with actual SMS sending logic.
''';
  }
}
