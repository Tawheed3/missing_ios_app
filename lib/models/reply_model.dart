// lib/models/reply_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReplyModel {
  String id;
  String commentId;
  String userId;
  String userDisplayName;
  String userPhotoUrl;
  String text;
  DateTime createdAt;
  Map<String, int> reactions;

  ReplyModel({
    required this.id,
    required this.commentId,
    required this.userId,
    required this.userDisplayName,
    required this.userPhotoUrl,
    required this.text,
    required this.createdAt,
    required this.reactions,
  });

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'reactions': reactions,
    };
  }

  factory ReplyModel.fromMap(String id, Map<String, dynamic> map) {
    return ReplyModel(
      id: id,
      commentId: map['commentId'] ?? '',
      userId: map['userId'] ?? '',
      userDisplayName: map['userDisplayName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'] ?? '',
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reactions: Map<String, int>.from(map['reactions'] ?? {}),
    );
  }
}