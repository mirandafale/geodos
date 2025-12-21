// lib/services/news_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/news_item.dart';
import '../services/auth_service.dart';

class NewsService {
  static final _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('news');

  /// Stream de noticias publicadas ordenadas por fecha (recientes primero)
  static Stream<List<NewsItem>> publishedStream() {
    return _col
        .where('published', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((d) => NewsItem.fromDoc(d)).toList());
  }

  /// Stream de todas las noticias (panel admin)
  static Stream<List<NewsItem>> streamAll() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((d) => NewsItem.fromDoc(d)).toList());
  }

  /// Crea una noticia nueva
  static Future<String> create(NewsItem item) async {
    if (!AuthService.instance.isAdmin) {
      throw Exception('Solo un administrador autenticado puede crear noticias.');
    }
    final doc = await _col.add({
      ...item.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Actualiza una noticia existente
  static Future<void> update(NewsItem item) async {
    if (!AuthService.instance.isAdmin) {
      throw Exception('Solo un administrador autenticado puede modificar noticias.');
    }
    await _col.doc(item.id).set(
      {
        ...item.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Borra una noticia
  static Future<void> delete(String id) async {
    if (!AuthService.instance.isAdmin) {
      throw Exception('Solo un administrador autenticado puede eliminar noticias.');
    }
    await _col.doc(id).delete();
  }
}
