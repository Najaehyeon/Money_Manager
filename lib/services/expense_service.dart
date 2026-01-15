import 'package:money_manager/models/expense.dart';
import 'package:money_manager/services/storage_service.dart';
import 'package:money_manager/utils/date_formatter.dart';

/// 지출 데이터를 관리하는 서비스 클래스
class ExpenseService {
  final StorageService _storageService;

  ExpenseService(this._storageService);

  /// 특정 월의 지출 목록 가져오기
  Future<List<Expense>> getExpensesForMonth(DateTime month) async {
    final key = DateFormatter.toMonthlyKey(month);
    final jsonList = await _storageService.getStringList(key);
    return jsonList.map((json) => Expense.fromJsonString(json)).toList();
  }

  /// 여러 월의 지출 목록 가져오기
  Future<List<Expense>> getExpensesForMonths(List<DateTime> months) async {
    final allExpenses = <Expense>[];
    for (final month in months) {
      final expenses = await getExpensesForMonth(month);
      allExpenses.addAll(expenses);
    }
    return allExpenses;
  }

  /// 지출 추가
  Future<void> addExpense(Expense expense) async {
    final key = DateFormatter.toMonthlyKey(DateTime.parse(expense.date));
    final currentList = await _storageService.getStringList(key);
    currentList.add(expense.toJsonString());
    await _storageService.setStringList(key, currentList);
  }

  /// 지출 업데이트
  Future<void> updateExpense({
    required Expense oldExpense,
    required Expense newExpense,
  }) async {
    // 기존 지출 삭제
    await deleteExpense(oldExpense);
    // 새 지출 추가
    await addExpense(newExpense);
  }

  /// 지출 삭제
  Future<void> deleteExpense(Expense expense) async {
    final key = DateFormatter.toMonthlyKey(DateTime.parse(expense.date));
    final currentList = await _storageService.getStringList(key);
    final expenseJson = expense.toJsonString();
    currentList.remove(expenseJson);
    await _storageService.setStringList(key, currentList);
  }

  /// 날짜별로 그룹화된 지출 가져오기
  Future<Map<String, List<Expense>>> getExpensesGroupedByDate(DateTime month) async {
    final expenses = await getExpensesForMonth(month);
    final grouped = <String, List<Expense>>{};

    for (final expense in expenses) {
      if (!grouped.containsKey(expense.date)) {
        grouped[expense.date] = [];
      }
      grouped[expense.date]!.add(expense);
    }

    return grouped;
  }

  /// 특정 날짜의 총 지출 계산
  double calculateDayTotal(List<Expense> expenses) {
    return expenses.fold(0.0, (sum, expense) => sum + expense.priceAsDouble);
  }

  /// 특정 월의 총 지출 계산
  Future<double> calculateMonthTotal(DateTime month) async {
    final expenses = await getExpensesForMonth(month);
    return expenses.fold<double>(0.0, (sum, expense) => sum + expense.priceAsDouble);
  }

  /// 특정 날짜의 총 지출 계산
  Future<double> calculateDateTotal(String date) async {
    final dateObj = DateTime.parse(date);
    final expenses = await getExpensesForMonth(dateObj);
    final dateExpenses = expenses.where((e) => e.date == date).toList();
    return dateExpenses.fold<double>(0.0, (sum, expense) => sum + expense.priceAsDouble);
  }
}
