import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({
    super.key,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  double _targetMoney = 0;

  final double _currentSpentMoney = 0;
  double _monthDailyLimitMoney = 0;
  double _limitMoneyHeightRatio = 0;
  final double _spentMoneyHeightRatio = 0;
  final double todaySpentMoney = 0;

  @override
  void initState() {
    super.initState();
    _loadTargetMoney();
  }

  Future<void> _loadTargetMoney() async {
    final prefs = await SharedPreferences.getInstance();
    _targetMoney = prefs.getDouble('target_money') ?? 0;
    DateTime now = DateTime.now();
    _limitMoneyHeightRatio = now.day / DateTime(now.year, now.month + 1, 0).day;
    _monthDailyLimitMoney = _targetMoney * _limitMoneyHeightRatio;
  }

  Future<void> _storeTargetMoney(double newTarget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('target_money', newTarget);
    setState(() {
      _targetMoney = newTarget;
    });
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadTargetMoney(),
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState != ConnectionState.done ||
            asyncSnapshot.hasError) {
          return const Center();
        }
        final screenWidth = MediaQuery.of(context).size.width;
        return Column(
          children: [
            Header(),
            TodaySpentMoney(todaySpentMoney: todaySpentMoney),
            SizedBox(height: 24),
            Expanded(
              child: Cylinder(
                screenWidth: screenWidth,
                currentSpentMoney: _currentSpentMoney,
                limitMoney: _monthDailyLimitMoney,
                limitMoneyHeightRatio: _limitMoneyHeightRatio,
                spentMoneyHeightRatio: _spentMoneyHeightRatio,
                targetMoney: _targetMoney,
              ),
            ),
            SizedBox(height: 24),
            TargetMonthlyMax(
              targetMoney: _targetMoney,
              onSetTargetMoney: _storeTargetMoney,
            ),
            SizedBox(height: 36),
          ],
        );
      },
    );
  }
}

class Header extends StatelessWidget {
  const Header({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.chevron_left_rounded,
                  size: 48,
                  color: Colors.black,
                ),
                padding: EdgeInsets.all(0),
              ),
              SizedBox(width: 4),
              Text(
                'Nov. 2025',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.chevron_right_rounded,
                  size: 48,
                  color: Colors.black,
                ),
                padding: EdgeInsets.all(0),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton.filled(
              onPressed: () {},
              icon: Icon(
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

class TodaySpentMoney extends StatelessWidget {
  const TodaySpentMoney({
    super.key,
    required this.todaySpentMoney,
  });

  final double todaySpentMoney;

  static const Color primaryColor = Color(0xFF0000BB);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Today Spent",
          style: TextStyle(
            fontSize: 16,
            color: primaryColor,
          ),
        ),
        Text(
          "\$ $todaySpentMoney",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        Text(
          "Daily limit: Under \$50",
          style: TextStyle(
            fontSize: 12,
            color: primaryColor,
          ),
        ),
      ],
    );
  }
}

class Cylinder extends StatelessWidget {
  const Cylinder({
    super.key,
    required this.screenWidth,
    required this.currentSpentMoney,
    required this.limitMoney,
    required this.limitMoneyHeightRatio,
    required this.spentMoneyHeightRatio,
    required this.targetMoney,
  });

  final double screenWidth;
  final double currentSpentMoney;
  final double limitMoney;
  final double limitMoneyHeightRatio;
  final double spentMoneyHeightRatio;
  final double targetMoney;

  @override
  Widget build(BuildContext context) {
    const Color blueColor = Color(0xFF0000BB);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxHeight = constraints.maxHeight;
        // 높이 비율은 임의로 설정된 값
        final double limitMoneyHeight = limitMoneyHeightRatio <= 0.888
            ? maxHeight * limitMoneyHeightRatio
            : maxHeight * 0.888;
        final double spentMoneyHeight = spentMoneyHeightRatio <= 0.888
            ? maxHeight * spentMoneyHeightRatio
            : maxHeight * 0.888;
        final double cylinderWidth = screenWidth * 0.38;

        final String formattedSpentMoney =
            "\$${NumberFormat('#,###.0', 'en-US').format(currentSpentMoney)}";
        final String formattedLimitMoney =
            "${DateFormat("MMM d").format(DateTime.now())}\n\$${NumberFormat('#,###', 'en-US').format(limitMoney)}";

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formattedLimitMoney,
                    style: TextStyle(
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
            SizedBox(width: 8),
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
                  // 기본 배경 (원통의 빈 부분)
                  Container(
                    width: cylinderWidth,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                  ),
                  // 사용 금액 표시 (채워진 부분)
                  Container(
                    width: cylinderWidth,
                    height: spentMoneyHeight,
                    decoration: const BoxDecoration(
                      color: blueColor,
                    ),
                  ),
                  // 목표 한계선
                  SizedBox(
                    width: cylinderWidth,
                    height: limitMoneyHeight,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.black,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedSpentMoney,
                    style: TextStyle(
                      color: blueColor,
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
        "\$${NumberFormat('#,###', 'en-US').format(targetMoney)}";
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 24),
            Text(
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
              icon: Icon(
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
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 0.5,
          ),
        ),
      ],
    );
  }
}

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
      alignment: Alignment(0, -0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Target Monthly Max",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
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
                fillColor: Color(0xFFF1F1F1),
                hintText: "Enter The Target",
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16, // 좌우 여백을 늘려 힌트 텍스트가 잘리지 않게 조정
                  vertical: 14, // 높이 조정
                ),
              ),
              textAlign: TextAlign.center, // 텍스트 중앙 정렬
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onCancelPressed,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.fromHeight(48),
                      backgroundColor: Color(0xFFF1F1F1),
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
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onOkPressed,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.fromHeight(48),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      overlayColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                    child: Text(
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
