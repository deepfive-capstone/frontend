import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';
import '../user_data.dart';
import '../services/api_service.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() =>
      _MyPageScreenState();
}

class _MyPageScreenState
    extends State<MyPageScreen> {
  Future<void> _changeNickname(
  BuildContext context,
) async {
  final controller =
      TextEditingController();

  final nickname =
      await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('닉네임 변경'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: '새 닉네임 입력',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            controller.text,
          ),
          child: const Text('확인'),
        ),
      ],
    ),
  );

  if (nickname == null ||
      nickname.trim().isEmpty) {
    return;
  }

  try {
    final result =
        await ApiService.updateNickname(
      nickname,
    );
    setState(() {
      UserData.nickname =
          result['nickname'] ?? nickname;
    });
  } catch (e) {
    debugPrint('$e');
  }
}

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

              GestureDetector(
                onTap: () => _changeNickname(context),
                  child: _menuItem(
                    title: '닉네임',
                    value: UserData.nickname,
                  ),
                ),

              _menuItem(
                title: '이메일',
                value: UserData.email,
              ),

              GestureDetector(
                onTap: () async {
                  try {
                    await ApiService.logout();

                    UserData.accessToken = '';
                    UserData.nickname = '';
                    UserData.email = '';

                    Navigator.pushAndRemoveUntil(
                     context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  } catch (e) {
                    debugPrint('$e');
                  }
                },
               child: _menuItem(
                 title: '로그아웃',
               ),
              ),

              GestureDetector(
                onTap: () async {
                  final confirm =
                      await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('회원탈퇴'),
                      content: const Text(
                        '정말 탈퇴하시겠습니까?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(
                                  context, false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(
                                  context, true),
                          child: const Text('탈퇴'),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  try {
                    await ApiService.deleteAccount();

                    UserData.accessToken = '';
                    UserData.nickname = '';
                   UserData.email = '';

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  } catch (e) {
                    debugPrint('$e');
                  }
                },
                child: _menuItem(
                  title: '회원탈퇴',
                ),
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
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFBBBBBB),
            ),
        ],
      ),
    );
  }
}