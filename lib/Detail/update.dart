import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UpdatePage extends StatefulWidget {
  final int itemIndex;
  final Map<String, dynamic> initialData;

  const UpdatePage({
    super.key,
    required this.itemIndex,
    required this.initialData,
  });

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  // 상태 변수들
  late DateTime _selectedDate;
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
    _selectedDate = DateTime.parse(widget.initialData['date']);
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

  // --- 수정 기능 ---
  Future<void> _updateExpenseData() async {
    final detail = _detailController.text.trim();
    final price = _priceController.text.trim();

    if (_selectedCategory == null || detail.isEmpty || price.isEmpty) return;

    final updatedExpense = {
      'date': _storageDate,
      'category': _selectedCategory,
      'detail': detail,
      'price': price,
    };

    final storageKey =
        DateFormat('MMMM_yyyy').format(_selectedDate).toLowerCase() + '_data';
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentData = prefs.getStringList(storageKey) ?? [];

    if (widget.itemIndex < currentData.length) {
      currentData[widget.itemIndex] = json.encode(updatedExpense);
      await prefs.setStringList(storageKey, currentData);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  // --- 삭제 기능 추가 ---
  Future<void> _deleteExpenseData() async {
    final storageKey =
        DateFormat('MMMM_yyyy').format(_selectedDate).toLowerCase() + '_data';
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentData = prefs.getStringList(storageKey) ?? [];

    if (widget.itemIndex < currentData.length) {
      currentData.removeAt(widget.itemIndex); // 해당 인덱스 삭제
      await prefs.setStringList(storageKey, currentData);
    }

    if (mounted) {
      Navigator.of(context).pop(true); // 삭제 성공 알림 후 뒤로가기
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
                    style: const TextStyle(color: Colors.black, fontSize: 16),
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
                fixedSize: Size(MediaQuery.of(context).size.width, 48),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _selectedCategory ?? 'Select Category',
                style: const TextStyle(color: Colors.black, fontSize: 16),
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
