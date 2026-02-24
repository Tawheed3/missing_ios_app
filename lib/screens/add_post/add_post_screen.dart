// lib/screens/add_post/add_post_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../models/post_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/language_switch.dart';
import '../../l10n/app_localizations.dart';

class AddPostScreen extends StatefulWidget {
  final PostModel? postToEdit;

  const AddPostScreen({Key? key, this.postToEdit}) : super(key: key);

  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  // متغيرات اختيار الدولة
  String _selectedCountry = 'egypt';
  final List<Map<String, dynamic>> _countries = [
    {'code': 'egypt', 'name': 'مصر', 'flag': '🇪🇬', 'prefix': '+20', 'regex': r'^01[0-9]{9}$'},
    {'code': 'saudi', 'name': 'السعودية', 'flag': '🇸🇦', 'prefix': '+966', 'regex': r'^05[0-9]{8}$'},
  ];

  // قائمة الحيوانات المتاحة مع إضافة "أخرى"
  final List<Map<String, dynamic>> _petTypes = [
    {'value': 'cat', 'name': 'قط', 'emoji': '🐱'},
    {'value': 'dog', 'name': 'كلب', 'emoji': '🐶'},
    {'value': 'bird', 'name': 'طائر', 'emoji': '🐦'},
    {'value': 'rabbit', 'name': 'أرنب', 'emoji': '🐰'},
    {'value': 'fish', 'name': 'سمك', 'emoji': '🐠'},
    {'value': 'hamster', 'name': 'هامستر', 'emoji': '🐹'},
    {'value': 'turtle', 'name': 'سلحفاة', 'emoji': '🐢'},
    {'value': 'other', 'name': 'أخرى', 'emoji': ''},
  ];
  String? _selectedPetType;
  String _customPetType = ''; // للحيوان المخصص
  final TextEditingController _customPetController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  String _type = 'lost';
  String _category = 'pet';
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  List<XFile> _selectedImages = [];
  XFile? _selectedVideo;
  bool _isLoading = false;

  bool _isEditMode = false;
  String? _originalPostId;

