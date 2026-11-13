import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DateRangePreset {
  today,
  last7Days,
  last30Days,
  last90Days,
  last180Days,
  custom,
}

class DateRangeSelection {
  final DateTime startDate;
  final DateTime endDate;
  final String label;
  final DateRangePreset preset;

  DateRangeSelection({
    required this.startDate,
    required this.endDate,
    required this.label,
    required this.preset,
  });
}

class DateRangePickerBar extends StatefulWidget {
  final Function(DateRangeSelection selection) onRangeSelected;

  const DateRangePickerBar({
    super.key,
    required this.onRangeSelected,
  });

  @override
  State<DateRangePickerBar> createState() => _DateRangePickerBarState();
}

class _DateRangePickerBarState extends State<DateRangePickerBar> {
  DateRangePreset _selectedPreset = DateRangePreset.last30Days;
  late DateTime _startDate;
  late DateTime _endDate;
  String _customLabel = '';

  @override
  void initState() {
    super.initState();
    _applyPreset(DateRangePreset.last30Days, notify: false);
  }

  void _applyPreset(DateRangePreset preset, {bool notify = true}) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    String label;

    switch (preset) {
      case DateRangePreset.today:
        start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        label = "Bugün";
        break;
      case DateRangePreset.last7Days:
        start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
        label = "Son 7 Gün";
        break;
      case DateRangePreset.last30Days:
        start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
        label = "Son 30 Gün";
        break;
      case DateRangePreset.last90Days:
        start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 90));
        label = "Son 90 Gün";
        break;
      case DateRangePreset.last180Days:
        start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 180));
        label = "Son 180 Gün";
        break;
      case DateRangePreset.custom:
        return;
    }

    setState(() {
      _selectedPreset = preset;
      _startDate = start;
      _endDate = end;
      _customLabel = label;
    });

    if (notify) {
      widget.onRangeSelected(
        DateRangeSelection(
          startDate: start,
          endDate: end,
          label: label,
          preset: preset,
        ),
      );
    }
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F172A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final start = DateTime(picked.start.year, picked.start.month, picked.start.day, 0, 0, 0);
      final end = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      final dateFormat = DateFormat('dd.MM.yyyy');
      final label = "${dateFormat.format(start)} - ${dateFormat.format(end)}";

      setState(() {
        _selectedPreset = DateRangePreset.custom;
        _startDate = start;
        _endDate = end;
        _customLabel = label;
      });

      widget.onRangeSelected(
        DateRangeSelection(
          startDate: start,
          endDate: end,
          label: label,
          preset: DateRangePreset.custom,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _presetButton("Bugün", DateRangePreset.today),
          _presetButton("Son 7 Gün", DateRangePreset.last7Days),
          _presetButton("Son 30 Gün", DateRangePreset.last30Days),
          _presetButton("Son 90 Gün", DateRangePreset.last90Days),
          _presetButton("Son 180 Gün", DateRangePreset.last180Days),
          InkWell(
            onTap: _pickCustomRange,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _selectedPreset == DateRangePreset.custom
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedPreset == DateRangePreset.custom
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: _selectedPreset == DateRangePreset.custom
                        ? Colors.white
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedPreset == DateRangePreset.custom
                        ? _customLabel
                        : "Özel Tarih",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _selectedPreset == DateRangePreset.custom
                          ? Colors.white
                          : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetButton(String title, DateRangePreset preset) {
    final isSelected = _selectedPreset == preset;
    return InkWell(
      onTap: () => _applyPreset(preset),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
