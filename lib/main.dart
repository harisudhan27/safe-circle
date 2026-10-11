import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/family_safety_screen.dart';
import 'screens/create_family_screen.dart';
import 'screens/join_family_screen.dart';
import 'screens/add_members_screen.dart';
import 'screens/member_tracking_screen.dart';
import 'screens/tourist_screen.dart';
import 'screens/crowd_level_screen.dart';
import 'screens/safety_zone_screen.dart';
import 'screens/missing_child_screen.dart';
import 'screens/child_details_screen.dart';
import 'screens/last_seen_screen.dart';
import 'screens/missing_child_report_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SafeCircleApp());
}

class SafeCircleApp extends StatelessWidget {
  const SafeCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeCircle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/home': (_) => const HomeScreen(),
        '/family-safety': (_) => const FamilySafetyScreen(),
        '/create-family': (_) => const CreateFamilyScreen(),
        '/join-family': (_) => const JoinFamilyScreen(),
        '/add-members': (_) => const AddMembersScreen(),
        '/member-tracking': (_) => const MemberTrackingScreen(),
        '/tourist': (_) => const TouristScreen(),
        '/crowd-level': (_) => const CrowdLevelScreen(),
        '/safety-zone': (_) => const SafetyZoneScreen(),
        '/missing-child': (_) => const MissingChildScreen(),
        '/child-details': (_) => const ChildDetailsScreen(),
        '/last-seen': (_) => const LastSeenScreen(),
        '/missing-report': (_) => const MissingChildReportScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/edit-profile': (_) => const EditProfileScreen(),
        '/notifications': (_) => const NotificationsScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
