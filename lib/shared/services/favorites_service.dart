import 'package:shared_preferences/shared_preferences.dart';

/// خدمة إدارة المفضلة
/// تتيح للمستخدم حفظ العملات والعيارات المهمة
class FavoritesService {
  static const String _favoritesKey = 'user_favorites';

  /// إضافة عنصر للمفضلة
  Future<bool> addToFavorites(String priceId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_favoritesKey) ?? [];

    if (!favorites.contains(priceId)) {
      favorites.add(priceId);
      return await prefs.setStringList(_favoritesKey, favorites);
    }

    return false; // already exists
  }

  /// إزالة عنصر من المفضلة
  Future<bool> removeFromFavorites(String priceId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_favoritesKey) ?? [];

    if (favorites.contains(priceId)) {
      favorites.remove(priceId);
      return await prefs.setStringList(_favoritesKey, favorites);
    }

    return false; // not found
  }

  /// التبديل (إضافة/إزالة)
  Future<bool> toggleFavorite(String priceId) async {
    final isFavorite = await this.isFavorite(priceId);

    if (isFavorite) {
      return await removeFromFavorites(priceId);
    } else {
      return await addToFavorites(priceId);
    }
  }

  /// التحقق من وجود عنصر في المفضلة
  Future<bool> isFavorite(String priceId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_favoritesKey) ?? [];
    return favorites.contains(priceId);
  }

  /// الحصول على قائمة المفضلة
  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  /// مسح جميع المفضلة
  Future<bool> clearAllFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_favoritesKey);
  }

  /// عدد العناصر في المفضلة
  Future<int> getFavoritesCount() async {
    final favorites = await getFavorites();
    return favorites.length;
  }
}
