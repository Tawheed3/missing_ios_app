// lib/models/post_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  String id;
  String userId;
  String userDisplayName;
  String userPhotoUrl;
  String country;
  String phone; // <--- أضف هذا السطر
  String type; // 'lost' or 'found'
  String category; // 'pet' or 'item'
  String? petType ;
  String title;
  String description;
  List<String> images;
  String? videoUrl;
  GeoPoint location;
  String locationName;
  String status; // 'active' or 'resolved'
  DateTime createdAt;
  int commentCount;

  PostModel({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.userPhotoUrl,
    required this.country,
    required this.phone, // <--- أضف هذا
    required this.type,
    required this.category,
    this.petType,
    required this.title,
    required this.description,
    required this.images,
    this.videoUrl,
    required this.location,
    required this.locationName,
    required this.status,
    required this.createdAt,
    this.commentCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userPhotoUrl': userPhotoUrl,
      'country': country,
      'phone': phone, // <--- أضف هذا
      'type': type,
      'category': category,
      'petType': petType,
      'title': title,
      'description': description,
      'images': images,
      'videoUrl': videoUrl,
      'location': location,
      'locationName': locationName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'commentCount': commentCount,
    };
  }

  factory PostModel.fromMap(String id, Map<String, dynamic> map) {
    return PostModel(
      id: id,
      userId: map['userId'] ?? '',
      userDisplayName: map['userDisplayName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'] ?? '',
      country: map['country'] ?? 'egypt',
      phone: map['phone'] ?? '', // <--- أضف هذا
      type: map['type'] ?? '',
      category: map['category'] ?? '',
      petType: map['petType'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      videoUrl: map['videoUrl'],
      location: map['location'] ?? GeoPoint(0, 0),
      locationName: map['locationName'] ?? '',
      status: map['status'] ?? 'active',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      commentCount: map['commentCount'] ?? 0,
    );
  }
}