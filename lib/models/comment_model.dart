// lib/models/comment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  String id;
  String postId;
  String? parentId;
  String userId;
  String userDisplayName;
  String userPhotoUrl;
  String text;
  DateTime createdAt;
  Map<String, int> reactions;
  int replyCount; // عدد الردود فقط (بدون تخزين الردود هنا)

  CommentModel({
    required this.id,
    required this.postId,
    this.parentId,
    required this.userId,
    required this.userDisplayName,
    required this.userPhotoUrl,
    required this.text,
    required this.createdAt,
    required this.reactions,
    required this.replyCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'parentId': parentId,
      'userDisplayName': userDisplayName,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'reactions': reactions,
      'replyCount': replyCount,
    };
  }

  factory CommentModel.fromMap(String id, Map<String, dynamic> map) {
    return CommentModel(
      id: id,
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      parentId: map['parentId'],
      userDisplayName: map['userDisplayName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'] ?? '',
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reactions: Map<String, int>.from(map['reactions'] ?? {}),
      replyCount: map['replyCount'] ?? 0,
    );
  }
}