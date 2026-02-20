/// Calendar panel for the DateTimePicker popup dialog.
///
/// Displays a month grid with navigation, weekday labels,
/// day selection, and a Today button.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'date_time_picker_style.dart';

/// Custom scroll behavior that enables drag scrolling for all pointer devices.
/// Flutter desktop/web disables mouse-drag by default — this override
/// re-enables it so the month and year lists can be dragged with a mouse.
class _AllDevicesDragScrollBehavior extends MaterialScrollBehavior {
  const _AllDevicesDragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
      };
}

class CalendarPanel extends StatefulWidget {
  /// Currently selected date (may be null).
  final DateTime? selectedDate;

  /// Called when the user taps a day.
  final ValueChanged<DateTime> onDateSelected;

  /// Earliest selectable date.
  final DateTime minDate;

  /// Latest selectable date.
  final DateTime maxDate;

  /// Which weekday starts the grid (e.g. DateTime.sunday = 7).
  final int firstDayOfWeek;

  /// Whether to show the Today button.
  final bool showTodayButton;

  /// Visual style.
  final DateTimePickerStyle style;

  const CalendarPanel({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.minDate,
    required this.maxDate,
    this.firstDayOfWeek = DateTime.sunday,
    this.showTodayButton = true,
    required this.style,
  });

  @override
  State<CalendarPanel> createState() => _CalendarPanelState();
}

class _CalendarPanelState extends State<CalendarPanel> {
  /// The month currently being viewed.
  late DateTime _viewMonth;

  /// Whether the month/year dropdown is open.
  bool _showMonthYearPicker = false;

  @override
  void initState() {
    super.initState();
    final ref = widget.selectedDate ?? DateTime.now();
    _viewMonth = DateTime(ref.year, ref.month);
  }

  @override
  void didUpdateWidget(covariant CalendarPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the selected date changes externally, jump view to that month.
    if (widget.selectedDate != null &&
        oldWidget.selectedDate != widget.selectedDate) {
      _viewMonth =
          DateTime(widget.selectedDate!.year, widget.selectedDate!.month);
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────

  void _previousMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() => _viewMonth = DateTime(now.year, now.month));
    widget.onDateSelected(DateTime(now.year, now.month, now.day));
  }

  // ── Weekday labels ────────────────────────────────────────────────────

  List<String> get _weekdayLabels {
    // Standard order starting from Sunday.
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    // Rotate so firstDayOfWeek is first.
    final offset = widget.firstDayOfWeek % 7; // Sunday=0 after mod
    return [
      for (int i = 0; i < 7; i++) labels[(offset + i) % 7],
    ];
  }

  // ── Day grid data ────────────────────────────────────────────────────

