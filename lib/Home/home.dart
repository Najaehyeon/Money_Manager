import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // JSON 데이터 처리를 위한 import

// 현재 사용하고 있는 파란색 기본 색상
const Color _primaryColor = Color(0xFF0000BB);

String formatCurrency(BuildContext context, double amount) {
  // 현재 디바이스/앱의 언어 설정을 가져옵니다.
  final locale = Localizations.localeOf(context).toString();

  // 소수점이 없는 화폐(KRW, JPY 등) 리스트
  const noDecimalLocales = ['ko_KR', 'ja_JP', 'ko', 'ja'];
  int digits = noDecimalLocales.contains(locale) ? 0 : 0;

  final formatter = NumberFormat.simpleCurrency(
    locale: 'ko_KR',
    decimalDigits: digits,
  );

  return formatter.format(amount);
}

// ---------------------------------------------------------------
// Home (StatefulWidget)
// ---------------------------------------------------------------

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with RouteAware {
  double _targetMoney = 0;
  DateTime _selectedDate = DateTime.now();
  double _currentSpentMoney = 0;
  double _monthDailyLimitMoney = 0;
  double _limitMoneyHeightRatio = 0;
  double _spentMoneyHeightRatio = 0;
  double _todaySpentMoney = 0;
  double _dailyLimit = 0;
  bool _isLoading = true;
  // Week-Chart State Variable
  bool _isWeekCharted = false;
  DateTime _selectedWeekDate = DateTime.now();
  DateTime _selectedWeekDateMin = DateTime.now();
  DateTime _selectedWeekDateMax = DateTime.now();
  double _weeklyLimit = 0;
  List<double> _weeklySpending = List.filled(7, 0.0);
  int fromThisWeekCount = 0;
  String weekStatsTitle = "This week";

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAllData();
    _loadThisWeekData();
  }

  // 2. 현재 화면이 스택으로 돌아왔을 때 호출되는 메서드
  @override
  void didPopNext() {
    _loadAllData();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // 저장된 값이 없으면 기본값인 false(리스트) 사용
      _isWeekCharted = prefs.getBool('show_weekStats') ?? false;
    });
  }

  /// SharedPreferences에서 목표 금액을 로드합니다.
  Future<void> _loadTargetMoney() async {
    final prefs = await SharedPreferences.getInstance();
    _targetMoney = prefs.getDouble('target_money') ?? 0;
  }

  /// 선택된 날짜에 맞는 SharedPreferences 키를 생성합니다. (e.g., "november_2025_data")
  String _getMonthlyDataKey(DateTime date) {
    // 키 이름은 이전과 동일하게 유지하되, 데이터 구조가 List<String>임을 반영하여 로직을 수정합니다.
    return DateFormat('MMMM_yyyy', 'en_US').format(date).toLowerCase() +
        '_data';
  }

  // 🚨 이 함수가 getStringList()를 사용하도록 수정되었습니다.
  /// 선택된 월의 지출 데이터를 로드하고, 총 지출 및 오늘 지출을 계산합니다.
  Future<void> _loadMonthlySpentData() async {
    final prefs = await SharedPreferences.getInstance();

    // 불러와야 할 월(Month) 키들을 저장할 셋 (중복 방지)
    Set<String> keysToLoad = {
      _getMonthlyDataKey(_selectedDate), // 현재 선택된 월
      _getMonthlyDataKey(_selectedWeekDateMin), // 주간 시작일의 월
      _getMonthlyDataKey(_selectedWeekDateMax), // 주간 종료일의 월
    };

    List<String> allTransactions = [];
    for (String key in keysToLoad) {
      final List<String>? data = prefs.getStringList(key);
      if (data != null) allTransactions.addAll(data);
    }

    double totalSpent = 0;
    double todaySpent = 0;
    List<double> tempWeeklySpent = List.filled(7, 0.0);

    final String todayDateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 날짜 비교를 위해 시간 정보가 없는 날짜 생성
    DateTime minDate = DateTime(
      _selectedWeekDateMin.year,
      _selectedWeekDateMin.month,
      _selectedWeekDateMin.day,
    );
    DateTime maxDate = DateTime(
      _selectedWeekDateMax.year,
      _selectedWeekDateMax.month,
      _selectedWeekDateMax.day,
    );

    for (String transactionJson in allTransactions) {
      final Map<String, dynamic> item = json.decode(transactionJson);
      final double price =
          double.tryParse(item['price']?.toString() ?? '0') ?? 0;
      final String itemDateStr = item['date']?.toString() ?? '';

      // 월 총액 계산 (현재 _selectedDate 기준)
      if (itemDateStr.startsWith(DateFormat('yyyy-MM').format(_selectedDate))) {
        totalSpent += price;
      }

      // 오늘 총액
      if (itemDateStr == todayDateStr) {
        todaySpent += price;
      }

      // 주간 지출 계산
      DateTime itemDate = DateTime.parse(itemDateStr);
      DateTime compareDate = DateTime(
        itemDate.year,
        itemDate.month,
        itemDate.day,
      );

      if ((compareDate.isAtSameMomentAs(minDate) ||
              compareDate.isAfter(minDate)) &&
          (compareDate.isAtSameMomentAs(maxDate) ||
              compareDate.isBefore(maxDate))) {
        // 일요일이 0이 되도록 인덱스 계산 (DateTime.weekday는 월=1...일=7)
        int weekdayIdx = itemDate.weekday % 7;
        tempWeeklySpent[weekdayIdx] += price;
      }
    }

    setState(() {
      _currentSpentMoney = totalSpent;
      _todaySpentMoney = todaySpent;
      _weeklySpending = tempWeeklySpent;
      _calculateMoneyAndRatio();
    });
  }

  /// 목표 금액과 지출 금액을 바탕으로 모든 비율과 한도 금액을 계산합니다.
  void _calculateMoneyAndRatio() {
    // 한도 계산은 항상 '현재 달력상의 날짜'를 기준으로 합니다.
    final DateTime now = DateTime.now();
    final DateTime lastDayOfCurrentMonth = DateTime(now.year, now.month + 1, 0);
    final int totalDaysInCurrentMonth = lastDayOfCurrentMonth.day;
    final int currentDay = now.day;

    if (_targetMoney <= 0) {
      _monthDailyLimitMoney = 0;
      _limitMoneyHeightRatio = 0;
      _dailyLimit = 0;
      _weeklyLimit = 0;
    } else {
      // 1. 오늘의 일일 한도 금액 (Daily Limit)
      _dailyLimit = _targetMoney / totalDaysInCurrentMonth;
      _weeklyLimit = _targetMoney / 7;

      // 2. 현재 일자까지의 누적 한도 금액 (limitMoney)
      _monthDailyLimitMoney = _dailyLimit * currentDay;

      // 3. 누적 한도 금액의 실린더 높이 비율
      _limitMoneyHeightRatio = currentDay / totalDaysInCurrentMonth;
    }

    // 4. 총 지출 금액의 실린더 높이 비율 (선택된 월의 총 지출 금액 기준)
    _spentMoneyHeightRatio = _targetMoney > 0
        ? _currentSpentMoney / _targetMoney
        : 0;

    // 지출 비율이 1을 초과하는 경우 1로 설정하여 실린더가 넘치지 않도록 제한
    if (_spentMoneyHeightRatio > 1.6) {
      _spentMoneyHeightRatio = 1.6;
    }

    // 상태가 변경될 수 있도록 setState 호출
    if (mounted) {
      setState(() {});
    }
  }

  /// 모든 비동기 데이터를 로드하고 상태를 초기화합니다.
  Future<void> _loadAllData() async {
    await _loadTargetMoney();

    final int todayYear = DateTime.now().year;
    final int todayMonth = DateTime.now().month;
    _selectedDate = DateTime(todayYear, todayMonth);

    await _loadMonthlySpentData();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 목표 금액을 SharedPreferences에 저장하고 상태를 업데이트합니다.
  Future<void> _storeTargetMoney(double newTarget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('target_money', newTarget);

    setState(() {
      _targetMoney = newTarget;
      _calculateMoneyAndRatio();
    });

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// 선택된 월을 이전 달로 변경하고 데이터를 다시 로드/계산합니다.
  void _goToPreviousMonth() async {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
      _currentSpentMoney = 0; // 데이터를 로드하기 전에 초기화 (선택적)
      _todaySpentMoney = 0;
      _isLoading = true; // 로딩 상태를 잠시 true로 설정하여 시각적 피드백 제공
    });
    await _loadMonthlySpentData();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 선택된 월을 다음 달로 변경하고 데이터를 다시 로드/계산합니다.
  void _goToNextMonth() async {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
      _currentSpentMoney = 0; // 데이터를 로드하기 전에 초기화 (선택적)
      _todaySpentMoney = 0;
      _isLoading = true; // 로딩 상태를 잠시 true로 설정하여 시각적 피드백 제공
    });
    await _loadMonthlySpentData();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------------
  //                         Week Functions
  // ---------------------------------------------------------------
  void setWeekChart() async {
    _loadThisWeekData();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isWeekCharted = !_isWeekCharted;
      prefs.setBool('show_weekStats', _isWeekCharted);
    });
  }

  void _loadThisWeekData() async {
    _selectedWeekDate = DateTime.now();
    final thisWeekYear = _selectedWeekDate.year;
    final thisWeekMonth = _selectedWeekDate.month;
    final thisWeekDay = _selectedWeekDate.day;
    _selectedWeekDateMin = DateTime(
      thisWeekYear,
      thisWeekMonth,
      thisWeekDay - _selectedWeekDate.weekday,
    );
    _selectedWeekDateMax = DateTime(
      thisWeekYear,
      thisWeekMonth,
      thisWeekDay + (6 - _selectedWeekDate.weekday),
    );
    await _loadMonthlySpentData();
  }

  void _goToPreviousWeek() async {
    setState(() {
      _selectedWeekDateMin = _selectedWeekDateMin.subtract(
        const Duration(days: 7),
      );
      _selectedWeekDateMax = _selectedWeekDateMax.subtract(
        const Duration(days: 7),
      );
      _isLoading = true;
      fromThisWeekCount--;
    });
    _setWeekStatsTitle();
    await _loadMonthlySpentData();
    setState(() => _isLoading = false);
  }

  void _goToNextWeek() async {
    setState(() {
      _selectedWeekDateMin = _selectedWeekDateMin.add(const Duration(days: 7));
      _selectedWeekDateMax = _selectedWeekDateMax.add(const Duration(days: 7));
      _isLoading = true;
      fromThisWeekCount++;
    });
    _setWeekStatsTitle();
    await _loadMonthlySpentData();
    setState(() => _isLoading = false);
  }

  void _setWeekStatsTitle() {
    if (fromThisWeekCount == 0) {
      weekStatsTitle = "This week";
    } else if (fromThisWeekCount == -1) {
      weekStatsTitle = "Last week";
    } else if (fromThisWeekCount == 1) {
      weekStatsTitle = "Next week";
    } else if (fromThisWeekCount < -1) {
      weekStatsTitle = "${fromThisWeekCount.abs()} weeks ago";
    } else {
      weekStatsTitle = "$fromThisWeekCount weeks later";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final screenWidth = MediaQuery.of(context).size.width;

    const double limitLineHeight = 100.0;

    return Column(
      children: [
        Header(
          selectedDate: _selectedDate,
          onPreviousMonth: _goToPreviousMonth,
          onNextMonth: _goToNextMonth,
          setWeekCharted: setWeekChart,
          isWeekCharted: _isWeekCharted,
          selectedWeekDateMin: _selectedWeekDateMin,
          selectedWeekDateMax: _selectedWeekDateMax,
          onPreviousWeek: _goToPreviousWeek,
          onNextWeek: _goToNextWeek,
        ),
        TodaySpentMoney(
          todaySpentMoney: _todaySpentMoney,
          dailyLimit: _dailyLimit,
          isWeekCharted: _isWeekCharted,
          weeklyLimit: _weeklyLimit,
          weeklySpending: _weeklySpending,
          weekStatsTitle: weekStatsTitle,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: _isWeekCharted
              ? WeekStats(
                  weekStatsTitle: weekStatsTitle,
                  weeklySpending: _weeklySpending,
                  limitLineHeight: limitLineHeight,
                  dailyLimit: _dailyLimit,
                  selectedWeekDateMin: _selectedWeekDateMin,
                  selectedWeekDateMax: _selectedWeekDateMax,
                )
              : Cylinder(
                  screenWidth: screenWidth,
                  currentSpentMoney: _currentSpentMoney,
                  limitMoney: _monthDailyLimitMoney,
                  limitMoneyHeightRatio: _limitMoneyHeightRatio,
                  spentMoneyHeightRatio: _spentMoneyHeightRatio,
                  targetMoney: _targetMoney,
                  selectedDate: _selectedDate,
                ),
        ),
        const SizedBox(height: 24),
        TargetMonthlyMax(
          targetMoney: _targetMoney,
          onSetTargetMoney: _storeTargetMoney,
        ),
        const SizedBox(height: 36),
      ],
    );
  }
}

