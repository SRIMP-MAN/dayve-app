enum LiveUpdateRuntimeCapability { promoted, standard, unsupported }

class LiveUpdateDiagnostic {
  const LiveUpdateDiagnostic({
    required this.androidVersion,
    required this.sdkInt,
    required this.sdkIntFull,
    required this.manufacturer,
    required this.model,
    required this.oneUiVersion,
    required this.android16OrAbove,
    required this.api361OrAbove,
    required this.postNotificationsGranted,
    required this.notificationsEnabled,
    required this.promotedPermissionDeclared,
    required this.promotedUserAllowed,
    required this.canPostPromotedNotifications,
    required this.hasPromotableCharacteristics,
    required this.currentlyPromoted,
    required this.ongoing,
    required this.hasContentTitle,
    required this.notificationStyle,
    required this.progressStyle,
    required this.customRemoteViews,
    required this.colorized,
    required this.channelId,
    required this.channelImportance,
    required this.channelImportanceLabel,
    required this.visibility,
    required this.foregroundService,
    required this.currentState,
    required this.liveUpdateActive,
    required this.headline,
    required this.progress,
    required this.startTime,
    required this.endTime,
    required this.lastUpdated,
    required this.nextScheduledRefresh,
    required this.canOpenNotificationSettings,
    required this.canOpenLockScreenSettings,
    required this.canOpenPromotionSettings,
  });

  final String androidVersion;
  final int sdkInt;
  final int? sdkIntFull;
  final String manufacturer;
  final String model;
  final String? oneUiVersion;
  final bool android16OrAbove;
  final bool api361OrAbove;
  final bool postNotificationsGranted;
  final bool notificationsEnabled;
  final bool promotedPermissionDeclared;
  final bool promotedUserAllowed;
  final bool canPostPromotedNotifications;
  final bool hasPromotableCharacteristics;
  final bool currentlyPromoted;
  final bool ongoing;
  final bool hasContentTitle;
  final String notificationStyle;
  final bool progressStyle;
  final bool customRemoteViews;
  final bool colorized;
  final String channelId;
  final int? channelImportance;
  final String channelImportanceLabel;
  final String visibility;
  final bool foregroundService;
  final String currentState;
  final bool liveUpdateActive;
  final String headline;
  final double progress;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? lastUpdated;
  final DateTime? nextScheduledRefresh;
  final bool canOpenNotificationSettings;
  final bool canOpenLockScreenSettings;
  final bool canOpenPromotionSettings;

  LiveUpdateRuntimeCapability get capability {
    if (!postNotificationsGranted || !notificationsEnabled) {
      return LiveUpdateRuntimeCapability.unsupported;
    }
    if (android16OrAbove &&
        api361OrAbove &&
        promotedPermissionDeclared &&
        canPostPromotedNotifications &&
        promotedUserAllowed &&
        hasPromotableCharacteristics) {
      return LiveUpdateRuntimeCapability.promoted;
    }
    return LiveUpdateRuntimeCapability.standard;
  }

  bool get shouldUseCustomRenderer =>
      capability == LiveUpdateRuntimeCapability.standard;

  factory LiveUpdateDiagnostic.fromMap(Map<Object?, Object?> map) {
    return LiveUpdateDiagnostic(
      androidVersion: _string(map, 'androidVersion', fallback: '알 수 없음'),
      sdkInt: _integer(map, 'sdkInt') ?? 0,
      sdkIntFull: _integer(map, 'sdkIntFull'),
      manufacturer: _string(map, 'manufacturer', fallback: '알 수 없음'),
      model: _string(map, 'model', fallback: '알 수 없음'),
      oneUiVersion: _nullableString(map, 'oneUiVersion'),
      android16OrAbove: _boolean(map, 'android16OrAbove'),
      api361OrAbove: _boolean(map, 'api361OrAbove'),
      postNotificationsGranted: _boolean(map, 'postNotificationsGranted'),
      notificationsEnabled: _boolean(map, 'notificationsEnabled'),
      promotedPermissionDeclared: _boolean(map, 'promotedPermissionDeclared'),
      promotedUserAllowed: _boolean(map, 'promotedUserAllowed'),
      canPostPromotedNotifications:
          _boolean(map, 'canPostPromotedNotifications'),
      hasPromotableCharacteristics:
          _boolean(map, 'hasPromotableCharacteristics'),
      currentlyPromoted: _boolean(map, 'currentlyPromoted'),
      ongoing: _boolean(map, 'ongoing'),
      hasContentTitle: _boolean(map, 'hasContentTitle'),
      notificationStyle: _string(map, 'notificationStyle', fallback: 'None'),
      progressStyle: _boolean(map, 'progressStyle'),
      customRemoteViews: _boolean(map, 'customRemoteViews'),
      colorized: _boolean(map, 'colorized'),
      channelId: _string(map, 'channelId', fallback: 'haru_live_update'),
      channelImportance: _integer(map, 'channelImportance'),
      channelImportanceLabel:
          _string(map, 'channelImportanceLabel', fallback: 'NOT_CREATED'),
      visibility: _string(map, 'visibility', fallback: 'UNKNOWN'),
      foregroundService: _boolean(map, 'foregroundService'),
      currentState: _string(map, 'currentState', fallback: 'unknown'),
      liveUpdateActive: _boolean(map, 'liveUpdateActive'),
      headline: _string(map, 'headline'),
      progress: (_number(map, 'progress') ?? 0).clamp(0.0, 1.0).toDouble(),
      startTime: _dateFromMillis(map['startTimeMillis']),
      endTime: _dateFromMillis(map['endTimeMillis']),
      lastUpdated: _dateFromMillis(map['lastUpdatedMillis']),
      nextScheduledRefresh: _dateFromMillis(map['nextScheduledRefreshMillis']),
      canOpenNotificationSettings: _boolean(map, 'canOpenNotificationSettings'),
      canOpenLockScreenSettings: _boolean(map, 'canOpenLockScreenSettings'),
      canOpenPromotionSettings: _boolean(map, 'canOpenPromotionSettings'),
    );
  }

