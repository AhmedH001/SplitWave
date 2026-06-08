import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role; // "admin" or "member"
  final String avatarEmoji;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.role = 'member',
    this.avatarEmoji = '🏖️',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isAdmin => role == 'admin';

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'member',
      avatarEmoji: data['avatarEmoji'] ?? '🏖️',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'avatarEmoji': avatarEmoji,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? role,
    String? avatarEmoji,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      createdAt: createdAt,
    );
  }

  /// List of available avatar emojis for selection.
  static const List<String> availableAvatars = [
    '🏖️', '🌊', '☀️', '🐚', '🏄', '🎣', '🚤', '⛱️',
    '🌴', '🦀', '🐠', '🧜', '🏝️', '🌅', '🦈', '🐬',
  ];
}
