// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/posts_controller.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/language_switch.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_screen.dart';
import 'post_card.dart';
import '../add_post/add_post_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchType = 'all';
  List _searchResults = [];

  @override
  void initState() {
    super.initState();
    // تحميل المنشورات عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostsController>().loadPosts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final postsController = context.watch<PostsController>();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: !_isSearching
              ? Text(t.translate('home'))
              : TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: t.translate('searchHint'),
              border: InputBorder.none,
              hintStyle: const TextStyle(color: Colors.white70),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 18),
            onChanged: (value) => _performLocalSearch(),
          ),
          centerTitle: true,
          actions: _isSearching
              ? [
            // أزرار وضع البحث
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: (value) {
                setState(() => _searchType = value);
                _performLocalSearch();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'all',
                  child: Row(
                    children: [
                      Icon(Icons.all_inclusive,
                        color: _searchType == 'all' ? Colors.blue : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text('الكل'),
                      if (_searchType == 'all')
                        const Icon(Icons.check, color: Colors.green, size: 16),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'title',
                  child: Row(
                    children: [
                      Icon(Icons.title,
                        color: _searchType == 'title' ? Colors.blue : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text('العنوان'),
                      if (_searchType == 'title')
                        const Icon(Icons.check, color: Colors.green, size: 16),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'description',
                  child: Row(
                    children: [
                      Icon(Icons.description,
                        color: _searchType == 'description' ? Colors.blue : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text('الوصف'),
                      if (_searchType == 'description')
                        const Icon(Icons.check, color: Colors.green, size: 16),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'user',
                  child: Row(
                    children: [
                      Icon(Icons.person,
                        color: _searchType == 'user' ? Colors.blue : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text('اسم المستخدم'),
                      if (_searchType == 'user')
                        const Icon(Icons.check, color: Colors.green, size: 16),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchResults.clear();
                  _searchController.clear();
                });
              },
            ),
          ]
              : [
            // الأزرار العادية
            PopupMenuButton(
              icon: const Icon(Icons.filter_list),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Text(t.translate('all')),
                  onTap: () => postsController.setFilter(type: null, category: null),
                ),
                PopupMenuItem(
                  child: Text(t.translate('lost')),
                  onTap: () => postsController.setFilter(type: 'lost'),
                ),
                PopupMenuItem(
                  child: Text(t.translate('found')),
                  onTap: () => postsController.setFilter(type: 'found'),
                ),
                PopupMenuItem(
                  child: Text(t.translate('pet')),
                  onTap: () => postsController.setFilter(category: 'pet'),
                ),
                PopupMenuItem(
                  child: Text(t.translate('item')),
                  onTap: () => postsController.setFilter(category: 'item'),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
        body: _isSearching
            ? _buildSearchResults()
            : RefreshIndicator(
          onRefresh: () => postsController.refreshPosts(),
          child: postsController.isLoading
              ? LoadingWidget()
              : postsController.error != null
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${t.translate('error')}: ${postsController.error}',
                textAlign: TextAlign.center,
              ),
            ),
          )
              : postsController.posts.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  t.translate('noPosts'),
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: postsController.posts.length,
            itemBuilder: (context, index) {
              return PostCard(post: postsController.posts[index]);
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddPostScreen()),
            );
            if (result == true) {
              postsController.onPostAdded(); // تحديث بعد الإضافة
            }
          },
          child: const Icon(Icons.add),
          tooltip: t.translate('addPost'),
        ),
      ),
    );
  }

  // ========== عرض نتائج البحث ==========
  Widget _buildSearchResults() {
    final t = AppLocalizations.of(context)!;

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'اكتب ما تبحث عنه...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد نتائج لـ "${_searchController.text}"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'جرب كلمات أخرى',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // شريط النتائج
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'نتائج البحث عن "${_searchController.text}"',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_searchResults.length} نتيجة',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // قائمة النتائج
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return PostCard(post: _searchResults[index]);
            },
          ),
        ),
      ],
    );
  }

  // ========== تنفيذ البحث المحلي (في البيانات المحملة) ==========
  void _performLocalSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    final postsController = context.read<PostsController>();
    final results = postsController.searchInLoadedPosts(query, searchType: _searchType);

    setState(() {
      _searchResults = results;
    });

    print('🔍 بحث محلي عن "$query" (${_searchType}) - النتائج: ${results.length}');
  }
}