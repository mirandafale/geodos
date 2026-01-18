// lib/models/news_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NewsItem {
  final String id;
  final String title;
  final String body;
  final String imageUrl;
  final bool published;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool published;
  final bool hasCreatedAt;

  NewsItem({
    required this.id,
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.published,
    required this.createdAt,
    required this.updatedAt,
    required this.published,
    this.hasCreatedAt = true,
  });

  factory NewsItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAtRaw = data['createdAt'];
    final updatedAtRaw = data['updatedAt'];
    final hasCreatedAt = createdAtRaw is Timestamp;
    return NewsItem(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      body: (data['body'] ?? data['summary'] ?? '') as String,
      imageUrl: (data['imageUrl'] ??
          'https://images.pexels.com/photos/3184465/pexels-photo-3184465.jpeg?auto=compress&cs=tinysrgb&w=1200')
      as String,
      createdAt:
          hasCreatedAt ? (createdAtRaw as Timestamp).toDate() : DateTime.now(),
      updatedAt: (updatedAtRaw is Timestamp)
          ? updatedAtRaw.toDate()
          : (hasCreatedAt ? (createdAtRaw as Timestamp).toDate() : DateTime.now()),
      published: data['published'] == true,
      hasCreatedAt: hasCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'summary': body,
      'imageUrl': imageUrl,
      'published': published,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'published': published,
    };
  }

  NewsItem copyWith({
    String? id,
    String? title,
    String? summary,
    String? imageUrl,
    bool? published,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NewsItem(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      imageUrl: imageUrl ?? this.imageUrl,
      published: published ?? this.published,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
