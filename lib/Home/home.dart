import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // JSON 데이터 처리를 위한 import

// 현재 사용하고 있는 파란색 기본 색상
const Color _primaryColor = Color(0xFF0000BB);

// ---------------------------------------------------------------
// Home (StatefulWidget)
// ---------------------------------------------------------------

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with RouteAware {
  String state = '초기 상태';
  // 상태 변수 (이전과 동일)
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

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // 1. RouteAware를 사용하기 위해 routeObserver에 현재 Route를 등록합니다.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  // 2. 현재 화면이 스택으로 돌아왔을 때 호출되는 메서드
  @override
  void didPopNext() {
    _loadAllData();
  }

  // 6. 위젯이 제거될 때 구독을 해제합니다.
  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
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
    final String key = _getMonthlyDataKey(_selectedDate);

    // 🚨 수정: getStringList를 사용하여 JSON 문자열의 리스트를 받아옵니다.
    final List<String>? monthlyDataList = prefs.getStringList(key);

    double totalSpent = 0;
    double todaySpent = 0;
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (monthlyDataList != null && monthlyDataList.isNotEmpty) {
      try {
        // 리스트의 각 문자열 요소를 순회하며 개별적으로 JSON 디코딩합니다.
        for (String transactionJson in monthlyDataList) {
          final Map<String, dynamic> item = json.decode(transactionJson);

          // price는 문자열로 저장되어 있으므로 double로 변환
          final double price =
              double.tryParse(item['price']?.toString() ?? '0') ?? 0;

          // 1. 선택된 월의 총 지출 금액 계산
          totalSpent += price;

          // 2. 현재 달력상의 오늘 지출 금액 계산
          final String itemDate = item['date']?.toString() ?? '';
          if (itemDate == todayDate) {
            todaySpent += price;
          }
        }
      } catch (e) {
        // 데이터 파싱 오류 처리
        print('Error parsing monthly data: $e');
      }
    }

    // 상태 업데이트
    _currentSpentMoney = totalSpent;
    _todaySpentMoney = todaySpent;

    // 데이터가 업데이트되었으므로 비율 및 한도를 다시 계산
    _calculateMoneyAndRatio();
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
  void setWeekChart() {
    _loadThisWeekData();
    setState(() {
      _isWeekCharted = !_isWeekCharted;
    });
  }

  void _loadThisWeekData() {
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
  }

  void _goToPreviousWeek() {
    setState(() {
      _selectedWeekDateMin = _selectedWeekDateMin.subtract(Duration(days: 7));
      _selectedWeekDateMax = _selectedWeekDateMax.subtract(Duration(days: 7));
    });
  }

  void _goToNextWeek() {
    setState(() {
      _selectedWeekDateMin = _selectedWeekDateMin.add(Duration(days: 7));
      _selectedWeekDateMax = _selectedWeekDateMax.add(Duration(days: 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final screenWidth = MediaQuery.of(context).size.width;

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
        ),
        const SizedBox(height: 24),
        Expanded(
          child: _isWeekCharted
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
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
                                "This week",
                                style: TextStyle(fontSize: 16),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "\$3,013",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text("Spent"),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          FractionallySizedBox(
                            widthFactor: 0.9,
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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

  const TodaySpentMoney({
    super.key,
    required this.todaySpentMoney,
    required this.dailyLimit,
    required this.isWeekCharted,
    required this.weeklyLimit,
  });

  @override
  Widget build(BuildContext context) {
    final String formattedTodaySpent = NumberFormat(
      '#,##0.0',
      'en_US',
    ).format(todaySpentMoney);

    final String formattedDailyLimit = NumberFormat(
      '#,###',
      'en_US',
    ).format(dailyLimit);

    final String formattedWeeklyLimit = NumberFormat(
      '#,###',
      'en_US',
    ).format(weeklyLimit);

    return Column(
      children: [
        Text(
          isWeekCharted ? "Week Spent" : "Today Spent",
          style: TextStyle(
            fontSize: 16,
            color: _primaryColor,
          ),
        ),
        Text(
          "\$ $formattedTodaySpent",
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: _primaryColor,
          ),
        ),
        Text(
          isWeekCharted
              ? "Weekly limit: Under \$$formattedWeeklyLimit"
              : "Daily limit: Under \$$formattedDailyLimit",
          style: const TextStyle(
            fontSize: 12,
            color: _primaryColor,
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final DateTime today = DateTime.now();
        final double maxHeight = constraints.maxHeight;
        const double maxRatioLimit = 0.86;

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
            spentMoneyHeightRatio <= maxRatioLimit * 1.5
            ? maxHeight * spentMoneyHeightRatio * maxRatioLimit
            : maxHeight * maxRatioLimit * 1.25;

        final double spentMoneyTextHeight =
            spentMoneyHeightRatio <= maxRatioLimit * 1.44
            ? maxHeight * spentMoneyHeightRatio * maxRatioLimit
            : maxHeight * maxRatioLimit * 1.188;

        final double cylinderWidth = screenWidth * 0.38;

        String formattedSpentMoney = '';
        String formattedLimitMoney = '';

        if (isPastMonth) {
          // 과거 월: 지출 금액은 해당 월의 최종 지출 금액, 한도는 해당 월의 목표 금액
          formattedLimitMoney =
              "${DateFormat("MMM", 'en_US').format(selectedDate)}\n\$${NumberFormat("#,###", 'en_US').format(targetMoney)}";
          formattedSpentMoney =
              "\$${NumberFormat('#,##0.0', 'en_US').format(currentSpentMoney)}";
          limitMoneyHeight = maxHeight * maxRatioLimit;
        } else if (isFutureMonth) {
          // 미래 월: 지출 금액 0, 한도는 목표 금액 (또는 0)
          formattedLimitMoney =
              "${DateFormat("MMM", 'en_US').format(selectedDate)}\n\$0";
          formattedSpentMoney = "\$0.0";
          limitMoneyHeight = 0;
        } else {
          // 현재 월 (isCurrentMonth)
          // 현재 월: 지출 금액은 현재까지의 총 지출, 한도는 오늘까지의 누적 한도
          formattedLimitMoney =
              "${DateFormat("MMM d", 'en_US').format(today)}\n\$${NumberFormat('#,###', 'en_US').format(limitMoney)}";
          formattedSpentMoney =
              "\$${NumberFormat('#,##0.0', 'en_US').format(currentSpentMoney)}";
          limitMoneyHeight = limitMoneyHeightRatio <= maxRatioLimit
              ? maxHeight * limitMoneyHeightRatio * maxRatioLimit
              : maxHeight * maxRatioLimit;
        }

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
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.end,
                  ),
                  SizedBox(
                    height: limitMoneyHeight,
                  ),
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
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    width: cylinderWidth,
                    height: spentMoneyHeight,
                    decoration: const BoxDecoration(
                      color: _primaryColor,
                    ),
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
                  Text(
                    formattedSpentMoney,
                    style: const TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.start,
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

  @override
  Widget build(BuildContext context) {
    final String formattedTargetMoney =
        "\$${NumberFormat('#,###', 'en_US').format(targetMoney)}";

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
