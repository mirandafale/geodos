import 'package:cloud_firestore/cloud_firestore.dart';

class CarouselItem {
  final String id;
  final String imageUrl;
  final String? title;
  final String? linkUrl;
  final bool isActive;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CarouselItem({
    required this.id,
    required this.imageUrl,
    required this.isActive,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.linkUrl,
  });

  factory CarouselItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAtRaw = data['createdAt'];
    final updatedAtRaw = data['updatedAt'];
    final createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
    final updatedAt = updatedAtRaw is Timestamp
        ? updatedAtRaw.toDate()
        : createdAt;
    final rawTitle = (data['title'] as String?)?.trim();
    final rawLink = (data['linkUrl'] as String?)?.trim();

    return CarouselItem(
      id: doc.id,
      imageUrl: (data['imageUrl'] ?? '') as String,
      title: rawTitle == null || rawTitle.isEmpty ? null : rawTitle,
      linkUrl: rawLink == null || rawLink.isEmpty ? null : rawLink,
      isActive: data['isActive'] == true,
      order: (data['order'] as num?)?.toInt() ?? 0,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'linkUrl': linkUrl,
      'isActive': isActive,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CarouselItem copyWith({
    String? id,
    String? imageUrl,
    String? title,
    String? linkUrl,
    bool? isActive,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CarouselItem(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      linkUrl: linkUrl ?? this.linkUrl,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
