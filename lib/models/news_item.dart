// lib/models/news_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NewsItem {
  final String id;
  final String title;
  final String body;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool published;

  NewsItem({
    required this.id,
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.published,
  });

  factory NewsItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return NewsItem(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      body: (data['body'] ?? data['summary'] ?? '') as String,
      imageUrl: (data['imageUrl'] ??
          'https://images.pexels.com/photos/3184465/pexels-photo-3184465.jpeg?auto=compress&cs=tinysrgb&w=1200')
      as String,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      published: data['published'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'summary': body,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'published': published,
    };
  }
}
