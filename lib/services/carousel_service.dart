import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/carousel_item.dart';

class CarouselService {
  static final _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('carousel');

  static Stream<List<CarouselItem>> streamAll() {
    return _col
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(CarouselItem.fromDoc).toList());
  }

  static Stream<List<CarouselItem>> streamActive() {
    return _col
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(CarouselItem.fromDoc).toList());
  }

  static Future<void> create(CarouselItem item) async {
    await _col.add({
      ...item.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> update(CarouselItem item) async {
    await _col.doc(item.id).update({
      ...item.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
