import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../settings/settings_screen.dart';
import 'widgets/hybrid_fab.dart';
import 'widgets/macro_bars.dart';
import 'widgets/progress_ring.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen Hoy'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: const HybridFab(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const ProgressRing(),
            const SizedBox(height: 32),
            MacroBars(
              proteinGrams: provider.proteinGrams,
              proteinTarget: provider.proteinTarget,
              carbGrams: provider.carbGrams,
              carbTarget: provider.carbTarget,
              fatGrams: provider.fatGrams,
              fatTarget: provider.fatTarget,
            ),
          ],
        ),
      ),
    );
  }
}