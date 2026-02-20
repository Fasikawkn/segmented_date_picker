import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:segmented_date_picker/segmented_date_picker.dart';

void main() {
  group('DateTimePickerController', () {
    test('initial value is set correctly', () {
      final dt = DateTime(2025, 6, 15, 10, 30);
      final controller = DateTimePickerController(initialValue: dt);
      expect(controller.value, dt);
      controller.dispose();
    });

    test('setValue updates value and notifies listeners', () {
      final controller = DateTimePickerController();
      DateTime? received;
      controller.addListener(() {
        received = controller.value;
      });
      final dt = DateTime(2025, 1, 1);
      controller.setValue(dt);
      expect(received, dt);
      controller.dispose();
    });

    test('clear sets value to null', () {
      final controller = DateTimePickerController(
        initialValue: DateTime.now(),
      );
      controller.clear();
      expect(controller.value, isNull);
      controller.dispose();
    });
  });

  group('DateTimePickerStyle', () {
    test('default values are sensible', () {
      const style = DateTimePickerStyle();
      expect(style.accentColor, Colors.blue);
      expect(style.dialogBackgroundColor, Colors.white);
      expect(style.selectedDayShape, BoxShape.rectangle);
      expect(style.inputDecoration, isNull);
      expect(style.inputHeight, isNull);
    });

    test('copyWith overrides specific fields', () {
      const original = DateTimePickerStyle(accentColor: Colors.blue);
      final copy = original.copyWith(accentColor: Colors.red);
      expect(copy.accentColor, Colors.red);
      expect(copy.dialogBackgroundColor, Colors.white);
    });
  });

  group('SegmentedDatePicker widget', () {
    testWidgets('renders in date mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SegmentedDatePicker(
              mode: DateTimePickerMode.date,
              initialValue: DateTime(2025, 3, 15),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show month, day, year segments with separators.
      expect(find.text('03'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('2025'), findsOneWidget);
    });

    testWidgets('renders in time mode with 12h format', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SegmentedDatePicker(
              mode: DateTimePickerMode.time,
              use24HourFormat: false,
              initialValue: DateTime(2025, 1, 1, 14, 5),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 14:05 in 12h is 02:05 PM
      expect(find.text('02'), findsOneWidget);
      expect(find.text('05'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
    });

    testWidgets('onChanged fires when controller value changes',
        (tester) async {
      final controller = DateTimePickerController(
        initialValue: DateTime(2025, 1, 1),
      );
      DateTime? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SegmentedDatePicker(
              controller: controller,
              mode: DateTimePickerMode.date,
              onChanged: (v) => changedValue = v,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final newDt = DateTime(2025, 6, 20);
      controller.setValue(newDt);
      await tester.pumpAndSettle();

      expect(changedValue, newDt);
      controller.dispose();
    });
  });
}
