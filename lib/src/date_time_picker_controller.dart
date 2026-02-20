/// Controller for the DateTimePicker widget.
///
/// Manages the current [DateTime] value and notifies listeners on changes.
/// Exposes methods to clear, set, and programmatically focus segments.
library;

import 'package:flutter/foundation.dart';
import 'date_time_picker_mode.dart';

class DateTimePickerController extends ChangeNotifier {
  DateTime? _value;

  /// Optional callback when the focused segment should change programmatically.
  ValueChanged<DateTimeSegment>? onFocusSegmentRequested;

  DateTimePickerController({DateTime? initialValue}) : _value = initialValue;

  /// The current date/time value, or null if cleared.
  DateTime? get value => _value;

  /// Updates the value and notifies listeners.
  void setValue(DateTime? dt) {
    if (_value != dt) {
      _value = dt;
      notifyListeners();
    }
  }

  /// Clears the current value (sets to null) and notifies listeners.
  void clear() {
    if (_value != null) {
      _value = null;
      notifyListeners();
    }
  }

  /// Requests focus on the given segment.
  /// The widget listens to [onFocusSegmentRequested] to handle this.
  void focusSegment(DateTimeSegment segment) {
    onFocusSegmentRequested?.call(segment);
  }
}
