## 0.0.3

* **Bug fix:** Fixed desktop input being completely blocked after tapping a segment.
* **Improved:** Replaced focus-based dedup guard with a frame-level suppress flag to correctly handle both desktop (hardware key events) and mobile (soft keyboard) input paths without double-processing.

## 0.0.2

* **Bug fix:** Fixed double-processing of digit input that caused single-digit values (01, 02, 03, etc.) to auto-advance to the next segment prematurely.
* **Bug fix:** Prevented `didUpdateWidget` from overwriting segment values while the user is mid-typing.

## 0.0.1

* Initial release.
* Segmented inline editing for date, time, and date-time modes.
* Keyboard navigation (arrow keys, Tab, digit typing, A/P for AM/PM).
* Auto-advance on segment completion.
* Popup dialog with calendar and time picker panels.
* Fully customizable styling via `DateTimePickerStyle`.
* Support for 12-hour and 24-hour time formats.
* Configurable min/max date range.
* Today button in calendar panel.
