// lib/controllers/comments_controller.dart
import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../models/reply_model.dart';
import '../services/firestore_service.dart';

class CommentsController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final String postId;

  List<CommentModel> _comments = [];
  Map<String, List<ReplyModel>> _replies = {};
  Map<String, bool> _showReplies = {};
  bool _isLoading = false;
  String? _error;

  CommentsController(this.postId);

  List<CommentModel> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // تحميل التعليقات لمرة واحدة
  Future<void> loadComments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _comments = await _firestoreService.getPostCommentsOnce(postId);
      // تحميل الردود لكل تعليق
      for (var comment in _comments) {
        await _loadRepliesForComment(comment.id);
      }
    } catch (e) {
      _error = e.toString();
      _comments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تحميل الردود لتعليق معين
  Future<void> _loadRepliesForComment(String commentId) async {
    try {
      _replies[commentId] = await _firestoreService.getRepliesOnce(commentId);
    } catch (e) {
      _replies[commentId] = [];
    }
  }

  // الحصول على ردود تعليق معين
  List<ReplyModel> getRepliesForComment(String commentId) {
    return _replies[commentId] ?? [];
  }

  // تبديل عرض/إخفاء الردود
  void toggleShowReplies(String commentId) {
    _showReplies[commentId] = !(_showReplies[commentId] ?? false);
    notifyListeners();
  }

  bool shouldShowReplies(String commentId) {
    return _showReplies[commentId] ?? false;
  }

  // إضافة تعليق جديد
  Future<void> addComment(String text) async {
    try {
      await _firestoreService.addComment(postId, text);
      await loadComments(); // إعادة تحميل التعليقات
    } catch (e) {
      throw e;
    }
  }

  // إضافة رد جديد
  Future<void> addReply(String commentId, String text) async {
    try {
      await _firestoreService.addReply(commentId, text);
      await _loadRepliesForComment(commentId);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  // تحديث تفاعل
  Future<void> toggleReaction(String commentId, String reactionType) async {
    try {
      await _firestoreService.toggleReaction(commentId, reactionType);
      await loadComments(); // إعادة تحميل التعليقات لتحديث التفاعلات
    } catch (e) {
      throw e;
    }
  }
}