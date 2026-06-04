import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/finance_viewmodel.dart';
import 'views/auth/auth_view.dart';
import 'views/dashboard/dashboard_view.dart';
import 'views/analysis/analysis_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => FinanceViewModel()),
      ],
      child: MaterialApp(
        title: 'Controle Financeiro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        initialRoute: '/auth',
        routes: {
          '/auth': (_) => const AuthView(),
          '/dashboard': (_) => const DashboardView(),
          '/analysis': (_) => const AnalysisView(),
        },
      ),
    );
  }
}
