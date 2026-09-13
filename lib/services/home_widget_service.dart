import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../data/local/settings_store.dart';
import '../domain/services/schedule_entry_service.dart';
import '../domain/services/widget_snapshot_calculator.dart';

const _widgetRefreshUniqueName = 'haru.widget.nextEvent';
const _widgetRefreshTaskName = 'haru.widget.refresh';

bool get _supportsAndroidWidgets =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

@pragma('vm:entry-point')
void widgetWorkmanagerDispatcher() {
  if (!_supportsAndroidWidgets) return;
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _widgetRefreshTaskName) return true;
    WidgetsFlutterBinding.ensureInitialized();
    final preferences = await SharedPreferences.getInstance();
    await refreshHomeWidgetSnapshot(SettingsStore(preferences));
    return true;
  });
}

@pragma('vm:entry-point')
Future<void> homeWidgetBackgroundCallback(Uri? uri) async {
  if (!_supportsAndroidWidgets) return;
  if (uri?.scheme != 'haru' || uri?.host != 'refresh') return;
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  await refreshHomeWidgetSnapshot(SettingsStore(preferences));
}

Future<void> initializeWidgetBackgroundRefresh() async {
  if (!_supportsAndroidWidgets) return;
  await Workmanager().initialize(widgetWorkmanagerDispatcher);
  await HomeWidget.registerInteractivityCallback(homeWidgetBackgroundCallback);
}

enum WidgetQuickAction { spend, schedule }

class HaruHomeWidgetService extends ChangeNotifier {
  HaruHomeWidgetService(this._store);

  final SettingsStore _store;
  StreamSubscription<Uri?>? _clickSubscription;
  WidgetQuickAction? _pendingAction;

  WidgetQuickAction? consumeAction() {
    final action = _pendingAction;
    _pendingAction = null;
    return action;
  }

  Future<void> initialize() async {
    if (!_supportsAndroidWidgets) return;
    _acceptUri(await HomeWidget.initiallyLaunchedFromHomeWidget());
    _clickSubscription = HomeWidget.widgetClicked.listen(_acceptUri);
    await refresh();
  }

  Future<void> refresh({DateTime? now}) {
    return refreshHomeWidgetSnapshot(_store, now: now);
  }

  void _acceptUri(Uri? uri) {
    if (uri?.scheme != 'haru' || uri?.host != 'widget') return;
    final action = uri!.pathSegments.firstOrNull;
    _pendingAction = switch (action) {
      'spend' => WidgetQuickAction.spend,
      'schedule' => WidgetQuickAction.schedule,
      _ => null,
    };
    if (_pendingAction != null) notifyListeners();
  }

  @override
  void dispose() {
    _clickSubscription?.cancel();
    super.dispose();
  }
}

Future<void> refreshHomeWidgetSnapshot(
  SettingsStore store, {
  DateTime? now,
}) async {
  if (!_supportsAndroidWidgets) return;
  final settings = store.loadSettings();
  if (settings == null) return;

  final current = now ?? DateTime.now();
  final scheduleEntry = ScheduleEntryService(store).activeFor(
    current,
    settings.schedule,
  );
  final calculation = const WidgetSnapshotCalculator().calculate(
    now: current,
    settings: settings,
    spends: store.loadDailySpends(),
    scheduleEntry: scheduleEntry,
  );

  await HomeWidget.saveWidgetData<String>(
    'widget_snapshot',
    calculation.snapshot.encode(),
  );
  await HomeWidget.updateWidget(
    qualifiedAndroidName: 'com.haruapp.haru_app.HaruWidgetProvider',
  );
  await _scheduleNextRefresh(current, calculation);
}

Future<void> _scheduleNextRefresh(
  DateTime now,
  WidgetSnapshotCalculation calculation,
) async {
  final delay = calculation.nextRefresh.at.difference(now);
  await Workmanager().registerOneOffTask(
    _widgetRefreshUniqueName,
    _widgetRefreshTaskName,
    initialDelay: delay + const Duration(seconds: 2),
    inputData: {'reason': calculation.nextRefresh.reason.name},
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
}
