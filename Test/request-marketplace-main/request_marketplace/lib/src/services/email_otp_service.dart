import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailOtpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate a 6-digit OTP
  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Send OTP to email for verification
  Future<String> sendEmailOtp(String email) async {
    // Clean email format
    final cleanedEmail = email.trim().toLowerCase();
    
    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(cleanedEmail)) {
      throw Exception('Invalid email format');
    }

    // Generate OTP
    final otp = _generateOtp();
    final otpExpiry = DateTime.now().add(const Duration(minutes: 10));

    try {
      // Store OTP in Firestore with expiry
      await _firestore
          .collection('email_otp_verifications')
          .doc(cleanedEmail)
          .set({
        'email': cleanedEmail,
        'otp': otp,
        'expiresAt': Timestamp.fromDate(otpExpiry),
        'verified': false,
        'attempts': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send OTP via email
      await _sendOtpEmail(cleanedEmail, otp);
      
      return 'OTP sent successfully to $cleanedEmail';
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  /// Send the actual OTP email
  Future<void> _sendOtpEmail(String email, String otp) async {
    try {
      // For development/testing, we'll simulate email sending
      // In production, you would use a service like:
      // - SendGrid
      // - AWS SES
      // - Mailgun
      // - Firebase Extensions (Send Email via SendGrid)
      
      print('📧 Email OTP for $email: $otp (expires in 10 minutes)');
      
      // TODO: Replace with actual email service
      await _simulateEmailDelay();
      
      // Example implementation with a real SMTP service:
      /*
      final smtpServer = gmail('your-email@gmail.com', 'your-app-password');
      
      final message = Message()
        ..from = Address('noreply@request.lk', 'Request')
        ..recipients.add(email)
        ..subject = 'Your Verification Code - Request'
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #2196F3;">Email Verification</h2>
            <p>Your verification code is:</p>
            <div style="background: #f5f5f5; padding: 20px; text-align: center; margin: 20px 0;">
              <h1 style="color: #2196F3; font-size: 32px; margin: 0; letter-spacing: 5px;">$otp</h1>
            </div>
            <p>This code will expire in 10 minutes.</p>
            <p>If you didn't request this code, please ignore this email.</p>
            <hr>
            <p style="color: #666; font-size: 12px;">Request Team</p>
          </div>
        ''';
      
      await send(message, smtpServer);
      */
      
    } catch (e) {
      throw Exception('Failed to send email: $e');
    }
  }

  /// Simulate email sending delay for development
  Future<void> _simulateEmailDelay() async {
    await Future.delayed(const Duration(seconds: 2));
  }

  /// Verify the email OTP
  Future<bool> verifyEmailOtp(String email, String enteredOtp) async {
    final cleanedEmail = email.trim().toLowerCase();

    try {
      final otpDoc = await _firestore
          .collection('email_otp_verifications')
          .doc(cleanedEmail)
          .get();

      if (!otpDoc.exists) {
        throw Exception('No OTP found for this email address');
      }

      final data = otpDoc.data()!;
      final storedOtp = data['otp'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final attempts = (data['attempts'] as int? ?? 0);
      final isVerified = data['verified'] as bool? ?? false;

      // Check if already verified
      if (isVerified) {
        throw Exception('This email is already verified');
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
            .collection('email_otp_verifications')
            .doc(cleanedEmail)
            .update({
          'attempts': attempts + 1,
        });
        throw Exception('Invalid OTP. ${2 - attempts} attempts remaining');
      }

      // OTP is correct - mark as verified
      await _firestore
          .collection('email_otp_verifications')
          .doc(cleanedEmail)
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

  /// Check if email is verified via OTP
  Future<bool> isEmailVerifiedOtp(String email) async {
    final cleanedEmail = email.trim().toLowerCase();

    try {
      final otpDoc = await _firestore
          .collection('email_otp_verifications')
          .doc(cleanedEmail)
          .get();

      if (!otpDoc.exists) return false;

      final data = otpDoc.data()!;
      return data['verified'] as bool? ?? false;
    } catch (e) {
      print('Error checking email verification: $e');
      return false;
    }
  }

  /// Resend email OTP (with rate limiting)
  Future<String> resendEmailOtp(String email) async {
    final cleanedEmail = email.trim().toLowerCase();

    try {
      final otpDoc = await _firestore
          .collection('email_otp_verifications')
          .doc(cleanedEmail)
          .get();

      if (otpDoc.exists) {
        final data = otpDoc.data()!;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        
        // Rate limiting - only allow resend after 1 minute
        if (createdAt != null && 
            DateTime.now().difference(createdAt).inMinutes < 1) {
          final waitTime = 60 - DateTime.now().difference(createdAt).inSeconds;
          throw Exception('Please wait $waitTime seconds before requesting another OTP');
        }
      }

      // Generate new OTP
      return await sendEmailOtp(cleanedEmail);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to resend OTP: $e');
    }
  }

  /// Delete OTP record (cleanup)
  Future<void> deleteEmailOtp(String email) async {
    final cleanedEmail = email.trim().toLowerCase();
    
    try {
      await _firestore
          .collection('email_otp_verifications')
          .doc(cleanedEmail)
          .delete();
    } catch (e) {
      print('Error deleting email OTP: $e');
    }
  }

  /// Get remaining time for OTP expiry
  Future<Duration?> getOtpRemainingTime(String email) async {
    final cleanedEmail = email.trim().toLowerCase();

    try {
      final otpDoc = await _firestore
          .collection('email_otp_verifications')
          .doc(cleanedEmail)
          .get();

      if (!otpDoc.exists) return null;

      final data = otpDoc.data()!;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final now = DateTime.now();

      if (now.isAfter(expiresAt)) {
        return Duration.zero;
      }

      return expiresAt.difference(now);
    } catch (e) {
      print('Error getting OTP remaining time: $e');
      return null;
    }
  }
}
