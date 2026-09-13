import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../domain/models/live_update_diagnostic.dart';
import '../services/notification_service.dart';

class LiveUpdateDiagnosticScreen extends StatefulWidget {
  const LiveUpdateDiagnosticScreen({
    required this.notificationService,
    super.key,
  });

  final HaruNotificationService notificationService;

  @override
  State<LiveUpdateDiagnosticScreen> createState() =>
      _LiveUpdateDiagnosticScreenState();
}

class _LiveUpdateDiagnosticScreenState
    extends State<LiveUpdateDiagnosticScreen> {
  late Future<LiveUpdateDiagnostic> _diagnostic;

  @override
  void initState() {
    super.initState();
    _diagnostic = widget.notificationService.liveUpdateDiagnostics();
  }

  void _refresh() {
    setState(() {
      _diagnostic = widget.notificationService.liveUpdateDiagnostics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live Update 진단',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<LiveUpdateDiagnostic>(
        future: _diagnostic,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final diagnostic = snapshot.data!;
          return ListView(
            key: const Key('live_update_diagnostic_screen'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _SummaryCard(diagnostic: diagnostic),
              const SizedBox(height: 14),
              _DiagnosticSection(
                title: 'Android 정보',
                children: [
                  _DiagnosticRow.text(
                      'Android version', diagnostic.androidVersion),
                  _DiagnosticRow.text('SDK_INT', '${diagnostic.sdkInt}'),
                  _DiagnosticRow.text(
                    'SDK_INT_FULL',
                    diagnostic.sdkIntFull?.toString() ?? '사용 불가',
                  ),
                  _DiagnosticRow.text('제조사', diagnostic.manufacturer),
                  _DiagnosticRow.text('모델', diagnostic.model),
                  if (diagnostic.oneUiVersion != null)
                    _DiagnosticRow.text('One UI', diagnostic.oneUiVersion!),
                ],
              ),
              _DiagnosticSection(
                title: 'Live Update 조건',
                children: [
                  _DiagnosticRow.text(
                    '현재 사용 경로',
                    diagnostic.capability.name,
                  ),
                  _DiagnosticRow.check(
                    'Android 16 이상',
                    diagnostic.android16OrAbove,
                  ),
                  _DiagnosticRow.check(
                    'API 36.1 이상',
                    diagnostic.api361OrAbove,
                    unavailable: diagnostic.sdkIntFull == null,
                  ),
                  _DiagnosticRow.check(
                    'POST_NOTIFICATIONS',
                    diagnostic.postNotificationsGranted,
                  ),
                  _DiagnosticRow.check(
                    '앱 알림 사용',
                    diagnostic.notificationsEnabled,
                  ),
                  _DiagnosticRow.check(
                    'Promoted 권한 선언',
                    diagnostic.promotedPermissionDeclared,
                  ),
                  _DiagnosticRow.check(
                    'Promoted 사용자 허용',
                    diagnostic.promotedUserAllowed,
                  ),
                  _DiagnosticRow.check(
                    'CanPostPromoted',
                    diagnostic.canPostPromotedNotifications,
                  ),
                  _DiagnosticRow.check(
                    'Promotable 조건',
                    diagnostic.hasPromotableCharacteristics,
                  ),
                  _DiagnosticRow.check(
                    '현재 시스템 승격',
                    diagnostic.currentlyPromoted,
                  ),
                ],
              ),
              _DiagnosticSection(
                title: 'Notification 조건',
                children: [
                  _DiagnosticRow.check('Ongoing', diagnostic.ongoing),
                  _DiagnosticRow.check(
                    'Content title',
                    diagnostic.hasContentTitle,
                  ),
                  _DiagnosticRow.text('Style', diagnostic.notificationStyle),
                  _DiagnosticRow.check(
                    'ProgressStyle',
                    diagnostic.progressStyle,
                  ),
                  _DiagnosticRow.check(
                    'Custom RemoteViews 없음',
                    !diagnostic.customRemoteViews,
                  ),
                  _DiagnosticRow.check('Colorized 아님', !diagnostic.colorized),
                  _DiagnosticRow.text('Channel', diagnostic.channelId),
                  _DiagnosticRow.check(
                    '채널 중요도',
                    (diagnostic.channelImportance ?? 0) > 1,
                    value: diagnostic.channelImportanceLabel,
                    unavailable: diagnostic.channelImportance == null,
                  ),
                  _DiagnosticRow.text('Visibility', diagnostic.visibility),
                  _DiagnosticRow.check(
                    'Foreground service 미사용',
                    !diagnostic.foregroundService,
                  ),
                ],
              ),
              _DiagnosticSection(
                title: 'HARU 상태',
                children: [
                  _DiagnosticRow.text(
                      'TimeEngine state', diagnostic.currentState),
                  _DiagnosticRow.check(
                    'Live Update active',
                    diagnostic.liveUpdateActive,
                  ),
                  _DiagnosticRow.text(
                    'Headline',
                    diagnostic.headline.isEmpty ? '-' : diagnostic.headline,
                  ),
                  _DiagnosticRow.text(
                    'Progress',
                    '${(diagnostic.progress * 100).round()}%',
                  ),
                  _DiagnosticRow.text(
                      'Start time', _date(diagnostic.startTime)),
                  _DiagnosticRow.text('End time', _date(diagnostic.endTime)),
                  _DiagnosticRow.text(
                    'Last updated',
                    _date(diagnostic.lastUpdated),
                  ),
                  _DiagnosticRow.text(
                    'Next refresh',
                    _date(diagnostic.nextScheduledRefresh),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: diagnostic.canOpenNotificationSettings
                        ? () => widget.notificationService
                            .openNotificationSettings()
                        : null,
                    child: const Text('알림 설정 열기'),
                  ),
                  OutlinedButton(
                    onPressed: diagnostic.canOpenLockScreenSettings
                        ? () => widget.notificationService
                            .openLockScreenNotificationSettings()
                        : null,
                    child: const Text('잠금화면 알림 설정'),
                  ),
                  OutlinedButton(
                    onPressed: diagnostic.canOpenPromotionSettings
                        ? () =>
                            widget.notificationService.openLiveUpdateSettings()
                        : null,
                    child: const Text('Promoted 설정'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                key: const Key('copy_live_update_diagnostic'),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: diagnostic.copyText),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('진단 정보를 복사했어요.')),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('진단 정보 복사'),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _date(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(value);
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.diagnostic});

  final LiveUpdateDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) {
    final ready =
        diagnostic.capability != LiveUpdateRuntimeCapability.unsupported;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ready ? const Color(0xffe9f5ed) : const Color(0xfffff4df),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ready ? Icons.check_circle_outline : Icons.info_outline,
            color: ready ? const Color(0xff327348) : const Color(0xff8b6418),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              diagnostic.summary,
              key: const Key('live_update_diagnostic_summary'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticSection extends StatelessWidget {
  const _DiagnosticSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xff6657b5),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow._({
    required this.label,
    required this.value,
    required this.result,
    this.unavailable = false,
  });

  factory _DiagnosticRow.text(String label, String value) =>
      _DiagnosticRow._(label: label, value: value, result: null);

  factory _DiagnosticRow.check(
    String label,
    bool result, {
    String? value,
    bool unavailable = false,
  }) =>
      _DiagnosticRow._(
        label: label,
        value: value ?? '',
        result: result,
        unavailable: unavailable,
      );

  final String label;
  final String value;
  final bool? result;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final icon = unavailable
        ? '－'
        : result == null
            ? null
            : result!
                ? '✅'
                : '❌';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          if (value.isNotEmpty)
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xff54515e),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (icon != null) ...[
            const SizedBox(width: 7),
            Text(icon),
          ],
        ],
      ),
    );
  }
}
