import 'package:cloud_firestore/cloud_firestore.dart';

class LeadService {
  static Future<void> submit({
    required String name,
    required String email,
    String? company,
    required String message,
  }) {
    return FirebaseFirestore.instance.collection('leads').add({
      'name': name.trim(),
      'email': email.trim(),
      'company': (company ?? '').trim(),
      'message': message.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
