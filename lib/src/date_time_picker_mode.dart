/// Enums for the DateTimePicker widget.
///
/// [DateTimePickerMode] controls which segments and panels are displayed.
/// [DateTimeSegment] identifies each individually-focusable segment in the input field.
library;

/// Controls what is shown in the input field and popup dialog.
enum DateTimePickerMode {
  /// Only date segments (MM/dd/yyyy) and the calendar panel.
  date,

  /// Only time segments (hh:mm AM/PM) and the time scroll panel.
  time,

  /// Both date and time segments with both panels side by side.
  dateTime,
}

/// Identifies each individually-focusable segment in the segmented input field.
enum DateTimeSegment {
  month,
  day,
  year,
  hour,
  minute,
  period, // AM/PM
}
