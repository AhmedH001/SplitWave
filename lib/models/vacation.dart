import 'package:cloud_firestore/cloud_firestore.dart';

class Vacation {
  final String id;
  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final String createdBy;
  final List<String> memberIds;
  final Map<String, String> memberNames; // uid → display name
  final DateTime createdAt;

  Vacation({
    required this.id,
    required this.name,
    this.description,
    required this.startDate,
    required this.endDate,
    required this.createdBy,
    required this.memberIds,
    required this.memberNames,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get memberCount => memberIds.length;

  /// Whether the vacation period is currently active.
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate.add(const Duration(days: 1)));
  }

  /// Whether the vacation has ended.
  bool get hasEnded => DateTime.now().isAfter(endDate.add(const Duration(days: 1)));

  /// Duration in days.
  int get durationDays => endDate.difference(startDate).inDays + 1;

  factory Vacation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Vacation(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      memberNames: Map<String, String>.from(data['memberNames'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdBy': createdBy,
      'memberIds': memberIds,
      'memberNames': memberNames,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Vacation copyWith({
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? memberIds,
    Map<String, String>? memberNames,
  }) {
    return Vacation(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdBy: createdBy,
      memberIds: memberIds ?? this.memberIds,
      memberNames: memberNames ?? this.memberNames,
      createdAt: createdAt,
    );
  }
}
