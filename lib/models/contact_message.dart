import 'package:cloud_firestore/cloud_firestore.dart';

class ContactMessage {
  ContactMessage({
    required this.id,
    required this.name,
    required this.email,
    required this.message,
    required this.originSection,
    required this.source,
    required this.company,
    required this.projectType,
    required this.createdAt,
    required this.isRead,
    required this.readAt,
  });

  final String id;
  final String name;
  final String email;
  final String message;
  final String originSection;
  final String source;
  final String company;
  final String projectType;
  final DateTime? createdAt;
  final bool isRead;
  final DateTime? readAt;

  factory ContactMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ContactMessage(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
      originSection: (data['originSection'] ?? '').toString(),
      source: (data['source'] ?? '').toString(),
      company: (data['company'] ?? '').toString(),
      projectType: (data['projectType'] ?? '').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isRead: data['isRead'] == true,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }

  factory ContactMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ContactMessage(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
      originSection: (data['originSection'] ?? '').toString(),
      source: (data['source'] ?? '').toString(),
      company: (data['company'] ?? '').toString(),
      projectType: (data['projectType'] ?? '').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isRead: data['isRead'] == true,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }
}
