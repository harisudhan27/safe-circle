import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int index;
  const AppBottomNav({super.key, required this.index});

  static const _routes = ['/home', '/family-safety', '/tourist', '/profile'];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) {
        if (i == index) return;
        Navigator.pushNamedAndRemoveUntil(context, _routes[i], (r) => false);
      },
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home'),
        NavigationDestination(
            icon: Icon(Icons.family_restroom_outlined),
            selectedIcon: Icon(Icons.family_restroom),
            label: 'Family'),
        NavigationDestination(
            icon: Icon(Icons.travel_explore_outlined),
            selectedIcon: Icon(Icons.travel_explore),
            label: 'Tourist'),
        NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile'),
      ],
    );
  }
}
