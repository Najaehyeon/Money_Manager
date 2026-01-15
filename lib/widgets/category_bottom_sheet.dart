import 'package:flutter/material.dart';
import 'package:money_manager/constants/app_colors.dart';
import 'package:money_manager/constants/app_styles.dart';
import 'package:money_manager/constants/app_strings.dart';
import 'package:money_manager/services/category_service.dart';

/// 카테고리 선택 BottomSheet 위젯
class CategoryBottomSheet extends StatefulWidget {
  final List<String> categories;
  final String? selectedCategory;
  final CategoryService categoryService;
  final Function(String) onCategorySelected;
  final Function(String) onCategoryDeleted;

  const CategoryBottomSheet({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.categoryService,
    required this.onCategorySelected,
    required this.onCategoryDeleted,
  });

  @override
  State<CategoryBottomSheet> createState() => _CategoryBottomSheetState();
}

class _CategoryBottomSheetState extends State<CategoryBottomSheet> {
  late List<String> _categories;
  bool _isDeleteMode = false;
  final TextEditingController _addCategoryController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _categories = List.from(widget.categories);
  }

  @override
  void dispose() {
    _addCategoryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _addCategory(StateSetter innerSetState) async {
    final newCategory = _addCategoryController.text.trim();
    if (newCategory.isEmpty) return;

    final success = await widget.categoryService.addCategory(newCategory);
    if (!success) {
      _addCategoryController.clear();
      if (mounted) Navigator.of(context).pop();
      return;
    }

    innerSetState(() {
      _categories.add(newCategory);
    });

    setState(() {
      _categories = List.from(_categories);
    });

    _addCategoryController.clear();
    if (mounted) Navigator.of(context).pop();
    widget.onCategorySelected(newCategory);
  }

  Future<void> _deleteCategory(String category, StateSetter innerSetState) async {
    await widget.categoryService.deleteCategory(category);
    _categories.remove(category);
    innerSetState(() {});
    widget.onCategoryDeleted(category);
  }

  void _showAddCategoryDialog(BuildContext context, StateSetter innerSetState) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
        return Dialog(
          shadowColor: Colors.black,
          elevation: 4,
          backgroundColor: AppColors.surface,
          alignment: const Alignment(0, -0.1),
          shape: AppStyles.dialogShape(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  AppStrings.addCategoryTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: AppStyles.spacingL),
                TextField(
                  controller: _addCategoryController,
                  focusNode: _focusNode,
                  cursorColor: AppColors.textPrimary,
                  decoration: AppStyles.inputDecoration(
                    hintText: AppStrings.enterCategory,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppStyles.spacingL),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _addCategoryController.clear();
                        },
                        style: AppStyles.secondaryButtonStyle(),
                        child: const Text(AppStrings.cancel),
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacingS),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _addCategory(innerSetState),
                        style: AppStyles.primaryButtonStyle(),
                        child: const Text(AppStrings.ok),
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusLarge),
      ),
      child: StatefulBuilder(
        builder: (BuildContext innerContext, StateSetter innerSetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppStyles.spacingXS),
              Container(
                width: 64,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppStyles.borderRadiusCircular),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppStyles.spacingL),
                  child: GridView.builder(
                    shrinkWrap: true,
                    itemCount: _isDeleteMode ? _categories.length : _categories.length + 1,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2 / 1,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final isAddButton = index == _categories.length;
                      final categoryText = isAddButton ? null : _categories[index];
                      final isSelected = categoryText == widget.selectedCategory && !isAddButton;

                      return ElevatedButton(
                        onPressed: () {
                          if (isAddButton) {
                            _showAddCategoryDialog(context, innerSetState);
                          } else {
                            if (_isDeleteMode) return;
                            widget.onCategorySelected(categoryText!);
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          backgroundColor: isSelected ? AppColors.accent : AppColors.surfaceLight,
                          padding: const EdgeInsets.all(AppStyles.spacingS),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppStyles.borderRadiusSmall),
                          ),
                        ),
                        child: isAddButton
                            ? const Icon(Icons.add, color: AppColors.textPrimary)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: _isDeleteMode ? 4 : 5,
                                    child: Text(
                                      categoryText!,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (_isDeleteMode)
                                    Expanded(
                                      flex: 2,
                                      child: IconButton(
                                        onPressed: () => _deleteCategory(categoryText, innerSetState),
                                        icon: const Icon(Icons.close),
                                        padding: const EdgeInsets.all(AppStyles.spacingS),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        iconSize: 16,
                                        color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
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
                padding: const EdgeInsets.all(AppStyles.spacingXL),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () {
                        innerSetState(() {
                          _isDeleteMode = !_isDeleteMode;
                        });
                      },
                      icon: Icon(
                        Icons.delete_rounded,
                        color: _isDeleteMode ? AppColors.error : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
