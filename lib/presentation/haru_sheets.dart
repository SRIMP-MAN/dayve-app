import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<TimeOfDay?> showHaruTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  required String title,
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xfffbfaff),
    builder: (context) => _HaruTimePickerSheet(
      initialTime: initialTime,
      title: title,
    ),
  );
}

Future<int?> showHaruSpendInput({
  required BuildContext context,
  required int initialAmount,
}) {
  return showHaruAmountInput(
    context: context,
    initialAmount: initialAmount,
    title: '오늘 쓴 돈',
  );
}

Future<int?> showHaruAmountInput({
  required BuildContext context,
  required int initialAmount,
  required String title,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xfffbfaff),
    builder: (context) => _HaruSpendSheet(
      initialAmount: initialAmount,
      title: title,
    ),
  );
}

class _HaruTimePickerSheet extends StatefulWidget {
  const _HaruTimePickerSheet({
    required this.initialTime,
    required this.title,
  });

  final TimeOfDay initialTime;
  final String title;

  @override
  State<_HaruTimePickerSheet> createState() => _HaruTimePickerSheetState();
}

class _HaruTimePickerSheetState extends State<_HaruTimePickerSheet> {
  static const _itemExtent = 42.0;
  static final _hours = List<int>.generate(24, (index) => index);
  static final _minutes = List<int>.generate(12, (index) => index * 5);

  late int _hour;
  late int _minuteIndex;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  int get _minute => _minutes[_minuteIndex];

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minuteIndex = ((widget.initialTime.minute / 5).round()).clamp(0, 11);
    _hourController = FixedExtentScrollController(initialItem: _hour);
    _minuteController = FixedExtentScrollController(
      initialItem: _minuteIndex,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final wheelHeight = (screenHeight * .23).clamp(112.0, 164.0);
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.only(bottom: insets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 7, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xffd8d5e5),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xff24222d),
                    ),
              ),
              const SizedBox(height: 3),
              const Text(
                '24시간제 · 5분 단위',
                style: TextStyle(color: Color(0xff777382)),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xffebe7f1)),
                ),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 5),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              '시간',
                              style: TextStyle(
                                color: Color(0xff777382),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 28),
                        Expanded(
                          child: Center(
                            child: Text(
                              '분',
                              style: TextStyle(
                                color: Color(0xff777382),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: wheelHeight,
                      child: Row(
                        children: [
                          Expanded(
                            child: _TimeWheel(
                              key: const Key('haru_time_hour'),
                              semanticLabel: '시간 선택',
                              controller: _hourController,
                              values: _hours,
                              onSelected: (index) {
                                setState(() => _hour = _hours[index]);
                              },
                            ),
                          ),
                          const SizedBox(
                            width: 28,
                            child: Center(
                              child: Text(
                                ':',
                                style: TextStyle(
                                  color: Color(0xff6657b5),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _TimeWheel(
                              key: const Key('haru_time_minute'),
                              semanticLabel: '분 선택',
                              controller: _minuteController,
                              values: _minutes,
                              onSelected: (index) {
                                setState(() => _minuteIndex = index);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const Key('haru_time_confirm'),
                      onPressed: () => Navigator.of(context).pop(
                        TimeOfDay(hour: _hour, minute: _minute),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        visualDensity: VisualDensity.compact,
                      ),
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
  }
}

class _TimeWheel extends StatelessWidget {
  const _TimeWheel({
    required this.semanticLabel,
    required this.controller,
    required this.values,
    required this.onSelected,
    super.key,
  });

  final String semanticLabel;
  final FixedExtentScrollController controller;
  final List<int> values;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: _HaruTimePickerSheetState._itemExtent,
        useMagnifier: true,
        magnification: 1.16,
        squeeze: 1.12,
        diameterRatio: 1.35,
        selectionOverlay: const _WheelSelectionOverlay(),
        onSelectedItemChanged: onSelected,
        children: [
          for (final value in values)
            Center(
              child: Text(
                value.toString().padLeft(2, '0'),
                style: const TextStyle(
                  color: Color(0xff24222d),
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WheelSelectionOverlay extends StatelessWidget {
  const _WheelSelectionOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('haru_wheel_selection'),
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x127565c8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x667565c8), width: 1),
      ),
    );
  }
}

class _HaruSpendSheet extends StatefulWidget {
  const _HaruSpendSheet({
    required this.initialAmount,
    required this.title,
  });

  final int initialAmount;
  final String title;

  @override
  State<_HaruSpendSheet> createState() => _HaruSpendSheetState();
}

class _HaruSpendSheetState extends State<_HaruSpendSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialAmount == 0 ? '' : '${widget.initialAmount}',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addQuickAmount(int amount) {
    final current = int.tryParse(_controller.text) ?? 0;
    _controller.text = '${current + amount}';
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  void _appendDigit(int digit) {
    if (_controller.text.length >= 9) return;
    final current = _controller.text == '0' ? '' : _controller.text;
    setState(() => _controller.text = '$current$digit');
  }

  void _backspace() {
    if (_controller.text.isEmpty) return;
    setState(() {
      _controller.text = _controller.text.substring(
        0,
        _controller.text.length - 1,
      );
    });
  }

  void _clear() => setState(_controller.clear);

  void _submit() {
    final amount = int.tryParse(
      _controller.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (amount != null && amount >= 0) Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetHeight = screenHeight * .45;
    return SafeArea(
      child: SizedBox(
        height: sheetHeight,
        child: SingleChildScrollView(
          key: const Key('spend_sheet_scroll'),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('취소'),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              TextField(
                key: const Key('spend_amount_field'),
                controller: _controller,
                readOnly: true,
                showCursor: false,
                canRequestFocus: false,
                enableInteractiveSelection: false,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xff24222d),
                    ),
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: '원',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  for (final amount in const [10000, 30000, 50000])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: OutlinedButton(
                          key: Key('spend_quick_$amount'),
                          onPressed: () => _addQuickAmount(amount),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(30),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('+${amount ~/ 10000}만원'),
                        ),
                      ),
                    ),
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('spend_clear'),
                      onPressed: _clear,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(30),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('초기화'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _keyRow([
                _digitKey(1),
                _digitKey(2),
                _digitKey(3),
                _actionKey(
                  key: const Key('spend_backspace'),
                  icon: Icons.backspace_outlined,
                  onPressed: _backspace,
                ),
              ]),
              _keyRow([
                _digitKey(4),
                _digitKey(5),
                _digitKey(6),
                _digitKey(0),
              ]),
              _keyRow([
                _digitKey(7),
                _digitKey(8),
                _digitKey(9),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: FilledButton(
                      key: const Key('spend_confirm'),
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(34),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('저장'),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _keyRow(List<Widget> children) => Row(children: children);

  Widget _digitKey(int digit) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: TextButton(
          key: Key('spend_key_$digit'),
          onPressed: () => _appendDigit(digit),
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(34),
            foregroundColor: const Color(0xff24222d),
            backgroundColor: Colors.white,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            '$digit',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _actionKey({
    required Key key,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: TextButton(
          key: key,
          onPressed: onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(34),
            foregroundColor: const Color(0xff6657b5),
            backgroundColor: const Color(0xffeeeafa),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Icon(icon, size: 19),
        ),
      ),
    );
  }
}
