/// Main DateTimePicker widget.
///
/// Combines the [SegmentedInputField] with a popup dialog containing
/// [CalendarPanel] and/or [TimePickerPanel] depending on the [DateTimePickerMode].
library;

import 'package:flutter/material.dart';
import 'date_time_picker_controller.dart';
import 'date_time_picker_mode.dart';
import 'date_time_picker_style.dart';
import 'segmented_input_field.dart';
import 'calendar_panel.dart';
import 'time_picker_panel.dart';

class SegmentedDatePicker extends StatefulWidget {
  /// Controller that holds and manages the current value.
  final DateTimePickerController? controller;

  /// Initial value (used when no controller is provided).
  final DateTime? initialValue;

  /// Controls which segments and popup panels are shown.
  final DateTimePickerMode mode;

  /// Earliest selectable date.
  final DateTime minDate;

  /// Latest selectable date.
  final DateTime maxDate;

  /// Whether to use 24-hour format.
  final bool use24HourFormat;

  /// Which weekday starts the calendar grid.
  final int firstDayOfWeek;

  /// Whether to show the Today button in the calendar panel.
  final bool showTodayButton;

  /// Visual style configuration.
  final DateTimePickerStyle style;

  /// Called whenever the value changes (from segment editing or popup).
  final ValueChanged<DateTime?>? onChanged;

  /// Called when the popup dialog is dismissed (confirmed).
  final ValueChanged<DateTime?>? onConfirmed;

  SegmentedDatePicker({
    super.key,
    this.controller,
    this.initialValue,
    this.mode = DateTimePickerMode.dateTime,
    DateTime? minDate,
    DateTime? maxDate,
    this.use24HourFormat = false,
    this.firstDayOfWeek = DateTime.sunday,
    this.showTodayButton = true,
    this.style = const DateTimePickerStyle(),
    this.onChanged,
    this.onConfirmed,
  })  : minDate = minDate ?? DateTime(2000),
        maxDate = maxDate ?? DateTime(2100);

  @override
  State<SegmentedDatePicker> createState() => _SegmentedDatePickerState();
}

class _SegmentedDatePickerState extends State<SegmentedDatePicker> {
  late DateTimePickerController _controller;
  bool _ownsController = false;

  /// Segment focus request from the controller.
  DateTimeSegment? _requestedSegment;

