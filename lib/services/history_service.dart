import '../models/history.dart';
import '../utils/constants.dart';

class HistoryService {
  static Future<List<History>> getAllHistory() async {
    final response = await supabase
        .from(Tables.transactions)
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((history) => History.fromJson(history))
        .toList();
  }

  static Future<List<History>> getHistoryByItemId(String itemId) async {
    final response = await supabase
        .from(Tables.transactions)
        .select()
        .eq('item_id', itemId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((history) => History.fromJson(history))
        .toList();
  }

  static Future<History> borrowItem({
    required String itemId,
    required String itemName,
    required String borrowerName,
    required String responsiblePerson,
    required String category,
    required String purpose,
    required int quantity,
  }) async {
    final response = await supabase
        .from(Tables.transactions)
        .insert({
          'item_id': itemId,
          'item_name': itemName,
          'borrower_name': borrowerName,
          'responsible_person': responsiblePerson,
          'category': category,
          'purpose': purpose,
          'quantity': quantity,
          'status': 'borrowed',
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return History.fromJson(response);
  }

  static Future<History> returnItem(
    String historyId,
    int quantityToReturn,
  ) async {
    // Get current transaction
    final currentTransaction = await supabase
        .from(Tables.transactions)
        .select()
        .eq('id', historyId)
        .single();

    int currentQuantity = currentTransaction['quantity'] ?? 1;
    int newQuantity = currentQuantity - quantityToReturn;

    if (newQuantity < 0) {
      throw Exception('Return quantity exceeds borrowed quantity');
    }

    Map<String, dynamic> updateData = {};
    if (newQuantity == 0) {
      updateData = {
        'status': 'returned',
        'returned_at': DateTime.now().toIso8601String(),
        'quantity': 0,
      };
    } else {
      updateData = {'quantity': newQuantity};
    }

    final response = await supabase
        .from(Tables.transactions)
        .update(updateData)
        .eq('id', historyId)
        .select()
        .single();

    return History.fromJson(response);
  }

  static Future<List<History>> getBorrowedItems() async {
    final response = await supabase
        .from(Tables.transactions)
        .select()
        .eq('status', 'borrowed')
        .order('created_at', ascending: false);

    return (response as List)
        .map((history) => History.fromJson(history))
        .toList();
  }

  static Future<List<History>> getReturnedItems() async {
    final response = await supabase
        .from(Tables.transactions)
        .select()
        .eq('status', 'returned')
        .order('returned_at', ascending: false);

    return (response as List)
        .map((history) => History.fromJson(history))
        .toList();
  }
}
