import 'package:cloud_firestore/cloud_firestore.dart';

class GuardianModel {
  final String uid;
  final String displayName;
  final String email;
  final String familyTag;
  final String inviteCode; // Mã mời để Hero nhập vào
  final List<String> heroIds; // Danh sách UID các con em
  final String? guildId; // UID của Guild mà phụ huynh tham gia
  final DateTime createdAt;

  GuardianModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.familyTag,
    required this.inviteCode,
    this.heroIds = const [],
    this.guildId,
    required this.createdAt,
  });

  factory GuardianModel.fromMap(Map<String, dynamic> map) {
    return GuardianModel(
      uid: map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      familyTag: map['familyTag'] as String? ?? '',
      inviteCode: map['inviteCode'] as String? ?? '',
      heroIds: List<String>.from(map['heroIds'] ?? []),
      guildId: map['guildId'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory GuardianModel.fromDoc(DocumentSnapshot doc) {
    final data = Map<String, dynamic>.from(doc.data() as Map);
    data['uid'] = doc.id;
    return GuardianModel.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'familyTag': familyTag,
      'inviteCode': inviteCode,
      'heroIds': heroIds,
      'guildId': guildId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  GuardianModel copyWith({
    String? displayName,
    String? familyTag,
    String? inviteCode,
    List<String>? heroIds,
    String? guildId,
  }) {
    return GuardianModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      familyTag: familyTag ?? this.familyTag,
      inviteCode: inviteCode ?? this.inviteCode,
      heroIds: heroIds ?? this.heroIds,
      guildId: guildId ?? this.guildId,
      createdAt: createdAt,
    );
  }

  int get heroCount => heroIds.length;
}
