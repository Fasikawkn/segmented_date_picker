/// Time picker panel with vertically scrollable columns.
///
/// Displays Hour, Minute, and optionally AM/PM columns with looping scroll,
/// snap-to-item behavior, and accent-color highlighting of the selected item.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'date_time_picker_style.dart';

/// Custom scroll behavior that enables drag scrolling for all pointer devices
/// (mouse, touch, stylus, trackpad). Flutter desktop/web disables mouse-drag
/// by default — this override re-enables it.
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

class TimePickerPanel extends StatefulWidget {
  /// Current hour (0–23).
  final int hour;

  /// Current minute (0–59).
  final int minute;

  /// Whether to use 24-hour format (hides AM/PM column).
  final bool use24HourFormat;

  /// Called when the time changes.
  final void Function(int hour, int minute) onTimeChanged;

  /// Visual style.
  final DateTimePickerStyle style;

  const TimePickerPanel({
    super.key,
    required this.hour,
    required this.minute,
    required this.use24HourFormat,
    required this.onTimeChanged,
    required this.style,
  });

  @override
  State<TimePickerPanel> createState() => _TimePickerPanelState();
}

class _TimePickerPanelState extends State<TimePickerPanel> {
  /// Item height for each scroll item.
  static const double _itemHeight = 40.0;

  /// Number of visible items above and below the selected item.
  static const int _visibleSideItems = 3;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _periodController;

  /// Tracks whether each column is currently being scrolled by the user.
  /// When true, we skip jumpToItem in didUpdateWidget so we don't
  /// interrupt the ongoing scroll gesture.
  bool _hourScrolling = false;
  bool _minuteScrolling = false;
  bool _periodScrolling = false;

  // ── Derived values ────────────────────────────────────────────────────

  int get _hourCount => widget.use24HourFormat ? 24 : 12;
  bool get _isPm => widget.hour >= 12;

  int get _hourIndex {
    if (widget.use24HourFormat) return widget.hour;
    int h12 = widget.hour % 12;
    // In 12h mode, display values are 1–12, index 0 = 1, index 11 = 12.
    return h12 == 0 ? 11 : h12 - 1;
  }

  int get _minuteIndex => widget.minute;
  int get _periodIndex => _isPm ? 1 : 0;

