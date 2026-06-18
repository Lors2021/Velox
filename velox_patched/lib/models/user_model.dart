import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String? avatarUrl;
  final String? fcmToken;
  final DateTime createdAt;
  final bool isOnline;
  final DateTime? lastSeen;

  const UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.avatarUrl,
    this.fcmToken,
    required this.createdAt,
    this.isOnline = false,
    this.lastSeen,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      username: map['username'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
      fcmToken: map['fcmToken'] as String?,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isOnline: map['isOnline'] as bool? ?? false,
      lastSeen: map['lastSeen'] != null
          ? (map['lastSeen'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'avatarUrl': avatarUrl,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    };
  }

  UserModel copyWith({
    String? username,
    String? avatarUrl,
    String? fcmToken,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
