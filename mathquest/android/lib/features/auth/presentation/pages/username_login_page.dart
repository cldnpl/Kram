import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/dio_client.dart';

/// Stessa schermata di UsernameLoginView (iOS): login/register con username e password.
/// Titolo "Login" o "Register"; link alterna. Salva username in SharedPreferences.
class UsernameLoginPage extends StatefulWidget {
  const UsernameLoginPage({super.key});

  @override
  State<UsernameLoginPage> createState() => _UsernameLoginPageState();
}

class _UsernameLoginPageState extends State<UsernameLoginPage> {
  bool _isLoginMode = true;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isRegistering = false;
  final _dio = DioClient();

  static const _keyUsername = 'profile_username';
  static const _keyName = 'profile_name';
  static const _usernameAlreadyExistsMessage = 'Nome utente già esistente';

  // Stessi colori iOS: appPurple (0.4, 0.3, 0.9), background white 0.95
  static const _appPurple = Color(0xFF664DE6);
  static const _bgGray = Color(0xFFF2F2F2);

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final u = _usernameController.text.trim();
    if (u.isEmpty) return;
    setState(() {
      _errorMessage = null;
    });
    if (_isLoginMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUsername, u);
      if (!mounted) return;
      context.go('/');
      return;
    }
    // Register: verifica che lo username non esista già
    setState(() => _isRegistering = true);
    Response<dynamic> response;
    try {
      response = await _dio.dio.post(
        'auth/register-username',
        data: {'username': u},
        options: Options(validateStatus: (s) => s != null && s! < 500),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      setState(() {
        _isRegistering = false;
        _errorMessage = status == 409 ? _usernameAlreadyExistsMessage : 'Errore di rete. Riprova.';
      });
      return;
    }
    setState(() => _isRegistering = false);
    if (!mounted) return;
    if (response.statusCode == 409) {
      setState(() => _errorMessage = _usernameAlreadyExistsMessage);
      return;
    }
    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUsername, u);
      if (!mounted) return;
      context.go('/');
    } else {
      setState(() => _errorMessage = 'Errore di rete. Riprova.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _bgGray,
      body: Stack(
        children: [
          // Forme decorative come iOS: Circle 320 opacity 0.12, Ellipse 280 opacity 0.1
          Positioned(
            left: -120,
            top: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _appPurple.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            left: screenWidth - 100,
            top: screenHeight * 0.5 - 100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _appPurple.withOpacity(0.1),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pulsante chiudi come iOS: xmark, nero 0.6, padding 10, bianco 0.9, circle, shadow 6
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20, top: 16),
                    child: Material(
                      color: Colors.white.withOpacity(0.9),
                      shape: const CircleBorder(),
                      elevation: 0,
                      shadowColor: Colors.black.withOpacity(0.06),
                      child: InkWell(
                        onTap: () => context.go('/'),
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Titolo "Login" / "Register" come iOS: size 34 bold, nero, leading, padding 24 24 20
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _isLoginMode ? 'Login' : 'Register',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                // Card bianca, radius 24, bordo viola 1, shadow 12 y 4, padding horizontal 20
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _appPurple, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Username: label 18 medium nero, spacing 8, field rounded 10, padding vertical 4
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Username',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _usernameController,
                                style: const TextStyle(fontSize: 17),
                                textCapitalization: TextCapitalization.none,
                                inputFormatters: [
                                  TextInputFormatter.withFunction(
                                    (oldValue, newValue) => TextEditingValue(
                                      text: newValue.text.toLowerCase(),
                                      selection: newValue.selection,
                                      composing: newValue.composing,
                                    ),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  hintText: 'Insert username',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Password: label 18 medium, spacing 2 (iOS), field, padding top 24 bottom 20
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Password',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                style: const TextStyle(fontSize: 17),
                                decoration: InputDecoration(
                                  hintText: 'Insert password',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Link: "Don't you have an account? Create one" / "Already have an account? Login", 14 gray, padding top 8
                        TextButton(
                          onPressed: () => setState(() {
                            _isLoginMode = !_isLoginMode;
                            _errorMessage = null;
                          }),
                          child: Text(
                            _isLoginMode
                                ? "Don't you have an account? Create one"
                                : 'Already have an account? Login',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        // Pulsante Login/Register: 17 semibold bianco, 300x50, gradient, radius 14, padding top 20 bottom 24
                        Center(
                          child: SizedBox(
                            width: 300,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [
                                    _appPurple,
                                    Color(0xFF9966F2),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isRegistering ? null : _submit,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Center(
                                    child: _isRegistering
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            _isLoginMode ? 'Login' : 'Register',
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
