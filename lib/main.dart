import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'providers/app_state.dart';
import 'services/user_session_service.dart';
import 'theme/app_theme.dart';
import 'screens/common/landing_screen.dart';
import 'screens/patient/patient_dashboard_screen.dart';
import 'screens/helper/helper_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CareDropApp());
}

class CareDropApp extends StatelessWidget {
  const CareDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CareDropAppState(),
      child: MaterialApp(
        title: 'CareDrop',
        debugShowCheckedModeBanner: false,
        theme: CareDropTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: CareDropTheme.royalBlue,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final firebaseUser = snapshot.data;
        if (firebaseUser == null) {
          return const LandingScreen();
        }

        return FutureBuilder<UserModel?>(
          future: UserSessionService.fetchUserProfile(firebaseUser.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting &&
                context.read<CareDropAppState>().currentUserModel == null) {
              return const Scaffold(
                backgroundColor: CareDropTheme.royalBlue,
                body: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            }

            final userModel = userSnapshot.data;
            if (userModel != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final appState = context.read<CareDropAppState>();
                if (appState.currentUserModel?.id != userModel.id) {
                  appState.setUserModel(userModel);
                }
              });

              if (userModel.role.toLowerCase() == 'helper') {
                return const HelperMainMainScreen();
              } else {
                return const PatientDashboardScreen();
              }
            }

            return const LandingScreen();
          },
        );
      },
    );
  }
}