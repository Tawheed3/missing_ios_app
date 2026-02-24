// lib/screens/profile/view_profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../widgets/loading_widget.dart';
import '../../l10n/app_localizations.dart';
import '../home/post_card.dart';
import 'profile_screen.dart';

class ViewProfileScreen extends StatefulWidget {
  final String userId;

  const ViewProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ViewProfileScreenState createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _userModel;
  bool _isLoadingUser = true;
  String? _errorMessage;
  bool _dependenciesLoaded = false;

  @override
  void initState() {
    super.initState();
    // لا نستدعي _loadUserData هنا
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // نتأكد إننا مش حملنا قبل كده
    if (!_dependenciesLoaded) {
      _dependenciesLoaded = true;
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    // محاولة جلب بيانات المستخدم من Firestore
    setState(() {
      _isLoadingUser = true;
      _errorMessage = null;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (mounted) {
        if (userDoc.exists) {
          _userModel = UserModel.fromMap(userDoc.data()!);
        } else {
          _errorMessage = AppLocalizations.of(context)?.translate('userNotFound') ?? 'المستخدم غير موجود';
        }
      }
    } catch (e) {
      print('❌ خطأ في تحميل بيانات المستخدم: $e');
      if (mounted) {
        _errorMessage = AppLocalizations.of(context)?.translate('errorLoadingData') ?? 'حدث خطأ في تحميل البيانات';
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final currentUserId = Provider.of<AuthService>(context).user?.uid;
    final isMyProfile = currentUserId == widget.userId;

    return
      SafeArea(child:  Scaffold(
      appBar: AppBar(
        title: Text(isMyProfile ? t.translate('myProfile') : t.translate('userProfile')),
        centerTitle: true,
        actions: [
          if (isMyProfile)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
            ),

        ],
      ),
      body: _isLoadingUser
          ? LoadingWidget(message: t.translate('loadingProfile'))
          : _errorMessage != null
          ? _buildErrorWidget()
          : _buildProfileContent(isMyProfile),
        )
      );
  }

  Widget _buildErrorWidget() {
    final t = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadUserData,
            child: Text(t.translate('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(bool isMyProfile) {
    final t = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Column(
        children: [
          // معلومات المستخدم
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // الصورة الشخصية
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _userModel?.photoUrl != null
                      ? CachedNetworkImageProvider(_userModel!.photoUrl!)
                      : null,
                  child: _userModel?.photoUrl == null
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
                const SizedBox(height: 16),

                // الاسم
                Text(
                  _userModel?.name ?? t.translate('user'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // البريد الإلكتروني
                if (_userModel?.email != null)
                  Text(
                    _userModel!.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                const SizedBox(height: 4),

                // رقم الهاتف (إذا كان متاحاً)
                if (_userModel?.phone != null)
                  Text(
                    _userModel!.phone!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                const SizedBox(height: 16),

                // تاريخ الانضمام
                if (_userModel?.createdAt != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t.translateWithParams('joinDate', params: {
                        'date': DateFormat('dd/MM/yyyy').format(_userModel!.createdAt)
                      }),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // منشورات المستخدم
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                t.translate('userPosts'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // StreamBuilder لمنشورات المستخدم
          StreamBuilder<List<PostModel>>(
            stream: _firestoreService.getUserPosts(widget.userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.orange, size: 48),
                        const SizedBox(height: 8),
                        Text('${t.translate('error')}: ${snapshot.error}'),
                      ],
                    ),
                  ),
                );
              }

              final posts = snapshot.data ?? [];

              if (posts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          t.translate('noPosts'),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  return PostCard(post: posts[index]);
                },
              );
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}