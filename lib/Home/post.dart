import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // JSON 인코딩/디코딩을 위해 추가

class Post extends StatefulWidget {
  const Post({super.key});

  @override
  State<Post> createState() => _PostState();
}

class _PostState extends State<Post> {
  // 캘린더 관련 상태
  DateTime _selectedDate = DateTime.now();
  // 사용자가 볼 날짜 형식
  String get formatedDate => DateFormat('MMMM d, yyyy').format(_selectedDate);
  // 저장용 날짜 형식 (YYYY-MM-dd)
  String get _storageDate => DateFormat('yyyy-MM-dd').format(_selectedDate);

  // 카테고리 관련 상태
  List<String> categories = [];
  String? _selectedCategory; // 현재 선택된 카테고리
  late TextEditingController _setAddCategory;
  final FocusNode _focusNode = FocusNode();

  // 입력 필드 관련 상태
  late TextEditingController _detailController; // Detail
  late TextEditingController _priceController; // Price

  @override
  void initState() {
    super.initState();
    _setAddCategory = TextEditingController();
    _detailController = TextEditingController(); // Detail 컨트롤러 초기화
    _priceController = TextEditingController(); // Price 컨트롤러 초기화
    _initializeData();
  }

  // 데이터 초기화 및 로딩 함수
  Future<void> _initializeData() async {
    await _loadCategoryData();
    // 초기 로딩 후 기본 카테고리 설정
    if (categories.isNotEmpty && _selectedCategory == null) {
      setState(() {
        _selectedCategory = categories.first;
      });
    }
  }

  @override
  void dispose() {
    _setAddCategory.dispose();
    _detailController.dispose();
    _priceController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // SharedPreferences에서 카테고리 로드
  Future<void> _loadCategoryData() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedCategories = prefs.getStringList('categories') ?? [];

    // 로드 후 상태 업데이트
    if (mounted) {
      setState(() {
        categories = loadedCategories;
        // 로드된 카테고리가 있을 경우, 현재 선택된 카테고리가 없을 때 첫 번째 항목을 기본 선택
        if (categories.isNotEmpty && _selectedCategory == null) {
          _selectedCategory = categories.first;
        }
      });
    }
  }

  // 새 카테고리 추가
  Future<void> _addCategory() async {
    final newCategory = _setAddCategory.text.trim();

    if (newCategory.isEmpty) return; // 빈 값은 추가하지 않음

    final prefs = await SharedPreferences.getInstance();

    if (categories.contains(newCategory)) {
      _setAddCategory.clear();
      if (mounted) {
        Navigator.of(context).pop(); // Dialog 닫기
      }
      return;
    }

    // setState 내에서 categories 리스트 업데이트 및 SharedPreferences 저장
    setState(() {
      categories.add(newCategory);
      _selectedCategory = newCategory; // 새로 추가된 카테고리를 선택
    });

    await prefs.setStringList('categories', categories);

    _setAddCategory.clear(); // 텍스트 필드 초기화

    // Dialog 닫기
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // 모든 데이터 삭제 (개발용)
  Future<void> _deleteAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // UI 상태도 초기화
    setState(() {
      categories = [];
      _selectedCategory = null;
      _selectedDate = DateTime.now();
      _detailController.clear();
      _priceController.clear();
    });
    print('All SharedPreferences data cleared.');
  }

  // 지출 데이터를 SharedPreferences에 저장
  Future<void> _saveExpenseData() async {
    final detail = _detailController.text.trim();
    final price = _priceController.text.trim();

    // 입력값 유효성 검사
    if (_selectedCategory == null || detail.isEmpty || price.isEmpty) {
      // 사용자에게 알림 (Snack Bar 등)을 표시할 수 있으나, 여기서는 콘솔 출력만 하겠습니다.
      print('Error: All fields (Category, Detail, Price) must be filled.');
      return;
    }

    // 저장할 데이터 맵 생성
    final expense = {
      'date': _storageDate,
      'category': _selectedCategory,
      'detail': detail,
      'price': price, // 문자열로 저장 요청에 따라 문자열 유지
    };

    // 데이터 맵을 JSON 문자열로 인코딩
    final expenseJsonString = json.encode(expense);

    // 저장 키 생성 (예: november_2025_data)
    final storageKey =
        DateFormat('MMMM_yyyy').format(_selectedDate).toLowerCase() + '_data';

    final prefs = await SharedPreferences.getInstance();

    // 현재 키의 기존 목록을 로드
    final List<String> currentData = prefs.getStringList(storageKey) ?? [];

    // 새 데이터를 목록에 추가
    currentData.add(expenseJsonString);

    // 업데이트된 목록을 다시 저장
    await prefs.setStringList(storageKey, currentData);

    print('Data saved successfully to key: $storageKey');
    print('Saved Data: $expenseJsonString');
    print('All Data: $currentData');

    // 성공 후 입력 필드 초기화 및 사용자 피드백 (옵션)
    setState(() {
      _detailController.clear();
      _priceController.clear();
      Navigator.of(context).pop(true);
    });
    // showSnackBar(context, '지출 내역이 저장되었습니다.');
  }

