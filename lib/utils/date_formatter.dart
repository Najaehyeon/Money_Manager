import 'package:intl/intl.dart';

/// 날짜 포맷팅 유틸리티 클래스
class DateFormatter {
  DateFormatter._();

  /// 저장용 날짜 포맷 (yyyy-MM-dd)
  static String toStorageFormat(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// 표시용 날짜 포맷 (MMMM d, yyyy)
  static String toDisplayFormat(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }

  /// 월별 데이터 키 생성 (november_2025_data)
  static String toMonthlyKey(DateTime date) {
    return DateFormat('MMMM_yyyy', 'en_US').format(date).toLowerCase() + '_data';
  }

  /// 월 표시 포맷 (MMM. yyyy)
  static String toMonthYearFormat(DateTime date) {
    return DateFormat('MMM. yyyy').format(date);
  }

  /// 요일 포맷 (E)
  static String toWeekdayFormat(DateTime date) {
    return DateFormat('E').format(date);
  }

  /// 월/일 포맷 (MM/dd)
  static String toMonthDayFormat(DateTime date) {
    return DateFormat('MM/dd', 'en_US').format(date);
  }

  /// 월/일 간단 포맷 (MMM d)
  static String toMonthDayShortFormat(DateTime date) {
    return DateFormat('MMM d', 'en_US').format(date);
  }

  /// 년.월 포맷 (yyyy.MM)
  static String toYearMonthFormat(DateTime date) {
    return "${date.year}.${date.month.toString().padLeft(2, '0')}";
  }
}
