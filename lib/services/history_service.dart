import '../models/history.dart';
import '../utils/constants.dart';

class HistoryService {
  static Future<List<History>> getAllHistory() async {
    final response = await supabase
        .from(Tables.transactions)
        .select()
        .order('created_at', ascending: false);
    
    return (response as List).map((history) => History.fromJson(history)).toList();
  }

  static Future<List<History>> getHistoryByItemId(String itemId) async {
    final response = await supabase
        .from(Tables.transactions)
        .select()
        .eq('item_id', itemId)
        .order('created_at', ascending: false);
    
    return (response as List).map((history) => History.fromJson(history)).toList();
  }

  static Future<History> borrowItem({
    required String itemId,
    required String itemName,
    required String borrowerName,
    required String responsiblePerson,
  }) async {
    final response = await supabase
        .from(Tables.transactions)
        .insert({
          'item_id': itemId,
          'item_name': itemName,
          'borrower_name': borrowerName,
          'responsible_person': responsiblePerson,
          'status': 'borrowed',
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    
    return History.fromJson(response);
  }

  static Future<History> returnItem(String historyId) async {
    final response = await supabase
        .from(Tables.transactions)
        .update({
          'status': 'returned',
          'returned_at': DateTime.now().toIso8601String(),
        })
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
    
    return (response as List).map((history) => History.fromJson(history)).toList();
  }

  static Future<List<History>> getReturnedItems() async {
    final response = await supabase
        .from(Tables.transactions)
        .select()
        .eq('status', 'returned')
        .order('returned_at', ascending: false);
    
    return (response as List).map((history) => History.fromJson(history)).toList();
  }
} 