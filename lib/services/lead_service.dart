import 'package:cloud_firestore/cloud_firestore.dart';

class LeadService {
  static Future<void> submit({
    required String name,
    required String email,
    required String message,
    String originSection = 'contact_page',
    String? company,
  }) {
    return FirebaseFirestore.instance.collection('contact_messages').add({
      'name': name.trim(),
      'email': email.trim(),
      'originSection': originSection,
      'company': (company ?? '').trim(),
      'message': message.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
