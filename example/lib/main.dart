import 'package:flutter/material.dart';
import 'package:segmented_date_picker/segmented_date_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Segmented Date Picker Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DemoPage(),
    );
  }
}

/// Demo page showing all three modes: date, time, and dateTime.
class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final _dateController = DateTimePickerController(
    initialValue: DateTime.now(),
  );
  final _timeController = DateTimePickerController(
    initialValue: DateTime.now(),
  );
  final _dateTimeController = DateTimePickerController(
    initialValue: DateTime.now(),
  );

  String _dateLabel = '';
  String _timeLabel = '';
  String _dateTimeLabel = '';

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _dateTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Segmented Date Picker Demo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date Only ───────────────────────────────
            const Text(
              'Date Only',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SegmentedDatePicker(
              controller: _dateController,
              mode: DateTimePickerMode.date,
              minDate: DateTime(2000),
              maxDate: DateTime(2100),
              style: const DateTimePickerStyle(
                accentColor: Colors.blue,
                selectedDayShape: BoxShape.rectangle,
              ),
              onChanged: (value) {
                setState(() {
                  _dateLabel = value != null
                      ? '${value.month}/${value.day}/${value.year}'
                      : 'null';
                });
              },
            ),
            const SizedBox(height: 4),
            Text('Value: $_dateLabel',
                style: TextStyle(color: Colors.grey.shade600)),

            const SizedBox(height: 32),

            // ── Time Only ───────────────────────────────
            const Text(
              'Time Only (12h)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SegmentedDatePicker(
              controller: _timeController,
              mode: DateTimePickerMode.time,
              use24HourFormat: false,
              style: const DateTimePickerStyle(
                accentColor: Colors.deepOrange,
                segmentHighlightColor: Colors.deepOrange,
              ),
              onChanged: (value) {
                setState(() {
                  if (value != null) {
                    final h = value.hour;
                    final m = value.minute.toString().padLeft(2, '0');
                    final period = h >= 12 ? 'PM' : 'AM';
                    final h12 = h % 12 == 0 ? 12 : h % 12;
                    _timeLabel = '$h12:$m $period';
                  } else {
                    _timeLabel = 'null';
                  }
                });
              },
            ),
            const SizedBox(height: 4),
            Text('Value: $_timeLabel',
                style: TextStyle(color: Colors.grey.shade600)),

            const SizedBox(height: 32),

            // ── Date + Time ─────────────────────────────
            const Text(
              'Date + Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SegmentedDatePicker(
              controller: _dateTimeController,
              mode: DateTimePickerMode.dateTime,
              minDate: DateTime.now().subtract(const Duration(days: 10)),
              maxDate: DateTime.now(),
              use24HourFormat: false,
              firstDayOfWeek: DateTime.sunday,
              showTodayButton: true,
              style: const DateTimePickerStyle(
                accentColor: Colors.teal,
                segmentHighlightColor: Colors.teal,
                selectedDayShape: BoxShape.circle,
                inputDecoration: InputDecoration(
                  labelText: 'Select date & time',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                ),
                inputHeight: null
              ),
              onChanged: (value) {
                setState(() {
                  if (value != null) {
                    _dateTimeLabel =
                        '${value.month}/${value.day}/${value.year} '
                        '${value.hour}:${value.minute.toString().padLeft(2, '0')}';
                  } else {
                    _dateTimeLabel = 'null';
                  }
                });
              },
            ),
            const SizedBox(height: 4),
            Text('Value: $_dateTimeLabel',
                style: TextStyle(color: Colors.grey.shade600)),

            const SizedBox(height: 32),

            // ── With InputDecoration ────────────────────
            const Text(
              'With InputDecoration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SegmentedDatePicker(
              mode: DateTimePickerMode.dateTime,
              initialValue: DateTime.now(),
              style: DateTimePickerStyle(
                accentColor: Colors.indigo,
                inputDecoration: InputDecoration(
                  labelText: 'Select date & time',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                inputHeight: 56,
              ),
              onChanged: (value) {
                debugPrint('InputDecoration picker: $value');
              },
            ),
          ],
        ),
      ),
    );
  }
}