  // ── Lifecycle ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller =
          DateTimePickerController(initialValue: widget.initialValue);
      _ownsController = true;
    }
    _controller.onFocusSegmentRequested = (seg) {
      setState(() => _requestedSegment = seg);
    };
    _controller.addListener(_onControllerChange);
  }

  @override
  void didUpdateWidget(covariant SegmentedDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onControllerChange);
      if (widget.controller != null) {
        if (_ownsController) _controller.dispose();
        _controller = widget.controller!;
        _ownsController = false;
      }
      _controller.addListener(_onControllerChange);
      _controller.onFocusSegmentRequested = (seg) {
        setState(() => _requestedSegment = seg);
      };
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    // Rebuild when controller value changes.
    setState(() {});
    widget.onChanged?.call(_controller.value);
  }

  // ── Input field callbacks ─────────────────────────────────────────────

  void _onFieldChanged(DateTime? value) {
    _controller.setValue(value);
  }

  // ── Popup dialog ──────────────────────────────────────────────────────

  Future<void> _showPickerDialog() async {
    // Snapshot the current value — dialog works on its own copy.
    final DateTime dialogInitial = _controller.value ?? DateTime.now();

    final DateTime? result = await showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) {
        return _PickerDialog(
          initialValue: dialogInitial,
          mode: widget.mode,
          use24HourFormat: widget.use24HourFormat,
          firstDayOfWeek: widget.firstDayOfWeek,
          showTodayButton: widget.showTodayButton,
          minDate: widget.minDate,
          maxDate: widget.maxDate,
          style: widget.style,
        );
      },
    );

    // Only apply if user pressed OK (result is non-null).
    if (result != null) {
      _controller.setValue(result);
      widget.onConfirmed?.call(result);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SegmentedInputField(
      mode: widget.mode,
      use24HourFormat: widget.use24HourFormat,
      value: _controller.value,
      onChanged: _onFieldChanged,
      onCalendarTap: _showPickerDialog,
      style: widget.style,
      minDate: widget.minDate,
      maxDate: widget.maxDate,
      requestedFocusSegment: _requestedSegment,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Popup dialog — combines CalendarPanel and TimePickerPanel.
// ═══════════════════════════════════════════════════════════════════════════

class _PickerDialog extends StatefulWidget {
  final DateTime initialValue;
  final DateTimePickerMode mode;
  final bool use24HourFormat;
  final int firstDayOfWeek;
  final bool showTodayButton;
  final DateTime minDate;
  final DateTime maxDate;
  final DateTimePickerStyle style;

  const _PickerDialog({
    required this.initialValue,
    required this.mode,
    required this.use24HourFormat,
    required this.firstDayOfWeek,
    required this.showTodayButton,
    required this.minDate,
    required this.maxDate,
    required this.style,
  });

  @override
  State<_PickerDialog> createState() => _PickerDialogState();
}

class _PickerDialogState extends State<_PickerDialog> {
  late DateTime _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _value = DateTime(
        date.year,
        date.month,
        date.day,
        _value.hour,
        _value.minute,
      );
    });
  }

  void _onTimeChanged(int hour, int minute) {
    setState(() {
      _value = DateTime(
        _value.year,
        _value.month,
        _value.day,
        hour,
        minute,
      );
    });
  }

  void _onOk() {
    Navigator.of(context).pop(_value);
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool showCalendar = widget.mode == DateTimePickerMode.date ||
        widget.mode == DateTimePickerMode.dateTime;
    final bool showTime = widget.mode == DateTimePickerMode.time ||
        widget.mode == DateTimePickerMode.dateTime;

    // Use LayoutBuilder to decide between horizontal (wide) and vertical
    // (narrow / mobile) layouts. On narrow screens the two panels stack.
    return Center(
      child: Material(
        color: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, outerConstraints) {
            // Threshold: if less than 540 logical pixels wide, go vertical.
            final bool isNarrow = outerConstraints.maxWidth < 540;

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isNarrow ? outerConstraints.maxWidth - 32 : 600,
                maxHeight: outerConstraints.maxHeight - 32,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.style.dialogBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: isNarrow
                    ? _buildVerticalLayout(showCalendar, showTime)
                    : _buildHorizontalLayout(showCalendar, showTime),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _onCancel,
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _onOk,
          style: FilledButton.styleFrom(
            backgroundColor: widget.style.accentColor,
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }

  /// Wide layout: calendar and time side by side.
  Widget _buildHorizontalLayout(bool showCalendar, bool showTime) {
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showCalendar)
                  CalendarPanel(
                    selectedDate: _value,
                    onDateSelected: _onDateSelected,
                    minDate: widget.minDate,
                    maxDate: widget.maxDate,
                    firstDayOfWeek: widget.firstDayOfWeek,
                    showTodayButton: widget.showTodayButton,
                    style: widget.style,
                  ),
                if (showCalendar && showTime)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                  ),
                if (showTime)
                  TimePickerPanel(
                    hour: _value.hour,
                    minute: _value.minute,
                    use24HourFormat: widget.use24HourFormat,
                    onTimeChanged: _onTimeChanged,
                    style: widget.style,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// Narrow / mobile layout: calendar on top, time below.
  Widget _buildVerticalLayout(bool showCalendar, bool showTime) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCalendar)
            CalendarPanel(
              selectedDate: _value,
              onDateSelected: _onDateSelected,
              minDate: widget.minDate,
              maxDate: widget.maxDate,
              firstDayOfWeek: widget.firstDayOfWeek,
              showTodayButton: widget.showTodayButton,
              style: widget.style,
            ),
          if (showCalendar && showTime)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                height: 1,
                color: Colors.grey.shade300,
              ),
            ),
          if (showTime)
            TimePickerPanel(
              hour: _value.hour,
              minute: _value.minute,
              use24HourFormat: widget.use24HourFormat,
              onTimeChanged: _onTimeChanged,
              style: widget.style,
            ),
          const SizedBox(height: 12),
          _buildActionButtons(),
        ],
      ),
    );
  }
}