  factory LiveUpdateDiagnostic.unsupported() {
    return const LiveUpdateDiagnostic(
      androidVersion: 'Android 아님',
      sdkInt: 0,
      sdkIntFull: null,
      manufacturer: '지원되지 않는 플랫폼',
      model: '-',
      oneUiVersion: null,
      android16OrAbove: false,
      api361OrAbove: false,
      postNotificationsGranted: false,
      notificationsEnabled: false,
      promotedPermissionDeclared: false,
      promotedUserAllowed: false,
      canPostPromotedNotifications: false,
      hasPromotableCharacteristics: false,
      currentlyPromoted: false,
      ongoing: false,
      hasContentTitle: false,
      notificationStyle: 'None',
      progressStyle: false,
      customRemoteViews: false,
      colorized: false,
      channelId: 'haru_live_update',
      channelImportance: null,
      channelImportanceLabel: 'NOT_CREATED',
      visibility: 'UNKNOWN',
      foregroundService: false,
      currentState: 'unsupported',
      liveUpdateActive: false,
      headline: '',
      progress: 0,
      startTime: null,
      endTime: null,
      lastUpdated: null,
      nextScheduledRefresh: null,
      canOpenNotificationSettings: false,
      canOpenLockScreenSettings: false,
      canOpenPromotionSettings: false,
    );
  }

  String get summary {
    switch (capability) {
      case LiveUpdateRuntimeCapability.promoted:
        return '이 기기는 Promoted Live Update를 지원합니다.';
      case LiveUpdateRuntimeCapability.standard:
        return '이 기기는 DAYVE 잠금화면 실시간 정보를 지원합니다.\n'
            '일반 알림 방식으로 표시됩니다.';
      case LiveUpdateRuntimeCapability.unsupported:
        return '잠금화면 실시간 정보를 사용하려면 알림 권한이 필요합니다.';
    }
  }

  String get copyText {
    String value(bool input) => input ? 'true' : 'false';
    String date(DateTime? input) => input?.toIso8601String() ?? 'n/a';
    return [
      'DAYVE Live Update Diagnostic',
      'Android: $androidVersion',
      'SDK_INT: $sdkInt',
      'SDK_INT_FULL: ${sdkIntFull ?? 'unavailable'}',
      'Capability: ${capability.name}',
      'Manufacturer: $manufacturer',
      'Model: $model',
      if (oneUiVersion != null) 'One UI: $oneUiVersion',
      'Android16OrAbove: ${value(android16OrAbove)}',
      'API36_1OrAbove: ${value(api361OrAbove)}',
      'PostNotificationsGranted: ${value(postNotificationsGranted)}',
      'NotificationsEnabled: ${value(notificationsEnabled)}',
      'PromotedPermissionDeclared: ${value(promotedPermissionDeclared)}',
      'PromotedUserAllowed: ${value(promotedUserAllowed)}',
      'Promotable: ${value(hasPromotableCharacteristics)}',
      'CanPostPromoted: ${value(canPostPromotedNotifications)}',
      'CurrentlyPromoted: ${value(currentlyPromoted)}',
      'Channel: $channelId',
      'Importance: $channelImportanceLabel (${channelImportance ?? 'n/a'})',
      'Style: $notificationStyle',
      'ProgressStyle: ${value(progressStyle)}',
      'Ongoing: ${value(ongoing)}',
      'ContentTitle: ${value(hasContentTitle)}',
      'CustomRemoteViews: ${value(customRemoteViews)}',
      'Colorized: ${value(colorized)}',
      'Visibility: $visibility',
      'ForegroundService: ${value(foregroundService)}',
      'State: $currentState',
      'LiveUpdateActive: ${value(liveUpdateActive)}',
      'Headline: $headline',
      'Progress: ${progress.toStringAsFixed(3)}',
      'StartTime: ${date(startTime)}',
      'EndTime: ${date(endTime)}',
      'LastUpdated: ${date(lastUpdated)}',
      'NextScheduledRefresh: ${date(nextScheduledRefresh)}',
    ].join('\n');
  }
}

bool _boolean(Map<Object?, Object?> map, String key) =>
    map[key] as bool? ?? false;

int? _integer(Map<Object?, Object?> map, String key) =>
    (map[key] as num?)?.toInt();

double? _number(Map<Object?, Object?> map, String key) =>
    (map[key] as num?)?.toDouble();

String _string(
  Map<Object?, Object?> map,
  String key, {
  String fallback = '',
}) =>
    map[key] as String? ?? fallback;

String? _nullableString(Map<Object?, Object?> map, String key) {
  final value = map[key] as String?;
  return value == null || value.isEmpty ? null : value;
}

DateTime? _dateFromMillis(Object? value) {
  final millis = (value as num?)?.toInt();
  if (millis == null || millis <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(millis);
}
