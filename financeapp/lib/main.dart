import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'app_theme.dart';
import 'views/auth/auth_view.dart';
import 'views/dashboard/dashboard_view.dart';
import 'views/analysis/analysis_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('pt_BR', null);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Financeiro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/auth',
      routes: {
        '/auth': (_) => const AuthView(),
        '/dashboard': (_) => const DashboardView(),
        '/analysis': (_) => const AnalysisView(),
      },
    );
  }
}
