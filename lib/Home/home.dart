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
  String _message = '초기 상태';

  // 1. RouteAware를 사용하기 위해 routeObserver에 현재 Route를 등록합니다.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  // 2. 현재 화면이 스택으로 돌아왔을 때 호출되는 메서드
  @override
  void didPopNext() {
    // SecondScreen에서 pop()을 실행하여 돌아왔을 때 이곳이 호출됩니다.
    setState(() {
      _message = '${DateTime.now().second}초';
    });
    super.didPopNext();
  }

  // 상태 변수 (이전과 동일)
  double _targetMoney = 0;
  DateTime _selectedDate = DateTime(2025, 11);
  double _currentSpentMoney = 0;
  double _monthDailyLimitMoney = 0;
  double _limitMoneyHeightRatio = 0;
  double _spentMoneyHeightRatio = 0;
  double _todaySpentMoney = 0;
  double _dailyLimit = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
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
    } else {
      // 1. 오늘의 일일 한도 금액 (Daily Limit)
      _dailyLimit = _targetMoney / totalDaysInCurrentMonth;

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
    if (_spentMoneyHeightRatio > 1.0) {
      _spentMoneyHeightRatio = 1.0;
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
    });
    await _loadMonthlySpentData();
  }

  /// 선택된 월을 다음 달로 변경하고 데이터를 다시 로드/계산합니다.
  void _goToNextMonth() async {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    });
    await _loadMonthlySpentData();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
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
        ),
        TodaySpentMoney(
          todaySpentMoney: _todaySpentMoney,
          dailyLimit: _dailyLimit,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Cylinder(
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

  const Header({
    super.key,
    required this.selectedDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat(
      'MMM. yyyy',
      'en_US',
    ).format(selectedDate);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPreviousMonth,
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  size: 48,
                  color: Colors.black,
                ),
                padding: const EdgeInsets.all(0),
              ),
              const SizedBox(width: 4),
              Text(
                formattedDate,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onNextMonth,
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
              onPressed: () {
                // TODO: 통계 화면으로 이동하는 로직 추가
              },
              icon: const Icon(
                Icons.bar_chart,
                size: 36,
                color: Colors.black,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
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

  const TodaySpentMoney({
    super.key,
    required this.todaySpentMoney,
    required this.dailyLimit,
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

    return Column(
      children: [
        const Text(
          "Today Spent",
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
          "Daily limit: Under \$$formattedDailyLimit",
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
        final double maxHeight = constraints.maxHeight;
        const double maxRatioLimit = 0.888;

        final double limitMoneyHeight = limitMoneyHeightRatio <= maxRatioLimit
            ? maxHeight * limitMoneyHeightRatio
            : maxHeight * maxRatioLimit;

        final double spentMoneyHeight = spentMoneyHeightRatio <= maxRatioLimit
            ? maxHeight * spentMoneyHeightRatio
            : maxHeight * maxRatioLimit;

        final double cylinderWidth = screenWidth * 0.38;

        final String formattedSpentMoney =
            "\$${NumberFormat('#,##0.0', 'en_US').format(currentSpentMoney)}";

        final String formattedLimitMoney =
            "${DateFormat("MMM d", 'en_US').format(DateTime.now())}\n\$${NumberFormat('#,###', 'en_US').format(limitMoney)}";

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
                  SizedBox(height: spentMoneyHeight),
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
