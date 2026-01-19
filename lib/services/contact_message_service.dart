import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geodos/models/contact_message.dart';
import 'package:geodos/services/auth_service.dart';

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
    return streamAll().map(
      (messages) => messages.where((message) => !message.isArchived).toList(growable: false),
    );
  }

  static Stream<int> streamUnreadCount() {
    return streamAll().map(
      (messages) => messages
          .where((message) => !message.isArchived && !message.isRead)
          .length,
    );
  }

  static Future<void> markAsRead(String id) {
    if (!AuthService.instance.isAdmin) {
      throw Exception('Solo un administrador autenticado puede modificar mensajes.');
    }
    return _collection.doc(id).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> archiveMessage(String messageId) {
    if (!AuthService.instance.isAdmin) {
      throw Exception('Solo un administrador autenticado puede archivar mensajes.');
    }
    return _collection.doc(messageId).update({
      'isArchived': true,
      'archivedAt': FieldValue.serverTimestamp(),
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteMessage(String messageId) {
    if (!AuthService.instance.isAdmin) {
      throw Exception('Solo un administrador autenticado puede eliminar mensajes.');
    }
    return _collection.doc(messageId).delete();
  }

  static Stream<List<ContactMessage>> getArchivedMessagesStream() {
    return streamAll().map(
      (messages) => messages.where((message) => message.isArchived).toList(growable: false),
    );
  }

  static Stream<ContactMessage?> streamMessage(String messageId) {
    return _collection
        .doc(messageId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? ContactMessage.fromDoc(snapshot) : null);
  }
}
