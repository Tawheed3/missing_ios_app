// lib/controllers/posts_controller.dart
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';

class PostsController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<PostModel> _posts = [];
  List<PostModel> _filteredPosts = [];
  bool _isLoading = false;
  String? _error;
  String? _currentFilterType;
  String? _currentFilterCategory;

  List<PostModel> get posts => _filteredPosts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // تحميل المنشورات لمرة واحدة
  Future<void> loadPosts({String? filterType, String? filterCategory}) async {
    _isLoading = true;
    _error = null;
    _currentFilterType = filterType;
    _currentFilterCategory = filterCategory;
    notifyListeners();

    try {
      _posts = await _firestoreService.getPostsOnce(
        filterType: filterType,
        filterCategory: filterCategory,
      );
      _applyFilters();
    } catch (e) {
      _error = e.toString();
      _posts = [];
      _filteredPosts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // إعادة تحميل (Refresh)
  Future<void> refreshPosts() async {
    await loadPosts(
      filterType: _currentFilterType,
      filterCategory: _currentFilterCategory,
    );
  }

  // تطبيق الفلاتر
  void _applyFilters() {
    _filteredPosts = _posts;
  }

  // تغيير الفلتر
  void setFilter({String? type, String? category}) {
    _currentFilterType = type;
    _currentFilterCategory = category;
    refreshPosts();
  }

  // بعد إضافة منشور جديد
  void onPostAdded() {
    refreshPosts();
  }

  // بعد تعديل/حذف منشور
  void onPostChanged() {
    refreshPosts();
  }

  // البحث في المنشورات المحملة
  List<PostModel> searchInLoadedPosts(String query, {String searchType = 'all'}) {
    if (query.isEmpty) return _filteredPosts;

    return _filteredPosts.where((post) {
      String searchQuery = query.toLowerCase();

      switch (searchType) {
        case 'title':
          return post.title.toLowerCase().contains(searchQuery);
        case 'description':
          return post.description.toLowerCase().contains(searchQuery);
        case 'user':
          return post.userDisplayName.toLowerCase().contains(searchQuery);
        case 'all':
        default:
          return post.title.toLowerCase().contains(searchQuery) ||
              post.description.toLowerCase().contains(searchQuery) ||
              post.userDisplayName.toLowerCase().contains(searchQuery);
      }
    }).toList();
  }
}