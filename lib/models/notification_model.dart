import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationAudience { allApp, restaurantSpecific, newCustomers }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationAudience audience;
  final DateTime sentAt;
  final int recipientCount;
  final bool scheduled;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.audience,
    required this.sentAt,
    required this.recipientCount,
    this.scheduled = false,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationModel.fromJson({...json, 'id': doc.id});
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      audience: NotificationAudience.values.firstWhere(
        (e) => e.name == json['audience'],
        orElse: () => NotificationAudience.allApp,
      ),
      sentAt: _parseTimestamp(json['sent_at']) ?? DateTime.now(),
      recipientCount: json['recipient_count'] as int? ?? 0,
      scheduled: json['scheduled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'message': message,
        'audience': audience.name,
        'sent_at': Timestamp.fromDate(sentAt),
        'recipient_count': recipientCount,
        'scheduled': scheduled,
      };

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
