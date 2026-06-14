import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'screens/main_screen.dart';
import 'screens/link_screen.dart';
import 'screens/storage_screen.dart';
import 'screens/mypage_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const SwipeApp());
}

class SwipeApp extends StatelessWidget {
  const SwipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinkSwipe!',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: Colors.white,
       colorScheme: const ColorScheme.light(
          surface: Colors.white,
        ),
        useMaterial3: true,

        pageTransitionsTheme:
            const PageTransitionsTheme(
         builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android:
                const ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS:
                const ZoomPageTransitionsBuilder(),
            TargetPlatform.windows:
                const ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 2;
  int _storageRefreshKey = 0;
  int _mainRefreshKey = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (
          Widget child,
          Animation<double> animation,
        ) {
    return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: IndexedStack(
    key: ValueKey(_tab),
    index: _tab,
    children: [
      StorageScreen(key: ValueKey(_storageRefreshKey)),
      MainScreen(key: ValueKey(_mainRefreshKey)),
      const LinkScreen(),
      const MyPageScreen(),
    ],
  ),
      ),
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
          _navItem(0, Icons.folder_outlined),
          _navItem(1, Icons.swap_horiz_rounded),
          _navItem(2, Icons.add_box_outlined),
          _navItem(3, Icons.person_outline_rounded),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon) {
    final isActive = _tab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (index == 0) _storageRefreshKey++;
          if (index == 1 && _tab == 2) _mainRefreshKey++;
          _tab = index;
        });
      },
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