  @override
  void initState() {
    super.initState();
    print('🔥 [AddPostScreen] initState - تم تحميل شاشة إضافة منشور');

    if (widget.postToEdit != null) {
      _isEditMode = true;
      _originalPostId = widget.postToEdit!.id;
      print('✏️ [AddPostScreen] وضع التعديل - تحميل بيانات المنشور ID: $_originalPostId');

      _type = widget.postToEdit!.type;
      _category = widget.postToEdit!.category;
      _titleController.text = widget.postToEdit!.title;
      _descriptionController.text = widget.postToEdit!.description;
      _phoneController.text = widget.postToEdit!.phone;
      _selectedCountry = widget.postToEdit!.country;
      _selectedPetType = widget.postToEdit!.petType;

      // إذا كان نوع الحيوان مش موجود في القائمة، نعتبره "أخرى" ونحط القيمة في الحقل المخصص
      if (_selectedPetType != null &&
          !_petTypes.any((pet) => pet['value'] == _selectedPetType)) {
        _customPetType = _selectedPetType!;
        _selectedPetType = 'other';
        _customPetController.text = _customPetType;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔥 [AddPostScreen] build - إعادة بناء الشاشة');

    final t = AppLocalizations.of(context)!;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditMode ? t.translate('edit') : t.translate('addPost')),
          centerTitle: true,
          actions: [
            LanguageSwitch(),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // نوع المنشور
              Text(t.translate('postType'), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(t.translate('lost')),
                      selected: _type == 'lost',
                      onSelected: (selected) {
                        if (selected) setState(() => _type = 'lost');
                      },
                      selectedColor: Colors.red[100],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(t.translate('found')),
                      selected: _type == 'found',
                      onSelected: (selected) {
                        if (selected) setState(() => _type = 'found');
                      },
                      selectedColor: Colors.green[100],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // التصنيف
              Text(t.translate('category'), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(t.translate('pet')),
                      selected: _category == 'pet',
                      onSelected: (selected) {
                        if (selected) setState(() => _category = 'pet');
                      },
                      selectedColor: Colors.orange[100],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(t.translate('item')),
                      selected: _category == 'item',
                      onSelected: (selected) {
                        if (selected) setState(() => _category = 'item');
                      },
                      selectedColor: Colors.blue[100],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // العنوان
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: t.translate('title'),
                  border: const OutlineInputBorder(),
                  hintText: t.translate('titleHint'),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t.translate('titleRequired');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // الوصف
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: t.translate('description'),
                  border: const OutlineInputBorder(),
                  hintText: t.translate('descriptionHint'),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t.translate('descriptionRequired');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // اختيار الدولة
              Text(t.translate('country'), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: _countries.map((country) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCountry = country['code'];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedCountry == country['code']
                                ? Colors.blue.shade50
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              right: BorderSide(
                                color: country['code'] != _countries.last['code']
                                    ? Colors.grey.shade300
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(country['flag'], style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Text(
                                t.translate(country['code'] == 'egypt' ? 'egypt' : 'saudi'),
                                style: TextStyle(
                                  fontWeight: _selectedCountry == country['code']
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _selectedCountry == country['code']
                                      ? Colors.blue
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                country['prefix'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // رقم الهاتف
              Text(t.translate('phone'), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: t.translate('phone'),
                  border: const OutlineInputBorder(),
                  hintText: _selectedCountry == 'egypt'
                      ? t.translate('phoneHintEgypt')
                      : t.translate('phoneHintSaudi'),
                  prefixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 12),
                      Text(
                        _countries.firstWhere((c) => c['code'] == _selectedCountry)['prefix'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.phone, size: 20),
                    ],
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t.translate('phoneRequired');
                  }

                  final selectedCountry = _countries.firstWhere((c) => c['code'] == _selectedCountry);
                  final regex = RegExp(selectedCountry['regex']);

                  if (!regex.hasMatch(value)) {
                    if (_selectedCountry == 'egypt') {
                      return t.translate('invalidPhoneEgypt');
                    } else {
                      return t.translate('invalidPhoneSaudi');
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ========== قسم اختيار نوع الحيوان ==========
              if (_category == 'pet') ...[
                const Text('نوع الحيوان:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                          itemCount: _petTypes.length,
                          itemBuilder: (context, index) {
                            final pet = _petTypes[index];
                            final isSelected = _selectedPetType == pet['value'];

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPetType = pet['value'];
                                  if (_selectedPetType != 'other') {
                                    _customPetType = '';
                                    _customPetController.clear();
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.orange.shade100 : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? Colors.orange : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      pet['emoji'],
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      pet['name'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? Colors.orange.shade700 : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // 🔥 حقل إدخال للحيوان المخصص
                        if (_selectedPetType == 'other') ...[
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.edit, color: Colors.blue.shade700, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'اكتب نوع الحيوان:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _customPetController,
                                  decoration: InputDecoration(
                                    hintText: 'مثلاً: ببغاء، خروف، قرد...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  onChanged: (value) {
                                    _customPetType = value.trim();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // رسالة للمستخدم في وضع التعديل
              if (_isEditMode) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.translate('editModeMessage'),
                          style: TextStyle(color: Colors.blue[800]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // اختيار الصور
              if (!_isEditMode) ...[
                Text(t.translate('images'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library),
                  label: Text(t.translate('selectImages')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                if (_selectedImages.isNotEmpty)
                  Container(
                    height: 100,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.all(4),
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(File(_selectedImages[index].path)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              // اختيار فيديو
              if (!_isEditMode) ...[
                Text(t.translate('video'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.video_library),
                  label: Text(t.translate('selectVideo')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                if (_selectedVideo != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.video_file, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedVideo!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _selectedVideo = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
              ],

              // زر النشر/التعديل
              CustomButton(
                text: _isEditMode ? t.translate('save') : t.translate('post'),
                isLoading: _isLoading,
                onPressed: _submitPost,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    print('📸 [AddPostScreen] _pickImages - بدأ اختيار الصور');
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      imageQuality: 70,
    );
    print('📸 [AddPostScreen] تم اختيار ${images.length} صور');
    setState(() {
      _selectedImages.addAll(images);
    });
  }

  Future<void> _pickVideo() async {
    print('🎥 [AddPostScreen] _pickVideo - بدأ اختيار الفيديو');
    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    if (video != null) {
      print('🎥 [AddPostScreen] تم اختيار فيديو: ${video.name}');
    } else {
      print('🎥 [AddPostScreen] لم يتم اختيار فيديو');
    }
    setState(() {
      _selectedVideo = video;
    });
  }

  Future<void> _submitPost() async {
    final t = AppLocalizations.of(context)!;

    print('🔥 [AddPostScreen] _submitPost - بدأ ${_isEditMode ? 'تعديل' : 'نشر'} المنشور');
    print('📋 التحقق من صحة النموذج...');

    // التحقق من اختيار نوع الحيوان
    if (_category == 'pet') {
      if (_selectedPetType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار نوع الحيوان')),
        );
        return;
      }

      // إذا اختار "أخرى"، تأكد من أنه كتب اسم الحيوان
      if (_selectedPetType == 'other' && _customPetType.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء كتابة نوع الحيوان')),
        );
        return;
      }
    }

    if (_formKey.currentState!.validate()) {
      print('✅ [AddPostScreen] التحقق من صحة النموذج ناجح');

      if (!_isEditMode && _selectedImages.isEmpty) {
        print('⚠️ [AddPostScreen] لم يتم اختيار أي صور');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.translate('selectImageRequired'))),
        );
        return;
      }

      setState(() => _isLoading = true);
      print('🔄 [AddPostScreen] جاري التحميل...');

      try {
        print('👤 [AddPostScreen] جلب معلومات المستخدم...');
        final authService = Provider.of<AuthService>(context, listen: false);

        if (authService.user == null) {
          print('❌ [AddPostScreen] المستخدم غير مسجل دخول');
          throw Exception(t.translate('loginRequired'));
        }

        final userId = authService.user!.uid;
        final userDisplayName = authService.userModel?.name ??
            authService.user!.displayName ??
            'مستخدم';
        final userPhotoUrl = authService.userModel?.photoUrl ??
            authService.user!.photoURL ?? '';

        print('✅ [AddPostScreen] المستخدم: $userId');

        // تحديد نوع الحيوان النهائي
        String? finalPetType = _selectedPetType;
        if (_selectedPetType == 'other') {
          finalPetType = _customPetType; // استخدم القيمة المخصصة
        }

        if (_isEditMode) {
          // وضع التعديل
          print('✏️ [AddPostScreen] وضع التعديل - تحديث المنشور ID: $_originalPostId');

          await _firestoreService.updatePost(_originalPostId!, {
            'type': _type,
            'category': _category,
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'phone': _phoneController.text.trim(),
            'country': _selectedCountry,
            'petType': finalPetType,
          });

          print('✅ [AddPostScreen] تم تحديث المنشور بنجاح');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.translate('editSuccess'))),
          );

          Navigator.pop(context, true);
        } else {
          // وضع الإضافة
          print('📸 [AddPostScreen] عدد الصور المختارة: ${_selectedImages.length}');

          print('📤 [AddPostScreen] بدأ رفع الصور...');
          List<String> imageUrls = await _storageService.uploadMultipleImages(
            _selectedImages,
            'posts/$userId',
          );
          print('✅ [AddPostScreen] تم رفع الصور بنجاح: ${imageUrls.length} صورة');

          String? videoUrl;
          if (_selectedVideo != null) {
            print('📤 [AddPostScreen] بدأ رفع الفيديو...');
            videoUrl = await _storageService.uploadFile(
              File(_selectedVideo!.path),
              'posts/$userId/videos/${DateTime.now().millisecondsSinceEpoch}.mp4',
            );
            print('✅ [AddPostScreen] تم رفع الفيديو بنجاح: $videoUrl');
          }

          print('📝 [AddPostScreen] إنشاء كائن المنشور...');
          print('   العنوان: ${_titleController.text}');
          print('   الوصف: ${_descriptionController.text}');
          print('   الهاتف: ${_phoneController.text}');
          print('   النوع: $_type');
          print('   التصنيف: $_category');
          print('   نوع الحيوان: $finalPetType');

          final post = PostModel(
            id: '',
            userId: userId,
            userDisplayName: userDisplayName,
            userPhotoUrl: userPhotoUrl,
            country: _selectedCountry,
            phone: _phoneController.text.trim(),
            type: _type,
            category: _category,
            petType: finalPetType,
            title: _titleController.text,
            description: _descriptionController.text,
            images: imageUrls,
            videoUrl: videoUrl,
            location: const GeoPoint(0, 0),
            locationName: 'غير محدد',
            status: 'active',
            createdAt: DateTime.now(),
          );

          print('💾 [AddPostScreen] حفظ المنشور في Firestore...');
          await _firestoreService.addPost(post);
          print('✅ [AddPostScreen] تم حفظ المنشور بنجاح');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.translate('postSuccess'))),
          );

          print('🔙 [AddPostScreen] العودة للشاشة السابقة');
          Navigator.pop(context, true);
        }
      } catch (e) {
        print('❌ [AddPostScreen] خطأ في ${_isEditMode ? 'تعديل' : 'نشر'} المنشور: $e');
        print('📋 [AddPostScreen] نوع الخطأ: ${e.runtimeType}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.translate('postError'))),
        );
      } finally {
        print('🏁 [AddPostScreen] انتهت عملية ${_isEditMode ? 'التعديل' : 'النشر'}');
        setState(() => _isLoading = false);
      }
    } else {
      print('⚠️ [AddPostScreen] فشل التحقق من صحة النموذج');
    }
  }

  @override
  void dispose() {
    print('🔥 [AddPostScreen] dispose - تنظيف الشاشة');
    _titleController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _customPetController.dispose();
    super.dispose();
  }
}