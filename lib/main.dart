import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/local/settings_store.dart';
import 'services/notification_service.dart';
import 'services/home_widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR');
  final preferences = await SharedPreferences.getInstance();
  final settingsStore = SettingsStore(preferences);
  await initializeWidgetBackgroundRefresh();
  final notificationService = HaruNotificationService(settingsStore);
  await notificationService.initialize();
  final homeWidgetService = HaruHomeWidgetService(settingsStore);
  await homeWidgetService.initialize();
  runApp(
    HaruApp(
      settingsStore: settingsStore,
      notificationService: notificationService,
      homeWidgetService: homeWidgetService,
    ),
  );
}
