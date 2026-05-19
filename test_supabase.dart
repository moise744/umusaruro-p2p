import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://fcszxlufbuntqppkrgwl.supabase.co',
    'sb_publishable_Re6s6W00Og3ijtgfbrGBvw_1zgucWV9',
  );

  try {
    for (final table in ['users', 'projects', 'investments', 'messages', 'farm_updates', 'transactions', 'notifications']) {
      try {
        final response = await supabase.from(table).select().limit(1);
        print('Table $table exists. Sample: $response');
      } catch (e) {
        print('Table $table does not exist or error: $e');
      }
    }
  } catch (e) {
    print('Connection failed: $e');
  }
}
