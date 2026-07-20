import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme.dart';
import 'services/api_service.dart';
import 'providers/progress_provider.dart';
import 'providers/dashboard_provider.dart';
import 'ui/layout/main_layout.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await initializeDateFormatting('es_ES');

  final apiService = ApiService();
  await apiService.initSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProgressProvider(apiService)),
        ChangeNotifierProvider(create: (_) => DashboardProvider(apiService)),
      ],
      child: const Macroai(),
    ),
  );
}

class Macroai extends StatelessWidget {
  const Macroai({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Macroai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainLayout(),
    );
  }
}