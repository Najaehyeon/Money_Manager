import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/widget/MyBannerAdWidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class Detail extends StatefulWidget {
  const Detail({super.key});

  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> {
  Map<String, List<Map<String, dynamic>>> groupedData = {};
  List<String> sortedDates = [];
  DateTime _viewDate = DateTime(2025, 12);

  // 캘린더 보기 모드 상태 추가
  bool _showCalendar = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _changeMonth(int offset) {
    setState(() {
      _viewDate = DateTime(_viewDate.year, _viewDate.month + offset);
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

    List<String> sortedKeys = tempGrouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

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
  String _formatCurrency(int amount) {
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
    int total = 0;
    for (var e in expenses) {
      total += int.tryParse(e['price'].replaceAll(',', '')) ?? 0;
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
                    onPressed: () {
                      setState(() {
                        _showCalendar = !_showCalendar;
                      });
                    },
                    icon: Icon(
                      _showCalendar
                          ? Icons.list_alt_rounded
                          : Icons.calendar_month_rounded,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      return const Center(child: Text("내역이 없습니다."));
    }
    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (BuildContext ctx, int idx) {
        String dateKey = sortedDates[idx];
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
                  int.parse(item['price'].replaceAll(',', '')),
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          item['category'] ?? "",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      Expanded(flex: 3, child: Text(item['detail'] ?? "")),
                      Expanded(
                        flex: 2,
                        child: Text(
                          price,
                          textAlign: TextAlign.end,
                          style: const TextStyle(color: Color(0xFF0000BB)),
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
      },
    );
  }

  // --- 달력 뷰 위젯 추가 ---
  Widget _buildCalendarView() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _viewDate,
      headerVisible: false, // 상단 자체 헤더는 숨김 (이미 구현된 헤더 사용)
      calendarFormat: CalendarFormat.month,
      locale: Localizations.localeOf(context).toString(),
      onPageChanged: (focusedDay) {
        setState(() {
          _viewDate = DateTime(focusedDay.year, focusedDay.month);
        });
        _loadData();
      },
      calendarBuilders: CalendarBuilders(
        // 각 날짜의 아래쪽에 지출 총액 표시
        markerBuilder: (context, date, events) {
          String dateKey = DateFormat('yyyy-MM-dd').format(date);
          if (groupedData.containsKey(dateKey)) {
            return Positioned(
              bottom: 1,
              child: Text(
                _getDayTotal(groupedData[dateKey]!),
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.blue,
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
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
