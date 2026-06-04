import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:invoice_ai/firebase_options.dart';
import 'package:invoice_ai/l10n/app_localizations.dart';
import 'package:invoice_ai/profile.dart';
import 'package:invoice_ai/providers/locale_provider.dart';
import 'package:provider/provider.dart';

import 'login.dart';
import 'dash.dart';
import 'invoices.dart';
import 'nav.dart';
import 'recive.dart';
import 'technical_support.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);


  final localeProvider = LocaleProvider();
  await localeProvider.loadLocale();
  runApp(
    ChangeNotifierProvider.value(value: localeProvider, child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      locale: localeProvider.locale,


      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [Locale('en'), Locale('ar')],



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
          ? const DashPage()
          : const LoginPage(),
    );
  }
}
