import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient client;

  SupabaseService(this.client);

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://fcszxlufbuntqppkrgwl.supabase.co',
      anonKey: 'sb_publishable_Re6s6W00Og3ijtgfbrGBvw_1zgucWV9', 
    );
  }
}

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
