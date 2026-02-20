/// Segmented input field for date and/or time editing.
///
/// Divides the input into individually focusable segments (MM, dd, yyyy, hh, mm, AM/PM).
/// Supports keyboard navigation (arrows, digit typing, A/P for period),
/// auto-advance on segment completion, and real-time value updates.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'date_time_picker_mode.dart';
import 'date_time_picker_style.dart';

/// Callback signature when the segmented field value changes.
typedef SegmentedValueChanged = void Function(DateTime? value);

class SegmentedInputField extends StatefulWidget {
  /// Which segments to display.
  final DateTimePickerMode mode;

  /// Whether to use 24-hour format (hides AM/PM segment).
  final bool use24HourFormat;

  /// Current value to display.
  final DateTime? value;

  /// Called when the value changes through segment editing.
  final SegmentedValueChanged onChanged;

  /// Called when the calendar icon is tapped.
  final VoidCallback onCalendarTap;

  /// Visual style.
  final DateTimePickerStyle style;

  /// Minimum allowed date (for year clamping).
  final DateTime minDate;

  /// Maximum allowed date (for year clamping).
  final DateTime maxDate;

  /// Externally requested segment to focus.
  final DateTimeSegment? requestedFocusSegment;

  const SegmentedInputField({
    super.key,
    required this.mode,
    required this.use24HourFormat,
    required this.value,
    required this.onChanged,
    required this.onCalendarTap,
    required this.style,
    required this.minDate,
    required this.maxDate,
    this.requestedFocusSegment,
  });

  @override
  State<SegmentedInputField> createState() => SegmentedInputFieldState();
}

class SegmentedInputFieldState extends State<SegmentedInputField> {
  /// Which segment is currently focused (null = none).
  DateTimeSegment? _focusedSegment;

  /// Per-segment nullable values — null means placeholder shown.
  int? _month;
  int? _day;
  int? _year;
  int? _hour; // stored in 24h internally
  int? _minute;
  bool _isPm = false;

  /// Buffer for multi-digit keyboard input.
  String _inputBuffer = '';

  /// Guard: true while we are emitting a change from our own editing.
  /// Prevents [didUpdateWidget] from overwriting partially-cleared segments.
  bool _selfEditing = false;

  final FocusNode _focusNode = FocusNode();

  /// Hidden text controller used to raise the soft keyboard on mobile.
  final TextEditingController _hiddenTextController = TextEditingController();
  final FocusNode _hiddenFocusNode = FocusNode();

  // ── Segment ordering helpers ──────────────────────────────────────────

  /// Returns the list of segments for the current mode.
  List<DateTimeSegment> get _segments {
    final List<DateTimeSegment> segs = [];
    if (widget.mode == DateTimePickerMode.date ||
        widget.mode == DateTimePickerMode.dateTime) {
      segs.addAll([
        DateTimeSegment.month,
        DateTimeSegment.day,
        DateTimeSegment.year,
      ]);
    }
    if (widget.mode == DateTimePickerMode.time ||
        widget.mode == DateTimePickerMode.dateTime) {
      segs.addAll([
        DateTimeSegment.hour,
        DateTimeSegment.minute,
        if (!widget.use24HourFormat) DateTimeSegment.period,
      ]);
    }
    return segs;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _syncFromValue(widget.value);
    _focusNode.addListener(_onFocusChange);
    _hiddenTextController.addListener(_onHiddenTextChanged);
  }

  @override
  void didUpdateWidget(covariant SegmentedInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync if value changed externally (e.g. from calendar/time panel),
    // but NOT if we ourselves triggered the change (partial clear).
    if (widget.value != oldWidget.value && !_selfEditing) {
      _syncFromValue(widget.value);
    }
    _selfEditing = false;
    // Handle programmatic focus requests.
    if (widget.requestedFocusSegment != null &&
        widget.requestedFocusSegment != oldWidget.requestedFocusSegment) {
      setState(() => _focusedSegment = widget.requestedFocusSegment);
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _hiddenTextController.removeListener(_onHiddenTextChanged);
    _hiddenTextController.dispose();
    _hiddenFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      setState(() => _focusedSegment = null);
    }
  }

