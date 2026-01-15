import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/Detail/update.dart';
import 'package:money_manager/widget/MyBannerAdWidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class Detail extends StatefulWidget {
  const Detail({super.key});

  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> with RouteAware {
  Map<String, List<Map<String, dynamic>>> groupedData = {};
  List<String> sortedDates = [];
  DateTime _viewDate = DateTime.now();

  // 선택된 날짜 상태 추가
  DateTime? _selectedDay;

  // 캘린더 보기 모드 상태 추가
  bool _showCalendar = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadData();
  }

  // 2. 현재 화면이 스택으로 돌아왔을 때 호출되는 메서드
  @override
  void didPopNext() {
    _loadSettings();
    _loadData();
  }

  // 뷰 모드 설정 불러오기
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // 저장된 값이 없으면 기본값인 false(리스트) 사용
      _showCalendar = prefs.getBool('show_calendar') ?? false;
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _viewDate = DateTime(_viewDate.year, _viewDate.month + offset);
      _selectedDay = null; // 월 변경 시 선택된 날짜 초기화
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey =
        DateFormat('MMMM_yyyy').format(_viewDate).toLowerCase() + '_data';
    final List<String> rawData = prefs.getStringList(storageKey) ?? [];

    Map<String, List<Map<String, dynamic>>> tempGrouped = {};

    for (var item in rawData) {
      Map<String, dynamic> expense = json.decode(item);
      String date = expense['date'];

      if (tempGrouped[date] == null) {
        tempGrouped[date] = [];
      }
      tempGrouped[date]!.add(expense);
    }

    // 날짜 역순 정렬 (최신순)
    List<String> sortedKeys = tempGrouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    // 중요: 각 날짜 내부의 리스트도 일관성을 위해 정렬이 필요하다면 여기서 수행할 수 있습니다.
    // 현재는 입력 순서를 유지합니다.

    setState(() {
      groupedData = tempGrouped;
      sortedDates = sortedKeys;
    });
  }

  String _getWeekday(String dateStr) {
    DateTime date = DateTime.parse(dateStr);
    return DateFormat('E').format(date);
  }

  // 금액 포맷팅을 위한 통합 함수
  String _formatCurrency(double amount) {
    final locale = Localizations.localeOf(context).toString();
    const noDecimalLocales = ['ko_KR', 'ja_JP', 'ko', 'ja'];
    int digits = noDecimalLocales.contains(locale) ? 0 : 1;
    final formatter = NumberFormat.simpleCurrency(
      locale: locale,
      decimalDigits: digits,
    );
    return formatter.format(amount);
  }

  String _getDayTotal(List<Map<String, dynamic>> expenses) {
    double total = 0;
    for (var e in expenses) {
      total += double.tryParse(e['price'].replaceAll(',', '')) ?? 0;
    }
    return _formatCurrency(total);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 상단 헤더 부분
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _changeMonth(-1),
                      icon: const Icon(Icons.chevron_left_rounded, size: 48),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM. yyyy').format(_viewDate),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => _changeMonth(1),
                      icon: const Icon(Icons.chevron_right_rounded, size: 48),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton.filled(
                    // 버튼 클릭 시 리스트 <-> 캘린더 전환
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      setState(() {
                        _showCalendar = !_showCalendar;
                        _selectedDay = null;
                        // 변경된 상태를 저장
                        prefs.setBool('show_calendar', _showCalendar);
                      });
                    },
                    icon: Icon(
                      Icons.calendar_month_rounded,
                      size: 28,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _showCalendar
                          ? Colors.black
                          : Colors.white,
                      foregroundColor: _showCalendar
                          ? Colors.white
                          : Colors.black,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 광고 영역
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: MyBannerAdWidget(adSize: AdSize.banner),
            ),
          ),
          // 메인 콘텐츠 영역 (리스트 또는 달력)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _showCalendar ? _buildCalendarView() : _buildListView(),
            ),
          ),
        ],
      ),
    );
  }

  // --- 기존 리스트 뷰 위젯 ---
  Widget _buildListView() {
    if (sortedDates.isEmpty) {
      return const Center(child: Text("No history"));
    }
    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (BuildContext ctx, int idx) {
        String dateKey = sortedDates[idx];
        return _buildDailyItem(dateKey); // 공통 아이템 빌더로 분리
      },
    );
  }

  // 날짜별 상세 내역 디자인 (리스트뷰와 달력 선택 결과에서 공통 사용)
  Widget _buildDailyItem(String dateKey) {
    if (!groupedData.containsKey(dateKey)) return const SizedBox.shrink();

    List<Map<String, dynamic>> dayExpenses = groupedData[dateKey]!;
    DateTime dateObj = DateTime.parse(dateKey);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dateObj.day.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _getWeekday(dateKey),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  "${dateObj.year}.${dateObj.month.toString().padLeft(2, '0')}",
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
            Text(
              _getDayTotal(dayExpenses),
              style: const TextStyle(
                color: Color(0xFF0000BB),
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dayExpenses.length,
          itemBuilder: (context, subIdx) {
            var item = dayExpenses[subIdx];
            final price = _formatCurrency(
              double.parse(item['price'].replaceAll(',', '')),
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      item['category'] ?? "",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: SizedBox(),
                  ),
                  Expanded(
                    flex: 6,
                    child: GestureDetector(
                      onTap: () async {
                        final storageKey =
                            DateFormat(
                              'MMMM_yyyy',
                            ).format(DateTime.parse(dateKey)).toLowerCase() +
                            '_data';

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UpdatePage(
                              // itemIndex: subIdx,  <-- 인덱스는 이제 사용하지 않습니다.
                              initialData: Map<String, dynamic>.from(
                                item,
                              ), // 수정될 데이터
                              oldData: Map<String, dynamic>.from(
                                item,
                              ), // 비교용 원본 데이터
                              dateKey: storageKey,
                            ),
                          ),
                        );
                        if (result == true) await _loadData();
                      },
                      child: Text(item['detail'] ?? ""),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      price,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: Color(0xFF0000BB),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // --- 달력 뷰 위젯 추가 ---
  Widget _buildCalendarView() {
    String? selectedKey = _selectedDay != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDay!)
        : null;

    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2100, 12, 31),
          focusedDay: _viewDate,
          headerVisible: false,
          calendarFormat: CalendarFormat.month,
          locale: Localizations.localeOf(context).toString(),

          // 선택된 날짜 로직 추가
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _viewDate = focusedDay;
            });
          },

          onPageChanged: (focusedDay) {
            setState(() {
              _viewDate = DateTime(focusedDay.year, focusedDay.month);
              _selectedDay = null; // 월 변경 시 선택 해제
            });
            _loadData();
          },
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              String dateKey = DateFormat('yyyy-MM-dd').format(date);
              if (groupedData.containsKey(dateKey)) {
                return Positioned(
                  bottom: -4,
                  child: Text(
                    _getDayTotal(groupedData[dateKey]!),
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF0000BB),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
              return null;
            },
          ),
          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
        // 선택된 날짜의 리스트 표시
        Expanded(
          child: SingleChildScrollView(
            child: selectedKey != null && groupedData.containsKey(selectedKey)
                ? _buildDailyItem(selectedKey)
                : Center(
                    child: Text(
                      _selectedDay == null ? "Select Date" : "No history",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
