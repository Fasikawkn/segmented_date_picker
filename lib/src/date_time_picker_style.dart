/// Style configuration for the DateTimePicker widget.
///
/// Allows full visual customization of the picker's input field,
/// calendar panel, time panel, and popup dialog.
library;

import 'package:flutter/material.dart';

class DateTimePickerStyle {
  /// Primary accent color used for selections and highlights.
  final Color accentColor;

  /// Background color of the popup dialog.
  final Color dialogBackgroundColor;

  /// Border radius of the input field.
  final BorderRadius inputBorderRadius;

  /// Background color of the currently focused segment.
  final Color segmentHighlightColor;

  /// Shape used for the selected day indicator in the calendar.
  /// [BoxShape.circle] or [BoxShape.rectangle] (rounded rectangle).
  final BoxShape selectedDayShape;

  /// Text style for the calendar header (month/year).
  final TextStyle? headerTextStyle;

  /// Text style for day numbers in the calendar grid.
  final TextStyle? dayTextStyle;

  /// Text style for items in the time scroll columns.
  final TextStyle? timeTextStyle;

  /// Text style for segment values in the input field.
  final TextStyle? inputTextStyle;

  /// Text style for the currently focused/active segment.
  /// If null, defaults to the [inputTextStyle] with [FontWeight.w700].
  final TextStyle? activeSegmentTextStyle;

  /// Text style for separator characters (/, :, ,) in the input field.
  final TextStyle? separatorTextStyle;

  /// Optional [InputDecoration] applied to the input field.
  /// When provided, the field renders inside an [InputDecorator] so you get
  /// the same border styles as a [TextFormField] (outline, underline, etc.).
  /// If null, a simple container border is used.
  final InputDecoration? inputDecoration;

  /// Fixed height of the input field. If null, the height is determined by
  /// content and padding.
  final double? inputHeight;

  const DateTimePickerStyle({
    this.accentColor = Colors.blue,
    this.dialogBackgroundColor = Colors.white,
    this.inputBorderRadius = const BorderRadius.all(Radius.circular(8)),
    this.segmentHighlightColor = Colors.blue,
    this.selectedDayShape = BoxShape.rectangle,
    this.headerTextStyle,
    this.dayTextStyle,
    this.timeTextStyle,
    this.inputTextStyle,
    this.activeSegmentTextStyle,
    this.separatorTextStyle,
    this.inputDecoration,
    this.inputHeight,
  });

  /// Creates a copy of this style with the given overrides.
  DateTimePickerStyle copyWith({
    Color? accentColor,
    Color? dialogBackgroundColor,
    BorderRadius? inputBorderRadius,
    Color? segmentHighlightColor,
    BoxShape? selectedDayShape,
    TextStyle? headerTextStyle,
    TextStyle? dayTextStyle,
    TextStyle? timeTextStyle,
    TextStyle? inputTextStyle,
    TextStyle? activeSegmentTextStyle,
    TextStyle? separatorTextStyle,
    InputDecoration? inputDecoration,
    double? inputHeight,
  }) {
    return DateTimePickerStyle(
      accentColor: accentColor ?? this.accentColor,
      dialogBackgroundColor:
          dialogBackgroundColor ?? this.dialogBackgroundColor,
      inputBorderRadius: inputBorderRadius ?? this.inputBorderRadius,
      segmentHighlightColor:
          segmentHighlightColor ?? this.segmentHighlightColor,
      selectedDayShape: selectedDayShape ?? this.selectedDayShape,
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      dayTextStyle: dayTextStyle ?? this.dayTextStyle,
      timeTextStyle: timeTextStyle ?? this.timeTextStyle,
      inputTextStyle: inputTextStyle ?? this.inputTextStyle,
      activeSegmentTextStyle:
          activeSegmentTextStyle ?? this.activeSegmentTextStyle,
      separatorTextStyle: separatorTextStyle ?? this.separatorTextStyle,
      inputDecoration: inputDecoration ?? this.inputDecoration,
      inputHeight: inputHeight ?? this.inputHeight,
    );
  }
}
