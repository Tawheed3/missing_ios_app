// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/reply_model.dart';
import '../l10n/app_localizations.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ========== POSTS ==========

  Future<String> addPost(PostModel post) async {
    try {
      DocumentReference docRef = await _firestore.collection('posts').add(post.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception(_getLocalizedString('addPostFailed') + ': $e');
    }
  }

  Stream<List<PostModel>> getPosts({String? filterType, String? filterCategory}) {
    Query query = _firestore.collection('posts').orderBy('createdAt', descending: true);

    if (filterType != null) {
      query = query.where('type', isEqualTo: filterType);
    }
    if (filterCategory != null) {
      query = query.where('category', isEqualTo: filterCategory);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return PostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Stream<PostModel> getPostById(String postId) {
    return _firestore.collection('posts').doc(postId).snapshots().map((doc) {
      return PostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    });
  }

  Stream<List<PostModel>> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> updatePostStatus(String postId, String status) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'status': status,
      });
    } catch (e) {
      throw Exception(_getLocalizedString('updatePostStatusFailed') + ': $e');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      throw Exception(_getLocalizedString('deletePostFailed') + ': $e');
    }
  }

  // ========== GET POSTS ONCE (بدون Stream) ==========
  Future<List<PostModel>> getPostsOnce({String? filterType, String? filterCategory}) async {
    try {
      Query query = _firestore.collection('posts').orderBy('createdAt', descending: true);

      if (filterType != null) {
        query = query.where('type', isEqualTo: filterType);
      }
      if (filterCategory != null) {
        query = query.where('category', isEqualTo: filterCategory);
      }

      final QuerySnapshot snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return PostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('❌ خطأ في جلب المنشورات: $e');
      return [];
    }
  }

  // ========== GET USER POSTS ONCE ==========
  Future<List<PostModel>> getUserPostsOnce(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return PostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('❌ خطأ في جلب منشورات المستخدم: $e');
      return [];
    }
  }

  // ========== GET POST BY ID ONCE ==========
  Future<PostModel?> getPostByIdOnce(String postId) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('posts').doc(postId).get();

      if (!doc.exists) return null;

      return PostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('❌ خطأ في جلب المنشور: $e');
      return null;
    }
  }

  // ========== GET COMMENTS ONCE ==========
  Future<List<CommentModel>> getPostCommentsOnce(String postId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return CommentModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('❌ خطأ في جلب التعليقات: $e');
      return [];
    }
  }

  // ========== GET REPLIES ONCE ==========
  Future<List<ReplyModel>> getRepliesOnce(String commentId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('replies')
          .where('commentId', isEqualTo: commentId)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        return ReplyModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('❌ خطأ في جلب الردود: $e');
      return [];
    }
  }

  // ========== COMMENTS ==========
  Future<void> addComment(String postId, String text) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception(_getLocalizedString('loginRequired'));

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      CommentModel comment = CommentModel(
        id: '',
        postId: postId,
        userId: user.uid,
        userDisplayName: userData?['name'] ?? _getLocalizedString('user'),
        userPhotoUrl: userData?['photoUrl'] ?? '',
        text: text,
        createdAt: DateTime.now(),
        reactions: {},
        replyCount: 0,
      );

      await _firestore.collection('comments').add(comment.toMap());

      await _firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception(_getLocalizedString('addCommentFailed') + ': $e');
    }
  }

  Stream<List<CommentModel>> getPostComments(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CommentModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // ========== REPLIES ==========
  Future<void> addReply(String commentId, String text) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception(_getLocalizedString('loginRequired'));

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      ReplyModel reply = ReplyModel(
        id: '',
        commentId: commentId,
        userId: user.uid,
        userDisplayName: userData?['name'] ?? _getLocalizedString('user'),
        userPhotoUrl: userData?['photoUrl'] ?? '',
        text: text,
        createdAt: DateTime.now(),
        reactions: {},
      );

      await _firestore.collection('replies').add(reply.toMap());

      // تحديث عدد الردود في التعليق
      await _firestore.collection('comments').doc(commentId).update({
        'replyCount': FieldValue.increment(1),
      });

      print('✅ تم إضافة رد على التعليق: $commentId');
    } catch (e) {
      throw Exception(_getLocalizedString('addReplyFailed') + ': $e');
    }
  }

  Stream<List<ReplyModel>> getReplies(String commentId) {
    return _firestore
        .collection('replies')
        .where('commentId', isEqualTo: commentId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ReplyModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // ========== SEARCH ==========
  Future<List<PostModel>> searchPosts(String query) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('title')
          .startAt([query]).endAt([query + '\uf8ff'])
          .get();

      return snapshot.docs.map((doc) {
        return PostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception(_getLocalizedString('searchFailed') + ': $e');
    }
  }

  // ========== USER PROFILE ==========
  Future<void> updateUserPhoto(String userId, String photoUrl) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'photoUrl': photoUrl,
      });
      print('✅ تم تحديث صورة المستخدم');
    } catch (e) {
      throw Exception(_getLocalizedString('updatePhotoFailed') + ': $e');
    }
  }

  Future<void> updateUserName(String userId, String newName) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'name': newName,
      });
      print('✅ تم تحديث اسم المستخدم');
    } catch (e) {
      throw Exception(_getLocalizedString('updateNameFailed') + ': $e');
    }
  }

  // ========== REACTIONS ==========
  Future<void> toggleReaction(String commentId, String reactionType) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception(_getLocalizedString('loginRequired'));

      final reactionDocId = '${user.uid}_$commentId';
      final reactionDoc = _firestore.collection('user_reactions').doc(reactionDocId);
      final reactionSnapshot = await reactionDoc.get();

      if (reactionSnapshot.exists) {
        final existingReaction = reactionSnapshot.data()?['reactionType'];

        if (existingReaction == reactionType) {
          await reactionDoc.delete();
          await _firestore.collection('comments').doc(commentId).update({
            'reactions.$reactionType': FieldValue.increment(-1),
          });
        } else {
          await reactionDoc.update({'reactionType': reactionType});
          await _firestore.collection('comments').doc(commentId).update({
            'reactions.$existingReaction': FieldValue.increment(-1),
            'reactions.$reactionType': FieldValue.increment(1),
          });
        }
      } else {
        await reactionDoc.set({
          'userId': user.uid,
          'commentId': commentId,
          'reactionType': reactionType,
          'createdAt': Timestamp.now(),
        });
        await _firestore.collection('comments').doc(commentId).update({
          'reactions.$reactionType': FieldValue.increment(1),
        });
      }
    } catch (e) {
      throw Exception(_getLocalizedString('reactionFailed') + ': $e');
    }
  }

  Future<String?> getUserReaction(String commentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final reactionDoc = await _firestore
          .collection('user_reactions')
          .doc('${user.uid}_$commentId')
          .get();

      if (reactionDoc.exists) {
        return reactionDoc.data()?['reactionType'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ========== UPDATE POST ==========
  Future<void> updatePost(String postId, Map<String, dynamic> updatedData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception(_getLocalizedString('loginRequired'));

      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) throw Exception(_getLocalizedString('postNotFound'));

      final postData = postDoc.data();
      if (postData?['userId'] != user.uid) {
        throw Exception(_getLocalizedString('noPermissionToEdit'));
      }

      updatedData['updatedAt'] = Timestamp.now();
      await _firestore.collection('posts').doc(postId).update(updatedData);
      print('✅ تم تحديث المنشور');
    } catch (e) {
      throw Exception(_getLocalizedString('updatePostFailed') + ': $e');
    }
  }

  // ========== UPDATE COMMENT ==========
  Future<void> updateComment(String commentId, String newText) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception(_getLocalizedString('loginRequired'));

      final commentDoc = await _firestore.collection('comments').doc(commentId).get();
      if (!commentDoc.exists) throw Exception(_getLocalizedString('commentNotFound'));

      final commentData = commentDoc.data();
      if (commentData?['userId'] != user.uid) {
        throw Exception(_getLocalizedString('noPermissionToEditComment'));
      }

      await _firestore.collection('comments').doc(commentId).update({
        'text': newText,
        'editedAt': Timestamp.now(),
      });
      print('✅ تم تحديث التعليق');
    } catch (e) {
      throw Exception(_getLocalizedString('updateCommentFailed') + ': $e');
    }
  }

  // ========== CLEAN DUPLICATES ==========
  Future<void> cleanDuplicateComments() async {
    try {
      print('🧹 بدء تنظيف التكرارات...');

      final snapshot = await _firestore.collection('comments').get();
      Map<String, List<QueryDocumentSnapshot>> grouped = {};

      for (var doc in snapshot.docs) {
        String userId = (doc.data() as Map<String, dynamic>)['userId'] ?? '';
        String text = (doc.data() as Map<String, dynamic>)['text'] ?? '';
        String key = '$userId|$text';

        if (!grouped.containsKey(key)) {
          grouped[key] = [];
        }
        grouped[key]!.add(doc);
      }

      for (var key in grouped.keys) {
        var docs = grouped[key]!;
        if (docs.length > 1) {
          print('⚠️ وجدت ${docs.length} نسخ للمفتاح: $key');

          List<QueryDocumentSnapshot> mainComments = [];
          List<QueryDocumentSnapshot> replies = [];

          for (var doc in docs) {
            var docData = doc.data() as Map<String, dynamic>;
            if (docData['parentId'] == null) {
              mainComments.add(doc);
            } else {
              replies.add(doc);
            }
          }

          if (mainComments.length > 1) {
            mainComments.sort((a, b) {
              var aData = a.data() as Map<String, dynamic>;
              var bData = b.data() as Map<String, dynamic>;
              return (aData['createdAt'] as Timestamp).compareTo(bData['createdAt'] as Timestamp);
            });
            for (int i = 1; i < mainComments.length; i++) {
              await mainComments[i].reference.delete();
              print('🗑️ تم حذف تعليق رئيسي مكرر: ${mainComments[i].id}');
            }
          }
        }
      }
      print('✅ تم الانتهاء من تنظيف التكرارات');
    } catch (e) {
      print('❌ فشل في تنظيف التكرارات: $e');
    }
  }

  // ========== GET ALL POSTS (للبحث) ==========
  Future<List<PostModel>> getAllPosts() async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return PostModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

    } catch (e) {
      print('❌ خطأ في جلب جميع المنشورات: $e');
      throw Exception('فشل في جلب المنشورات: $e');
    }
  }

  // ========== دالة مساعدة للحصول على النصوص المترجمة ==========
  String _getLocalizedString(String key) {
    // هذه دالة مساعدة، سيتم استبدالها بالنص الفعلي من التطبيق
    // عند استخدامها في الشاشات، سنمرر context
    return key;
  }
}