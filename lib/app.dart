import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'data/local/settings_store.dart';
import 'domain/models/app_settings.dart';
import 'domain/models/budget_profile.dart';
import 'domain/models/daily_spend.dart';
import 'domain/models/schedule_entry.dart';
import 'domain/models/schedule_profile.dart';
import 'domain/models/time_summary.dart';
import 'domain/services/budget_engine.dart';
import 'domain/services/daily_spend_service.dart';
import 'domain/services/schedule_entry_service.dart';
import 'domain/services/time_engine.dart';
import 'presentation/dashboard_tabs.dart';
import 'presentation/dayve_design_tokens.dart';
import 'presentation/haru_sheets.dart';
import 'presentation/live_update_diagnostic_screen.dart';
import 'services/calendar_integration_service.dart';
import 'services/notification_service.dart';
import 'services/home_widget_service.dart';

class HaruApp extends StatefulWidget {
  const HaruApp({
    required this.settingsStore,
    required this.notificationService,
    required this.homeWidgetService,
    super.key,
  });

  final SettingsStore settingsStore;
  final HaruNotificationService notificationService;
  final HaruHomeWidgetService homeWidgetService;

  @override
  State<HaruApp> createState() => _HaruAppState();
}

class _HaruAppState extends State<HaruApp> {
  AppSettings? _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settingsStore.loadSettings();
  }

  Future<void> _completeOnboarding(AppSettings settings) async {
    await widget.settingsStore.saveSettings(settings);
    await widget.notificationService.sync(settings, null);
    await widget.homeWidgetService.refresh();
    if (mounted) setState(() => _settings = settings);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DAYVE',
      debugShowCheckedModeBanner: false,
      theme: buildDayveTheme(),
      home: _settings == null
          ? OnboardingScreen(onComplete: _completeOnboarding)
          : DashboardScreen(
              settings: _settings!,
              settingsStore: widget.settingsStore,
              notificationService: widget.notificationService,
              homeWidgetService: widget.homeWidgetService,
              onSettingsChanged: (settings) {
                if (mounted) setState(() => _settings = settings);
              },
            ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onComplete, super.key});

  final Future<void> Function(AppSettings settings) onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _budgetController = TextEditingController(text: '600000');
  var _step = 0;
  var _saving = false;
  var _workStart = const TimeOfDay(hour: 9, minute: 0);
  var _workEnd = const TimeOfDay(hour: 18, minute: 0);
  var _wake = const TimeOfDay(hour: 7, minute: 0);
  var _sleep = const TimeOfDay(hour: 23, minute: 30);
  var _sleepReminder = const TimeOfDay(hour: 23, minute: 0);
  var _sleepReminderEnabled = false;
  var _wakeNotificationEnabled = false;
  var _reminder = const TimeOfDay(hour: 21, minute: 0);
  var _payday = 1;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(
    String title,
    TimeOfDay initial,
    ValueChanged<TimeOfDay> onSelected,
  ) async {
    final selected = await showHaruTimePicker(
      context: context,
      initialTime: initial,
      title: title,
    );
    if (!mounted || selected == null) return;
    setState(() => onSelected(selected));
  }

  Future<void> _next() async {
    final budget = int.tryParse(
      _budgetController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (_step == 2 && (budget == null || budget <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('한 달 생활비를 1원 이상 입력해 주세요.')),
      );
      return;
    }
    if (_step < 3) {
      setState(() => _step += 1);
      return;
    }

    setState(() => _saving = true);
    await widget.onComplete(
      AppSettings(
        schedule: ScheduleProfile(
          workStartMinutes: _minutes(_workStart),
          workEndMinutes: _minutes(_workEnd),
          wakeMinutes: _minutes(_wake),
          sleepMinutes: _minutes(_sleep),
          workingWeekdays: const {1, 2, 3, 4, 5},
        ),
        budget: BudgetProfile(cycleBudget: budget!, cycleStartDay: _payday),
        dailyReminderMinutes: _minutes(_reminder),
        sleepReminderEnabled: _sleepReminderEnabled,
        sleepReminderMinutes: _minutes(_sleepReminder),
        wakeNotificationEnabled: _wakeNotificationEnabled,
      ),
    );
    if (mounted) setState(() => _saving = false);
  }

  int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  @override
  Widget build(BuildContext context) {
    const titles = ['출근과 퇴근', '기상과 취침', '생활비 설정', '지출 확인 알림'];
    const descriptions = [
      '평일의 기본 근무 시간을 알려주세요.',
      '하루의 시작과 마무리 시간을 알려주세요.',
      '월급날과 다음 월급날 전까지 사용할 생활비를 정해 주세요.',
      '매일 지출을 돌아볼 시간을 정해 주세요.',
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('DAYVE', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 24),
              LinearProgressIndicator(value: (_step + 1) / 4),
              const SizedBox(height: 32),
              Text(
                '${_step + 1} / 4',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(titles[_step],
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(descriptions[_step]),
              const SizedBox(height: 32),
              Expanded(child: _stepContent()),
              Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed:
                          _saving ? null : () => setState(() => _step -= 1),
                      child: const Text('이전'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _saving ? null : _next,
                    child: Text(_step == 3 ? '시작하기' : '다음'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepContent() {
    return switch (_step) {
      0 => Column(
          children: [
            _TimeTile(
              label: '출근',
              value: _workStart,
              onTap: () =>
                  _pickTime('출근 시간', _workStart, (value) => _workStart = value),
            ),
            const SizedBox(height: 12),
            _TimeTile(
              label: '퇴근',
              value: _workEnd,
              onTap: () =>
                  _pickTime('퇴근 시간', _workEnd, (value) => _workEnd = value),
            ),
          ],
        ),
      1 => ListView(
          children: [
            _TimeTile(
              label: '취침 시간',
              value: _sleep,
              onTap: () =>
                  _pickTime('취침 시간', _sleep, (value) => _sleep = value),
            ),
            const SizedBox(height: 12),
            _TimeTile(
              label: '기상 시간',
              value: _wake,
              onTap: () => _pickTime('기상 시간', _wake, (value) => _wake = value),
            ),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                title: const Text('취침 준비 알림'),
                subtitle: const Text('정한 시간에 잠자리를 준비하도록 알려드려요.'),
                value: _sleepReminderEnabled,
                onChanged: (value) =>
                    setState(() => _sleepReminderEnabled = value),
              ),
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: _sleepReminderEnabled ? 1 : .5,
              child: IgnorePointer(
                ignoring: !_sleepReminderEnabled,
                child: _TimeTile(
                  label: '취침 준비 알림 시간',
                  value: _sleepReminder,
                  onTap: () => _pickTime(
                    '취침 준비 알림 시간',
                    _sleepReminder,
                    (value) => _sleepReminder = value,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                title: const Text('기상 알림'),
                subtitle: const Text('설정한 기상 시간에 알려드려요.'),
                value: _wakeNotificationEnabled,
                onChanged: (value) =>
                    setState(() => _wakeNotificationEnabled = value),
              ),
            ),
          ],
        ),
      2 => ListView(
          children: [
            DropdownButtonFormField<int>(
              initialValue: _payday,
              decoration: const InputDecoration(
                labelText: '월급날',
                border: OutlineInputBorder(),
              ),
              items: [
                for (var day = 1; day <= 31; day += 1)
                  DropdownMenuItem(value: day, child: Text('$day일')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _payday = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '한 달 생활비',
                suffixText: '원',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      _ => _TimeTile(
          label: '매일 알림 시간',
          value: _reminder,
          onTap: () => _pickTime(
            '지출 확인 알림 시간',
            _reminder,
            (value) => _reminder = value,
          ),
        ),
    };
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final TimeOfDay value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(label),
        trailing: Text(
          '${value.hour.toString().padLeft(2, '0')}:'
          '${value.minute.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        onTap: onTap,
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.settings,
    required this.settingsStore,
    required this.notificationService,
    required this.homeWidgetService,
    this.onSettingsChanged,
    this.nowProvider = DateTime.now,
    super.key,
  });

  final AppSettings settings;
  final SettingsStore settingsStore;
  final HaruNotificationService notificationService;
  final HaruHomeWidgetService homeWidgetService;
  final ValueChanged<AppSettings>? onSettingsChanged;
  final DateTime Function() nowProvider;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  static const _timeEngine = TimeEngine();
  static const _budgetEngine = BudgetEngine();

  late List<DailySpend> _spends;
  late AppSettings _settings;
  late ScheduleEntryService _scheduleService;
  late DailySpendService _spendService;
  late final CalendarIntegrationService _calendarService;
  ScheduleEntry? _scheduleEntry;
  late Timer _clock;
  Timer? _stateTransitionClock;
  late DateTime _now;
  var _surfaceOpen = false;
  var _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _now = widget.nowProvider();
    _settings = widget.settings;
    _scheduleService = ScheduleEntryService(widget.settingsStore);
    _spendService = DailySpendService(widget.settingsStore);
    _calendarService = CalendarIntegrationService();
    _spends = _spendService.load();
    _scheduleEntry = _scheduleService.activeFor(_now, _settings.schedule);
    widget.notificationService.addListener(_handleNotificationAction);
    widget.homeWidgetService.addListener(_handleHomeWidgetAction);
    unawaited(widget.notificationService.sync(_settings, _scheduleEntry));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleHomeWidgetAction();
      _handleNotificationAction();
    });
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() => _now = widget.nowProvider());
        _scheduleStateTransition();
      }
    });
    _scheduleStateTransition();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.notificationService.removeListener(_handleNotificationAction);
    widget.homeWidgetService.removeListener(_handleHomeWidgetAction);
    _clock.cancel();
    _stateTransitionClock?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_resumeFromBackground());
    }
  }

  Future<void> _resumeFromBackground() async {
    await widget.notificationService.consumePendingLiveUpdateAction();
    if (!mounted) return;
    await _refreshDataViews();
  }

  void _reloadLocalData() {
    if (!mounted) return;
    setState(() {
      _now = widget.nowProvider();
      _spends = _spendService.load();
      _scheduleEntry = _scheduleService.activeFor(
        _now,
        _settings.schedule,
      );
    });
    _scheduleStateTransition();
  }

  void _handleNotificationAction() {
    final action = widget.notificationService.consumeAction();
    if (action == null) {
      unawaited(_refreshDataViews());
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (action.type) {
        case NotificationQuickAction.overtime:
          unawaited(_showOvertimeMenu(action.date));
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  void _scheduleStateTransition() {
    _stateTransitionClock?.cancel();
    if (!mounted) return;
    final summary = _timeEngine.calculate(
      now: _now,
      profile: _settings.schedule,
      scheduleEntry: _scheduleEntry,
    );
    final delay = summary.nextEventAt.difference(_now);
    if (delay <= Duration.zero) return;
    _stateTransitionClock =
        Timer(delay + const Duration(milliseconds: 100), () {
      if (!mounted) return;
      unawaited(_refreshDataViews());
    });
  }

  Future<void> _refreshDataViews() async {
    if (!mounted) return;
    _reloadLocalData();
    final refreshAt = _now;
    await widget.homeWidgetService.refresh(now: refreshAt);
    if (!mounted) return;
    await widget.notificationService.sync(_settings, _scheduleEntry);
  }

  void _handleHomeWidgetAction() {
    final action = widget.homeWidgetService.consumeAction();
    if (action == null || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (action) {
        case WidgetQuickAction.spend:
          unawaited(_editTodaySpend());
          break;
        case WidgetQuickAction.schedule:
          unawaited(_showOverrideMenu());
          break;
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  Future<void> _editTodaySpend() async {
    if (!mounted || _surfaceOpen) return;
    _surfaceOpen = true;
    try {
      final amount = await showHaruSpendInput(
        context: context,
        initialAmount: _spendService.amountFor(_now),
      );
      if (!mounted || amount == null) return;

      await _spendService.update(_now, amount);
      if (!mounted) return;
      await _refreshDataViews();
    } finally {
      _surfaceOpen = false;
    }
  }

  Future<TimeOfDay?> _pickMinutes(int minutes, String helpText) {
    return showHaruTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (minutes ~/ 60) % 24, minute: minutes % 60),
      title: helpText,
    );
  }

  int _toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  Future<void> _showOverrideMenu() async {
    if (!mounted || _surfaceOpen) return;
    _surfaceOpen = true;
    final today = DateTime(_now.year, _now.month, _now.day);
    try {
      final action = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: const Color(0xfffbfaff),
        builder: (sheetContext) => SafeArea(
          child: SingleChildScrollView(
            key: const Key('schedule_settings_sheet'),
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              14 + MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xffd8d5e5),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  title: Text(
                    '설정',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('시간, 생활비와 잠금화면 정보를 관리해요.'),
                ),
                const _SettingsSectionLabel('일정'),
                _OverrideTile(
                  icon: Icons.date_range_outlined,
                  label: '요일별 기본 일정',
                  detail: '근무·휴무와 출퇴근 시간을 설정해요',
                  onTap: () => Navigator.pop(sheetContext, 'weekdays'),
                ),
                _OverrideTile(
                  icon: Icons.bedtime_outlined,
                  label: '수면 및 알림',
                  detail: '취침·기상 시간과 알림을 설정해요',
                  onTap: () => Navigator.pop(sheetContext, 'sleep'),
                ),
                _OverrideTile(
                  icon: Icons.tune,
                  label: '오늘만 변경',
                  detail: '오늘 출근과 퇴근 시간만 바꿔요',
                  onTap: () => Navigator.pop(sheetContext, 'custom'),
                ),
                _OverrideTile(
                  icon: Icons.weekend_outlined,
                  label: '오늘 휴무 처리',
                  onTap: () => Navigator.pop(sheetContext, 'dayOff'),
                ),
                if (_scheduleService.entryForDate(today) != null)
                  _OverrideTile(
                    icon: Icons.restart_alt,
                    label: '오늘 변경 취소',
                    detail: '요일별 기본 일정으로 돌아가요',
                    onTap: () => Navigator.pop(sheetContext, 'delete'),
                  ),
                const _SettingsSectionLabel('생활비'),
                _OverrideTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: '생활비 설정',
                  detail: '월급날과 한 달 생활비를 설정해요',
                  onTap: () => Navigator.pop(sheetContext, 'budget'),
                ),
                const _SettingsSectionLabel('알림 및 잠금화면'),
                SwitchListTile(
                  key: const Key('lock_screen_live_toggle'),
                  visualDensity: const VisualDensity(vertical: -2),
                  secondary: const Icon(
                    Icons.notifications_active_outlined,
                    color: Color(0xff6657b5),
                  ),
                  title: const Text(
                    '잠금화면 실시간 정보',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('근무 중 남은 시간을 잠금화면에 표시해요'),
                  value: _settings.lockScreenLiveEnabled,
                  onChanged: (enabled) => Navigator.pop(
                    sheetContext,
                    enabled ? 'enableLockScreenLive' : 'disableLockScreenLive',
                  ),
                ),
                _OverrideTile(
                  icon: Icons.lock_outline,
                  label: '잠금화면 돈 정보',
                  detail:
                      _settings.lockScreenMoneyVisible ? '표시 중' : '숨김 · 기본값',
                  onTap: () => Navigator.pop(sheetContext, 'lockScreen'),
                ),
                const Divider(height: 22),
                const _SettingsSectionLabel('개발자 진단'),
                _OverrideTile(
                  icon: Icons.science_outlined,
                  label: 'Live Update 진단',
                  detail: 'Now Bar 승격 조건과 현재 상태를 확인해요',
                  onTap: () => Navigator.pop(sheetContext, 'diagnostic'),
                ),
              ],
            ),
          ),
        ),
      );
      if (!mounted || action == null) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      switch (action) {
        case 'weekdays':
          await _showWeekdaySettings();
          return;
        case 'sleep':
          await _showSleepSettings();
          return;
        case 'budget':
          await _showBudgetSettings();
          return;
        case 'enableLockScreenLive':
          await _setLockScreenLiveEnabled(true);
          return;
        case 'disableLockScreenLive':
          await _setLockScreenLiveEnabled(false);
          return;
        case 'lockScreen':
          await _showLockScreenSettings();
          return;
        case 'diagnostic':
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => LiveUpdateDiagnosticScreen(
                notificationService: widget.notificationService,
              ),
            ),
          );
          return;
        case 'custom':
          await _setTodaySchedule(today);
          return;
        case 'dayOff':
          await _saveSchedule(
            _scheduleService.save(
              ScheduleEntry(date: today, type: ScheduleEntryType.dayOff),
            ),
          );
          return;
        case 'delete':
          await _scheduleService.delete(today);
          if (mounted) await _refreshDataViews();
          return;
      }
    } finally {
      _surfaceOpen = false;
    }
  }

  Future<void> _showWeekdaySettings() async {
    final selectedDay = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xfffbfaff),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .78,
            ),
            child: ListView(
              key: const Key('weekday_schedule_sheet'),
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  title: Text(
                    '요일별 기본 일정',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('각 요일의 근무 여부와 시간을 정해요.'),
                ),
                for (var day = DateTime.monday;
                    day <= DateTime.sunday;
                    day += 1)
                  ListTile(
                    key: Key('weekday_schedule_$day'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text(_weekdayName(day)),
                    subtitle: Text(
                      _settings.schedule.isWorkingDay(day)
                          ? '${_formatMinutes(_settings.schedule.workStartFor(day))}'
                              ' – ${_formatMinutes(_settings.schedule.workEndFor(day))}'
                          : '휴무',
                    ),
                    onTap: _settings.schedule.isWorkingDay(day)
                        ? () => Navigator.pop(sheetContext, day)
                        : null,
                    trailing: Switch(
                      value: _settings.schedule.isWorkingDay(day),
                      onChanged: (value) async {
                        await _saveWeekday(day, isWorking: value);
                        if (sheetContext.mounted) setSheetState(() {});
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || selectedDay == null) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final start = await _pickMinutes(
      _settings.schedule.workStartFor(selectedDay),
      '${_weekdayName(selectedDay)} 출근 시간',
    );
    if (!mounted || start == null) return;
    final end = await _pickMinutes(
      _settings.schedule.workEndFor(selectedDay),
      '${_weekdayName(selectedDay)} 퇴근 시간',
    );
    if (!mounted || end == null) return;
    await _saveWeekday(
      selectedDay,
      isWorking: true,
      workStartMinutes: _toMinutes(start),
      workEndMinutes: _toMinutes(end),
    );
  }

  Future<void> _saveWeekday(
    int weekday, {
    required bool isWorking,
    int? workStartMinutes,
    int? workEndMinutes,
  }) async {
    final schedule = _settings.schedule;
    final updatedSchedule = schedule.withWeekday(
      weekday,
      WeekdaySchedule(
        isWorking: isWorking,
        workStartMinutes: workStartMinutes ?? schedule.workStartFor(weekday),
        workEndMinutes: workEndMinutes ?? schedule.workEndFor(weekday),
      ),
    );
    final updated = _settings.copyWith(schedule: updatedSchedule);
    await widget.settingsStore.saveSettings(updated);
    if (!mounted) return;
    setState(() => _settings = updated);
    widget.onSettingsChanged?.call(updated);
    await _refreshDataViews();
  }

  Future<void> _showSleepSettings() async {
    var sleepMinutes = _settings.schedule.sleepMinutes;
    var wakeMinutes = _settings.schedule.wakeMinutes;
    var sleepReminderEnabled = _settings.sleepReminderEnabled;
    var sleepReminderMinutes = _settings.sleepReminderMinutes;
    var wakeNotificationEnabled = _settings.wakeNotificationEnabled;

    final result = await showModalBottomSheet<_SleepSettingsDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xfffbfaff),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .86,
            ),
            child: ListView(
              key: const Key('sleep_settings_sheet'),
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              children: [
                const Text(
                  '수면 및 알림',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  '현재 적용되는 시간을 직접 확인하고 바꿀 수 있어요.',
                  style: TextStyle(color: Color(0xff777382), fontSize: 13),
                ),
                const SizedBox(height: 12),
                ListTile(
                  key: const Key('sleep_time_setting'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: const Text('취침 시간'),
                  trailing: Text(
                    _formatMinutes(sleepMinutes),
                    style: const TextStyle(
                      color: Color(0xff6657b5),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () async {
                    final selected = await _pickMinutes(
                      sleepMinutes,
                      '취침 시간',
                    );
                    if (!sheetContext.mounted || selected == null) return;
                    setSheetState(() => sleepMinutes = _toMinutes(selected));
                  },
                ),
                ListTile(
                  key: const Key('wake_time_setting'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: const Text('기상 시간'),
                  trailing: Text(
                    _formatMinutes(wakeMinutes),
                    style: const TextStyle(
                      color: Color(0xff6657b5),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () async {
                    final selected = await _pickMinutes(
                      wakeMinutes,
                      '기상 시간',
                    );
                    if (!sheetContext.mounted || selected == null) return;
                    setSheetState(() => wakeMinutes = _toMinutes(selected));
                  },
                ),
                SwitchListTile(
                  key: const Key('sleep_reminder_toggle'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: const Text('취침 준비 알림'),
                  subtitle: const Text('잠자리를 준비할 시간을 알려드려요.'),
                  value: sleepReminderEnabled,
                  onChanged: (value) =>
                      setSheetState(() => sleepReminderEnabled = value),
                ),
                ListTile(
                  key: const Key('sleep_reminder_time_setting'),
                  enabled: sleepReminderEnabled,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: const Text('취침 준비 알림 시간'),
                  trailing: Text(
                    _formatMinutes(sleepReminderMinutes),
                    style: TextStyle(
                      color: sleepReminderEnabled
                          ? const Color(0xff6657b5)
                          : const Color(0xffaaa7b2),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () async {
                    final selected = await _pickMinutes(
                      sleepReminderMinutes,
                      '취침 준비 알림 시간',
                    );
                    if (!sheetContext.mounted || selected == null) return;
                    setSheetState(
                      () => sleepReminderMinutes = _toMinutes(selected),
                    );
                  },
                ),
                SwitchListTile(
                  key: const Key('wake_notification_toggle'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: const Text('기상 알림'),
                  subtitle: const Text('설정한 기상 시간에 알려드려요.'),
                  value: wakeNotificationEnabled,
                  onChanged: (value) =>
                      setSheetState(() => wakeNotificationEnabled = value),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  key: const Key('save_sleep_settings'),
                  onPressed: () => Navigator.pop(
                    sheetContext,
                    _SleepSettingsDraft(
                      sleepMinutes: sleepMinutes,
                      wakeMinutes: wakeMinutes,
                      sleepReminderEnabled: sleepReminderEnabled,
                      sleepReminderMinutes: sleepReminderMinutes,
                      wakeNotificationEnabled: wakeNotificationEnabled,
                    ),
                  ),
                  child: const Text('저장'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || result == null) return;

    final updated = _settings.copyWith(
      schedule: _settings.schedule.copyWith(
        wakeMinutes: result.wakeMinutes,
        sleepMinutes: result.sleepMinutes,
      ),
      sleepReminderEnabled: result.sleepReminderEnabled,
      sleepReminderMinutes: result.sleepReminderMinutes,
      wakeNotificationEnabled: result.wakeNotificationEnabled,
    );
    await widget.settingsStore.saveSettings(updated);
    final todayEntry = _scheduleService.entryForDate(_now);
    if (todayEntry != null && !todayEntry.isDayOff) {
      if (todayEntry.workStartMinutes == null &&
          todayEntry.workEndMinutes == null) {
        await _scheduleService.delete(_now);
      } else {
        await _scheduleService.save(
          ScheduleEntry(
            date: todayEntry.date,
            type: todayEntry.type,
            workStartMinutes: todayEntry.workStartMinutes,
            workEndMinutes: todayEntry.workEndMinutes,
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() => _settings = updated);
    widget.onSettingsChanged?.call(updated);
    await _refreshDataViews();
  }

  Future<void> _showLockScreenSettings() async {
    var showMoney = _settings.lockScreenMoneyVisible;
    final result = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: const Color(0xfffbfaff),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '잠금화면 정보',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  '시간과 진행률은 항상 표시하고, 돈 정보만 선택할 수 있어요.',
                  style: TextStyle(color: Color(0xff777382), fontSize: 13),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  key: const Key('lock_screen_money_toggle'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('잠금화면 돈 정보'),
                  subtitle: Text(showMoney ? '표시' : '숨김'),
                  value: showMoney,
                  onChanged: (value) => setSheetState(() => showMoney = value),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        key: const Key('save_lock_screen_settings'),
                        onPressed: () => Navigator.pop(sheetContext, showMoney),
                        child: const Text('저장'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || result == null) return;
    final updated = _settings.copyWith(lockScreenMoneyVisible: result);
    await widget.settingsStore.saveSettings(updated);
    if (!mounted) return;
    setState(() => _settings = updated);
    widget.onSettingsChanged?.call(updated);
    await _refreshDataViews();
  }

  Future<void> _setLockScreenLiveEnabled(bool enabled) async {
    var introSeen = _settings.lockScreenLiveIntroSeen;
    if (enabled && !introSeen) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('잠금화면에서도 DAYVE를 볼까요?'),
          content: const Text(
            '퇴근까지 남은 시간과\n'
            '오늘의 흐름을 잠금해제 없이 확인할 수 있어요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            FilledButton(
              key: const Key('enable_lock_screen_live'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('사용하기'),
            ),
          ],
        ),
      );
      if (!mounted || accepted != true) return;
      introSeen = true;
      await widget.notificationService.requestNotificationPermission();
      if (!mounted) return;
    } else if (enabled) {
      await widget.notificationService.requestNotificationPermission();
      if (!mounted) return;
    }

    final updated = _settings.copyWith(
      lockScreenLiveEnabled: enabled,
      lockScreenLiveIntroSeen: introSeen,
    );
    await widget.settingsStore.saveSettings(updated);
    if (!mounted) return;
    setState(() => _settings = updated);
    widget.onSettingsChanged?.call(updated);
    await _refreshDataViews();
  }

  Future<void> _showBudgetSettings() async {
    var payday = _settings.budget.cycleStartDay;
    var cycleBudget = _settings.budget.cycleBudget;
    final currency = NumberFormat.decimalPattern('ko_KR');

    final result = await showModalBottomSheet<_BudgetSettingsDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xfffbfaff),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final nextReset = _budgetEngine.nextCycleStart(
            now: _now,
            profile: BudgetProfile(
              cycleBudget: cycleBudget,
              cycleStartDay: payday,
            ),
          );
          return SafeArea(
            child: SingleChildScrollView(
              key: const Key('budget_settings_sheet'),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '생활비 설정',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '월급날부터 다음 월급날 전날까지 한 주기로 계산해요.',
                    style: TextStyle(color: Color(0xff777382), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    key: const Key('payday_setting'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: const Text('월급날'),
                    trailing: Text(
                      '매달 $payday일',
                      style: const TextStyle(
                        color: Color(0xff6657b5),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () async {
                      final selected = await _showPaydayPicker(payday);
                      if (!sheetContext.mounted || selected == null) return;
                      setSheetState(() => payday = selected);
                    },
                  ),
                  ListTile(
                    key: const Key('cycle_budget_setting'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: const Text('한 달 생활비'),
                    trailing: Text(
                      '${currency.format(cycleBudget)}원',
                      style: const TextStyle(
                        color: Color(0xff24222d),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () async {
                      final selected = await showHaruAmountInput(
                        context: context,
                        initialAmount: cycleBudget,
                        title: '한 달 생활비',
                      );
                      if (!sheetContext.mounted || selected == null) return;
                      setSheetState(() => cycleBudget = selected);
                    },
                  ),
                  Container(
                    key: const Key('next_budget_reset'),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffeeeafa),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Text('다음 초기화 날짜'),
                        const Spacer(),
                        Text(
                          DateFormat('yyyy년 M월 d일', 'ko_KR').format(nextReset),
                          style: const TextStyle(
                            color: Color(0xff6657b5),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const Key('save_budget_settings'),
                    onPressed: cycleBudget <= 0
                        ? null
                        : () => Navigator.pop(
                              sheetContext,
                              _BudgetSettingsDraft(
                                payday: payday,
                                cycleBudget: cycleBudget,
                              ),
                            ),
                    child: const Text('저장'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (!mounted || result == null) return;
    final updated = _settings.copyWith(
      budget: BudgetProfile(
        cycleBudget: result.cycleBudget,
        cycleStartDay: result.payday,
      ),
    );
    await widget.settingsStore.saveSettings(updated);
    if (!mounted) return;
    setState(() => _settings = updated);
    widget.onSettingsChanged?.call(updated);
    await _refreshDataViews();
  }

  Future<void> _openBudgetSettings() async {
    if (!mounted || _surfaceOpen) return;
    _surfaceOpen = true;
    try {
      await _showBudgetSettings();
    } finally {
      _surfaceOpen = false;
    }
  }

  Future<int?> _showPaydayPicker(int initialDay) async {
    var selectedDay = initialDay.clamp(1, 31);
    final controller = FixedExtentScrollController(
      initialItem: selectedDay - 1,
    );
    try {
      return await showModalBottomSheet<int>(
        context: context,
        useSafeArea: true,
        backgroundColor: const Color(0xfffbfaff),
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '월급날',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  child: CupertinoPicker(
                    key: const Key('payday_picker'),
                    scrollController: controller,
                    itemExtent: 40,
                    useMagnifier: true,
                    selectionOverlay: const _PaydaySelectionOverlay(),
                    onSelectedItemChanged: (index) => selectedDay = index + 1,
                    children: [
                      for (var day = 1; day <= 31; day += 1)
                        Center(child: Text('$day일')),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        key: const Key('payday_confirm'),
                        onPressed: () =>
                            Navigator.pop(sheetContext, selectedDay),
                        child: const Text('적용'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _setTodaySchedule(DateTime date) async {
    final weekday = date.weekday;
    final existing = _scheduleService.entryForDate(date);
    final start = await _pickMinutes(
      existing?.workStartMinutes ?? _settings.schedule.workStartFor(weekday),
      '오늘 출근 시간',
    );
    if (!mounted || start == null) return;
    final end = await _pickMinutes(
      existing?.workEndMinutes ?? _settings.schedule.workEndFor(weekday),
      '오늘 퇴근 시간',
    );
    if (!mounted || end == null) return;
    await _saveSchedule(
      _scheduleService.save(
        ScheduleEntry(
          date: date,
          type: ScheduleEntryType.custom,
          workStartMinutes: _toMinutes(start),
          workEndMinutes: _toMinutes(end),
          wakeMinutes: existing?.wakeMinutes,
          sleepMinutes: existing?.sleepMinutes,
        ),
      ),
    );
  }

  Future<void> _showOvertimeMenu(DateTime scheduleDate) async {
    if (!mounted || _surfaceOpen) return;
    _surfaceOpen = true;
    try {
      final action = await showModalBottomSheet<String>(
        context: context,
        useSafeArea: true,
        backgroundColor: const Color(0xfffbfaff),
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text(
                    '오늘 얼마나 더 일하나요?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                _OverrideTile(
                  icon: Icons.more_time,
                  label: '+30분',
                  onTap: () => Navigator.pop(sheetContext, '30'),
                ),
                _OverrideTile(
                  icon: Icons.more_time,
                  label: '+1시간',
                  onTap: () => Navigator.pop(sheetContext, '60'),
                ),
                _OverrideTile(
                  icon: Icons.tune,
                  label: '직접 설정',
                  onTap: () => Navigator.pop(sheetContext, 'custom'),
                ),
              ],
            ),
          ),
        ),
      );
      if (!mounted || action == null) return;
      if (action == '30' || action == '60') {
        await extendOvertime(
          widget.settingsStore,
          scheduleDate: scheduleDate,
          additionalMinutes: int.parse(action),
        );
        if (mounted) await _refreshDataViews();
        return;
      }
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final existing = _scheduleService.entryForDate(scheduleDate);
      final weekday = scheduleDate.weekday;
      final selected = await _pickMinutes(
        existing?.workEndMinutes ?? _settings.schedule.workEndFor(weekday),
        '오늘 퇴근 시간',
      );
      if (!mounted || selected == null) return;
      await setOvertimeEnd(
        widget.settingsStore,
        scheduleDate: scheduleDate,
        workEndMinutes: _toMinutes(selected),
      );
      if (mounted) await _refreshDataViews();
    } finally {
      _surfaceOpen = false;
    }
  }

  String _weekdayName(int weekday) => const [
        '월요일',
        '화요일',
        '수요일',
        '목요일',
        '금요일',
        '토요일',
        '일요일',
      ][weekday - 1];

  // Kept only to read and migrate existing date-specific data. The current UI
  // intentionally exposes weekday defaults and today's override only.
  // ignore: unused_element
  Future<DateTime?> _selectScheduleDate() {
    final today = DateTime(_now.year, _now.month, _now.day);
    final dates = List.generate(7, (index) => today.add(Duration(days: index)));
    return showModalBottomSheet<DateTime>(
      context: context,
      useSafeArea: true,
      backgroundColor: const Color(0xfffbfaff),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '일정 날짜',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: dates.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final label = index == 0
                        ? '오늘'
                        : index == 1
                            ? '내일'
                            : '${date.month}/${date.day}';
                    return ActionChip(
                      key: Key('schedule_date_$index'),
                      label: Text(label),
                      onPressed: () => Navigator.pop(sheetContext, date),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: sheetContext,
                    initialDate: today,
                    firstDate: today,
                    lastDate: DateTime(today.year + 3),
                    helpText: '날짜 선택',
                    cancelText: '취소',
                    confirmText: '선택',
                  );
                  if (sheetContext.mounted && date != null) {
                    Navigator.pop(sheetContext, date);
                  }
                },
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('날짜 선택'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Future<void> _showLegacyOverrideMenu() async {
    if (!mounted || _surfaceOpen) return;
    _surfaceOpen = true;
    try {
      final selectedDate = await _selectScheduleDate();
      if (!mounted || selectedDate == null) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final action = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: const Color(0xfffbfaff),
        builder: (sheetContext) {
          final screenHeight = MediaQuery.sizeOf(sheetContext).height;
          final viewInsets = MediaQuery.viewInsetsOf(sheetContext);
          return SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.only(bottom: viewInsets.bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: screenHeight * .84),
                child: SingleChildScrollView(
                  key: const Key('override_sheet_scroll'),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xffd8d5e5),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${selectedDate.month}월 ${selectedDate.day}일 일정',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      _OverrideTile(
                        icon: Icons.work_outline,
                        label: '근무',
                        detail: '출근과 퇴근 시간을 설정해요',
                        onTap: () => Navigator.pop(sheetContext, 'work'),
                      ),
                      _OverrideTile(
                        icon: Icons.weekend_outlined,
                        label: '휴무',
                        onTap: () => Navigator.pop(sheetContext, 'dayOff'),
                      ),
                      _OverrideTile(
                        icon: Icons.nights_stay_outlined,
                        label: '야간근무',
                        detail: '자정을 넘는 근무를 설정해요',
                        onTap: () => Navigator.pop(sheetContext, 'nightShift'),
                      ),
                      _OverrideTile(
                        icon: Icons.tune,
                        label: '직접 시간 설정',
                        onTap: () => Navigator.pop(sheetContext, 'custom'),
                      ),
                      _OverrideTile(
                        icon: Icons.more_time,
                        label: '야근',
                        detail: '퇴근 시간을 변경해요',
                        onTap: () => Navigator.pop(sheetContext, 'overtime'),
                      ),
                      _OverrideTile(
                        icon: Icons.event_outlined,
                        label: '약속',
                        onTap: () => Navigator.pop(sheetContext, 'appointment'),
                      ),
                      _OverrideTile(
                        icon: Icons.bedtime_outlined,
                        label: '늦게 자기',
                        onTap: () => Navigator.pop(sheetContext, 'lateSleep'),
                      ),
                      if (_scheduleService
                                  .entryForDate(selectedDate)
                                  ?.hasWorkSchedule ==
                              true &&
                          _calendarService.isSupported)
                        _OverrideTile(
                          icon: Icons.calendar_today_outlined,
                          label: '휴대폰 Calendar에 추가',
                          onTap: () => Navigator.pop(sheetContext, 'calendar'),
                        ),
                      if (_scheduleService.entryForDate(selectedDate) != null)
                        _OverrideTile(
                          icon: Icons.restart_alt,
                          label: '이 날짜 일정 삭제',
                          onTap: () => Navigator.pop(sheetContext, 'delete'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
      if (!mounted || action == null) return;

      // The route must finish disposing before the next sheet is inserted.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      switch (action) {
        case 'work':
          await _setWorkSchedule(selectedDate, ScheduleEntryType.work);
          return;
        case 'nightShift':
          await _setWorkSchedule(
            selectedDate,
            ScheduleEntryType.nightShift,
            defaultStart: 20 * 60,
            defaultEnd: 8 * 60,
          );
          return;
        case 'overtime':
          final existing = _scheduleService.entryForDate(selectedDate);
          final selected = await _pickMinutes(
            existing?.workEndMinutes ?? widget.settings.schedule.workEndMinutes,
            '${selectedDate.month}/${selectedDate.day} 퇴근 시간',
          );
          if (mounted && selected != null) {
            await _saveSchedule(
              _scheduleService.save(
                ScheduleEntry(
                  date: selectedDate,
                  type: ScheduleEntryType.work,
                  workStartMinutes: existing?.workStartMinutes ??
                      widget.settings.schedule.workStartMinutes,
                  workEndMinutes: _toMinutes(selected),
                  wakeMinutes: existing?.wakeMinutes,
                  sleepMinutes: existing?.sleepMinutes,
                ),
              ),
            );
          }
          return;
        case 'appointment':
          final selected = await _pickMinutes(
            _scheduleService.entryForDate(selectedDate)?.sleepMinutes ??
                widget.settings.schedule.sleepMinutes,
            '약속 후 취침 시간',
          );
          if (mounted && selected != null) {
            await _saveSleepAdjustment(selectedDate, _toMinutes(selected));
          }
          return;
        case 'lateSleep':
          final selected = await _pickMinutes(
            _scheduleService.entryForDate(selectedDate)?.sleepMinutes ??
                widget.settings.schedule.sleepMinutes,
            '${selectedDate.month}/${selectedDate.day} 취침 시간',
          );
          if (mounted && selected != null) {
            await _saveSleepAdjustment(selectedDate, _toMinutes(selected));
          }
          return;
        case 'dayOff':
          await _saveSchedule(
            _scheduleService.save(
              ScheduleEntry(
                date: selectedDate,
                type: ScheduleEntryType.dayOff,
              ),
            ),
          );
          return;
        case 'custom':
          await _setCustomSchedule(selectedDate);
          return;
        case 'delete':
          await _scheduleService.delete(selectedDate);
          if (!mounted) return;
          await _refreshDataViews();
          return;
        case 'calendar':
          final entry = _scheduleService.entryForDate(selectedDate);
          if (entry != null) await _exportToCalendar(entry);
          return;
      }
    } finally {
      _surfaceOpen = false;
    }
  }

  Future<void> _setWorkSchedule(
    DateTime date,
    ScheduleEntryType type, {
    int? defaultStart,
    int? defaultEnd,
  }) async {
    final schedule = widget.settings.schedule;
    final existing = _scheduleService.entryForDate(date);
    final start = await _pickMinutes(
      existing?.workStartMinutes ?? defaultStart ?? schedule.workStartMinutes,
      '출근 시간',
    );
    if (start == null || !mounted) return;
    final end = await _pickMinutes(
      existing?.workEndMinutes ?? defaultEnd ?? schedule.workEndMinutes,
      '퇴근 시간',
    );
    if (end == null || !mounted) return;
    await _saveSchedule(
      _scheduleService.save(
        ScheduleEntry(
          date: date,
          type: type,
          workStartMinutes: _toMinutes(start),
          workEndMinutes: _toMinutes(end),
          wakeMinutes: existing?.wakeMinutes,
          sleepMinutes: existing?.sleepMinutes,
        ),
      ),
    );
  }

  Future<void> _setCustomSchedule(DateTime date) async {
    final schedule = widget.settings.schedule;
    final existing = _scheduleService.entryForDate(date);
    final start = await _pickMinutes(
      existing?.workStartMinutes ?? schedule.workStartMinutes,
      '출근 시간',
    );
    if (start == null || !mounted) return;
    final end = await _pickMinutes(
      existing?.workEndMinutes ?? schedule.workEndMinutes,
      '퇴근 시간',
    );
    if (end == null || !mounted) return;
    final wake = await _pickMinutes(
      existing?.wakeMinutes ?? schedule.wakeMinutes,
      '기상 시간',
    );
    if (wake == null || !mounted) return;
    final sleep = await _pickMinutes(
      existing?.sleepMinutes ?? schedule.sleepMinutes,
      '취침 시간',
    );
    if (sleep == null || !mounted) return;
    await _saveSchedule(
      _scheduleService.save(
        ScheduleEntry(
          date: date,
          type: ScheduleEntryType.custom,
          workStartMinutes: _toMinutes(start),
          workEndMinutes: _toMinutes(end),
          wakeMinutes: _toMinutes(wake),
          sleepMinutes: _toMinutes(sleep),
        ),
      ),
    );
  }

  Future<void> _saveSleepAdjustment(DateTime date, int sleepMinutes) async {
    final existing = _scheduleService.entryForDate(date);
    await _saveSchedule(
      _scheduleService.save(
        ScheduleEntry(
          date: date,
          type: ScheduleEntryType.custom,
          workStartMinutes: existing?.workStartMinutes,
          workEndMinutes: existing?.workEndMinutes,
          wakeMinutes: existing?.wakeMinutes,
          sleepMinutes: sleepMinutes,
        ),
      ),
    );
  }

  Future<void> _exportToCalendar(ScheduleEntry entry) async {
    final allowed = await _calendarService.requestPermission();
    if (!mounted || !allowed) return;
    final calendars = await _calendarService.writableCalendars();
    if (!mounted || calendars.isEmpty) return;
    final selected = await showModalBottomSheet<DeviceCalendar>(
      context: context,
      useSafeArea: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          const ListTile(
            title: Text('Calendar 선택'),
            subtitle: Text('DAYVE 일정만 직접 추가합니다.'),
          ),
          for (final calendar in calendars)
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(calendar.name),
              onTap: () => Navigator.pop(context, calendar),
            ),
        ],
      ),
    );
    if (!mounted || selected == null) return;
    final saved = await _calendarService.export(entry, selected);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(saved ? 'Calendar에 추가했어요.' : '추가하지 못했어요.')),
    );
  }

  Future<void> _saveSchedule(Future<ScheduleEntry> operation) async {
    await operation;
    if (!mounted) return;
    await _refreshDataViews();
  }

  @override
  Widget build(BuildContext context) {
    final time = _timeEngine.calculate(
      now: _now,
      profile: _settings.schedule,
      scheduleEntry: _scheduleEntry,
    );
    final budget = _budgetEngine.calculate(
      now: _now,
      profile: _settings.budget,
      spends: _spends,
    );
    final currency = NumberFormat.decimalPattern('ko_KR');
    final isDayOff = time.state == HaruDayState.dayOff;
    final timeValue = isDayOff ? '휴무' : _durationLabel(time.remaining);
    final timeCaption = isDayOff ? '오늘은 쉬어도 괜찮아요' : _timeTitle(time.state);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedTabIndex == 0 ? '오늘의 여백' : '소비',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            key: const Key('open_settings'),
            onPressed: _showOverrideMenu,
            tooltip: '설정',
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTabIndex,
          children: [
            HaruTodayTab(
              dateLabel: DateFormat('M월 d일 EEEE', 'ko_KR').format(_now),
              state: _stateLabel(time.state),
              timeValue: timeValue,
              timeCaption: timeCaption,
              nextEvent: isDayOff ? null : _nextEventLabel(time),
              progress: time.state == HaruDayState.working ||
                      time.state == HaruDayState.afterWork
                  ? time.progress
                  : null,
              progressLabel:
                  time.state == HaruDayState.working ? '근무 진행' : '자유시간 진행',
              overrideLabel: _scheduleEntry == null
                  ? null
                  : _scheduleEntryLabel(_scheduleEntry!),
              onScheduleTap: _showOverrideMenu,
              recommendedBudget:
                  '${currency.format(budget.recommendedDailyAmount)}원',
              onSpendTap: _editTodaySpend,
            ),
            HaruSpendingTab(
              remainingBudget: '${currency.format(budget.remainingBudget)}원',
              spentAmount: '${currency.format(budget.spentAmount)}원',
              payday: _settings.budget.cycleStartDay,
              remainingDays: budget.remainingDays,
              reminder: _formatMinutes(_settings.dailyReminderMinutes),
              spends: _spends,
              formatAmount: (amount) => '${currency.format(amount)}원',
              formatDate: (date) =>
                  DateFormat('M월 d일 EEEE', 'ko_KR').format(date),
              onSpendTap: _editTodaySpend,
              onBudgetSettingsTap: _openBudgetSettings,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          if (_selectedTabIndex != index) {
            setState(() => _selectedTabIndex = index);
          }
        },
        destinations: const [
          NavigationDestination(
            key: Key('today_tab_destination'),
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today_rounded),
            label: '오늘',
          ),
          NavigationDestination(
            key: Key('spending_tab_destination'),
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: '소비',
          ),
        ],
      ),
    );
  }

  String _stateLabel(HaruDayState state) => switch (state) {
        HaruDayState.beforeWork => '출근 전',
        HaruDayState.working => '근무 중',
        HaruDayState.afterWork => '퇴근 후',
        HaruDayState.sleepWindow => '수면 시간',
        HaruDayState.dayOff => '휴무',
        HaruDayState.exception => '일정 변경',
      };

  String _scheduleEntryLabel(ScheduleEntry entry) => switch (entry.type) {
        ScheduleEntryType.work => '날짜별 근무 일정 적용 중',
        ScheduleEntryType.dayOff => '날짜별 휴무 일정 적용 중',
        ScheduleEntryType.nightShift => '야간근무 일정 적용 중',
        ScheduleEntryType.custom => '직접 설정 일정 적용 중',
        ScheduleEntryType.overtime => '오늘 야근 일정 적용 중',
        ScheduleEntryType.checkout => '퇴근 완료',
      };

  String _timeTitle(HaruDayState state) => switch (state) {
        HaruDayState.beforeWork => '출근까지',
        HaruDayState.working => '퇴근까지',
        HaruDayState.afterWork => '취침까지 자유 시간',
        HaruDayState.sleepWindow => '기상까지',
        HaruDayState.dayOff => '오늘은 휴무',
        HaruDayState.exception => '다음 일정까지',
      };

  String _durationLabel(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours > 0
        ? '${hours.toString().padLeft(2, '0')}시간 '
            '${minutes.toString().padLeft(2, '0')}분'
        : '${minutes.toString().padLeft(2, '0')}분';
  }

  String _nextEventLabel(TimeSummary summary) {
    final time = DateFormat('HH:mm').format(summary.nextEventAt);
    return switch (summary.state) {
      HaruDayState.beforeWork => '출근 $time',
      HaruDayState.working => '퇴근 $time',
      HaruDayState.afterWork => '취침 $time',
      HaruDayState.sleepWindow => '기상 $time',
      _ => '다음 $time',
    };
  }

  String _formatMinutes(int minutes) {
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _SleepSettingsDraft {
  const _SleepSettingsDraft({
    required this.sleepMinutes,
    required this.wakeMinutes,
    required this.sleepReminderEnabled,
    required this.sleepReminderMinutes,
    required this.wakeNotificationEnabled,
  });

  final int sleepMinutes;
  final int wakeMinutes;
  final bool sleepReminderEnabled;
  final int sleepReminderMinutes;
  final bool wakeNotificationEnabled;
}

class _BudgetSettingsDraft {
  const _BudgetSettingsDraft({
    required this.payday,
    required this.cycleBudget,
  });

  final int payday;
  final int cycleBudget;
}

class _PaydaySelectionOverlay extends StatelessWidget {
  const _PaydaySelectionOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x127565c8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x667565c8)),
      ),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 3),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xff777382),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _OverrideTile extends StatelessWidget {
  const _OverrideTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.detail,
  });

  final IconData icon;
  final String label;
  final String? detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: const VisualDensity(vertical: -2),
      leading: Icon(icon, color: const Color(0xff6657b5)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: detail == null ? null : Text(detail!),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}
