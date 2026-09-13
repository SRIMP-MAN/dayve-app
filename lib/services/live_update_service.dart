import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/local/settings_store.dart';
import '../domain/models/app_settings.dart';
import '../domain/models/live_update_snapshot.dart';
import '../domain/models/live_update_diagnostic.dart';
import '../domain/services/budget_engine.dart';
import '../domain/services/live_update_planner.dart';
import '../domain/services/schedule_entry_service.dart';

enum LiveUpdateDelivery {
  promoted,
  standard,
  hidden,
  unsupported,
}

enum LiveUpdateActionType { checkout, overtime30, overtime60, overtimeCustom }

class LiveUpdateAction {
  const LiveUpdateAction({required this.type, required this.scheduleDate});

  final LiveUpdateActionType type;
  final DateTime scheduleDate;
}

class LiveUpdatePlatformResult {
  const LiveUpdatePlatformResult({
    required this.delivery,
    required this.androidApi,
    required this.canPromote,
  });

  final LiveUpdateDelivery delivery;
  final int androidApi;
  final bool canPromote;
}

abstract class LiveUpdatePlatform {
  Future<LiveUpdatePlatformResult> sync(LiveUpdatePlan plan);

  Future<LiveUpdatePlatformResult> disable() async =>
      const LiveUpdatePlatformResult(
        delivery: LiveUpdateDelivery.hidden,
        androidApi: 0,
        canPromote: false,
      );

  Future<bool> openPromotionSettings() async => false;

  Future<LiveUpdateAction?> consumeAction() async => null;

  Future<LiveUpdateDiagnostic> diagnose() async =>
      LiveUpdateDiagnostic.unsupported();

  Future<bool> openNotificationSettings() async => false;

  Future<bool> openLockScreenSettings() async => false;
}

class MethodChannelLiveUpdatePlatform implements LiveUpdatePlatform {
  static const _channel = MethodChannel('haru/live_update');

  @override
  Future<LiveUpdatePlatformResult> sync(LiveUpdatePlan plan) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const LiveUpdatePlatformResult(
        delivery: LiveUpdateDelivery.unsupported,
        androidApi: 0,
        canPromote: false,
      );
    }
    try {
      final response = await _channel.invokeMapMethod<Object?, Object?>(
        'sync',
        plan.toMap(),
      );
      return _resultFromMap(response ?? const {});
    } on MissingPluginException {
      return const LiveUpdatePlatformResult(
        delivery: LiveUpdateDelivery.unsupported,
        androidApi: 0,
        canPromote: false,
      );
    } on PlatformException {
      return const LiveUpdatePlatformResult(
        delivery: LiveUpdateDelivery.unsupported,
        androidApi: 0,
        canPromote: false,
      );
    }
  }

  @override
  Future<LiveUpdatePlatformResult> disable() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const LiveUpdatePlatformResult(
        delivery: LiveUpdateDelivery.unsupported,
        androidApi: 0,
        canPromote: false,
      );
    }
    try {
      final response = await _channel.invokeMapMethod<Object?, Object?>(
        'disable',
      );
      return _resultFromMap(response ?? const {});
    } on MissingPluginException {
      return const LiveUpdatePlatformResult(
        delivery: LiveUpdateDelivery.unsupported,
        androidApi: 0,
        canPromote: false,
      );
    } on PlatformException {
      return const LiveUpdatePlatformResult(
        delivery: LiveUpdateDelivery.unsupported,
        androidApi: 0,
        canPromote: false,
      );
    }
  }

  LiveUpdatePlatformResult _resultFromMap(Map<Object?, Object?> map) {
    final mode = map['mode'] as String? ?? 'unsupported';
    return LiveUpdatePlatformResult(
      delivery: LiveUpdateDelivery.values.firstWhere(
        (value) => value.name == mode,
        orElse: () => LiveUpdateDelivery.unsupported,
      ),
      androidApi: (map['androidApi'] as num? ?? 0).toInt(),
      canPromote: map['canPromote'] as bool? ?? false,
    );
  }

  @override
  Future<bool> openPromotionSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _channel.invokeMethod<bool>('openPromotionSettings') ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<LiveUpdateAction?> consumeAction() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final response = await _channel.invokeMapMethod<Object?, Object?>(
        'consumeAction',
      );
      if (response == null) return null;
      final name = response['action'] as String?;
      final date = DateTime.tryParse(response['scheduleDate'] as String? ?? '');
      if (name == null || date == null) return null;
      final type = LiveUpdateActionType.values.where(
        (value) => value.name == name,
      );
      if (type.isEmpty) return null;
      return LiveUpdateAction(type: type.first, scheduleDate: date);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<LiveUpdateDiagnostic> diagnose() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return LiveUpdateDiagnostic.unsupported();
    }
    try {
      final response = await _channel.invokeMapMethod<Object?, Object?>(
        'diagnostics',
      );
      return LiveUpdateDiagnostic.fromMap(response ?? const {});
    } on PlatformException {
      return LiveUpdateDiagnostic.unsupported();
    } on MissingPluginException {
      return LiveUpdateDiagnostic.unsupported();
    }
  }

  @override
  Future<bool> openNotificationSettings() =>
      _openSettings('openNotificationSettings');

  @override
  Future<bool> openLockScreenSettings() =>
      _openSettings('openLockScreenSettings');

  Future<bool> _openSettings(String method) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

class HaruLiveUpdateService {
  HaruLiveUpdateService(
    this._store, {
    LiveUpdatePlatform? platform,
    LiveUpdatePlanner planner = const LiveUpdatePlanner(),
  })  : _platform = platform ?? MethodChannelLiveUpdatePlatform(),
        _planner = planner;

  final SettingsStore _store;
  final LiveUpdatePlatform _platform;
  final LiveUpdatePlanner _planner;

  Future<LiveUpdatePlatformResult> sync(
    AppSettings settings, {
    DateTime? now,
  }) {
    if (!settings.lockScreenLiveEnabled) return _platform.disable();
    final current = now ?? DateTime.now();
    final schedules = ScheduleEntryService(_store);
    final spends = _store.loadDailySpends();
    final currency = NumberFormat.decimalPattern('ko_KR');
    final plan = _planner.plan(
      now: current,
      profile: settings.schedule,
      activeScheduleFor: (at) => schedules.activeFor(at, settings.schedule),
      moneyFor: settings.lockScreenMoneyVisible
          ? (at) {
              final budget = const BudgetEngine().calculate(
                now: at,
                profile: settings.budget,
                spends: spends,
              );
              return LiveUpdateMoneyLabels(
                today: '${currency.format(budget.recommendedDailyAmount)}원',
                remaining: '${currency.format(budget.remainingBudget)}원',
                spent: '${currency.format(budget.spentAmount)}원',
              );
            }
          : null,
    );
    return _platform.sync(plan);
  }

  Future<bool> openPromotionSettings() => _platform.openPromotionSettings();

  Future<LiveUpdateAction?> consumeAction() => _platform.consumeAction();

  Future<LiveUpdateDiagnostic> diagnose() => _platform.diagnose();

  Future<bool> openNotificationSettings() =>
      _platform.openNotificationSettings();

  Future<bool> openLockScreenSettings() => _platform.openLockScreenSettings();
}
