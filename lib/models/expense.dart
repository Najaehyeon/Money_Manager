import 'dart:convert';

/// 지출 데이터 모델 클래스
class Expense {
  final String date;
  final String category;
  final String detail;
  final String price;

  Expense({
    required this.date,
    required this.category,
    required this.detail,
    required this.price,
  });

  /// JSON 맵에서 Expense 생성
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      date: json['date'] as String? ?? '',
      category: json['category'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      price: json['price'] as String? ?? '',
    );
  }

  /// JSON 문자열에서 Expense 생성
  factory Expense.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return Expense.fromJson(json);
  }

  /// JSON 맵으로 변환
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'category': category,
      'detail': detail,
      'price': price,
    };
  }

  /// JSON 문자열로 변환
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Expense 복사본 생성 (일부 필드 수정 가능)
  Expense copyWith({
    String? date,
    String? category,
    String? detail,
    String? price,
  }) {
    return Expense(
      date: date ?? this.date,
      category: category ?? this.category,
      detail: detail ?? this.detail,
      price: price ?? this.price,
    );
  }

  /// 가격을 double로 변환
  double get priceAsDouble {
    return double.tryParse(price.replaceAll(',', '')) ?? 0.0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense &&
        other.date == date &&
        other.category == category &&
        other.detail == detail &&
        other.price == price;
  }

  @override
  int get hashCode {
    return date.hashCode ^
        category.hashCode ^
        detail.hashCode ^
        price.hashCode;
  }

  @override
  String toString() {
    return 'Expense(date: $date, category: $category, detail: $detail, price: $price)';
  }
}
