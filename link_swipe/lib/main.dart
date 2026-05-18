import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'screens/link_screen.dart';
import 'screens/storage_screen.dart';
 
void main() {
  runApp(const SwipeApp());
}
 
class SwipeApp extends StatelessWidget {
  const SwipeApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swipe!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}
 
class AppShell extends StatefulWidget {
  const AppShell({super.key});
 
  @override
  State<AppShell> createState() => _AppShellState();
}
 
class _AppShellState extends State<AppShell> {
  int _tab = 0;
 
  final List<Widget> _pages = const [
    StorageScreen(), // 0: 보관함
    MainScreen(),    // 1: 스와이프 (⇄)
    LinkScreen(),    // 2: 링크 추가 (+)
    Placeholder(),   // 3: 마이페이지
  ];
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
 
  Widget _buildBottomNav() {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(0, Icons.storage_outlined),     // 보관함
          _navItem(1, Icons.swap_horiz_rounded),     // 스와이프
          _navItem(2, Icons.add_box_outlined),       // 링크 추가
          _navItem(3, Icons.person_outline_rounded), // 마이페이지
        ],
      ),
    );
  }
 
  Widget _navItem(int index, IconData icon) {
    final isActive = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: SizedBox(
        width: 60,
        height: 60,
        child: Icon(
          icon,
          size: 26,
          color: isActive ? const Color(0xFF1A1A1A) : const Color(0xFFBBBBBB),
        ),
      ),
    );
  }
}