  // Cupertino 날짜 선택기 표시
  void _showDatePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 300.0,
          color: Colors.white,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: _selectedDate,
            minimumDate: DateTime(2025),
            maximumDate: DateTime(2100),
            onDateTimeChanged: (DateTime newDate) {
              setState(() {
                _selectedDate = newDate;
              });
            },
          ),
        );
      },
    );
  }

  // 카테고리 BottomSheet 표시
  void showCategoryBottomSheet() {
    // BottomSheet가 올라올 때마다 최신 카테고리 데이터를 로드 (setState를 포함하므로 비동기로 처리)
    _loadCategoryData();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8, // 적당한 높이로 조절
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              Container(
                width: 120,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              // 카테고리 목록
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  // Consumer/StatefulBuilder 없이 _loadCategoryData()가 최신 목록을 가져오므로
                  // 빌더 함수에서는 `categories` 상태를 사용합니다.
                  child: GridView.builder(
                    shrinkWrap: true,
                    itemCount: categories.length + 1,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2 / 1,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                    itemBuilder: (BuildContext context, int index) {
                      final isAddButton = index == categories.length;
                      final categoryText = isAddButton
                          ? null
                          : categories[index];

                      final isSelected =
                          categoryText == _selectedCategory && !isAddButton;

                      return ElevatedButton(
                        onPressed: () {
                          if (isAddButton) {
                            // 'ADD' 버튼 클릭 시 Dialog 표시
                            showDialog(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  _focusNode.requestFocus();
                                });
                                return Dialog(
                                  // 기존 디자인 유지
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
                                          "ADD CATEGROY",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: _setAddCategory,
                                          focusNode: _focusNode,
                                          cursorColor: Colors.black,
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: const Color(0xFFF1F1F1),
                                            hintText: "Enter The Category",
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide.none,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 14,
                                                ),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.of(
                                                    dialogContext,
                                                  ).pop();
                                                  _setAddCategory
                                                      .clear(); // 취소 시 텍스트 초기화
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  minimumSize:
                                                      const Size.fromHeight(48),
                                                  backgroundColor: const Color(
                                                    0xFFF1F1F1,
                                                  ),
                                                  foregroundColor: Colors
                                                      .black, // 색상 수정: Cancel은 검은색 텍스트
                                                  overlayColor: Colors
                                                      .black12, // 오버레이 색상 수정
                                                  elevation: 0,
                                                  shadowColor:
                                                      Colors.transparent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
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
                                                onPressed:
                                                    _addCategory, // Dialog 닫기는 _addCategory에서 처리
                                                style: ElevatedButton.styleFrom(
                                                  minimumSize:
                                                      const Size.fromHeight(48),
                                                  backgroundColor: Colors.black,
                                                  foregroundColor: Colors.white,
                                                  overlayColor: Colors.white12,
                                                  elevation: 0,
                                                  shadowColor:
                                                      Colors.transparent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
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
                              },
                            );
                          } else {
                            // 카테고리 버튼 클릭 시
                            setState(() {
                              _selectedCategory = categoryText;
                            });
                            Navigator.of(context).pop(); // BottomSheet 닫기
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          // 선택된 카테고리 버튼 색상 변경 (옵션: 선택 상태를 명확히 보여주기 위해)
                          backgroundColor: isSelected
                              ? Colors.black
                              : const Color(0xFFF1F1F1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isAddButton
                            ? const Icon(
                                Icons.add,
                                color: Colors.black,
                              )
                            : Text(
                                categoryText!,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black, // 텍스트 색상도 변경
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F7),
        title: const Text(
          "New Expense",
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Date Section ---
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                "Date",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: () {
                _showDatePicker(context);
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                alignment: Alignment.centerLeft,
                backgroundColor: Colors.white,
                overlayColor: Colors.black12,
                shadowColor: Colors.transparent,
                fixedSize: Size(MediaQuery.of(context).size.width, 48),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatedDate,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const Icon(
                    Icons.date_range_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            // --- Category Section ---
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                "Category",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: showCategoryBottomSheet,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                alignment: Alignment.centerLeft,
                backgroundColor: Colors.white,
                overlayColor: Colors.black12,
                shadowColor: Colors.transparent,
                fixedSize: Size(MediaQuery.of(context).size.width, 48),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _selectedCategory ?? 'Select Category',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            // --- Detail Section ---
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                "Detail",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _detailController, // 컨트롤러 연결
              cursorColor: Colors.black,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(10),
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
            // --- Price Section ---
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                "Price",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _priceController, // 컨트롤러 연결
              cursorColor: Colors.black,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(10),
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
            // --- Post Button ---
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveExpenseData, // 저장 로직 함수 연결
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shadowColor: Colors.transparent,
                backgroundColor: Colors.black,
                fixedSize: Size(MediaQuery.of(context).size.width, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                overlayColor: Colors.white12,
              ),
              child: const Text(
                "POST",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // --- Delete All Data Button (개발용) ---
            ElevatedButton(
              onPressed: _deleteAllData,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shadowColor: Colors.transparent,
                backgroundColor: Colors.blue,
                fixedSize: Size(MediaQuery.of(context).size.width, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                overlayColor: Colors.white12,
              ),
              child: const Text(
                "DELETE All DATA",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
