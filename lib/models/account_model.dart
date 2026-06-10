import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { hero, guardian }

class AccountModel {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final DateTime createdAt;

  AccountModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
  });

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      role: map['role'] == 'guardian' ? UserRole.guardian : UserRole.hero,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory AccountModel.fromDoc(DocumentSnapshot doc) {
    return AccountModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role == UserRole.guardian ? 'guardian' : 'hero',
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isGuardian => role == UserRole.guardian;
  bool get isHero => role == UserRole.hero;
}
