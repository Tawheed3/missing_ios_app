// lib/screens/details/post_details_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../models/post_model.dart';
import '../../models/comment_model.dart';
import '../../models/reply_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/language_switch.dart';
import '../../l10n/app_localizations.dart';
import '../add_post/add_post_screen.dart';
import '../profile/view_profile_screen.dart';

class PostDetailsScreen extends StatefulWidget {
  final String postId;

  const PostDetailsScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _PostDetailsScreenState createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _commentController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  // متغيرات للتحميل اليدوي
  PostModel? _post;
  List<CommentModel> _comments = [];
  Map<String, List<ReplyModel>> _replies = {};
  Map<String, bool> _showReplies = {};
  bool _isLoadingPost = true;
  bool _isLoadingComments = true;
  String? _postError;
  String? _commentsError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // ========== تحميل جميع البيانات ==========
  Future<void> _loadData() async {
    await Future.wait([
      _loadPost(),
      _loadComments(),
    ]);
  }

  // ========== تحميل المنشور ==========
  Future<void> _loadPost() async {
    setState(() {
      _isLoadingPost = true;
      _postError = null;
    });

    try {
      final post = await _firestoreService.getPostByIdOnce(widget.postId);
      if (mounted) {
        setState(() {
          _post = post;
          _isLoadingPost = false;
        });

        // تهيئة الفيديو إذا وجد
        if (post?.videoUrl != null && !_isVideoInitialized) {
          _initializeVideo(post!.videoUrl!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _postError = e.toString();
          _isLoadingPost = false;
        });
      }
    }
  }