  // ── Lifecycle ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _hourController = FixedExtentScrollController(initialItem: _hourIndex);
    _minuteController =
        FixedExtentScrollController(initialItem: _minuteIndex);
    _periodController =
        FixedExtentScrollController(initialItem: _periodIndex);
  }

  @override
  void didUpdateWidget(covariant TimePickerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only sync scroll positions when the value changes externally
    // (NOT when it changed because the user is actively scrolling).
    if (widget.hour != oldWidget.hour && !_hourScrolling) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_hourController.hasClients) {
          _hourController.jumpToItem(_hourIndex);
        }
        if (!widget.use24HourFormat &&
            _periodController.hasClients &&
            !_periodScrolling) {
          _periodController.jumpToItem(_periodIndex);
        }
      });
    }
    if (widget.minute != oldWidget.minute && !_minuteScrolling) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_minuteController.hasClients) {
          _minuteController.jumpToItem(_minuteIndex);
        }
      });
    }
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  // ── Callbacks ─────────────────────────────────────────────────────────

  void _onHourChanged(int index) {
    int newHour;
    if (widget.use24HourFormat) {
      newHour = index % 24;
    } else {
      // index 0 = 1, index 11 = 12
      int h12 = (index % 12) + 1;
      if (_isPm) {
        newHour = h12 == 12 ? 12 : h12 + 12;
      } else {
        newHour = h12 == 12 ? 0 : h12;
      }
    }
    widget.onTimeChanged(newHour, widget.minute);
  }

  void _onMinuteChanged(int index) {
    widget.onTimeChanged(widget.hour, index % 60);
  }

  void _onPeriodChanged(int index) {
    final pm = (index % 2) == 1;
    int newHour = widget.hour;
    if (pm && newHour < 12) {
      newHour += 12;
    } else if (!pm && newHour >= 12) {
      newHour -= 12;
    }
    widget.onTimeChanged(newHour, widget.minute);
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.use24HourFormat ? 160 : 220,
      height: _itemHeight * (2 * _visibleSideItems + 1),
      child: Row(
        children: [
          // ── Hour column ──
          Expanded(
            child: _buildColumn(
              controller: _hourController,
              itemCount: _hourCount,
              labelBuilder: (index) {
                if (widget.use24HourFormat) {
                  return (index % 24).toString().padLeft(2, '0');
                } else {
                  return ((index % 12) + 1).toString().padLeft(2, '0');
                }
              },
              selectedIndex: _hourIndex,
              onChanged: _onHourChanged,
              onScrollingChanged: (v) => _hourScrolling = v,
            ),
          ),
          // ── Minute column ──
          Expanded(
            child: _buildColumn(
              controller: _minuteController,
              itemCount: 60,
              labelBuilder: (index) =>
                  (index % 60).toString().padLeft(2, '0'),
              selectedIndex: _minuteIndex,
              onChanged: _onMinuteChanged,
              onScrollingChanged: (v) => _minuteScrolling = v,
            ),
          ),
          // ── AM/PM column (only in 12h mode) ──
          if (!widget.use24HourFormat)
            Expanded(
              child: _buildColumn(
                controller: _periodController,
                itemCount: 2,
                labelBuilder: (index) => index == 0 ? 'AM' : 'PM',
                selectedIndex: _periodIndex,
                onChanged: _onPeriodChanged,
                loop: false,
                onScrollingChanged: (v) => _periodScrolling = v,
              ),
            ),
        ],
      ),
    );
  }

  /// Builds a single scrollable column with snap behavior.
  /// Uses [NotificationListener] to track user-initiated scrolling so that
  /// [didUpdateWidget] doesn't interrupt ongoing gestures.
  /// Tap-to-select uses a raw [Listener] (not GestureDetector) so it
  /// doesn't enter the gesture arena and compete with the scroll view.
  Widget _buildColumn({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int index) labelBuilder,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
    bool loop = true,
    required ValueChanged<bool> onScrollingChanged,
  }) {
    final timeStyle = widget.style.timeTextStyle ??
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w500);

    final double viewHeight = _itemHeight * (2 * _visibleSideItems + 1);

    // Track pointer-down position for tap detection.
    Offset? downPos;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          onScrollingChanged(true);
        } else if (notification is ScrollEndNotification) {
          // Delay clearing so the final rebuild doesn't jumpToItem.
          Future.delayed(const Duration(milliseconds: 100), () {
            onScrollingChanged(false);
          });
        }
        return false;
      },
      child: Listener(
        // Listener doesn't enter the gesture arena, so it won't
        // compete with the scroll view's drag recognizer.
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) => downPos = e.position,
        onPointerUp: (e) {
          if (downPos != null && (e.position - downPos!).distance < 18) {
            final double center = viewHeight / 2;
            final double tapY = e.localPosition.dy;
            final int itemOffset = ((tapY - center) / _itemHeight).round();
            if (itemOffset != 0) {
              final int target = controller.selectedItem + itemOffset;
              controller.animateToItem(
                target,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }
          downPos = null;
        },
        child: ScrollConfiguration(
          behavior: const _AllDevicesDragScrollBehavior(),
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: _itemHeight,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: 6,
            perspective: 0.003,
            onSelectedItemChanged: onChanged,
            childDelegate: loop
                ? ListWheelChildLoopingListDelegate(
                    children: List.generate(itemCount, (index) {
                      return _itemTile(
                        label: labelBuilder(index),
                        isSelected: index == selectedIndex,
                        style: timeStyle,
                      );
                    }),
                  )
                : ListWheelChildListDelegate(
                    children: List.generate(itemCount, (index) {
                      return _itemTile(
                        label: labelBuilder(index),
                        isSelected: index == selectedIndex,
                        style: timeStyle,
                      );
                    }),
                  ),
          ),
        ),
      ),
    );
  }

  /// Individual item tile in a scroll column.
  /// No gesture detector — taps are handled by the column-level detector,
  /// and drags pass straight through to the scroll view.
  Widget _itemTile({
    required String label,
    required bool isSelected,
    required TextStyle style,
  }) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? widget.style.accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: style.copyWith(
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
