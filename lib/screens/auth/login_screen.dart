// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/language_switch.dart';
import '../../l10n/app_localizations.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('🔥 [LoginScreen] initState - تم تحميل شاشة تسجيل الدخول');
  }

  @override
  Widget build(BuildContext context) {
    print('🔥 [LoginScreen] build - إعادة بناء الشاشة');

    // الحصول على خدمة اللغة والترجمة
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('appTitle')),
        centerTitle: true,
        actions: [
          LanguageSwitch(), // زر تبديل اللغة
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 30),
              // الشعار
              Icon(
                Icons.search,
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(height: 20),
              Text(
                t.translate('appTitle'),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              Text(
                t.translate('login'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _emailController,
                      hint: t.translate('email'),
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return t.translate('emailRequired');
                        }
                        if (!value.contains('@')) {
                          return t.translate('invalidEmail');
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    CustomTextField(
                      controller: _passwordController,
                      hint: t.translate('password'),
                      prefixIcon: Icons.lock,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return t.translate('passwordRequired');
                        }
                        if (value.length < 6) {
                          return t.translate('passwordTooShort');
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(height: 20),
              CustomButton(
                text: t.translate('login'),
                isLoading: _isLoading,
                onPressed: _login,
              ),

              SizedBox(height: 16),

              // زر Google
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
                label: Text(t.translate('loginWithGoogle')),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),

              // زر Apple (يظهر فقط على iOS)
              if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _isLoading ? null : _signInWithApple,
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    side: BorderSide(color: Colors.grey.shade300),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apple, size: 24),
                      SizedBox(width: 8),
                      Text(
                        t.translate('loginWithApple'),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  print('🔥 [LoginScreen] الضغط على رابط التسجيل - الذهاب لصفحة التسجيل');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RegisterScreen()),
                  );
                },
                child: Text(t.translate('dontHaveAccount')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    print('🔥 [LoginScreen] _login - بدأ تسجيل الدخول بالبريد الإلكتروني');
    print('📧 البريد الإلكتروني: ${_emailController.text}');
    print('🔑 كلمة المرور: ${_passwordController.text.replaceAll(RegExp(r'.'), '*')}');

    if (_formKey.currentState!.validate()) {
      print('✅ [LoginScreen] التحقق من صحة النموذج ناجح');

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('🔄 [LoginScreen] جاري الاتصال بـ AuthService...');
      final authService = Provider.of<AuthService>(context, listen: false);

      try {
        String? error = await authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        print('📨 [LoginScreen] نتيجة signIn: ${error ?? "نجاح"}');

        if (mounted) {
          setState(() {
            _isLoading = false;
            if (error != null) {
              _errorMessage = error;
            }
          });
        }
      } catch (e) {
        print('💥 [LoginScreen] استثناء غير متوقع: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'حدث خطأ غير متوقع: $e';
          });
        }
      }
    } else {
      print('⚠️ [LoginScreen] فشل التحقق من صحة النموذج');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    String? error = await authService.signInWithGoogle();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (error != null) {
          _errorMessage = error;
        }
      });
    }
  }

  Future<void> _signInWithApple() async {
    print('🔥 [LoginScreen] _signInWithApple - بدأ تسجيل الدخول بـ Apple');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    print('🔄 [LoginScreen] جاري الاتصال بـ AuthService.signInWithApple...');
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      String? error = await authService.signInWithApple();

      print('📨 [LoginScreen] نتيجة signInWithApple: ${error ?? "نجاح"}');

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (error != null) {
            _errorMessage = error;
          }
        });
      }
    } catch (e) {
      print('💥 [LoginScreen] استثناء غير متوقع في Apple: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'حدث خطأ غير متوقع: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    print('🔥 [LoginScreen] dispose - تنظيف الشاشة');
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}