  // ========== تحميل التعليقات ==========
  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
      _commentsError = null;
    });

    try {
      final comments = await _firestoreService.getPostCommentsOnce(widget.postId);

      // تحميل الردود لكل تعليق
      Map<String, List<ReplyModel>> repliesMap = {};
      for (var comment in comments) {
        final replies = await _firestoreService.getRepliesOnce(comment.id);
        repliesMap[comment.id] = replies;
      }

      if (mounted) {
        setState(() {
          _comments = comments;
          _replies = repliesMap;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _commentsError = e.toString();
          _isLoadingComments = false;
        });
      }
    }
  }

  // ========== تحديث البيانات (Refresh) ==========
  Future<void> _refreshData() async {
    await _loadData();
  }

  // ========== دالة بادئة الدولة ==========
  String _getCountryPrefix(String country) {
    switch (country) {
      case 'egypt':
        return '+20';
      case 'saudi':
        return '+966';
      default:
        return '';
    }
  }

  // ========== دوال مساعدة لعرض نوع الحيوان ==========
  String _getPetEmoji(String petType) {
    switch (petType) {
      case 'cat': return '🐱';
      case 'dog': return '🐶';
      case 'bird': return '🐦';
      case 'rabbit': return '🐰';
      case 'fish': return '🐠';
      case 'hamster': return '🐹';
      case 'turtle': return '🐢';
      default: return '🐾';
    }
  }

  String _getPetName(String petType) {
    switch (petType) {
      case 'cat': return 'قط';
      case 'dog': return 'كلب';
      case 'bird': return 'طائر';
      case 'rabbit': return 'أرنب';
      case 'fish': return 'سمك';
      case 'hamster': return 'هامستر';
      case 'turtle': return 'سلحفاة';
      default: return petType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.translate('postDetails')),
          centerTitle: true,
          actions: [
            LanguageSwitch(),
            // زر التحديث اليدوي
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
            ),
          ],
        ),
        body: _isLoadingPost
            ? LoadingWidget()
            : _postError != null || _post == null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _postError ?? t.translate('postNotFound'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshData,
                child: Text(t.translate('retry')),
              ),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: _refreshData,
          child: _buildBody(_post!),
        ),
        bottomSheet: _buildCommentInput(),
      ),
    );
  }

  Widget _buildBody(PostModel post) {
    final t = AppLocalizations.of(context)!;

    return CustomScrollView(
      slivers: [
        // App Bar مع الصورة
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: post.images.isNotEmpty
                ? CachedNetworkImage(
              imageUrl: post.images.first,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.error, size: 50),
              ),
            )
                : Container(color: Colors.grey[300]),
          ),
          actions: [
            if (post.userId == Provider.of<AuthService>(context).user?.uid)
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(t.translate('edit')),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(t.translate('delete')),
                  ),
                  if (post.status == 'active')
                    PopupMenuItem(
                      value: 'resolve',
                      child: Text(t.translate('resolve')),
                    ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editPost(post);
                      break;
                    case 'delete':
                      _deletePost(post);
                      break;
                    case 'resolve':
                      _markAsResolved(post);
                      break;
                  }
                },
              ),
          ],
        ),

        // محتوى المنشور
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // شارات الحالة
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: post.type == 'lost' ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        post.type == 'lost' ? t.translate('lost') : t.translate('found'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: post.category == 'pet' ? Colors.orange : Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        post.category == 'pet' ? t.translate('pet') : t.translate('item'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    if (post.category == 'pet' && post.petType != null && post.petType!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getPetEmoji(post.petType!),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getPetName(post.petType!),
                              style: TextStyle(
                                color: Colors.purple.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (post.status == 'resolved')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          t.translate('resolved'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // العنوان
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // معلومات المستخدم
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewProfileScreen(userId: post.userId),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: post.userPhotoUrl.isNotEmpty
                            ? CachedNetworkImageProvider(post.userPhotoUrl)
                            : null,
                        child: post.userPhotoUrl.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.userDisplayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              post.locationName,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(post.createdAt),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // رقم الهاتف
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.translate('contact'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.phone,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        post.country == 'egypt'
                                            ? t.translate('egypt')
                                            : t.translate('saudi'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _getCountryPrefix(post.country),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    post.phone.isNotEmpty ? post.phone : t.translate('notAvailable'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (post.phone.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.phone_in_talk, color: Colors.green.shade700),
                                onPressed: () => _callPhoneNumber(post.country, post.phone),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // الوصف
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.translate('description'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.description,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // صور إضافية
                if (post.images.length > 1)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.translate('additionalImages'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: post.images.length - 1,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                _showImageFullScreen(post.images[index + 1]);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: CachedNetworkImageProvider(
                                      post.images[index + 1],
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // فيديو
                if (post.videoUrl != null && _isVideoInitialized)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.translate('video'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              _videoController!.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                            onPressed: () {
                              setState(() {
                                _videoController!.value.isPlaying
                                    ? _videoController!.pause()
                                    : _videoController!.play();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // زر الاتصال بالصاحب
                if (post.userId != Provider.of<AuthService>(context).user?.uid)
                  CustomButton(
                    text: t.translate('contactOwner'),
                    onPressed: () => _contactUser(post),
                    icon: Icons.phone,
                  ),
                const SizedBox(height: 16),

                // التعليقات
                Text(
                  t.translateWithParams('comments', params: {'count': _comments.length.toString()}),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // قائمة التعليقات
        SliverToBoxAdapter(
          child: _isLoadingComments
              ? const Center(child: CircularProgressIndicator())
              : _commentsError != null
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.orange, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    t.translate('commentsError'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadComments,
                    child: Text(t.translate('retry')),
                  ),
                ],
              ),
            ),
          )
              : _comments.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(t.translate('noComments')),
            ),
          )
              : Column(
            children: _comments.map((comment) {
              return _buildCommentItem(comment);
            }).toList(),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  // ========== دالة بناء عنصر التعليق مع الردود ==========
  Widget _buildCommentItem(CommentModel comment) {
    final t = AppLocalizations.of(context)!;
    final currentUserId = Provider.of<AuthService>(context).user?.uid;
    final isMyComment = currentUserId == comment.userId;
    final replies = _replies[comment.id] ?? [];
    final showReplies = _showReplies[comment.id] ?? false;

    return FutureBuilder<String?>(
      future: _firestoreService.getUserReaction(comment.id),
      builder: (context, reactionSnapshot) {
        final userReaction = reactionSnapshot.data;

        return Container(
          key: ValueKey(comment.id),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس التعليق
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewProfileScreen(userId: comment.userId),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundImage: comment.userPhotoUrl.isNotEmpty
                          ? CachedNetworkImageProvider(comment.userPhotoUrl)
                          : null,
                      child: comment.userPhotoUrl.isEmpty
                          ? const Icon(Icons.person, size: 16)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ViewProfileScreen(userId: comment.userId),
                                    ),
                                  );
                                },
                                child: Text(
                                  comment.userDisplayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                            if (isMyComment) ...[
                              IconButton(
                                icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                onPressed: () => _showEditCommentDialog(comment),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                            Text(
                              DateFormat('dd/MM HH:mm').format(comment.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(comment.text),
                      ],
                    ),
                  ),
                ],
              ),

              // أزرار الريأكسات
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 40),
                child: Row(
                  children: [
                    _buildReactionButton(
                      comment: comment,
                      reactionType: 'like',
                      icon: Icons.thumb_up_alt_outlined,
                      filledIcon: Icons.thumb_up_alt,
                      color: Colors.blue,
                      count: comment.reactions['like'] ?? 0,
                      isActive: userReaction == 'like',
                    ),
                    const SizedBox(width: 16),
                    _buildReactionButton(
                      comment: comment,
                      reactionType: 'laugh',
                      icon: Icons.emoji_emotions_outlined,
                      filledIcon: Icons.emoji_emotions,
                      color: Colors.orange,
                      count: comment.reactions['laugh'] ?? 0,
                      isActive: userReaction == 'laugh',
                    ),
                    const SizedBox(width: 16),
                    _buildReactionButton(
                      comment: comment,
                      reactionType: 'heart',
                      icon: Icons.favorite_border,
                      filledIcon: Icons.favorite,
                      color: Colors.red,
                      count: comment.reactions['heart'] ?? 0,
                      isActive: userReaction == 'heart',
                    ),
                  ],
                ),
              ),

              // قسم الردود
              if (replies.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 40),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showReplies[comment.id] = !showReplies;
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          showReplies ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          showReplies
                              ? t.translate('hideReplies')
                              : t.translateWithParams('showReplies', params: {'count': replies.length.toString()}),
                          style: const TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

              // عرض الردود
              if (showReplies && replies.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 24),
                  child: Column(
                    children: replies.map((reply) => _buildReplyItem(reply)).toList(),
                  ),
                ),

              // حقل إضافة رد
              _AddReplyInput(
                commentId: comment.id,
                onReplyAdded: () {
                  _loadComments(); // إعادة تحميل التعليقات بعد إضافة الرد
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ========== دالة بناء زر التفاعل ==========
  Widget _buildReactionButton({
    required CommentModel comment,
    required String reactionType,
    required IconData icon,
    required IconData filledIcon,
    required Color color,
    required int count,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () async {
        try {
          await _firestoreService.toggleReaction(comment.id, reactionType);
          await _loadComments(); // إعادة تحميل التعليقات بعد التغيير
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${AppLocalizations.of(context)!.translate('reactionFailed')}: $e')),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? filledIcon : icon,
              color: isActive ? color : Colors.grey[600],
              size: 16,
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  color: isActive ? color : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ========== دالة بناء عنصر الرد ==========
  Widget _buildReplyItem(ReplyModel reply) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.subdirectory_arrow_right, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewProfileScreen(userId: reply.userId),
                ),
              );
            },
            child: CircleAvatar(
              radius: 12,
              backgroundImage: reply.userPhotoUrl.isNotEmpty
                  ? CachedNetworkImageProvider(reply.userPhotoUrl)
                  : null,
              child: reply.userPhotoUrl.isEmpty
                  ? const Icon(Icons.person, size: 12)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewProfileScreen(userId: reply.userId),
                      ),
                    );
                  },
                  child: Text(
                    reply.userDisplayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reply.text,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('HH:mm').format(reply.createdAt),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ========== دالة تعديل التعليق ==========
  Future<void> _showEditCommentDialog(CommentModel comment) async {
    final t = AppLocalizations.of(context)!;
    final TextEditingController editController = TextEditingController(text: comment.text);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.translate('editComment')),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(
            hintText: t.translate('editCommentHint'),
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.translate('save')),
          ),
        ],
      ),
    );

    if (result == true && editController.text.trim().isNotEmpty) {
      try {
        await _firestoreService.updateComment(comment.id, editController.text.trim());
        await _loadComments(); // إعادة تحميل التعليقات بعد التعديل
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.translate('editCommentSuccess'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${t.translate('editCommentFailed')}: $e')),
          );
        }
      }
    }
  }

  Widget _buildCommentInput() {
    final t = AppLocalizations.of(context)!;
    final user = Provider.of<AuthService>(context).user;

    if (user == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black12,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: t.translate('writeComment'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _submitComment,
            ),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Future<void> _initializeVideo(String url) async {
    _videoController = VideoPlayerController.network(url);
    await _videoController!.initialize();
    if (mounted) {
      setState(() {
        _isVideoInitialized = true;
      });
    }
  }

  void _showImageFullScreen(String imageUrl) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => Center(child: Text(t.translate('loading'))),
          ),
        ),
      ),
    );
  }

  Future<void> _submitComment() async {
    final t = AppLocalizations.of(context)!;

    if (_commentController.text.trim().isEmpty) return;

    try {
      await _firestoreService.addComment(
        widget.postId,
        _commentController.text.trim(),
      );
      _commentController.clear();
      await _loadComments(); // إعادة تحميل التعليقات بعد الإضافة
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.translate('commentFailed')}: $e')),
        );
      }
    }
  }

  Future<void> _editPost(PostModel post) async {
    final t = AppLocalizations.of(context)!;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPostScreen(
          postToEdit: post,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadPost(); // إعادة تحميل المنشور بعد التعديل
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.translate('editSuccess'))),
      );
    }
  }

  Future<void> _deletePost(PostModel post) async {
    final t = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.translate('deleteConfirm')),
        content: Text(t.translate('deletePostConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t.translate('delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.deletePost(widget.postId);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.translate('deleteSuccess'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${t.translate('deleteFailed')}: $e')),
          );
        }
      }
    }
  }

  Future<void> _markAsResolved(PostModel post) async {
    final t = AppLocalizations.of(context)!;

    try {
      await _firestoreService.updatePostStatus(widget.postId, 'resolved');
      await _loadPost(); // إعادة تحميل المنشور بعد تغيير الحالة
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.translate('resolveSuccess'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.translate('resolveFailed')}: $e')),
        );
      }
    }
  }

  Future<void> _callPhoneNumber(String country, String phoneNumber) async {
    final t = AppLocalizations.of(context)!;
    String prefix = _getCountryPrefix(country);
    String fullNumber = prefix + phoneNumber.substring(1);

    final Uri phoneUri = Uri(scheme: 'tel', path: fullNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw 'Could not launch $phoneUri';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.translate('callFailed')}: $e')),
        );
      }
    }
  }

  Future<void> _contactUser(PostModel post) async {
    final t = AppLocalizations.of(context)!;

    if (post.phone.isNotEmpty) {
      await _callPhoneNumber(post.country, post.phone);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.translate('noPhone'))),
        );
      }
    }
  }
}

// ========== كلاس إضافة رد ==========
class _AddReplyInput extends StatefulWidget {
  final String commentId;
  final VoidCallback onReplyAdded;

  const _AddReplyInput({
    Key? key,
    required this.commentId,
    required this.onReplyAdded,
  }) : super(key: key);

  @override
  __AddReplyInputState createState() => __AddReplyInputState();
}

class __AddReplyInputState extends State<_AddReplyInput> {
  final TextEditingController _replyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 40),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              decoration: InputDecoration(
                hintText: t.translate('writeReply'),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            child: IconButton(
              icon: const Icon(Icons.reply, size: 14),
              onPressed: _submitReply,
              padding: EdgeInsets.zero,
            ),
            backgroundColor: Colors.grey[200],
          ),
        ],
      ),
    );
  }

  Future<void> _submitReply() async {
    final t = AppLocalizations.of(context)!;

    if (_replyController.text.trim().isEmpty) return;

    try {
      await FirestoreService().addReply(
        widget.commentId,
        _replyController.text.trim(),
      );
      _replyController.clear();
      widget.onReplyAdded(); // استدعاء الدالة بعد إضافة الرد
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.translate('replyFailed')}: $e')),
        );
      }
    }
  }
}