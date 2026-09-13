import 'package:flutter_test/flutter_test.dart';
import 'package:haru_app/domain/models/live_update_diagnostic.dart';

void main() {
  test('diagnostic model parses Android and current snapshot values', () {
    final diagnostic = LiveUpdateDiagnostic.fromMap({
      ..._readyMap(),
      'androidVersion': '16',
      'manufacturer': 'samsung',
      'model': 'Galaxy',
      'currentState': 'working',
      'headline': '퇴근까지 02:14',
      'progress': .74,
      'startTimeMillis': DateTime(2026, 9, 13, 9).millisecondsSinceEpoch,
      'endTimeMillis': DateTime(2026, 9, 13, 18).millisecondsSinceEpoch,
    });

    expect(diagnostic.sdkInt, 36);
    expect(diagnostic.sdkIntFull, 3600001);
    expect(diagnostic.currentState, 'working');
    expect(diagnostic.progress, .74);
    expect(diagnostic.endTime, DateTime(2026, 9, 13, 18));
  });

  test('promoted capable result selects promoted path', () {
    final diagnostic = LiveUpdateDiagnostic.fromMap(_readyMap());

    expect(diagnostic.capability, LiveUpdateRuntimeCapability.promoted);
    expect(diagnostic.shouldUseCustomRenderer, isFalse);
    expect(diagnostic.summary, '이 기기는 Promoted Live Update를 지원합니다.');
  });

  test('Android 15 uses the supported standard path', () {
    final diagnostic = LiveUpdateDiagnostic.fromMap({
      ..._readyMap(),
      'sdkInt': 35,
      'sdkIntFull': null,
      'android16OrAbove': false,
      'api361OrAbove': false,
    });

    expect(diagnostic.capability, LiveUpdateRuntimeCapability.standard);
    expect(diagnostic.shouldUseCustomRenderer, isTrue);
    expect(diagnostic.summary, contains('일반 알림 방식'));
  });

  test('API 36.0 is standard while API 36.1 can be promoted', () {
    final api36 = LiveUpdateDiagnostic.fromMap({
      ..._readyMap(),
      'sdkIntFull': 3600000,
      'api361OrAbove': false,
    });
    final api361 = LiveUpdateDiagnostic.fromMap(_readyMap());

    expect(api36.capability, LiveUpdateRuntimeCapability.standard);
    expect(api36.shouldUseCustomRenderer, isTrue);
    expect(api361.capability, LiveUpdateRuntimeCapability.promoted);
    expect(api361.shouldUseCustomRenderer, isFalse);
  });

  test('notification permission denial is unsupported', () {
    final diagnostic = LiveUpdateDiagnostic.fromMap({
      ..._readyMap(),
      'postNotificationsGranted': false,
    });

    expect(diagnostic.capability, LiveUpdateRuntimeCapability.unsupported);
    expect(diagnostic.summary, contains('알림 권한'));
  });

  test('non-promotable notification falls back to standard', () {
    final diagnostic = LiveUpdateDiagnostic.fromMap({
      ..._readyMap(),
      'hasPromotableCharacteristics': false,
    });

    expect(diagnostic.capability, LiveUpdateRuntimeCapability.standard);
    expect(diagnostic.summary, contains('일반 알림 방식'));
  });

  test('canPostPromoted false falls back to standard', () {
    final diagnostic = LiveUpdateDiagnostic.fromMap({
      ..._readyMap(),
      'promotedUserAllowed': false,
      'canPostPromotedNotifications': false,
    });

    expect(diagnostic.capability, LiveUpdateRuntimeCapability.standard);
  });

  test('copy format is ready to paste into a support conversation', () {
    final diagnostic = LiveUpdateDiagnostic.fromMap({
      ..._readyMap(),
      'currentState': 'afterWork',
      'headline': '취침까지 04:12',
    });

    expect(diagnostic.copyText, startsWith('HARU Live Update Diagnostic'));
    expect(diagnostic.copyText, contains('SDK_INT_FULL: 3600001'));
    expect(diagnostic.copyText, contains('Capability: promoted'));
    expect(diagnostic.copyText, contains('Promotable: true'));
    expect(diagnostic.copyText, contains('CanPostPromoted: true'));
    expect(diagnostic.copyText, contains('ProgressStyle: true'));
    expect(diagnostic.copyText, contains('State: afterWork'));
  });
}

Map<Object?, Object?> _readyMap() => {
      'androidVersion': '16',
      'sdkInt': 36,
      'sdkIntFull': 3600001,
      'manufacturer': 'samsung',
      'model': 'test',
      'android16OrAbove': true,
      'api361OrAbove': true,
      'postNotificationsGranted': true,
      'notificationsEnabled': true,
      'promotedPermissionDeclared': true,
      'promotedUserAllowed': true,
      'canPostPromotedNotifications': true,
      'hasPromotableCharacteristics': true,
      'currentlyPromoted': true,
      'ongoing': true,
      'hasContentTitle': true,
      'notificationStyle': 'ProgressStyle',
      'progressStyle': true,
      'customRemoteViews': false,
      'colorized': false,
      'channelId': 'haru_live_update',
      'channelImportance': 2,
      'channelImportanceLabel': 'LOW',
      'visibility': 'PUBLIC',
      'foregroundService': false,
      'currentState': 'working',
      'liveUpdateActive': true,
      'headline': '퇴근까지 02:14',
      'progress': .74,
      'canOpenNotificationSettings': true,
      'canOpenLockScreenSettings': true,
      'canOpenPromotionSettings': true,
    };
