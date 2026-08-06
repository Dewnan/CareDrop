import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/common/landing_screen.dart';

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
        home: const LandingScreen(),
      ),
    );
  }
}