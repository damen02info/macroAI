import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/progress_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../history/history_screen.dart';
import '../progress/progress_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const HistoryScreen(),
    const ProgressScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadInitialData();
      context.read<ProgressProvider>().fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Hoy'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.monitor_weight), label: 'Físico'),
        ],
      ),
    );
  }
}