// ---------------------------------------------------------------
// Header (StatelessWidget) - 디자인 유지
// ---------------------------------------------------------------

class Header extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback setWeekCharted;
  final bool isWeekCharted;
  final DateTime selectedWeekDateMin;
  final DateTime selectedWeekDateMax;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  const Header({
    super.key,
    required this.selectedDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.setWeekCharted,
    required this.isWeekCharted,
    required this.selectedWeekDateMin,
    required this.selectedWeekDateMax,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat(
      'MMM. yyyy',
      'en_US',
    ).format(selectedDate);
    final String formattedWeekDateMin = DateFormat(
      'MM/dd',
      'en_US',
    ).format(selectedWeekDateMin);
    final String formattedWeekDateMax = DateFormat(
      'MM/dd',
      'en_US',
    ).format(selectedWeekDateMax);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: isWeekCharted ? onPreviousWeek : onPreviousMonth,
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  size: 48,
                  color: Colors.black,
                ),
                padding: const EdgeInsets.all(0),
              ),
              const SizedBox(width: 4),
              Text(
                isWeekCharted
                    ? "$formattedWeekDateMin~$formattedWeekDateMax"
                    : formattedDate,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: isWeekCharted ? onNextWeek : onNextMonth,
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  size: 48,
                  color: Colors.black,
                ),
                padding: const EdgeInsets.all(0),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton.filled(
              onPressed: setWeekCharted,
              icon: Icon(
                Icons.bar_chart,
                size: 36,
                color: isWeekCharted ? Colors.white : Colors.black,
              ),
              style: IconButton.styleFrom(
                backgroundColor: isWeekCharted ? Colors.black : Colors.white,
                foregroundColor: isWeekCharted ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------
// TodaySpentMoney (StatelessWidget) - 디자인 유지
// ---------------------------------------------------------------

class TodaySpentMoney extends StatelessWidget {
  final double todaySpentMoney;
  final double dailyLimit;
  final bool isWeekCharted;
  final double weeklyLimit;
  final List<double> weeklySpending;
  final String weekStatsTitle;

  const TodaySpentMoney({
    super.key,
    required this.todaySpentMoney,
    required this.dailyLimit,
    required this.isWeekCharted,
    required this.weeklyLimit,
    required this.weeklySpending,
    required this.weekStatsTitle,
  });

  @override
  Widget build(BuildContext context) {
    // 주간 합계 계산
    final double weeklyTotal = weeklySpending.reduce((a, b) => a + b);

    // 각 금액을 지역 설정에 맞게 포맷팅
    final String formattedTodaySpent = formatCurrency(context, todaySpentMoney);
    final String formattedDailyLimit = formatCurrency(context, dailyLimit);
    final String formattedWeeklyLimit = formatCurrency(context, weeklyLimit);
    final String formattedWeeklyTotal = formatCurrency(context, weeklyTotal);

    return Column(
      children: [
        Text(
          isWeekCharted ? "$weekStatsTitle Spent" : "Today Spent",
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF0000BB),
          ),
        ),
        Text(
          isWeekCharted ? formattedWeeklyTotal : formattedTodaySpent,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0000BB),
          ),
        ),
        Text(
          isWeekCharted
              ? "Weekly limit: Under $formattedWeeklyLimit"
              : "Daily limit: Under $formattedDailyLimit",
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF0000BB),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------
// Cylinder (StatelessWidget) - 디자인 유지
// ---------------------------------------------------------------

class Cylinder extends StatelessWidget {
  final double screenWidth;
  final double currentSpentMoney;
  final double limitMoney;
  final double limitMoneyHeightRatio;
  final double spentMoneyHeightRatio;
  final double targetMoney;
  final DateTime selectedDate;

  const Cylinder({
    super.key,
    required this.screenWidth,
    required this.currentSpentMoney,
    required this.limitMoney,
    required this.limitMoneyHeightRatio,
    required this.spentMoneyHeightRatio,
    required this.targetMoney,
    required this.selectedDate,
  });

  // 지역 설정을 반영한 통화 포맷팅 함수
  String _formatCurrency(BuildContext context, double amount, {int? decimal}) {
    final locale = Localizations.localeOf(context).toString();
    const noDecimalLocales = ['ko_KR', 'ja_JP', 'ko', 'ja'];
    // 별도의 설정이 없으면 KRW/JPY는 0자리, 나머지는 1자리 소수점 표시
    int digits = decimal ?? (noDecimalLocales.contains(locale) ? 0 : 0);

    final formatter = NumberFormat.simpleCurrency(
      locale: 'ko_KR',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final DateTime today = DateTime.now();
        final double maxHeight = constraints.maxHeight;

        const double topReservedSpace = 40.0;
        final double drawingAreaHeight = maxHeight - topReservedSpace;
        const double maxRatioLimit = 0.9;

        final bool isCurrentMonth =
            selectedDate.year == today.year &&
            selectedDate.month == today.month;
        final bool isFutureMonth =
            selectedDate.year > today.year ||
            (selectedDate.year == today.year &&
                selectedDate.month > today.month);
        final bool isPastMonth = !isCurrentMonth && !isFutureMonth;

        double limitMoneyHeight;

        final double spentMoneyHeight =
            (spentMoneyHeightRatio * drawingAreaHeight).clamp(
              0.0,
              drawingAreaHeight * 1.2,
            );

        final double spentMoneyTextHeight = spentMoneyHeight.clamp(
          0.0,
          drawingAreaHeight + 20,
        );

        final double cylinderWidth = screenWidth * 0.38;

        String formattedSpentMoney = '';
        String formattedLimitMoney = '';

        // --- 금액 표시 문자열 생성 로직 수정 구간 ---
        if (isPastMonth) {
          final String targetStr = formatCurrency(
            context,
            targetMoney,
          );
          formattedLimitMoney =
              "${DateFormat("MMM", 'en_US').format(selectedDate)}\n$targetStr";
          formattedSpentMoney = formatCurrency(context, currentSpentMoney);
          limitMoneyHeight = drawingAreaHeight * maxRatioLimit;
        } else if (isFutureMonth) {
          final String zeroStr = formatCurrency(context, 0);
          formattedLimitMoney =
              "${DateFormat("MMM", 'en_US').format(selectedDate)}\n$zeroStr";
          formattedSpentMoney = zeroStr;
          limitMoneyHeight = 0;
        } else {
          final String limitStr = formatCurrency(
            context,
            limitMoney,
          );
          formattedLimitMoney =
              "${DateFormat("MMM d", 'en_US').format(today)}\n$limitStr";
          formattedSpentMoney = formatCurrency(context, currentSpentMoney);
          limitMoneyHeight = (limitMoneyHeightRatio * drawingAreaHeight).clamp(
            0.0,
            drawingAreaHeight * maxRatioLimit,
          );
        }
        // ---------------------------------------

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formattedLimitMoney,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.end,
                  ),
                  SizedBox(height: limitMoneyHeight),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: cylinderWidth,
                    height: maxHeight,
                    color: Colors.white,
                  ),
                  Container(
                    width: cylinderWidth,
                    height: spentMoneyHeight.clamp(0.0, maxHeight),
                    decoration: const BoxDecoration(color: _primaryColor),
                  ),
                  Positioned(
                    bottom: limitMoneyHeight,
                    child: Container(
                      width: cylinderWidth,
                      height: 1,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formattedSpentMoney,
                      style: const TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  SizedBox(height: spentMoneyTextHeight),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------
// WeekStats (StatelessWidget)
// ---------------------------------------------------------------

class WeekStats extends StatelessWidget {
  const WeekStats({
    super.key,
    required this.weekStatsTitle,
    required List<double> weeklySpending,
    required this.limitLineHeight,
    required double dailyLimit,
    required DateTime selectedWeekDateMin,
    required DateTime selectedWeekDateMax,
  }) : _weeklySpending = weeklySpending,
       _dailyLimit = dailyLimit,
       _selectedWeekDateMin = selectedWeekDateMin,
       _selectedWeekDateMax = selectedWeekDateMax;

  final String weekStatsTitle;
  final List<double> _weeklySpending;
  final double limitLineHeight;
  final double _dailyLimit;
  final DateTime _selectedWeekDateMin;
  final DateTime _selectedWeekDateMax;

  // 지역 설정을 반영한 통화 포맷팅 함수
  String _formatCurrency(BuildContext context, double amount, {int? decimal}) {
    final locale = Localizations.localeOf(context).toString();
    const noDecimalLocales = ['ko_KR', 'ja_JP', 'ko', 'ja'];
    // KRW/JPY는 소수점 0자리, 나머지는 1자리 또는 지정된 자리수
    int digits = decimal ?? (noDecimalLocales.contains(locale) ? 0 : 0);

    final formatter = NumberFormat.simpleCurrency(
      locale: 'ko_KR',
      decimalDigits: digits,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.92,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weekStatsTitle,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        // 1. 주간 총 지출액 포맷팅 적용
                        _formatCurrency(
                          context,
                          _weeklySpending.reduce((a, b) => a + b),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        "Spent",
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    8,
                    (index) {
                      if (index == 7) {
                        return Expanded(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                bottom: limitLineHeight + 18,
                                left: 0,
                                child: FittedBox(
                                  fit: BoxFit.fill,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      // 2. 일일 한도 가이드 금액 포맷팅 (소수점 없이 정수로)
                                      _formatCurrency(
                                        context,
                                        _dailyLimit,
                                        decimal: 0,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      double daySpent = _weeklySpending[index];
                      double barHeight;
                      if (daySpent == 0) {
                        barHeight = 0;
                      } else {
                        barHeight =
                            (daySpent / _dailyLimit) * limitLineHeight >
                                limitLineHeight * 1.8
                            ? limitLineHeight * 1.8
                            : (daySpent / _dailyLimit) * limitLineHeight;
                      }

                      DateTime now = DateTime.now();
                      bool isToday = now.weekday % 7 == index;

                      // 3. 막대 상단 일일 지출액 포맷팅 (심플하게 표시하기 위해 simpleCurrency 대신 숫자로만 표시하거나 원화/달러 구분)
                      // 여기서는 통화 기호를 제외하고 숫자만 포맷팅하거나, 전체 포맷팅을 적용할 수 있습니다.
                      // 디자인상 숫자만 있는 게 깔끔하므로 숫자 포맷만 유지하거나 포맷팅 함수를 씁니다.
                      final locale = Localizations.localeOf(context).toString();
                      String spentText = NumberFormat.decimalPattern(
                        'ko_KR',
                      ).format(daySpent);

                      return Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              flex: 8,
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.bottomCenter,
                                children: [
                                  Positioned(
                                    bottom: limitLineHeight,
                                    child: Container(
                                      width: 36,
                                      height: 0.5,
                                      color: Colors.black45,
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      SizedBox(
                                        height: 14,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            spentText,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 16,
                                        height: barHeight,
                                        decoration: BoxDecoration(
                                          color: isToday
                                              ? const Color(0xFF00D0FF)
                                              : const Color(0xFF0000BB),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 0.5,
                              color: Colors.black,
                            ),
                            Expanded(
                              flex: 1,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${_selectedWeekDateMin.add(Duration(days: index)).day}",
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    Text(
                                      [
                                        "(S)",
                                        "(M)",
                                        "(T)",
                                        "(W)",
                                        "(T)",
                                        "(F)",
                                        "(S)",
                                      ][index],
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// TargetMonthlyMax (StatelessWidget) - 디자인 유지
// ---------------------------------------------------------------

class TargetMonthlyMax extends StatelessWidget {
  final double targetMoney;
  final ValueChanged<double> onSetTargetMoney;

  const TargetMonthlyMax({
    super.key,
    required this.targetMoney,
    required this.onSetTargetMoney,
  });

  // 지역 설정을 반영한 통화 포맷팅 함수
  String _formatCurrency(BuildContext context, double amount) {
    final locale = Localizations.localeOf(context).toString();
    const noDecimalLocales = ['ko_KR', 'ja_JP', 'ko', 'ja'];
    // 목표 금액은 보통 정수로 표시하는 것이 깔끔하므로 소수점을 0으로 설정합니다.
    int digits = noDecimalLocales.contains(locale) ? 0 : 0;

    final formatter = NumberFormat.simpleCurrency(
      locale: 'ko_KR',
      decimalDigits: digits,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // 수정한 부분: 지역 기반 포맷팅 함수 호출
    final String formattedTargetMoney = _formatCurrency(context, targetMoney);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 24),
            const Text(
              "Target Monthly Max",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            IconButton(
              onPressed: () {
                showDialog(
                  barrierColor: Colors.transparent,
                  context: context,
                  builder: (BuildContext context) {
                    return SettingTargetModal(
                      onSetTargetMoney: onSetTargetMoney,
                    );
                  },
                );
              },
              icon: const Icon(
                Icons.edit,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        Text(
          formattedTargetMoney,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 0.5,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------
// SettingTargetModal (StatefulWidget) - 디자인 유지
// ---------------------------------------------------------------

class SettingTargetModal extends StatefulWidget {
  final ValueChanged<double> onSetTargetMoney;

  const SettingTargetModal({
    super.key,
    required this.onSetTargetMoney,
  });

  @override
  State<SettingTargetModal> createState() => _SettingTargetModalState();
}

class _SettingTargetModalState extends State<SettingTargetModal> {
  late final TextEditingController _setTargetMonthlyMax;
  final FocusNode _focusNode = FocusNode();
  final NumberFormat _formatter = NumberFormat.decimalPattern('en_US');

  @override
  void initState() {
    super.initState();
    _setTargetMonthlyMax = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _setTargetMonthlyMax.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _unformat(String text) {
    return text.replaceAll(',', '');
  }

  void _onTextChanged(String newText) {
    String numericText = _unformat(newText);

    if (numericText.isEmpty) {
      _setTargetMonthlyMax.value = _setTargetMonthlyMax.value.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
        composing: TextRange.empty,
      );
      return;
    }

    double? value = double.tryParse(numericText);

    if (value != null) {
      String formattedText = _formatter.format(value);

      int offset = formattedText.length;

      _setTargetMonthlyMax.value = _setTargetMonthlyMax.value.copyWith(
        text: formattedText,
        selection: TextSelection.collapsed(offset: offset),
        composing: TextRange.empty,
      );
    }
  }

  void _onOkPressed() {
    double? newTarget = double.tryParse(_unformat(_setTargetMonthlyMax.text));
    if (newTarget != null && newTarget >= 0) {
      widget.onSetTargetMoney(newTarget);
    } else {
      return;
    }
  }

  void _onCancelPressed() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shadowColor: Colors.black,
      elevation: 4,
      backgroundColor: Colors.white,
      alignment: const Alignment(0, -0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Target Monthly Max",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _setTargetMonthlyMax,
              focusNode: _focusNode,
              onChanged: _onTextChanged,
              keyboardType: TextInputType.number,
              cursorColor: Colors.black,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF1F1F1),
                hintText: "Enter The Target",
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onCancelPressed,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: const Color(0xFFF1F1F1),
                      foregroundColor: Colors.black,
                      overlayColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onOkPressed,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      overlayColor: Colors.black,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
