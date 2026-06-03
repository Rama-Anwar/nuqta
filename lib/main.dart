import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:invoice_ai/firebase_options.dart';
import 'package:invoice_ai/profile.dart';

import 'login.dart';
import 'dash.dart';
import 'invoices.dart';
import 'nav.dart';
import 'recive.dart';
import 'services/local_server_service.dart';
import 'technical_support.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await LocalServerService.instance.start();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1D20),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFEE671C),
          surface: Color(0xFF2B3035),
        ),
      ),
      routes: {
        AppRoutes.dash: (_) => const DashPage(),
        AppRoutes.receipts: (_) => const ReceivePage(),
        AppRoutes.invoices: (_) => const InvoicesPage(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.support: (_) => const TechnicalSupportPage(),
      },
      home: FirebaseAuth.instance.currentUser != null
          ? const LoginPage()
          : const LoginPage(),
    );
  }
}
