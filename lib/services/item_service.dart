import '../models/item.dart';
import '../utils/constants.dart';

class ItemService {
  static Future<List<Item>> getAllItems() async {
    final response = await supabase
        .from(Tables.items)
        .select()
        .order('created_at', ascending: false);
    
    return (response as List).map((item) => Item.fromJson(item)).toList();
  }

  static Future<Item?> getItemById(String id) async {
    final response = await supabase
        .from(Tables.items)
        .select()
        .eq('id', id)
        .single();
    
    return Item.fromJson(response);
  }

  static Future<Item> createItem({
    required String name,
    required String image,
    required int stock,
  }) async {
    final response = await supabase
        .from(Tables.items)
        .insert({
          'name': name,
          'image': image,
          'stock': stock,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    
    return Item.fromJson(response);
  }

  static Future<Item> updateItem({
    required String id,
    String? name,
    String? image,
    int? stock,
  }) async {
    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (name != null) updateData['name'] = name;
    if (image != null) updateData['image'] = image;
    if (stock != null) updateData['stock'] = stock;

    final response = await supabase
        .from(Tables.items)
        .update(updateData)
        .eq('id', id)
        .select()
        .single();
    
    return Item.fromJson(response);
  }

  static Future<void> deleteItem(String id) async {
    await supabase
        .from(Tables.items)
        .delete()
        .eq('id', id);
  }

  static Future<void> decreaseStock(String itemId, int amount) async {
    await supabase.rpc('decrease_stock', params: {
      'item_id': itemId,
      'amount': amount,
    });
  }

  static Future<void> increaseStock(String itemId, int amount) async {
    await supabase.rpc('increase_stock', params: {
      'item_id': itemId,
      'amount': amount,
    });
  }
} 