import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/widget/MyBannerAdWidget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Detail extends StatefulWidget {
  const Detail({super.key});

  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> {
  Map<String, List<Map<String, dynamic>>> groupedData = {};
  List<String> sortedDates = [];
  // 현재 보고 있는 기준 날짜
  DateTime _viewDate = DateTime(2025, 12);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 달을 이동하는 함수
  void _changeMonth(int offset) {
    setState(() {
      _viewDate = DateTime(_viewDate.year, _viewDate.month + offset);
    });
    _loadData(); // 달이 변경되면 데이터를 다시 불러옴
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    // _viewDate 기준으로 storageKey 생성 (예: december_2025_data)
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

  String _getDayTotal(List<Map<String, dynamic>> expenses) {
    int total = 0;
    final locale = Localizations.localeOf(context).toString();
    const noDecimalLocales = ['ko_KR', 'ja_JP', 'ko', 'ja'];
    int digits = noDecimalLocales.contains(locale) ? 0 : 1;
    final formatter = NumberFormat.simpleCurrency(
      locale: locale,
      decimalDigits: digits,
    );
    for (var e in expenses) {
      total += int.tryParse(e['price'].replaceAll(',', '')) ?? 0;
    }
    return formatter.format(total);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _changeMonth(-1), // 이전 달
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        size: 48,
                        color: Colors.black,
                      ),
                      padding: const EdgeInsets.all(0),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM. yyyy').format(_viewDate),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => _changeMonth(1), // 다음 달
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
                    onPressed: () {}, // 날짜 직접 선택
                    icon: const Icon(
                      Icons.calendar_month_rounded,
                      size: 28,
                      color: Colors.black,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: MyBannerAdWidget(
                adSize: AdSize.banner,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: sortedDates.isEmpty
                  ? const Center(child: Text("내역이 없습니다.")) // 데이터 없을 때 처리
                  : ListView.builder(
                      itemCount: sortedDates.length,
                      itemBuilder: (BuildContext ctx, int idx) {
                        String dateKey = sortedDates[idx];
                        List<Map<String, dynamic>> dayExpenses =
                            groupedData[dateKey]!;
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
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
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
                              itemBuilder: (BuildContext ctx, int subIdx) {
                                var item = dayExpenses[subIdx];
                                final locale = Localizations.localeOf(
                                  context,
                                ).toString();
                                const noDecimalLocales = [
                                  'ko_KR',
                                  'ja_JP',
                                  'ko',
                                  'ja',
                                ];
                                int digits = noDecimalLocales.contains(locale)
                                    ? 0
                                    : 1;
                                final formatter = NumberFormat.simpleCurrency(
                                  locale: locale,
                                  decimalDigits: digits,
                                );
                                final price = formatter.format(
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
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(item['detail'] ?? ""),
                                      ),
                                      Expanded(
                                        flex: 2,
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
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
