import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geodos/models/contact_message.dart';

class ContactMessageService {
  static CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('contact_messages');

  static Stream<List<ContactMessage>> streamAll() {
    return _collection.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map(ContactMessage.fromDoc)
              .toList(growable: false),
        );
  }

  static Stream<List<ContactMessage>> getContactMessagesStream() {
    return streamAll();
  }

  static Stream<int> streamUnreadCount() {
    return streamAll().map(
      (messages) => messages.where((message) => !message.isRead).length,
    );
  }

  static Future<void> markAsRead(String id) {
    return _collection.doc(id).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }
}
