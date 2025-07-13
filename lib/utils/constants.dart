import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// Database table names
class Tables {
  static const String items = 'items';
  static const String categories = 'categories';
  static const String transactions = 'transactions';
}

// App constants
class AppConstants {
  static const String appName = 'Manajemen Barang';
  static const String appVersion = '1.0.0';
} 