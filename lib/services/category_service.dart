import 'package:money_manager/services/storage_service.dart';

/// 카테고리를 관리하는 서비스 클래스
class CategoryService {
  final StorageService _storageService;
  static const String _categoriesKey = 'categories';

  CategoryService(this._storageService);

  /// 모든 카테고리 가져오기
  Future<List<String>> getCategories() async {
    return await _storageService.getStringList(_categoriesKey);
  }

  /// 카테고리 추가
  Future<bool> addCategory(String category) async {
    final categories = await getCategories();
    if (categories.contains(category)) {
      return false; // 이미 존재함
    }
    categories.add(category);
    await _storageService.setStringList(_categoriesKey, categories);
    return true;
  }

  /// 카테고리 삭제
  Future<void> deleteCategory(String category) async {
    final categories = await getCategories();
    categories.remove(category);
    await _storageService.setStringList(_categoriesKey, categories);
  }

  /// 카테고리 존재 여부 확인
  Future<bool> categoryExists(String category) async {
    final categories = await getCategories();
    return categories.contains(category);
  }
}
