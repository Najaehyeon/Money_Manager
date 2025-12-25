import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Post extends StatefulWidget {
  const Post({super.key});

  @override
  State<Post> createState() => _PostState();
}

class _PostState extends State<Post> {
  // 캘린더 관련 상태
  DateTime _selectedDate = DateTime.now();
  String get formatedDate => DateFormat('MMMM d, yyyy').format(_selectedDate);
  String get _storageDate => DateFormat('yyyy-MM-dd').format(_selectedDate);

  // 카테고리 관련 상태
  List<String> categories = [];
  String? _selectedCategory;
  late TextEditingController _setAddCategory;
  final FocusNode _focusNode = FocusNode();
  bool isCategoryDeleteActivated = false;

  // 입력 필드 관련 상태
  late TextEditingController _detailController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _setAddCategory = TextEditingController();
    _detailController = TextEditingController();
    _priceController = TextEditingController();
    _initializeData();
  }

  // 데이터 초기화 및 로딩 함수
  Future<void> _initializeData() async {
    await _loadCategoryData();
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

    if (mounted) {
      setState(() {
        categories = loadedCategories;
        if (categories.isNotEmpty && _selectedCategory == null) {
          _selectedCategory = categories.first;
        }
      });
    }
  }

  // 새 카테고리 추가
  Future<void> _addCategory(StateSetter innerSetState) async {
    final newCategory = _setAddCategory.text.trim();

    if (newCategory.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    if (categories.contains(newCategory)) {
      _setAddCategory.clear();
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    // innerSetState 내에서 categories 리스트 업데이트 및 SharedPreferences 저장
    innerSetState(() {
      categories.add(newCategory);
      _selectedCategory = newCategory; // 새로 추가된 카테고리를 선택
    });

    // 메인 Post 위젯의 상태도 업데이트 (선택된 카테고리 표시를 위해)
    setState(() {
      _selectedCategory = newCategory;
    });

    await prefs.setStringList('categories', categories);

    _setAddCategory.clear();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // 카테고리를 삭제하고 SharedPreferences를 업데이트하는 함수
  Future<void> _deleteCategory(
    String category,
    StateSetter innerSetState,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 카테고리 목록에서 삭제
    categories.remove(category);

    // 2. SharedPreferences 업데이트
    await prefs.setStringList('categories', categories);

    // 3. UI 상태 업데이트
    if (_selectedCategory == category) {
      setState(() {
        _selectedCategory = categories.isNotEmpty ? categories.first : null;
      });
    }

    // 4. BottomSheet 내부 UI 갱신 (StatefulBuilder의 innerSetState 사용)
    innerSetState(() {
      // 리스트 갱신만 요청
    });
  }

  // 모든 데이터 삭제 (개발용)
  Future<void> _deleteAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
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

    if (_selectedCategory == null || detail.isEmpty || price.isEmpty) {
      print('Error: All fields (Category, Detail, Price) must be filled.');
      return;
    }

    final expense = {
      'date': _storageDate,
      'category': _selectedCategory,
      'detail': detail,
      'price': price,
    };

    final expenseJsonString = json.encode(expense);
    final storageKey =
        DateFormat('MMMM_yyyy').format(_selectedDate).toLowerCase() + '_data';
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentData = prefs.getStringList(storageKey) ?? [];

    currentData.add(expenseJsonString);

    await prefs.setStringList(storageKey, currentData);

    setState(() {
      _detailController.clear();
      _priceController.clear();
      Navigator.of(context).pop(true);
    });
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
    _loadCategoryData();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext innerContext, StateSetter innerSetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
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
                    width: 64,
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
                      child: GridView.builder(
                        shrinkWrap: true,
                        itemCount: isCategoryDeleteActivated
                            ? categories.length
                            : categories.length + 1,
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
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((
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
                                                fillColor: const Color(
                                                  0xFFF1F1F1,
                                                ),
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
                                                      _setAddCategory.clear();
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      minimumSize:
                                                          const Size.fromHeight(
                                                            48,
                                                          ),
                                                      backgroundColor:
                                                          const Color(
                                                            0xFFF1F1F1,
                                                          ),
                                                      foregroundColor:
                                                          Colors.black,
                                                      overlayColor:
                                                          Colors.black12,
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
                                                    onPressed: () =>
                                                        _addCategory(
                                                          innerSetState,
                                                        ),
                                                    style: ElevatedButton.styleFrom(
                                                      minimumSize:
                                                          const Size.fromHeight(
                                                            48,
                                                          ),
                                                      backgroundColor:
                                                          Colors.black,
                                                      foregroundColor:
                                                          Colors.white,
                                                      overlayColor:
                                                          Colors.white12,
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
                                if (isCategoryDeleteActivated) return;
                                setState(() {
                                  _selectedCategory = categoryText;
                                });
                                Navigator.of(context).pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              backgroundColor: isSelected
                                  ? Colors.black
                                  : const Color(0xFFF1F1F1),
                              padding: const EdgeInsets.all(8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isAddButton
                                ? const Icon(
                                    Icons.add,
                                    color: Colors.black,
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // 텍스트 영역 (X 버튼이 있을 경우 공간을 양보)
                                      Expanded(
                                        flex: isCategoryDeleteActivated ? 4 : 5,
                                        child: Text(
                                          textAlign: TextAlign.center,
                                          categoryText!,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ),

                                      // 삭제 아이콘 버튼
                                      if (isCategoryDeleteActivated)
                                        Expanded(
                                          flex: 2,
                                          child: IconButton(
                                            onPressed: () => _deleteCategory(
                                              categoryText!,
                                              innerSetState,
                                            ),
                                            icon: const Icon(Icons.close),
                                            padding: EdgeInsets.all(8),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            iconSize: 16,
                                            highlightColor: Colors.grey,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                    ],
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () {
                            innerSetState(() {
                              isCategoryDeleteActivated =
                                  !isCategoryDeleteActivated;
                            });
                          },
                          icon: Icon(
                            Icons.delete_rounded,
                            color: isCategoryDeleteActivated
                                ? Colors.red
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
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
              controller: _detailController,
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
              controller: _priceController,
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
              onPressed: _saveExpenseData,
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
            // ElevatedButton(
            //   onPressed: _deleteAllData,
            //   style: ElevatedButton.styleFrom(
            //     elevation: 0,
            //     shadowColor: Colors.transparent,
            //     backgroundColor: Colors.blue,
            //     fixedSize: Size(MediaQuery.of(context).size.width, 48),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(16),
            //     ),
            //     overlayColor: Colors.white12,
            //   ),
            //   child: const Text(
            //     "DELETE All DATA",
            //     style: TextStyle(color: Colors.white),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
