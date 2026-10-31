import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:women_safety/services/permission_service.dart';
import 'package:women_safety/firebase_options.dart';
import 'package:women_safety/theme/app_theme.dart';
import 'package:women_safety/providers/user_provider.dart';
import 'package:women_safety/providers/contact_provider.dart';
import 'package:women_safety/providers/location_provider.dart';
import 'package:women_safety/providers/emergency_provider.dart';
import 'package:women_safety/screens/auth/login_screen.dart';
import 'package:women_safety/bottomNav.dart';
import 'package:animate_do/animate_do.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
    // You might want to log this error to a crash reporting service
  }

  runApp(const SafeGuardApp());
}

class SafeGuardApp extends StatelessWidget {
  const SafeGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProxyProvider<UserProvider, ContactProvider>(
          create: (_) => ContactProvider(),
          update: (_, userProvider, contactProvider) {
            if (userProvider.currentUser != null) {
              contactProvider!.init(
                userProvider.currentUser!.uid,
                userProvider.currentUser!.role,
              );
            }
            return contactProvider!;
          },
        ),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
      ],
      child: MaterialApp(
        title: 'SafeGuard+',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authUser = FirebaseAuth.instance.currentUser;

    // Check if user is already logged in with Firebase Auth
    if (authUser != null) {
      if (userProvider.currentUser == null) {
        await userProvider.fetchCurrentUser(authUser.uid);
      }
      try {
        await PermissionService.requestAppPermissions();
      } catch (e) {
        debugPrint('Permission error on app resume: $e');
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNav()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlue,
      body: Center(
        child: Column(
          children: [
            const Spacer(flex: 3),
            FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.security,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: const Text(
                'SafeGuard+',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: const Text(
                'Your Safety, Anytime, Anywhere',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(flex: 2),
            FadeIn(
              delay: const Duration(milliseconds: 1000),
              child: const Column(
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryBlue,
                    ),
                  ),
                  SizedBox(height: 48),
                  Text(
                    'SECURE ACCESS PROTOCOL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black26,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
