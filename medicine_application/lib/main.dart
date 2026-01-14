import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme.dart';
import 'features/medicine/data/medicine_storage.dart';
import 'features/medicine/logic/medicine_provider.dart';
import 'features/medicine/ui/home_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage
  final storage = MedicineStorage();
  await storage.init();

  // Initialize notifications
  await NotificationService().init();

  runApp(
    ProviderScope(
      overrides: [medicineStorageProvider.overrideWithValue(storage)],
      child: const MedicineApp(),
    ),
  );
}

class MedicineApp extends StatelessWidget {
  const MedicineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicine Reminder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