  /// Called when the user types into the hidden TextField (mobile keyboard).
  void _onHiddenTextChanged() {
    final text = _hiddenTextController.text;
    if (text.isEmpty || _focusedSegment == null) return;

    // Process each character the user typed.
    for (final ch in text.characters) {
      if (_focusedSegment == null) break;
      final seg = _focusedSegment!;

      if (seg == DateTimeSegment.period) {
        if (ch.toUpperCase() == 'A') _setPeriod(false);
        if (ch.toUpperCase() == 'P') _setPeriod(true);
      } else if (RegExp(r'\d').hasMatch(ch)) {
        _handleDigitInput(seg, ch);
      }
    }

    // Clear the hidden field so the next keystroke is captured fresh.
    _hiddenTextController.clear();
  }

  /// Focuses a segment and opens the soft keyboard (mobile).
  void _focusSegmentAndOpenKeyboard(DateTimeSegment seg) {
    setState(() {
      _focusedSegment = seg;
      _inputBuffer = '';
    });
    _focusNode.requestFocus();

    // For period segment, just toggle — no keyboard needed.
    if (seg == DateTimeSegment.period) {
      _setPeriod(!_isPm);
      return;
    }

    // Raise the soft keyboard via the hidden TextField.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hiddenFocusNode.requestFocus();
    });
  }

  /// Populates segment values from a [DateTime].
  void _syncFromValue(DateTime? dt) {
    if (dt == null) {
      _month = null;
      _day = null;
      _year = null;
      _hour = null;
      _minute = null;
      _isPm = false;
    } else {
      _month = dt.month;
      _day = dt.day;
      _year = dt.year;
      _hour = dt.hour;
      _minute = dt.minute;
      _isPm = dt.hour >= 12;
    }
  }

  // ── Value assembly ────────────────────────────────────────────────────

  /// Builds a [DateTime] from current segment values, or null if incomplete.
  DateTime? _buildDateTime() {
    final bool needsDate = widget.mode == DateTimePickerMode.date ||
        widget.mode == DateTimePickerMode.dateTime;
    final bool needsTime = widget.mode == DateTimePickerMode.time ||
        widget.mode == DateTimePickerMode.dateTime;

    if (needsDate && (_month == null || _day == null || _year == null)) {
      return null;
    }
    if (needsTime && (_hour == null || _minute == null)) {
      return null;
    }

    final int y = _year ?? DateTime.now().year;
    final int m = _month ?? 1;
    final int d = _day ?? 1;
    final int h = _hour ?? 0;
    final int min = _minute ?? 0;

    // Clamp day to valid range for the month.
    final int maxDay = DateUtils.getDaysInMonth(y, m);
    final int clampedDay = d.clamp(1, maxDay);

    return DateTime(y, m, clampedDay, h, min);
  }

  void _emitChange() {
    _selfEditing = true;
    widget.onChanged(_buildDateTime());
  }

  // ── Display helpers ───────────────────────────────────────────────────

  /// Returns the display string for a segment.
  String _segmentText(DateTimeSegment seg) {
    switch (seg) {
      case DateTimeSegment.month:
        return _month != null ? _month.toString().padLeft(2, '0') : 'MM';
      case DateTimeSegment.day:
        return _day != null ? _day.toString().padLeft(2, '0') : 'dd';
      case DateTimeSegment.year:
        return _year != null ? _year.toString().padLeft(4, '0') : 'yyyy';
      case DateTimeSegment.hour:
        if (_hour == null) return 'hh';
        if (widget.use24HourFormat) {
          return _hour.toString().padLeft(2, '0');
        } else {
          int h12 = _hour! % 12;
          if (h12 == 0) h12 = 12;
          return h12.toString().padLeft(2, '0');
        }
      case DateTimeSegment.minute:
        return _minute != null ? _minute.toString().padLeft(2, '0') : 'mm';
      case DateTimeSegment.period:
        return _isPm ? 'PM' : 'AM';
    }
  }

  /// Whether the segment is currently showing a placeholder.
  bool _isPlaceholder(DateTimeSegment seg) {
    switch (seg) {
      case DateTimeSegment.month:
        return _month == null;
      case DateTimeSegment.day:
        return _day == null;
      case DateTimeSegment.year:
        return _year == null;
      case DateTimeSegment.hour:
        return _hour == null;
      case DateTimeSegment.minute:
        return _minute == null;
      case DateTimeSegment.period:
        return false; // always shows AM or PM
    }
  }

  // ── Keyboard handling ─────────────────────────────────────────────────

  /// Returns the maximum character length for a segment.
  int _maxDigits(DateTimeSegment seg) {
    switch (seg) {
      case DateTimeSegment.month:
      case DateTimeSegment.day:
      case DateTimeSegment.hour:
      case DateTimeSegment.minute:
        return 2;
      case DateTimeSegment.year:
        return 4;
      case DateTimeSegment.period:
        return 1;
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_focusedSegment == null) return KeyEventResult.ignored;

    final seg = _focusedSegment!;
    final key = event.logicalKey;

    // Arrow Left / Right — move between segments.
    if (key == LogicalKeyboardKey.arrowLeft) {
      _moveFocus(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _moveFocus(1);
      return KeyEventResult.handled;
    }

    // Tab — move forward (shift+tab = backward).
    if (key == LogicalKeyboardKey.tab) {
      final shift = HardwareKeyboard.instance.isShiftPressed;
      _moveFocus(shift ? -1 : 1);
      return KeyEventResult.handled;
    }

    // Arrow Up / Down — increment / decrement.
    if (key == LogicalKeyboardKey.arrowUp) {
      _incrementSegment(seg, 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _incrementSegment(seg, -1);
      return KeyEventResult.handled;
    }

    // A / P for AM/PM toggle.
    if (seg == DateTimeSegment.period) {
      if (key == LogicalKeyboardKey.keyA) {
        _setPeriod(false);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyP) {
        _setPeriod(true);
        return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }

    // Digit input.
    final String? digit = _digitFromKey(key);
    if (digit != null) {
      _handleDigitInput(seg, digit);
      return KeyEventResult.handled;
    }

    // Backspace — clear current segment.
    if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      _clearSegment(seg);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  String? _digitFromKey(LogicalKeyboardKey key) {
    final digits = {
      LogicalKeyboardKey.digit0: '0',
      LogicalKeyboardKey.digit1: '1',
      LogicalKeyboardKey.digit2: '2',
      LogicalKeyboardKey.digit3: '3',
      LogicalKeyboardKey.digit4: '4',
      LogicalKeyboardKey.digit5: '5',
      LogicalKeyboardKey.digit6: '6',
      LogicalKeyboardKey.digit7: '7',
      LogicalKeyboardKey.digit8: '8',
      LogicalKeyboardKey.digit9: '9',
      LogicalKeyboardKey.numpad0: '0',
      LogicalKeyboardKey.numpad1: '1',
      LogicalKeyboardKey.numpad2: '2',
      LogicalKeyboardKey.numpad3: '3',
      LogicalKeyboardKey.numpad4: '4',
      LogicalKeyboardKey.numpad5: '5',
      LogicalKeyboardKey.numpad6: '6',
      LogicalKeyboardKey.numpad7: '7',
      LogicalKeyboardKey.numpad8: '8',
      LogicalKeyboardKey.numpad9: '9',
    };
    return digits[key];
  }

  void _handleDigitInput(DateTimeSegment seg, String digit) {
    _inputBuffer += digit;
    final int parsed = int.parse(_inputBuffer);

    setState(() {
      switch (seg) {
        case DateTimeSegment.month:
          _month = parsed.clamp(0, 12);
          if (_month == 0 && _inputBuffer.length >= 2) _month = 1;
        case DateTimeSegment.day:
          final maxDay = _month != null && _year != null
              ? DateUtils.getDaysInMonth(_year!, _month!)
              : 31;
          _day = parsed.clamp(0, maxDay);
          if (_day == 0 && _inputBuffer.length >= 2) _day = 1;
        case DateTimeSegment.year:
          _year = parsed.clamp(0, 9999);
        case DateTimeSegment.hour:
          if (widget.use24HourFormat) {
            _hour = parsed.clamp(0, 23);
          } else {
            int h12 = parsed.clamp(0, 12);
            if (h12 == 0 && _inputBuffer.length >= 2) h12 = 1;
            // Convert 12h to 24h for internal storage.
            if (_isPm) {
              _hour = h12 == 12 ? 12 : h12 + 12;
            } else {
              _hour = h12 == 12 ? 0 : h12;
            }
          }
        case DateTimeSegment.minute:
          _minute = parsed.clamp(0, 59);
        case DateTimeSegment.period:
          break; // handled separately
      }
    });

    _emitChange();

    // Auto-advance when segment is fully typed.
    if (_inputBuffer.length >= _maxDigits(seg)) {
      _inputBuffer = '';
      _moveFocus(1);
    }
  }

  void _clearSegment(DateTimeSegment seg) {
    setState(() {
      _inputBuffer = '';
      switch (seg) {
        case DateTimeSegment.month:
          _month = null;
        case DateTimeSegment.day:
          _day = null;
        case DateTimeSegment.year:
          _year = null;
        case DateTimeSegment.hour:
          _hour = null;
        case DateTimeSegment.minute:
          _minute = null;
        case DateTimeSegment.period:
          _isPm = false;
      }
    });
    _emitChange();
  }

  void _incrementSegment(DateTimeSegment seg, int delta) {
    setState(() {
      switch (seg) {
        case DateTimeSegment.month:
          _month = ((_month ?? 1) - 1 + delta) % 12 + 1;
        case DateTimeSegment.day:
          final maxDay = _month != null && _year != null
              ? DateUtils.getDaysInMonth(_year!, _month!)
              : 31;
          int d = (_day ?? 1) + delta;
          if (d < 1) d = maxDay;
          if (d > maxDay) d = 1;
          _day = d;
        case DateTimeSegment.year:
          _year = ((_year ?? DateTime.now().year) + delta)
              .clamp(widget.minDate.year, widget.maxDate.year);
        case DateTimeSegment.hour:
          if (widget.use24HourFormat) {
            _hour = ((_hour ?? 0) + delta) % 24;
            if (_hour! < 0) _hour = _hour! + 24;
          } else {
            int h12 =
                _hour != null ? (_hour! % 12 == 0 ? 12 : _hour! % 12) : 12;
            h12 += delta;
            if (h12 < 1) h12 = 12;
            if (h12 > 12) h12 = 1;
            if (_isPm) {
              _hour = h12 == 12 ? 12 : h12 + 12;
            } else {
              _hour = h12 == 12 ? 0 : h12;
            }
          }
        case DateTimeSegment.minute:
          _minute = ((_minute ?? 0) + delta) % 60;
          if (_minute! < 0) _minute = _minute! + 60;
        case DateTimeSegment.period:
          _setPeriod(!_isPm);
          return;
      }
    });
    _emitChange();
  }

  void _setPeriod(bool pm) {
    if (_isPm == pm) return;
    setState(() {
      _isPm = pm;
      // Adjust internal 24h hour to match.
      if (_hour != null) {
        if (pm && _hour! < 12) {
          _hour = _hour! + 12;
        } else if (!pm && _hour! >= 12) {
          _hour = _hour! - 12;
        }
      }
    });
    _emitChange();
  }

  void _moveFocus(int direction) {
    final segs = _segments;
    if (_focusedSegment == null) return;
    final idx = segs.indexOf(_focusedSegment!);
    final newIdx = idx + direction;
    _inputBuffer = '';
    if (newIdx >= 0 && newIdx < segs.length) {
      setState(() => _focusedSegment = segs[newIdx]);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final segs = _segments;
    final inputStyle = widget.style.inputTextStyle ??
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
    final activeStyle = widget.style.activeSegmentTextStyle ??
        inputStyle.copyWith(fontWeight: FontWeight.w700);
    // Separator color matches the normal text color.
    final separatorStyle = widget.style.separatorTextStyle ??
        inputStyle.copyWith(
          color: inputStyle.color ?? Colors.black87,
        );

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // If no segment focused yet, focus the first one.
          if (_focusedSegment == null && segs.isNotEmpty) {
            _focusSegmentAndOpenKeyboard(segs.first);
          } else {
            _focusNode.requestFocus();
          }
        },
        child: Stack(
          children: [
            // Hidden TextField to trigger mobile soft keyboard.
            Positioned(
              left: -9999,
              child: SizedBox(
                width: 1,
                height: 1,
                child: TextField(
                  controller: _hiddenTextController,
                  focusNode: _hiddenFocusNode,
                  keyboardType: _focusedSegment == DateTimeSegment.period
                      ? TextInputType.text
                      : TextInputType.number,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  style: const TextStyle(fontSize: 1),
                ),
              ),
            ),
            _buildFieldContainer(segs, inputStyle, activeStyle, separatorStyle),
          ],
        ),
      ),
    );
  }

  /// Builds the outer container — either with [InputDecoration] or a simple
  /// border, depending on [widget.style.inputDecoration].
  Widget _buildFieldContainer(
    List<DateTimeSegment> segs,
    TextStyle inputStyle,
    TextStyle activeStyle,
    TextStyle separatorStyle,
  ) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._buildSegmentWidgets(segs, inputStyle, activeStyle, separatorStyle),
        const SizedBox(width: 8),
        // Calendar / clock icon.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onCalendarTap,
          child: Icon(
            widget.mode == DateTimePickerMode.time
                ? Icons.access_time
                : Icons.calendar_today,
            size: 20,
            color: widget.style.accentColor,
          ),
        ),
      ],
    );

    final double? height = widget.style.inputHeight;

    // If the user supplied an InputDecoration, use InputDecorator for
    // TextFormField-like borders (outline, underline, filled, etc.).
    if (widget.style.inputDecoration != null) {
      return SizedBox(
        height: height,
        child: InputDecorator(
          isFocused: _focusNode.hasFocus,
          decoration: widget.style.inputDecoration!,
          child: row,
        ),
      );
    }

    // Default: simple container with thin border.
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(
          color: _focusNode.hasFocus
              ? widget.style.accentColor
              : Colors.grey.shade400,
          width: _focusNode.hasFocus ? 2 : 1,
        ),
        borderRadius: widget.style.inputBorderRadius,
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: row,
    );
  }

  List<Widget> _buildSegmentWidgets(
    List<DateTimeSegment> segs,
    TextStyle inputStyle,
    TextStyle activeStyle,
    TextStyle separatorStyle,
  ) {
    final List<Widget> widgets = [];

    for (int i = 0; i < segs.length; i++) {
      final seg = segs[i];

      // Add separator before this segment if needed.
      if (i > 0) {
        final prevSeg = segs[i - 1];
        final sep = _separator(prevSeg, seg);
        if (sep != null) {
          widgets.add(
            Text(sep, style: separatorStyle),
          );
        }
      }

      // The segment chip — clickable text, bold when active.
      final isFocused = _focusedSegment == seg;
      final isPlaceholder = _isPlaceholder(seg);
      final baseStyle = isFocused ? activeStyle : inputStyle;

      widgets.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _focusSegmentAndOpenKeyboard(seg);
          },
          child: Text(
            _segmentText(seg),
            style: baseStyle.copyWith(
              color: isPlaceholder
                  ? Colors.grey.shade400
                  : (baseStyle.color ?? Colors.black87),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  /// Returns the separator string between two adjacent segments, or null.
  String? _separator(DateTimeSegment prev, DateTimeSegment next) {
    // Date separators: /
    if ((prev == DateTimeSegment.month && next == DateTimeSegment.day) ||
        (prev == DateTimeSegment.day && next == DateTimeSegment.year)) {
      return '/';
    }
    // Time separator: :
    if (prev == DateTimeSegment.hour && next == DateTimeSegment.minute) {
      return ':';
    }
    // Between date and time groups: ,
    if (prev == DateTimeSegment.year && next == DateTimeSegment.hour) {
      return ',';
    }
    // Space before AM/PM.
    if (next == DateTimeSegment.period) {
      return ' ';
    }
    return null;
  }
}
