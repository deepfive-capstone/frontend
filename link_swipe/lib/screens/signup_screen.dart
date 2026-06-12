import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _checkPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _checkPasswordController.dispose();
    super.dispose();
  }

  void _signup() {
    if (_passwordController.text !=
        _checkPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호가 일치하지 않습니다.'),
        ),
      );
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            '회원가입',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          iconTheme:
              const IconThemeData(color: Color(0xFF1A1A1A)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 8,
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),

              _label('Email'),
              const SizedBox(height: 6),

              _inputField(
                controller: _emailController,
                hint: '이메일',
              ),

              const SizedBox(height: 12),

              _label('Nickname'),
              const SizedBox(height: 6),

              _inputField(
                controller: _nicknameController,
                hint: '닉네임',
              ),

              const SizedBox(height: 12),

              _label('Password'),
              const SizedBox(height: 6),

              _inputField(
                controller: _passwordController,
                hint: '비밀번호',
                obscureText: true,
              ),

              const SizedBox(height: 12),

              _label('Check Password'),
              const SizedBox(height: 6),

              _inputField(
                controller: _checkPasswordController,
                hint: '비밀번호 확인',
                obscureText: true,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _signup,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor:
                        const Color(0xFF4A4A4A),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '가입',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12),
                    child: Text(
                      '또는',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 16),

              _socialButton(
                Icons.g_mobiledata,
                'Google 계정으로 가입하기',
              ),

              const SizedBox(height: 10),

              _socialButton(
                Icons.apple,
                'Apple 계정으로 가입하기',
              ),

              const SizedBox(height: 20),

              const Text(
                '계속을 클릭하면 당사의 서비스 이용 약관 및 개인정보 처리방침에\n동의하는 것으로 간주됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF999999),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
  }) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _socialButton(
      IconData icon, String text) {
    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
