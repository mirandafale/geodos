import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/news_item.dart';
import '../models/project.dart';
import 'auth_service.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<void> submitContactMessage({
    required String name,
    required String email,
    required String message,
    required String originSection,
    String? company,
    String? projectType,
    String? source,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'message': message.trim(),
      'originSection': originSection.trim(),
      'source': (source ?? originSection).trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    final companyValue = (company ?? '').trim();
    if (companyValue.isNotEmpty) {
      payload['company'] = companyValue;
    }

    final projectTypeValue = (projectType ?? '').trim();
    if (projectTypeValue.isNotEmpty) {
      payload['projectType'] = projectTypeValue;
    }

    await _firestore.collection('contact_messages').add(payload);
  }

  static Future<void> createOrUpdateProject(Project project) async {
    if (!AuthService.instance.isAdmin) {
      throw Exception(
          'Solo un administrador autenticado puede modificar proyectos.');
    }
    final doc = project.id.isEmpty
        ? _firestore.collection('projects').doc()
        : _firestore.collection('projects').doc(project.id);
    final data = {
      'title': project.title,
      'municipality': project.municipality,
      'year': project.year,
      'category': project.category,
      'lat': project.lat,
      'lon': project.lon,
      'island': project.island,
      'scope': Project.scopeToString(project.scope),
      'enRedaccion': project.enRedaccion,
      if (project.description != null && project.description!.trim().isNotEmpty)
        'description': project.description,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    await doc.set(data, SetOptions(merge: true));
  }

  static Future<String> createOrUpdateNews(NewsItem item) async {
    if (!AuthService.instance.isAdmin) {
      throw Exception(
          'Solo un administrador autenticado puede modificar noticias.');
    }
    final collection = _firestore.collection('news');
    final payload = {
      'title': item.title,
      'body': item.body,
      'summary': item.summary,
      'imageUrl': item.imageUrl,
      'published': item.published,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (item.id.isEmpty) {
      final doc = await collection.add(payload);
      return doc.id;
    } else {
      await collection.doc(item.id).set(payload, SetOptions(merge: true));
      return item.id;
    }
  }

  static Future<String> uploadImageToStorage(
    Uint8List data, {
    String folder = 'uploads',
    String? fileName,
  }) async {
    final safeFileName = fileName ??
        'img_${DateTime.now().millisecondsSinceEpoch}_${data.hashCode.toRadixString(16)}.jpg';
    final ref = _storage.ref().child(folder).child(safeFileName);
    final task = await ref.putData(
      data,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }
}
