// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/language_service.dart';
import '../../models/post_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/language_switch.dart';
import '../../l10n/app_localizations.dart';
import '../auth/login_screen.dart';
import '../home/post_card.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  // متغيرات لتحميل المنشورات
  List<PostModel> _userPosts = [];
  bool _isLoadingPosts = true;
  String? _postsError;

  @override
  void initState() {
    super.initState();
    _loadUserPosts();
  }

  // ========== تحميل منشورات المستخدم ==========
  Future<void> _loadUserPosts() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;

    if (user == null) return;

    setState(() {
      _isLoadingPosts = true;
      _postsError = null;
    });

    try {
      final posts = await _firestoreService.getUserPostsOnce(user.uid);
      if (mounted) {
        setState(() {
          _userPosts = posts;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _postsError = e.toString();
          _isLoadingPosts = false;
        });
      }
    }
  }

  // ========== تحديث البيانات بعد التعديل ==========
  Future<void> _refreshData() async {
    await _loadUserPosts();
    // تحديث بيانات المستخدم من AuthService
    await Provider.of<AuthService>(context, listen: false).reloadUser();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;
    final userModel = authService.userModel;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t.translate('profile')),
          centerTitle: true,
          actions: [
            LanguageSwitch(),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(t.translate('pleaseLogin')),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text(t.translate('login')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('profile')),
        centerTitle: true,
        actions: [
          // زر التحديث اليدوي
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? LoadingWidget()
          : RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // معلومات المستخدم
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue[50],
                child: Column(
                  children: [
                    Row(
                      children: [
                        // الصورة مع أيقونة تغيير
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: userModel?.photoUrl != null
                                  ? CachedNetworkImageProvider(userModel!.photoUrl!)
                                  : null,
                              child: userModel?.photoUrl == null
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
                            ),
                            // زر تغيير الصورة (أيقونة صغيرة)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickProfileImage,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      userModel?.name ?? t.translate('user'),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: _editName,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email ?? '',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              if (userModel?.phone != null)
                                Text(
                                  userModel!.phone!,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // زر تغيير الصورة (نص)
                    Align(
                      alignment: Alignment.center,
                      child: TextButton.icon(
                        onPressed: _pickProfileImage,
                        icon: const Icon(Icons.photo_camera, size: 16),
                        label: Text(t.translate('changePhoto')),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // زر تعديل الملف الشخصي
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: _editProfile,
                  icon: const Icon(Icons.edit),
                  label: Text(t.translate('editProfile')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // منشورات المستخدم
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    t.translate('myPosts'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // منشورات المستخدم - باستخدام FutureBuilder
              _isLoadingPosts
                  ? const Center(child: CircularProgressIndicator())
                  : _postsError != null
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.orange, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        '${t.translate('error')}: $_postsError',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserPosts,
                        child: Text(t.translate('retry')),
                      ),
                    ],
                  ),
                ),
              )
                  : _userPosts.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        t.translate('noPosts'),
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _userPosts.length,
                itemBuilder: (context, index) {
                  return PostCard(post: _userPosts[index]);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // ========== دالة اختيار صورة الملف الشخصي ==========
  Future<void> _pickProfileImage() async {
    final t = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 500,
      maxHeight: 500,
    );

    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;
      if (user == null) throw Exception(t.translate('loginRequired'));

      print('📤 بدأ رفع صورة الملف الشخصي...');

      // رفع الصورة إلى Firebase Storage
      final String downloadUrl = await _storageService.uploadFile(
        File(image.path),
        'profile_images/${user.uid}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      print('✅ تم رفع الصورة: $downloadUrl');

      // تحديث الصورة في Firestore
      await _firestoreService.updateUserPhoto(user.uid, downloadUrl);

      // تحديث AuthService
      await authService.reloadUser();

      // تحديث الصفحة
      await _refreshData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.translate('photoUpdated'))),
        );
      }
    } catch (e) {
      print('❌ خطأ في رفع الصورة: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.translate('photoUpdateFailed')}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ========== دالة تعديل الاسم ==========
  Future<void> _editName() async {
    final t = AppLocalizations.of(context)!;
    final TextEditingController nameController = TextEditingController(
      text: Provider.of<AuthService>(context, listen: false).userModel?.name ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.translate('editName')),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: t.translate('enterNewName'),
            border: const OutlineInputBorder(),
          ),
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

    if (result == true && nameController.text.trim().isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = authService.user;
        if (user == null) throw Exception(t.translate('loginRequired'));

        await _firestoreService.updateUserName(user.uid, nameController.text.trim());
        await authService.reloadUser();

        // تحديث الصفحة
        await _refreshData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.translate('nameUpdated'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${t.translate('nameUpdateFailed')}: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // ========== دالة تعديل الملف الشخصي (القديمة) ==========
  Future<void> _editProfile() async {
    _editName();
  }

  // ========== دالة تسجيل الخروج ==========
  Future<void> _logout() async {
    final t = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.translate('logout')),
        content: Text(t.translate('logoutConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.translate('logout')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      // تسجيل الخروج من Firebase
      await Provider.of<AuthService>(context, listen: false).signOut();

      // الانتقال إلى شاشة تسجيل الدخول
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }

      setState(() => _isLoading = false);
    }
  }
}