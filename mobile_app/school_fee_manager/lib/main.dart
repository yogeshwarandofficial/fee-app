import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_fee_manager/core/theme/app_theme.dart';
import 'package:school_fee_manager/router/app_router.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_IN', null);
  runApp(
    const ProviderScope(
      child: SchoolFeeManagerApp(),
    ),
  );
}

/// Root application widget.
///
/// Consumes [routerProvider] so the GoRouter instance is created once
/// and shared with [AuthNotifier] as its refreshListenable.
class SchoolFeeManagerApp extends ConsumerWidget {
  const SchoolFeeManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'MRT & ABR Matriculation School Fee Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
