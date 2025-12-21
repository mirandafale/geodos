import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LeadService {
  static Future<void> submit({
    required String name,
    required String email,
    String? company,
    required String message,
    String originSection = 'home',
  }) {
    final platform = kIsWeb ? 'web' : describeEnum(defaultTargetPlatform).toLowerCase();

    return FirebaseFirestore.instance.collection('contact_messages').add({
      'name': name.trim(),
      'email': email.trim(),
      'company': (company ?? '').trim(),
      'message': message.trim(),
      'originSection': originSection,
      'platform': platform,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
