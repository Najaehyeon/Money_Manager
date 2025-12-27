import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UpdatePage extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final String dateKey;
  final Map<String, dynamic> oldData;

  const UpdatePage({
    super.key,
    required this.initialData,
    required this.dateKey,
    required this.oldData,
  });

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  // 상태 변수들
  late DateTime _selectedDate;
  late DateTime _initialDate;
  String get formatedDate => DateFormat('MMMM d, yyyy').format(_selectedDate);
  String get _storageDate => DateFormat('yyyy-MM-dd').format(_selectedDate);

  List<String> categories = [];
  String? _selectedCategory;
  late TextEditingController _setAddCategory;
  final FocusNode _focusNode = FocusNode();
  bool isCategoryDeleteActivated = false;

  late TextEditingController _detailController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    // 초기값 세팅
    _initialDate = DateTime.parse(widget.initialData['date']);
    _selectedDate = _initialDate;

    _selectedCategory = widget.initialData['category'];
    _detailController = TextEditingController(
      text: widget.initialData['detail'],
    );
    _priceController = TextEditingController(text: widget.initialData['price']);
    _setAddCategory = TextEditingController();

    _loadCategoryData();
  }

  @override
  void dispose() {
    _setAddCategory.dispose();
    _detailController.dispose();
    _priceController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // 카테고리 로드 및 추가/삭제 로직
  Future<void> _loadCategoryData() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedCategories = prefs.getStringList('categories') ?? [];
    if (mounted) {
      setState(() {
        categories = loadedCategories;
      });
    }
  }

  Future<void> _addCategory(StateSetter innerSetState) async {
    final newCategory = _setAddCategory.text.trim();
    if (newCategory.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (categories.contains(newCategory)) {
      _setAddCategory.clear();
      Navigator.of(context).pop();
      return;
    }
    innerSetState(() {
      categories.add(newCategory);
      _selectedCategory = newCategory;
    });
    setState(() {
      _selectedCategory = newCategory;
    });
    await prefs.setStringList('categories', categories);
    _setAddCategory.clear();
    Navigator.of(context).pop();
  }

  Future<void> _deleteCategory(
    String category,
    StateSetter innerSetState,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    categories.remove(category);
    await prefs.setStringList('categories', categories);
    if (_selectedCategory == category) {
      setState(() {
        _selectedCategory = categories.isNotEmpty ? categories.first : null;
      });
    }
    innerSetState(() {});
  }

  Future<void> _updateExpenseData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 기존 데이터가 들어있는 '서랍' 열기 (수정 전 날짜 기준)
    String oldStorageKey = widget.dateKey;
    List<String> oldList = prefs.getStringList(oldStorageKey) ?? [];

    // 2. 원본(oldData)과 똑같은 항목을 찾아서 제거
    // 인덱스 대신 내용(JSON 문자열)을 직접 비교합니다.
    String oldJson = json.encode(widget.oldData);
    oldList.remove(oldJson);
    await prefs.setStringList(oldStorageKey, oldList);

    // 3. 새 데이터 준비 (날짜가 바뀌었을 수도 있음)
    String newStorageKey =
        DateFormat('MMMM_yyyy').format(_selectedDate).toLowerCase() + '_data';
    Map<String, dynamic> newData = {
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'category': _selectedCategory,
      'detail': _detailController.text,
      'price': _priceController.text,
    };

    // 4. 새 '서랍'에 저장
    List<String> newList = (newStorageKey == oldStorageKey)
        ? oldList
        : (prefs.getStringList(newStorageKey) ?? []);

    newList.add(json.encode(newData));
    await prefs.setStringList(newStorageKey, newList);

    if (mounted) Navigator.of(context).pop(true);
  }

  // --- 삭제 로직 ---
  Future<void> _deleteExpenseData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. 현재 저장된 리스트 가져오기
      List<String> currentData = prefs.getStringList(widget.dateKey) ?? [];

      // 2. 원본 데이터(oldData)를 JSON 문자열로 변환하여 찾기
      String targetJson = json.encode(widget.oldData);

      print("삭제 시도: $targetJson");

      // 3. 리스트에서 해당 내용과 완벽히 일치하는 항목 제거
      if (currentData.contains(targetJson)) {
        currentData.remove(targetJson);

        // 4. 저장 후 화면 닫기
        await prefs.setStringList(widget.dateKey, currentData);
        print("삭제 성공");

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        print("삭제 실패: 동일한 데이터를 찾을 수 없음");
        // 만약 못 찾았다면, 날짜 형식이 미세하게 다를 수 있으니 알림 처리
      }
    } catch (e) {
      print("삭제 에러: $e");
    }
  }

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
            onDateTimeChanged: (DateTime newDate) {
              setState(() => _selectedDate = newDate);
            },
          ),
        );
      },
    );
  }

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
                                showDialog(
                                  context: context,
                                  builder: (BuildContext dialogContext) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          _focusNode.requestFocus();
                                        });
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
                                              "ADD CATEGORY",
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
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                    ),
                                                    child: const Text('Cancel'),
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
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                    ),
                                                    child: const Text('OK'),
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
                                if (isCategoryDeleteActivated) return;
                                setState(() {
                                  _selectedCategory = categoryText;
                                });
                                Navigator.of(context).pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: isSelected
                                  ? Colors.black
                                  : const Color(0xFFF1F1F1),
                              padding: const EdgeInsets.all(8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isAddButton
                                ? const Icon(Icons.add, color: Colors.black)
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: isCategoryDeleteActivated ? 4 : 5,
                                        child: Text(
                                          categoryText!,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                      if (isCategoryDeleteActivated)
                                        Expanded(
                                          flex: 2,
                                          child: IconButton(
                                            onPressed: () => _deleteCategory(
                                              categoryText,
                                              innerSetState,
                                            ),
                                            icon: const Icon(Icons.close),
                                            padding: const EdgeInsets.all(8),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            iconSize: 16,
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
          "Update Expense",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                "Date",
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: () => _showDatePicker(context),
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
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const Icon(Icons.date_range_rounded, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                "Category",
                style: TextStyle(color: Colors.black, fontSize: 16),
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
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                "Detail",
                style: TextStyle(color: Colors.black, fontSize: 16),
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
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text("Price", style: TextStyle(fontSize: 16)),
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
            const SizedBox(height: 24),
            // --- 버튼 섹션: 삭제와 수정을 가로로 배치 ---
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _deleteExpenseData, // 삭제 로직 호출
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "DELETE",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2, // UPDATE 버튼을 조금 더 넓게 설정
                  child: ElevatedButton(
                    onPressed: _updateExpenseData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "UPDATE",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
