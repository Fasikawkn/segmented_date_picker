# Segmented Date Picker

A fully customizable segmented date & time picker for Flutter. Users edit each segment (month, day, year, hour, minute, AM/PM) individually via keyboard or tapping, and can open a popup dialog with a calendar and/or scrollable time picker.

## Features

- **Segmented inline editing** - Each segment (MM, DD, YYYY, HH, MM, AM/PM) is independently editable via keyboard input.
- **Calendar panel** - Month grid with month/year quick‑pickers and an optional Today button.
- **Time picker panel** - Scrollable hour, minute, and AM/PM columns with momentum physics.
- **Three modes** - `DateTimePickerMode.date`, `.time`, or `.dateTime`.
- **12h / 24h support** - Set `use24HourFormat: true` for 24‑hour clocks.
- **Style class** - Full visual customization via `DateTimePickerStyle` including accent color, text styles, selected day shape, and `InputDecoration` for TextFormField‑like borders.
- **Controller API** - `DateTimePickerController` (a `ChangeNotifier`) for programmatic reading/writing and focus control.
- **Mobile keyboard** - Opens the device soft keyboard for direct numeric input on mobile.
- **Responsive dialog** - Switches to vertical layout on narrow screens (< 540 px).
- **Cross‑platform drag** - Custom `ScrollBehavior` enables drag scrolling on web and desktop.

## Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  segmented_date_picker:
    path: ../segmented_date_picker  # or a pub.dev version once published
```

Then import it:

```dart
import 'package:segmented_date_picker/segmented_date_picker.dart';
```

## Usage

### Date only

```dart
SegmentedDatePicker(
  mode: DateTimePickerMode.date,
  initialValue: DateTime.now(),
  onChanged: (value) => print('Date: $value'),
)
```

### Time only

```dart
SegmentedDatePicker(
  mode: DateTimePickerMode.time,
  use24HourFormat: false,
  initialValue: DateTime.now(),
  onChanged: (value) => print('Time: $value'),
)
```

### Date & Time

```dart
SegmentedDatePicker(
  mode: DateTimePickerMode.dateTime,
  initialValue: DateTime.now(),
  showTodayButton: true,
  onChanged: (value) => print('DateTime: $value'),
  onConfirmed: (value) => print('Confirmed: $value'),
)
```

### With a controller

```dart
final controller = DateTimePickerController(DateTime.now());

SegmentedDatePicker(
  controller: controller,
  mode: DateTimePickerMode.dateTime,
  onChanged: (value) => print(value),
)

// Programmatic access
controller.setValue(DateTime(2025, 12, 25, 10, 30));
controller.clear();
```

### Custom styling

```dart
SegmentedDatePicker(
  mode: DateTimePickerMode.dateTime,
  style: DateTimePickerStyle(
    accentColor: Colors.teal,
    dialogBackgroundColor: Colors.grey.shade50,
    selectedDayShape: BoxShape.circle,
    inputTextStyle: const TextStyle(fontSize: 18, color: Colors.black87),
    activeSegmentTextStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Colors.teal,
    ),
    inputDecoration: InputDecoration(
      labelText: 'Pick a date & time',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputHeight: 56,
  ),
  onChanged: (value) => print(value),
)
```

## API Reference

### `SegmentedDatePicker`

| Property | Type | Default | Description |
|---|---|---|---|
| `controller` | `DateTimePickerController?` | `null` | Manages the value externally. |
| `initialValue` | `DateTime?` | `null` | Starting value when no controller is provided. |
| `mode` | `DateTimePickerMode` | `.dateTime` | Which segments and panels to show. |
| `minDate` | `DateTime` | `DateTime(1900)` | Earliest selectable date. |
| `maxDate` | `DateTime` | `DateTime(2100)` | Latest selectable date. |
| `use24HourFormat` | `bool` | `false` | Use 24‑hour clock. |
| `firstDayOfWeek` | `int` | `DateTime.sunday` | First day of the week in the calendar. |
| `showTodayButton` | `bool` | `true` | Show the "Today" button in the calendar. |
| `style` | `DateTimePickerStyle` | `DateTimePickerStyle()` | Visual customization. |
| `onChanged` | `ValueChanged<DateTime?>?` | `null` | Called on every value change. |
| `onConfirmed` | `ValueChanged<DateTime?>?` | `null` | Called when the dialog is confirmed. |

### `DateTimePickerController`

Extends `ChangeNotifier`.

| Method / Property | Description |
|---|---|
| `value` | Current `DateTime?`. |
| `setValue(DateTime?)` | Sets the value and notifies listeners. |
| `clear()` | Clears the value. |
| `focusSegment(DateTimeSegment)` | Requests focus on a specific segment. |

### `DateTimePickerStyle`

All fields are optional and have sensible defaults.

| Property | Type | Description |
|---|---|---|
| `accentColor` | `Color` | Primary accent (selections, highlights). |
| `dialogBackgroundColor` | `Color` | Popup dialog background. |
| `inputBorderRadius` | `BorderRadius` | Input field border radius. |
| `segmentHighlightColor` | `Color` | Active segment highlight color. |
| `selectedDayShape` | `BoxShape` | Calendar selected-day shape. |
| `headerTextStyle` | `TextStyle?` | Calendar header text. |
| `dayTextStyle` | `TextStyle?` | Calendar day numbers. |
| `timeTextStyle` | `TextStyle?` | Time scroll column items. |
| `inputTextStyle` | `TextStyle?` | Segment values. |
| `activeSegmentTextStyle` | `TextStyle?` | Currently focused segment. |
| `separatorTextStyle` | `TextStyle?` | Separator characters (/, :). |
| `inputDecoration` | `InputDecoration?` | TextFormField‑like border. |
| `inputHeight` | `double?` | Fixed input field height. |

## License

MIT
