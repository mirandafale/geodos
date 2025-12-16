// lib/models/news_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NewsItem {
  final String id;
  final String title;
  final String summary;
  final String imageUrl;
  final DateTime createdAt;

  NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.imageUrl,
    required this.createdAt,
  });

  factory NewsItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return NewsItem(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      summary: (data['summary'] ?? '') as String,
      imageUrl: (data['imageUrl'] ??
          'https://images.pexels.com/photos/3184465/pexels-photo-3184465.jpeg?auto=compress&cs=tinysrgb&w=1200')
      as String,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'summary': summary,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
