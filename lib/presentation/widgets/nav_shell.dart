import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'custom_bottom_nav.dart';

class NavShell extends StatelessWidget {
  final Widget child;
  final GoRouterState state;
  const NavShell({super.key, required this.child, required this.state});

  @override
  Widget build(BuildContext context) {
    final location = state.matchedLocation;
    int currentIndex = 0;
    
    if (location.startsWith('/dashboard')) {
      currentIndex = 0;
    } else if (location.startsWith('/history')) {
      currentIndex = 1;
    } else if (location.startsWith('/clients-tab') || location.startsWith('/clients')) {
      currentIndex = 2;
    } else if (location.startsWith('/expenses') || location.startsWith('/statistics')) {
      currentIndex = 3;
    } else if (location.startsWith('/profile')) {
      currentIndex = 4;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Stack(
        children: [
          child,
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomBottomNav(currentIndex: currentIndex),
          ),
        ],
      ),
    );
  }
}
