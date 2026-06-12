import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),

              // 제목
              const Text(
                '마이페이지',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),

              const SizedBox(height: 20),

              _menuItem(
                title: '닉네임',
                value: 'name',
              ),

              _menuItem(
                title: '이메일',
                value: 'email',
              ),

              _menuItem(
                title: '언어',
                value: 'language',
              ),

              GestureDetector(
                onTap: () {
                 Navigator.pushAndRemoveUntil(
                   context,
                   MaterialPageRoute(
                     builder: (_) => const LoginScreen(),
                   ),
                   (route) => false,
                 );
               },
               child: _menuItem(
                 title: '로그아웃',
               ),
              ),

              _menuItem(
                title: '회원탈퇴',
              ),

              _menuItem(
                title: '고유식별번호',
                value: '123456',
                showCopy: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem({
    required String title,
    String? value,
    bool showCopy = false,
  }) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEEEEEE),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),

          Expanded(
            child: Text(
              value ?? '',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF999999),
              ),
            ),
          ),

          if (showCopy)
            const Icon(
              Icons.copy_outlined,
              size: 18,
              color: Color(0xFF999999),
            )
          else
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFBBBBBB),
            ),
        ],
      ),
    );
  }
}
