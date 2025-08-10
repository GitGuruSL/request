import 'package:cloud_firestore/cloud_firestore.dart';

class PhoneNumber {
  final String number;
  final bool isVerified;
  final bool isPrimary;
  final Timestamp? verifiedAt;

  PhoneNumber({
    required this.number,
    required this.isVerified,
    required this.isPrimary,
    this.verifiedAt,
  });

  factory PhoneNumber.fromMap(Map<String, dynamic> data) {
    return PhoneNumber(
      number: data['number'] ?? '',
      isVerified: data['isVerified'] ?? false,
      isPrimary: data['isPrimary'] ?? false,
      verifiedAt: data['verifiedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'isVerified': isVerified,
      'isPrimary': isPrimary,
      'verifiedAt': verifiedAt,
    };
  }
}

class UserModel {
  final String id;
  final String? displayName;
  final String? email;
  final String? phoneNumber; // Primary phone number for backward compatibility
  final List<PhoneNumber> phoneNumbers; // All verified phone numbers
  final String? photoURL;
  final bool isVerified; // OTP verification status
  final Timestamp? createdAt;

  UserModel({
    required this.id,
    this.displayName,
    this.email,
    this.phoneNumber,
    this.phoneNumbers = const [],
    this.photoURL,
    this.isVerified = false,
    this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List<PhoneNumber> phoneNumbers = [];
    if (data['phoneNumbers'] != null) {
      phoneNumbers = (data['phoneNumbers'] as List)
          .map((phone) => PhoneNumber.fromMap(phone))
          .toList();
    }
    
    return UserModel(
      id: doc.id,
      displayName: data['displayName'] ?? data['name'], // Check both fields for backward compatibility
      email: data['email'],
      phoneNumber: data['phoneNumber'],
      phoneNumbers: phoneNumbers,
      photoURL: data['photoURL'],
      isVerified: data['isVerified'] ?? false,
      createdAt: data['createdAt'],
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> data) {
    List<PhoneNumber> phoneNumbers = [];
    if (data['phoneNumbers'] != null) {
      phoneNumbers = (data['phoneNumbers'] as List)
          .map((phone) => PhoneNumber.fromMap(phone))
          .toList();
    }
    
    return UserModel(
      id: data['uid'] ?? '',
      displayName: data['displayName'] ?? data['name'], // Check both fields for backward compatibility
      email: data['email'],
      phoneNumber: data['phoneNumber'],
      phoneNumbers: phoneNumbers,
      photoURL: data['photoURL'],
      isVerified: data['isVerified'] ?? false,
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'displayName': displayName,
      'name': displayName, // Save to both fields for backward compatibility
      'email': email,
      'phoneNumber': phoneNumber,
      'phoneNumbers': phoneNumbers.map((phone) => phone.toMap()).toList(),
      'photoURL': photoURL,
      'isVerified': isVerified,
      'createdAt': createdAt,
    };
  }

  // Get all verified phone numbers
  List<String> get verifiedPhoneNumbers {
    return phoneNumbers
        .where((phone) => phone.isVerified)
        .map((phone) => phone.number)
        .toList();
  }

  // Get primary phone number
  String? get primaryPhoneNumber {
    final primary = phoneNumbers.firstWhere(
      (phone) => phone.isPrimary && phone.isVerified,
      orElse: () => phoneNumbers.isNotEmpty 
          ? phoneNumbers.first 
          : PhoneNumber(number: '', isVerified: false, isPrimary: false),
    );
    return primary.number.isNotEmpty ? primary.number : phoneNumber;
  }
}
