import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> logActivity(
    String action, {
    Map<String, dynamic>? details,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        // Cannot log activity if user is not signed in,
        // unless it's an anonymous action.
        return;
      }

      await _firestore.collection('users').doc(user.uid).collection('activity_logs').add({
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
        'details': details ?? {},
        // You could add more context here, like device info, app version, etc.
      });
    } catch (e) {
      print('Error logging activity: $e');
      // It's often best not to disrupt the user flow if logging fails.
    }
  }
}
