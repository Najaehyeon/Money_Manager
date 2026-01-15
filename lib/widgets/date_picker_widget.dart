import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 날짜 선택 위젯
class DatePickerWidget {
  /// Cupertino 스타일 날짜 선택기 표시
  static void show({
    required BuildContext context,
    required DateTime initialDate,
    required Function(DateTime) onDateSelected,
    DateTime? minimumDate,
    DateTime? maximumDate,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 300.0,
          color: Colors.white,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: initialDate,
            minimumDate: minimumDate ?? DateTime(2025),
            maximumDate: maximumDate ?? DateTime(2100),
            onDateTimeChanged: onDateSelected,
          ),
        );
      },
    );
  }
}
