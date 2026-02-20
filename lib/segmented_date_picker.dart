/// A fully customizable segmented date & time picker for Flutter.
///
/// Provides an inline editable field with individually focusable segments
/// (month, day, year, hour, minute, AM/PM) and a popup dialog with a
/// calendar panel and scrollable time picker.
///
/// ## Usage
///
/// ```dart
/// import 'package:segmented_date_picker/segmented_date_picker.dart';
///
/// SegmentedDatePicker(
///   mode: DateTimePickerMode.dateTime,
///   initialValue: DateTime.now(),
///   onChanged: (value) => print(value),
/// )
/// ```
library;

export 'src/date_time_picker_mode.dart';
export 'src/date_time_picker_style.dart';
export 'src/date_time_picker_controller.dart';
export 'src/segmented_date_picker.dart';
