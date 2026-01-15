import 'package:money_manager/services/storage_service.dart';

/// 앱 설정을 관리하는 서비스 클래스
class SettingsService {
  final StorageService _storageService;

  SettingsService(this._storageService);

  // Target Money
  static const String _targetMoneyKey = 'target_money';

  Future<double> getTargetMoney() async {
    return await _storageService.getDouble(_targetMoneyKey);
  }

  Future<void> setTargetMoney(double value) async {
    await _storageService.setDouble(_targetMoneyKey, value);
  }

  // Week Stats View
  static const String _showWeekStatsKey = 'show_weekStats';

  Future<bool> getShowWeekStats() async {
    return await _storageService.getBool(_showWeekStatsKey);
  }

  Future<void> setShowWeekStats(bool value) async {
    await _storageService.setBool(_showWeekStatsKey, value);
  }

  // Calendar View
  static const String _showCalendarKey = 'show_calendar';

  Future<bool> getShowCalendar() async {
    return await _storageService.getBool(_showCalendarKey);
  }

  Future<void> setShowCalendar(bool value) async {
    await _storageService.setBool(_showCalendarKey, value);
  }
}
