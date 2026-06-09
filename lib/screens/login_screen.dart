import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';
import '../user_data.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _googleLogin(BuildContext context) async {
  try {
    final result =
        await ApiService.loginWithGoogle();

        UserData.nickname =
            result['user']['nickname'] ?? '';

        UserData.email =
            result['user']['email'] ?? '';

        UserData.accessToken =
            result['access_token'] ?? '';

    debugPrint(result.toString());

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const AppShell(),
      ),
    );
  } catch (e) {
    debugPrint('로그인 실패: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'LINK SWIPE!',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  '유튜브 영상을 더 쉽고 빠르게\n정리하고 다시 찾아보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 60),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _googleLogin(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 82, 82, 82),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Google로 시작하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}