  /// Returns a flat list of 42 (6 weeks × 7 days) dates for the grid,
  /// starting from the first visible day.
  List<DateTime> _gridDates() {
    final first = DateTime(_viewMonth.year, _viewMonth.month, 1);
    // Weekday of the 1st (Dart: Mon=1 … Sun=7). Convert to 0-based Sun=0.
    int firstWeekday = first.weekday % 7; // Sun=0
    final offset = widget.firstDayOfWeek % 7;
    int leadingBlanks = (firstWeekday - offset + 7) % 7;

    final start = first.subtract(Duration(days: leadingBlanks));
    return List.generate(42, (i) => start.add(Duration(days: i)));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isCurrentMonth(DateTime d) =>
      d.year == _viewMonth.year && d.month == _viewMonth.month;

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final headerStyle = widget.style.headerTextStyle ??
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    final dayStyle =
        widget.style.dayTextStyle ?? const TextStyle(fontSize: 14);

    return SizedBox(
      width: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(headerStyle),
          const SizedBox(height: 8),
          _buildWeekdayRow(dayStyle),
          const SizedBox(height: 4),
          if (_showMonthYearPicker)
            _buildMonthYearPicker()
          else
            _buildDayGrid(dayStyle),
          const SizedBox(height: 8),
          _buildFooter(),
        ],
      ),
    );
  }

  // ── Header: month/year + arrows ────────────────────────────────────────

  Widget _buildHeader(TextStyle headerStyle) {
    final monthYear = DateFormat('MMMM yyyy').format(_viewMonth);
    return Row(
      children: [
        // Month navigation: previous.
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 22),
          onPressed: _previousMonth,
          splashRadius: 18,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        const Spacer(),
        // Month/year label with dropdown toggle.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () =>
              setState(() => _showMonthYearPicker = !_showMonthYearPicker),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(monthYear, style: headerStyle),
              Icon(
                _showMonthYearPicker
                    ? Icons.arrow_drop_up
                    : Icons.arrow_drop_down,
                size: 20,
              ),
            ],
          ),
        ),
        const Spacer(),
        // Month navigation: next.
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 22),
          onPressed: _nextMonth,
          splashRadius: 18,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  // ── Weekday row ────────────────────────────────────────────────────────

  Widget _buildWeekdayRow(TextStyle dayStyle) {
    return Row(
      children: _weekdayLabels.map((label) {
        return Expanded(
          child: Center(
            child: Text(
              label,
              style: dayStyle.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Day grid ──────────────────────────────────────────────────────────

  Widget _buildDayGrid(TextStyle dayStyle) {
    final dates = _gridDates();
    final today = DateTime.now();
    final rows = <Widget>[];

    for (int row = 0; row < 6; row++) {
      final cells = <Widget>[];
      for (int col = 0; col < 7; col++) {
        final date = dates[row * 7 + col];
        final inMonth = _isCurrentMonth(date);
        final isToday = _isSameDay(date, today);
        final isSelected = widget.selectedDate != null &&
            _isSameDay(date, widget.selectedDate!);

        // Decoration for selected day.
        BoxDecoration? decoration;
        Color textColor = inMonth ? Colors.black87 : Colors.grey.shade400;

        if (isSelected) {
          decoration = BoxDecoration(
            color: widget.style.accentColor,
            shape: widget.style.selectedDayShape,
            borderRadius: widget.style.selectedDayShape == BoxShape.rectangle
                ? BorderRadius.circular(6)
                : null,
          );
          textColor = Colors.white;
        } else if (isToday) {
          decoration = BoxDecoration(
            border: Border.all(color: widget.style.accentColor, width: 1.5),
            shape: widget.style.selectedDayShape,
            borderRadius: widget.style.selectedDayShape == BoxShape.rectangle
                ? BorderRadius.circular(6)
                : null,
          );
          textColor = widget.style.accentColor;
        }

        cells.add(
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                widget
                    .onDateSelected(DateTime(date.year, date.month, date.day));
                if (!inMonth) {
                  setState(
                      () => _viewMonth = DateTime(date.year, date.month));
                }
              },
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: decoration,
                child: Text(
                  '${date.day}',
                  style: dayStyle.copyWith(color: textColor),
                ),
              ),
            ),
          ),
        );
      }
      rows.add(Row(children: cells));
    }

    return Column(children: rows);
  }

  // ── Month / Year quick picker ─────────────────────────────────────────

  Widget _buildMonthYearPicker() {
    return SizedBox(
      height: 220,
      child: Row(
        children: [
          // Month list — wrapped in ScrollConfiguration to enable
          // mouse-drag scrolling on desktop/web.
          Expanded(
            child: ScrollConfiguration(
              behavior: const _AllDevicesDragScrollBehavior(),
              child: ListView.builder(
                itemCount: 12,
                itemBuilder: (context, index) {
                  final m = index + 1;
                  final isSelected = m == _viewMonth.month;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _viewMonth = DateTime(_viewMonth.year, m);
                        _showMonthYearPicker = false;
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      color: isSelected
                          ? widget.style.accentColor.withValues(alpha: 0.15)
                          : null,
                      child: Text(
                        DateFormat('MMMM').format(DateTime(2000, m)),
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? widget.style.accentColor
                              : Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          // Year list — wrapped in ScrollConfiguration to enable
          // mouse-drag scrolling on desktop/web.
          Expanded(
            child: ScrollConfiguration(
              behavior: const _AllDevicesDragScrollBehavior(),
              child: ListView.builder(
                controller: ScrollController(
                  initialScrollOffset:
                      ((_viewMonth.year - widget.minDate.year) * 36)
                          .toDouble(),
                ),
                itemCount: widget.maxDate.year - widget.minDate.year + 1,
                itemBuilder: (context, index) {
                  final y = widget.minDate.year + index;
                  final isSelected = y == _viewMonth.year;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _viewMonth = DateTime(y, _viewMonth.month);
                        _showMonthYearPicker = false;
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      height: 36,
                      color: isSelected
                          ? widget.style.accentColor.withValues(alpha: 0.15)
                          : null,
                      child: Text(
                        '$y',
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? widget.style.accentColor
                              : Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer: Today button ──────────────────────────────────────────────

  Widget _buildFooter() {
    return Row(
      children: [
        const Spacer(),
        if (widget.showTodayButton)
          TextButton(
            onPressed: _goToToday,
            child: Text(
              'Today',
              style: TextStyle(color: widget.style.accentColor),
            ),
          ),
      ],
    );
  }
}
