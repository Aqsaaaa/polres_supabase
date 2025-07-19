import '../models/category.dart';
import '../utils/constants.dart';

class CategoryService {
  static Future<List<Category>> getAllCategories() async {
    final response = await supabase
        .from(Tables.categories)
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((category) => Category.fromJson(category))
        .toList();
  }

  static Future<Category?> getCategoryById(String id) async {
    final response = await supabase
        .from(Tables.categories)
        .select()
        .eq('id', id)
        .single();

    return Category.fromJson(response);
  }

  static Future<Category> createCategory({
    required String name,
  }) async {
    final response = await supabase
        .from(Tables.categories)
        .insert({
          'name': name,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return Category.fromJson(response);
  }
}
