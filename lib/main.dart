import 'package:flutter/material.dart';

import 'login.dart';
import 'dash.dart';
import 'invoices.dart';
import 'nav.dart';
import 'recive.dart';
import 'services/local_server_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        AppRoutes.profile: (_) => const SectionPlaceholderPage(
          title: 'Profile',
          subtitle: 'Account settings and user preferences are coming here.',
          activeIndex: 3,
        ),
      },
      home: const LoginPage(),
    );
  }
}
