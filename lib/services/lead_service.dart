import 'package:cloud_firestore/cloud_firestore.dart';

class LeadService {
  static Future<void> submit({
    required String name,
    required String email,
    required String message,
    String originSection = 'contact_page',
    String? company,
    String? projectType,
    String? source,
  }) {
    return FirebaseFirestore.instance.collection('contact_messages').add({
      'name': name.trim(),
      'email': email.trim(),
      'originSection': originSection,
      'source': (source ?? originSection).trim(),
      'company': (company ?? '').trim(),
      'projectType': (projectType ?? '').trim(),
      'message': message.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
