# 리팩토링 요약

## 개선 사항

### 1. 상수 관리 (`lib/constants/`)
- **app_colors.dart**: 모든 색상을 상수로 관리
- **app_styles.dart**: 공통 스타일 및 디자인 시스템
- **app_strings.dart**: 모든 문자열 상수화

### 2. 유틸리티 함수 (`lib/utils/`)
- **currency_formatter.dart**: 통화 포맷팅 중복 제거
- **date_formatter.dart**: 날짜 포맷팅 로직 통합

### 3. 모델 클래스 (`lib/models/`)
- **expense.dart**: Expense 모델 클래스로 타입 안정성 향상

### 4. 서비스 레이어 (`lib/services/`)
- **storage_service.dart**: SharedPreferences 추상화
- **expense_service.dart**: 지출 데이터 관리 로직 분리
- **category_service.dart**: 카테고리 관리 로직 분리
- **settings_service.dart**: 앱 설정 관리

### 5. 공통 위젯 (`lib/widgets/`)
- **category_bottom_sheet.dart**: 카테고리 선택 위젯 재사용 가능하게 분리
- **date_picker_widget.dart**: 날짜 선택 위젯 분리

## 사용 방법

### 서비스 사용 예시
```dart
// 초기화
final storageService = await StorageService.getInstance();
final expenseService = ExpenseService(storageService);
final categoryService = CategoryService(storageService);

// 지출 추가
final expense = Expense(
  date: '2025-01-15',
  category: '식비',
  detail: '점심',
  price: '15000',
);
await expenseService.addExpense(expense);

// 카테고리 추가
await categoryService.addCategory('교통비');
```

### 상수 사용 예시
```dart
// 색상
backgroundColor: AppColors.background
color: AppColors.primary

// 스타일
style: AppStyles.primaryButtonStyle()
decoration: AppStyles.inputDecoration(hintText: '입력하세요')

// 문자열
Text(AppStrings.newExpense)
```

### 유틸리티 사용 예시
```dart
// 통화 포맷팅
CurrencyFormatter.format(context, 15000.0)

// 날짜 포맷팅
DateFormatter.toStorageFormat(DateTime.now())
DateFormatter.toMonthlyKey(DateTime.now())
```

## 다음 단계

기존 파일들(`post.dart`, `home.dart`, `detail.dart`, `update.dart`)을 새 구조에 맞게 리팩토링하는 것을 권장합니다:

1. 하드코딩된 색상/문자열을 상수로 교체
2. SharedPreferences 직접 호출을 서비스로 교체
3. 통화/날짜 포맷팅을 유틸리티로 교체
4. Map<String, dynamic>을 Expense 모델로 교체
5. 중복된 위젯을 공통 위젯으로 교체

## 장점

- **유지보수성**: 상수와 스타일이 한 곳에서 관리됨
- **확장성**: 새로운 기능 추가가 쉬움
- **재사용성**: 공통 위젯과 서비스 재사용 가능
- **타입 안정성**: 모델 클래스로 런타임 에러 감소
- **테스트 용이성**: 서비스 레이어 분리로 단위 테스트 쉬움
