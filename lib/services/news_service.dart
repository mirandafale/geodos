// lib/services/news_service.dart
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/news_item.dart';

class NewsService {
  static final _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('news');
  static final _storage = FirebaseStorage.instance;

  /// Stream de noticias ordenadas por fecha (recientes primero)
  static Stream<List<NewsItem>> stream() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((d) => NewsItem.fromDoc(d)).toList());
  }

  /// Noticias publicadas para la web pública.
  static Stream<List<NewsItem>> publishedStream() {
    return _col
        .where('published', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((d) => NewsItem.fromDoc(d)).toList());
  }

  /// Crea una noticia nueva
  static Future<void> create(NewsItem item, {XFile? image}) async {
    final imageUrl = image != null ? await _uploadImage(image) : item.imageUrl;
    await _col.add({
      ...item.toMap(),
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Actualiza una noticia existente
  static Future<void> update(NewsItem item, {XFile? image}) async {
    final imageUrl = image != null ? await _uploadImage(image) : item.imageUrl;
    await _col.doc(item.id).update({
      ...item.toMap(),
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Borra una noticia
  static Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  static Future<String> _uploadImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final metadata = SettableMetadata(contentType: file.mimeType ?? 'image/jpeg');
    final name = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final ref = _storage.ref().child('news/$name');
    await ref.putData(Uint8List.fromList(bytes), metadata);
    return ref.getDownloadURL();
  }
}
