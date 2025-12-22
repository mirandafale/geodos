// lib/services/news_service.dart
import 'dart:async';
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

  static Future<List<NewsItem>> _fetchPublished(
      {required String orderByField}) async {
    final snapshot = await _publishedQuery(orderByField: orderByField).get();
    return snapshot.docs.map((d) => NewsItem.fromDoc(d)).toList();
  }

  static Query<Map<String, dynamic>> _publishedQuery({required String orderByField}) {
    return _col
        .where('published', isEqualTo: true)
        .orderBy(orderByField, descending: true)
        .limit(10);
  }

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
    Stream<QuerySnapshot<Map<String, dynamic>>> primaryStream;
    Stream<QuerySnapshot<Map<String, dynamic>>> fallbackStream;

    primaryStream = _publishedQuery(orderByField: 'createdAt').snapshots();
    fallbackStream = _publishedQuery(orderByField: 'updatedAt').snapshots();

    List<NewsItem> _toItems(QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs.map((d) => NewsItem.fromDoc(d)).toList();
    }

    return Stream.multi((controller) {
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sub;

      void listenTo(Stream<QuerySnapshot<Map<String, dynamic>>> stream) {
        sub = stream.listen(
          (snapshot) => controller.add(_toItems(snapshot)),
          onError: (error, stackTrace) {
            if (error is FirebaseException && error.code == 'failed-precondition') {
              sub?.cancel();
              listenTo(fallbackStream);
            } else {
              controller.addError(error, stackTrace);
            }
          },
          onDone: controller.close,
        );
      }

      listenTo(primaryStream);
      controller.onCancel = () => sub?.cancel();
    });
  }

  /// Noticias publicadas para la web pública (consulta única con fallback).
  static Future<List<NewsItem>> fetchPublishedOnce() async {
    try {
      return await _fetchPublished(orderByField: 'createdAt');
    } on FirebaseException catch (error) {
      if (error.code == 'failed-precondition') {
        return _fetchPublished(orderByField: 'updatedAt');
      }
      rethrow;
    }
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

  /// Inserta noticias de ejemplo en modo debug si aún no existen.
  static Future<void> seedDebugSamples(List<NewsItem> items) async {
    for (final item in items) {
      if (item.id.isEmpty) continue;
      final doc = _col.doc(item.id);
      final snapshot = await doc.get();
      if (snapshot.exists) continue;
      await doc.set({
        ...item.toMap(),
        'imageUrl': item.imageUrl,
        'createdAt': Timestamp.fromDate(item.createdAt),
        'updatedAt': Timestamp.fromDate(item.updatedAt),
        'published': true,
      });
    }
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
