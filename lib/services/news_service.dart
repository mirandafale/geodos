// lib/services/news_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/news_item.dart';
import 'firebase_service.dart';

class NewsService {
  static final _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('news');

  /// Stream de noticias ordenadas por fecha (recientes primero)
  static Stream<List<NewsItem>> stream() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((d) => NewsItem.fromDoc(d)).toList());
  }

  /// Crea una noticia nueva
  static Future<void> create(NewsItem item) async {
    await FirebaseService.createOrUpdateNews(item);
  }

  /// Actualiza una noticia existente
  static Future<void> update(NewsItem item) async {
    await FirebaseService.createOrUpdateNews(item);
  }

  /// Borra una noticia
  static Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
