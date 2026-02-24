// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/language_service.dart';
import '../../widgets/language_switch.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExpanded = false;
  bool _showAbout = false;
  bool _showContact = false;

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);

    return
      SafeArea(child:  Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        actions: [
          LanguageSwitch(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ========== Language Section ==========
          _buildSectionHeader(
            icon: Icons.language,
            title: 'Language',
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildLanguageTile(
                  flag: '🇸🇦',
                  language: 'العربية',
                  isSelected: languageService.isArabic,
                  onTap: () => languageService.changeLanguage('ar'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildLanguageTile(
                  flag: '🇬🇧',
                  language: 'English',
                  isSelected: languageService.isEnglish,
                  onTap: () => languageService.changeLanguage('en'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ========== About Section (with GestureDetector) ==========
          GestureDetector(
            onTap: () {
              setState(() {
                _showAbout = !_showAbout;
              });
            },
            child: _buildSectionHeader(
              icon: Icons.info_outline,
              title: 'About',
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),

          // About Content (shown when tapped)
          if (_showAbout) ...[
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
                    const SizedBox(height: 16),

                    // School Name (Arabic)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.school,
                            color: Colors.amber.shade700,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'مدرسة العقيق الأهلية النموذجية',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Students List Title (English)
                    const Text(
                      '👩‍🎓 Participating Students:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Show/Hide Students Button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: Colors.purple.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isExpanded ? 'Hide Names' : 'Show Names',
                              style: TextStyle(
                                color: Colors.purple.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Students Names (Arabic only)
                    if (_isExpanded) ...[
                      const SizedBox(height: 12),
                      _buildStudentCard('ملك كمال'),
                      _buildStudentCard('ريتال العليط'),
                      _buildStudentCard('دعاء القرشي'),
                      _buildStudentCard('حلا تيسير'),
                      _buildStudentCard('رغد ابو شال'),
                    ],

                    const SizedBox(height: 12),

                    // App Description (English)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info,
                                size: 18,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'About the app:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'This app helps you to post and report lost or found items. You can add posts with photos and videos, comment and interact with others\' posts.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ========== Contact Us Section (with GestureDetector) ==========
          GestureDetector(
            onTap: () {
              setState(() {
                _showContact = !_showContact;
              });
            },
            child: _buildSectionHeader(
              icon: Icons.contact_mail,
              title: 'Contact Us',
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),

          // Contact Content (shown when tapped)
          if (_showContact) ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildContactTile(
                      icon: Icons.email,
                      iconColor: Colors.red,
                      title: 'Gmail',
                      subtitle: 'malakkamaal1661@gmail.com',
                      onTap: () => _launchEmail('malakkamaal1661@gmail.com'),
                    ),
                    const Divider(height: 1),
                    _buildContactTile(
                      icon: Icons.phone,
                      iconColor: Colors.green,
                      title: 'Phone',
                      subtitle: '+966 541570716',
                      onTap: () => _launchPhone('+966541570716'),
                    ),
                    const Divider(height: 1),
                    _buildContactTile(
                      icon: Icons.message,
                      iconColor: Colors.teal,
                      title: 'WhatsApp',
                      subtitle: '+966 541570716',
                      onTap: () => _launchWhatsApp('966541570716'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ],
      ),
      )
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const Spacer(),
          Icon(
            title == 'About'
                ? (_showAbout ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down)
                : (_showContact ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
            color: Colors.grey.shade400,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile({
    required String flag,
    required String language,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Text(
        flag,
        style: const TextStyle(fontSize: 24),
      ),
      title: Text(language),
      trailing: isSelected
          ? const Icon(
        Icons.check_circle,
        color: Colors.green,
      )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildStudentCard(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person,
            color: Colors.purple,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.purple,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }

  // ========== Working Contact Functions ==========

  Future<void> _launchWhatsApp(String phone) async {
    final Uri uri = Uri.parse('https://wa.me/$phone');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri.parse('mailto:$email?subject=Inquiry&body=Hello');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchPhone(String phone) async {
    final Uri uri = Uri.parse('tel:$phone');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}