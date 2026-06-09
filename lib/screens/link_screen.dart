import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/card_store.dart';
 
class LinkScreen extends StatefulWidget {
  final void Function(VoidCallback clearFn)? onRegisterClear;
  const LinkScreen({super.key, this.onRegisterClear});
 
  @override
  State<LinkScreen> createState() => _LinkScreenState();
}
 
class _LinkScreenState extends State<LinkScreen> {
  final TextEditingController _ctrl = TextEditingController();
  bool _isLoading = false;
  String _status = '';
  bool _isSuccess = false;
 
  @override
  void initState() {
    super.initState();
    widget.onRegisterClear?.call(_clearStatus);
  }
 
  void _clearStatus() {
    if (mounted) setState(() { _status = ''; _isSuccess = false; });
  }
 
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
 
  bool _isValidUrl(String url) {
    return url.contains('youtube.com/watch') ||
        url.contains('youtu.be/') ||
        url.contains('youtube.com/shorts/');
  }
 
  Future<void> _submit() async {
    final url = _ctrl.text.trim();
    if (url.isEmpty) return;
    if (!_isValidUrl(url)) {
      setState(() { _status = 'YouTube 링크만 지원해요'; _isSuccess = false; });
      return;
    }
    setState(() { _isLoading = true; _status = 'AI가 분석 중이에요...'; _isSuccess = false; });
    try {
      final card = await ApiService.analyzeVideo(url);
      CardStore.instance.add(card);
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _status = '✓ [${card.category}] 카드가 생성됐어요!';
        _ctrl.clear();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        final msg = e.toString().replaceFirst('Exception: ', '');
        _status = msg.isNotEmpty ? msg : '오류가 발생했어요. 다시 시도해 주세요.';
      });
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Link Swipe!',
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  const Text('링크를 남기고 요약으로 다시 만나요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, color: Color(0xFF888888), height: 1.5)),
                  const SizedBox(height: 20),
                  Container(
                    height: 43,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          spreadRadius: 0,
                          offset: const Offset(3, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
                            decoration: const InputDecoration(
                              hintText: '링크를 추가해 주세요',
                              hintStyle: TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            onSubmitted: (_) => _submit(),
                            onChanged: (_) {
                              if (_status.isNotEmpty) setState(() => _status = '');
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: _isLoading ? null : _submit,
                          child: Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 227, 227, 227),
                              shape: BoxShape.circle,
                            ),
                            child: _isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.add,
                                    color: Color.fromARGB(255, 255, 255, 255), size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_status.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _status,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: _isSuccess
                              ? const Color.fromARGB(255, 45, 60, 45)
                              : const Color.fromARGB(255, 64, 42, 42),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}