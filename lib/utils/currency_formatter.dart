import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 통화 포맷팅 유틸리티 클래스
class CurrencyFormatter {
  CurrencyFormatter._();

  /// 소수점이 없는 로케일 리스트
  static const List<String> noDecimalLocales = ['ko_KR', 'ja_JP', 'ko', 'ja'];

  /// 기본 통화 포맷팅 (로케일 기반)
  static String format(BuildContext context, double amount, {int? decimalDigits}) {
    final locale = Localizations.localeOf(context).toString();
    final digits = decimalDigits ?? (noDecimalLocales.contains(locale) ? 0 : 1);

    final formatter = NumberFormat.simpleCurrency(
      locale: locale,
      decimalDigits: digits,
    );

    return formatter.format(amount);
  }

  /// 숫자만 포맷팅 (통화 기호 없이)
  static String formatNumber(BuildContext context, double amount) {
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat.decimalPattern(locale).format(amount);
  }

  /// 가격 문자열을 double로 변환 (쉼표 제거)
  static double parsePrice(String price) {
    return double.tryParse(price.replaceAll(',', '')) ?? 0.0;
  }
}
