import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// IMPORTANT: Uncomment this line after running `flutterfire configure`
import 'firebase_options.dart';

import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/vacations/vacations_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // IMPORTANT: Uncomment the options parameter after running `flutterfire configure`
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint(
      "Firebase initialization error. Did you run flutterfire configure? Error: $e",
    );
  }

  runApp(const MatrohApp());
}

class MatrohApp extends StatefulWidget {
  const MatrohApp({super.key});

  @override
  State<MatrohApp> createState() => _MatrohAppState();
}

class _MatrohAppState extends State<MatrohApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Matroh',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const VacationsListScreen(),
      },
    );
  }
}

/// Automatically directs users to Login or Home based on their auth state.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is signed in.
          // Note: If they haven't set a display name, they really should go to verify screen.
          // But auth changes stream doesn't easily let us check that without reading Firestore.
          // The verify screen handles the initial name setup. We'll just route to home here.
          return const VacationsListScreen();
        }

        // Not signed in
        return const LoginScreen();
      },
    );
  }
}
