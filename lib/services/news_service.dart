// lib/services/news_service.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/news_item.dart';

class NewsService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static CollectionReference<Map<String, dynamic>> get _col => _db.collection('news');

  // ---------------------------------------------------------------------------
  // PUBLIC API — Admin
  // ---------------------------------------------------------------------------

  /// Stream general de noticias (panel admin).
  /// Intenta orderBy(createdAt desc); si falta índice, cae a fallback sin orderBy.
  static Stream<List<NewsItem>> stream({int limit = 50}) {
    final primary = _col.orderBy('createdAt', descending: true).limit(limit).snapshots();
    final fallback = _col.limit(limit).snapshots();

    return _streamWithFallback(
      primary: primary,
      fallback: fallback,
      sortInClient: true,
      filterInClient: null,
    );
  }

  /// Crear noticia (compatible con AdminDashboard: create(news, image: pickedFile))
  static Future<void> create(NewsItem item, {XFile? image}) async {
    final doc = _col.doc();
    final imageUrl = image != null ? await _uploadImage(image) : item.imageUrl;

    await doc.set({
      ...item.toMap(),
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Actualizar noticia (compatible con AdminDashboard: update(news, image: pickedFile))
  static Future<void> update(NewsItem item, {XFile? image}) async {
    final imageUrl = image != null ? await _uploadImage(image) : item.imageUrl;

    await _col.doc(item.id).update({
      ...item.toMap(),
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  // ---------------------------------------------------------------------------
  // PUBLIC API — Home/Blog
  // ---------------------------------------------------------------------------

  /// Stream de noticias publicadas (Home/Blog/Carrusel).
  /// Query ideal: where(published==true) + orderBy(createdAt desc) -> puede requerir índice.
  /// Fallback: where(published==true) sin orderBy + ordenación en cliente.
  static Stream<List<NewsItem>> publishedStream({int limit = 10}) {
    final primary = _col
        .where('published', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();

    final fallback = _col.where('published', isEqualTo: true).limit(limit).snapshots();

    return _streamWithFallback(
      primary: primary,
      fallback: fallback,
      sortInClient: true,
      filterInClient: (item) => item.published == true,
    );
  }

  /// Future (una sola vez) de noticias publicadas.
  /// Esto lo requiere tu home_page.dart: _newsFuture = NewsService.fetchPublishedOnce();
  /// Tiene fallback sin índice.
  static Future<List<NewsItem>> fetchPublishedOnce({int limit = 10}) async {
    Future<List<NewsItem>> runNoOrderFallback() async {
      final snap = await _col.where('published', isEqualTo: true).limit(limit).get();
      final items = snap.docs.map((d) => NewsItem.fromDoc(d)).toList();
      items.sort((a, b) => _sortKey(b).compareTo(_sortKey(a)));
      return items;
    }

    try {
      final snap = await _col
          .where('published', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snap.docs.map((d) => NewsItem.fromDoc(d)).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' || e.code == 'invalid-argument') {
        if (kDebugMode) {
          // ignore: avoid_print
          print('[NewsService] fetchPublishedOnce: falta índice -> fallback sin orderBy.');
        }
        return runNoOrderFallback();
      }
      rethrow;
    }
  }

  /// Si en Home pasas "missingSamples" como List<NewsItem>, esta firma es correcta.
  /// Si la lista está vacía, siembra 2 noticias de ejemplo en debug.
  static Future<void> seedDebugSamples(List<NewsItem> missingSamples) async {
    if (!kDebugMode) return;
    if (missingSamples.isNotEmpty) return;

    final existing = await _col.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final now = DateTime.now();

    // Si tu NewsItem tiene un constructor diferente, pásame news_item.dart y lo adapto.
    final samples = <NewsItem>[
      NewsItem(
        id: '',
        title: 'Nueva actualización de GEODOS',
        body:
        'Ejemplo de noticia para desarrollo. Sustituye por contenido real desde el panel admin.',
        imageUrl: '',
        published: true,
        createdAt: now,
        updatedAt: now,
      ),
      NewsItem(
        id: '',
        title: 'Proyecto destacado',
        body: 'Ejemplo: descripción breve de un proyecto y enlace a más información.',
        imageUrl: '',
        published: true,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
    ];

    for (final s in samples) {
      await create(s);
    }
  }

  // ---------------------------------------------------------------------------
  // INTERNALS
  // ---------------------------------------------------------------------------

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime _sortKey(NewsItem item) {
    final c = _parseDate(item.createdAt);
    if (c.millisecondsSinceEpoch != 0) return c;
    return _parseDate(item.updatedAt);
  }

  static Stream<List<NewsItem>> _streamWithFallback({
    required Stream<QuerySnapshot<Map<String, dynamic>>> primary,
    required Stream<QuerySnapshot<Map<String, dynamic>>> fallback,
    required bool sortInClient,
    bool Function(NewsItem item)? filterInClient,
  }) {
    List<NewsItem> mapItems(QuerySnapshot<Map<String, dynamic>> snap, {required bool clientSort}) {
      var items = snap.docs.map((d) => NewsItem.fromDoc(d)).toList();

      if (filterInClient != null) {
        items = items.where(filterInClient).toList();
      }

      if (clientSort && sortInClient) {
        items.sort((a, b) => _sortKey(b).compareTo(_sortKey(a)));
      }

      return items;
    }

    return Stream.multi((controller) {
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sub;
      var usingFallback = false;

      void listenTo(Stream<QuerySnapshot<Map<String, dynamic>>> s, {required bool clientSort}) {
        sub = s.listen(
              (snap) => controller.add(mapItems(snap, clientSort: clientSort)),
          onError: (err, st) async {
            if (err is FirebaseException &&
                (err.code == 'failed-precondition' || err.code == 'invalid-argument')) {
              if (!usingFallback) {
                usingFallback = true;
                await sub?.cancel();
                if (kDebugMode) {
                  // ignore: avoid_print
                  print('[NewsService] Falta índice -> usando fallback sin orderBy (ordenación en cliente).');
                }
                listenTo(fallback, clientSort: true);
                return;
              }
            }
            controller.addError(err, st);
          },
          onDone: controller.close,
        );
      }

      listenTo(primary, clientSort: false);

      controller.onCancel = () async {
        await sub?.cancel();
      };
    });
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
