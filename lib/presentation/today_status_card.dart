import 'dart:async';

import 'package:flutter/material.dart' hide DayPeriod;

import '../domain/models/weather_snapshot.dart';
import '../domain/services/day_background_resolver.dart';
import '../domain/services/dayve_message_selector.dart';
import 'dayve_design_tokens.dart';

class TodayStatusCard extends StatefulWidget {
  const TodayStatusCard({
    required this.state,
    required this.value,
    required this.caption,
    this.overrideLabel,
    this.now,
    this.weather,
    super.key,
  });

  final String state;
  final String value;
  final String caption;
  final String? overrideLabel;
  final DateTime? now;
  final WeatherSnapshot? weather;

  @override
  State<TodayStatusCard> createState() => _TodayStatusCardState();
}

class _TodayStatusCardState extends State<TodayStatusCard>
    with WidgetsBindingObserver {
  static const _resolver = DayBackgroundResolver();
  static const _messageSelector = DayveMessageSelector();

  Timer? _transitionTimer;
  late DateTime _now;
  late DayBackgroundState _background;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _now = widget.now ?? DateTime.now();
    _background = _resolver.resolve(now: _now, weather: widget.weather);
    _scheduleNextTransition();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheCurrentAndNext();
  }

  @override
  void didUpdateWidget(covariant TodayStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.now != oldWidget.now || widget.weather != oldWidget.weather) {
      _updateBackground(
        widget.now ?? DateTime.now(),
        forceReschedule: widget.weather != oldWidget.weather,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _updateBackground(
          widget.now ?? DateTime.now(),
          forceReschedule: true,
        );
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _transitionTimer?.cancel();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transitionTimer?.cancel();
    super.dispose();
  }

  void _updateBackground(
    DateTime now, {
    bool forceReschedule = false,
  }) {
    final next = _resolver.resolve(now: now, weather: widget.weather);
    if (!mounted) return;
    final dateChanged =
        _now.year != now.year || _now.month != now.month || _now.day != now.day;
    final visualChanged = next.assetPath != _background.assetPath ||
        next.weatherCondition != _background.weatherCondition ||
        next.weatherOverlayOpacity != _background.weatherOverlayOpacity;
    final transitionChanged =
        next.nextTransitionAt != _background.nextTransitionAt;
    _now = now;
    if (visualChanged || dateChanged) {
      setState(() => _background = next);
      if (visualChanged) _precacheCurrentAndNext();
    } else {
      _background = next;
    }
    if (forceReschedule || transitionChanged) {
      _scheduleNextTransition();
    }
  }

  void _scheduleNextTransition() {
    _transitionTimer?.cancel();
    final nextMidnight = DateTime(_now.year, _now.month, _now.day + 1);
    final nextRefresh = nextMidnight.isBefore(_background.nextTransitionAt)
        ? nextMidnight
        : _background.nextTransitionAt;
    final delay = nextRefresh.difference(_now);
    if (delay <= Duration.zero) return;
    _transitionTimer = Timer(delay + const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _updateBackground(DateTime.now(), forceReschedule: true);
    });
  }

  void _precacheCurrentAndNext() {
    precacheImage(AssetImage(_background.assetPath), context);
    final next = _resolver.resolve(
      now: _background.nextTransitionAt.add(const Duration(seconds: 1)),
      weather: widget.weather,
    );
    if (next.assetPath != _background.assetPath) {
      precacheImage(AssetImage(next.assetPath), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentation = _StatusPresentation.forState(widget.state);
    final dailyMessage = _messageSelector.selectDailyMessage(
      date: _now,
      period: _background.period,
    );
    final radius = BorderRadius.circular(28);

    return Semantics(
      key: const Key('dashboard_time_area'),
      label:
          'DAYVE ${widget.state} ${widget.caption} ${widget.value} ${widget.overrideLabel ?? ''}',
      child: AspectRatio(
        key: const Key('dayve_hero_aspect_ratio'),
        aspectRatio: 16 / 9,
        child: Container(
          key: const Key('today_status_card'),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: DayveColors.border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff6450a0).withValues(alpha: .07),
                blurRadius: 22,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 900),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    fit: StackFit.expand,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild
                    ],
                  ),
                  child: Image.asset(
                    _background.assetPath,
                    key: ValueKey(_background.assetPath),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                  ),
                ),
                if (_background.weatherOverlayOpacity > 0)
                  ColoredBox(
                    color: _weatherOverlayColor(_background.weatherCondition)
                        .withValues(alpha: _background.weatherOverlayOpacity),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(
                          alpha:
                              _background.period == DayPeriod.night ? .74 : .66,
                        ),
                        Colors.white.withValues(alpha: .34),
                        Colors.white.withValues(alpha: .08),
                      ],
                      stops: const [0, .56, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(19, 17, 17, 16),
                  child: _HeroContent(
                    presentation: presentation,
                    state: widget.state,
                    value: widget.value,
                    caption: widget.caption,
                    weather: widget.weather,
                    background: _background,
                    dailyMessage: dailyMessage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _weatherOverlayColor(WeatherCondition condition) => switch (condition) {
        WeatherCondition.rain => const Color(0xff29365f),
        WeatherCondition.snow => const Color(0xffd8ecff),
        WeatherCondition.fog => Colors.white,
        WeatherCondition.cloudy => const Color(0xff72798c),
        WeatherCondition.partlyCloudy => const Color(0xff8793ad),
        WeatherCondition.clear ||
        WeatherCondition.unknown =>
          Colors.transparent,
      };
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({
    required this.presentation,
    required this.state,
    required this.value,
    required this.caption,
    required this.weather,
    required this.background,
    required this.dailyMessage,
  });

  final _StatusPresentation presentation;
  final String state;
  final String value;
  final String caption;
  final WeatherSnapshot? weather;
  final DayBackgroundState background;
  final String dailyMessage;

  @override
  Widget build(BuildContext context) {
    final temperature = weather?.temperature;
    final headline = presentation.headline(caption, value);

    return Stack(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Container(
            key: const Key('dayve_status_pill'),
            padding: const EdgeInsets.fromLTRB(9, 6, 8, 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .82),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: .9)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DAYVE · ${presentation.label}',
                  style: const TextStyle(
                    color: DayveColors.primaryPurple,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.2,
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: presentation.dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 1,
          width: 138,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                key: const Key('dayve_weather_summary'),
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    _weatherIcon(
                      background.weatherCondition,
                      background.period,
                    ),
                    size: 18,
                    color: DayveColors.primaryPurple,
                  ),
                  if (temperature != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      '${temperature.round()}°',
                      style: const TextStyle(
                        color: DayveColors.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 13,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    dailyMessage,
                    key: const Key('dayve_daily_message'),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: DayveColors.primaryPurple,
                      fontSize: 9,
                      height: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 52,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  headline,
                  key: const Key('dayve_hero_main_copy'),
                  maxLines: 1,
                  style: const TextStyle(
                    color: DayveColors.primaryText,
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.25,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                presentation.supportMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DayveColors.primaryText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _weatherIcon(WeatherCondition condition, DayPeriod period) {
    if (condition == WeatherCondition.unknown) {
      return period == DayPeriod.night
          ? Icons.nights_stay_outlined
          : Icons.wb_sunny_outlined;
    }
    return switch (condition) {
      WeatherCondition.clear => Icons.wb_sunny_outlined,
      WeatherCondition.partlyCloudy => Icons.cloud_queue_outlined,
      WeatherCondition.cloudy => Icons.cloud_outlined,
      WeatherCondition.rain => Icons.water_drop_outlined,
      WeatherCondition.snow => Icons.ac_unit_rounded,
      WeatherCondition.fog => Icons.dehaze_rounded,
      WeatherCondition.unknown => Icons.wb_sunny_outlined,
    };
  }
}

class _StatusPresentation {
  const _StatusPresentation({
    required this.label,
    required this.headline,
    required this.supportMessage,
    required this.dotColor,
  });

  final String label;
  final String Function(String caption, String value) headline;
  final String supportMessage;
  final Color dotColor;

  static _StatusPresentation forState(String state) => switch (state) {
        '휴무' => _StatusPresentation(
            label: '휴무',
            headline: (_, __) => '오늘은 쉬어도 괜찮아요',
            supportMessage: '충분히 쉬는 것도 오늘의 일이에요 💜',
            dotColor: const Color(0xffa99fc3),
          ),
        '퇴근 후' => _StatusPresentation(
            label: '내 시간',
            headline: (_, value) => '취침까지 $value',
            supportMessage: '오늘도 충분히 잘해냈어요 💜',
            dotColor: const Color(0xff8373e8),
          ),
        '근무 중' => _StatusPresentation(
            label: '근무 중',
            headline: (caption, value) => '$caption $value',
            supportMessage: '지금도 충분히 잘하고 있어요 💜',
            dotColor: const Color(0xff55b87a),
          ),
        '출근 전' => _StatusPresentation(
            label: '출근 전',
            headline: (caption, value) => '$caption $value',
            supportMessage: '오늘도 나답게 시작해 봐요 💜',
            dotColor: const Color(0xffe9a24d),
          ),
        '수면 시간' => _StatusPresentation(
            label: '수면',
            headline: (caption, value) => '$caption $value',
            supportMessage: '오늘도 정말 수고했어요 💜',
            dotColor: const Color(0xff6173c8),
          ),
        _ => _StatusPresentation(
            label: state,
            headline: (caption, value) => '$caption $value',
            supportMessage: '오늘의 흐름을 함께할게요 💜',
            dotColor: const Color(0xff8373e8),
          ),
      };
}
