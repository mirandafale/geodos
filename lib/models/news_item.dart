import 'package:cloud_firestore/cloud_firestore.dart';

class NewsItem {
  final String id;
  final String title;
  final String body;
  final String summary;
  final String imageUrl;
  final bool published;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hasCreatedAt;

  NewsItem({
    required this.id,
    required this.title,
    required this.body,
    required this.summary,
    required this.imageUrl,
    required this.published,
    required this.createdAt,
    required this.updatedAt,
    this.hasCreatedAt = true,
  });

  factory NewsItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAtRaw = data['createdAt'];
    final updatedAtRaw = data['updatedAt'];
    final hasCreatedAt = createdAtRaw is Timestamp;
    final body = (data['body'] ?? data['summary'] ?? '') as String;
    final summary = (data['summary'] ?? body) as String;

    return NewsItem(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      body: body,
      summary: summary,
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
      'summary': summary,
      'imageUrl': imageUrl,
      'published': published,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  NewsItem copyWith({
    String? id,
    String? title,
    String? body,
    String? summary,
    String? imageUrl,
    bool? published,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hasCreatedAt,
  }) {
    return NewsItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      summary: summary ?? this.summary,
      imageUrl: imageUrl ?? this.imageUrl,
      published: published ?? this.published,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasCreatedAt: hasCreatedAt ?? this.hasCreatedAt,
    );
  }
}
