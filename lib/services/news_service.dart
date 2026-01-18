import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/news_item.dart';
import '../services/auth_service.dart';

class NewsService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('news');
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Query<Map<String, dynamic>> _newsQuery({
    required bool includeDrafts,
    required String orderByField,
  }) {
    final base = includeDrafts ? _col : _col.where('published', isEqualTo: true);
    return base.orderBy(orderByField, descending: true).limit(10);
  }

  static Stream<List<NewsItem>> _queryWithFallback({
    required Query<Map<String, dynamic>> primary,
    required Query<Map<String, dynamic>> fallback,
  }) {
    List<NewsItem> toItems(QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs.map(NewsItem.fromDoc).toList();
    }

    return Stream.multi((controller) {
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sub;
      var usingFallback = false;

      void listenTo(Query<Map<String, dynamic>> query) {
        sub = query.snapshots().listen(
          (snapshot) => controller.add(toItems(snapshot)),
          onError: (error, stackTrace) {
            if (error is FirebaseException &&
                (error.code == 'failed-precondition' ||
                    error.code == 'invalid-argument') &&
                !usingFallback) {
              usingFallback = true;
              sub?.cancel();
              listenTo(fallback);
            } else {
              controller.addError(error, stackTrace);
            }
          },
          onDone: controller.close,
        );
      }

      listenTo(primary);
      controller.onCancel = () => sub?.cancel();
    });
  }

  /// Stream de noticias publicadas (o todo el listado en modo admin).
  static Stream<List<NewsItem>> publishedStream({bool includeDrafts = false}) {
    return _queryWithFallback(
      primary: _newsQuery(includeDrafts: includeDrafts, orderByField: 'createdAt'),
      fallback: _newsQuery(includeDrafts: includeDrafts, orderByField: 'updatedAt'),
    );
  }

  /// Crea una noticia nueva.
  static Future<void> create(NewsItem item, {XFile? image}) async {
    final imageUrl = image != null ? await _uploadImage(image) : item.imageUrl;
    await _col.add({
      ...item.toMap(),
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Actualiza una noticia existente.
  static Future<void> update(NewsItem item, {XFile? image}) async {
    final imageUrl = image != null ? await _uploadImage(image) : item.imageUrl;
    await _col.doc(item.id).update({
      ...item.toMap(),
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Borra una noticia.
  static Future<void> delete(String id) async {
    if (!AuthService.instance.isAdmin) {
      throw Exception(
          'Solo un administrador autenticado puede eliminar noticias.');
    }
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
        'title': item.title,
        'body': item.body,
        'summary': item.summary,
        'imageUrl': item.imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'published': true,
      });
    }
  }

  static Future<String> _uploadImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final metadata =
        SettableMetadata(contentType: file.mimeType ?? 'image/jpeg');
    final name = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final ref = _storage.ref().child('news/$name');
    await ref.putData(Uint8List.fromList(bytes), metadata);
    return ref.getDownloadURL();
  }
}
