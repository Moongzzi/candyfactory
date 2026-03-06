class SupabaseConfig {
  static const String projectUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://iqbjfrkscsioknlnvyyq.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlxYmpmcmtzY3Npb2tubG52eXlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIzNTc5OTcsImV4cCI6MjA4NzkzMzk5N30.ntzQ2R4KwBYcX_4Q49j8GrNWaQkurdp4IcVbOlQljQA',
  );

  static Uri restUri(String table, {Map<String, String>? queryParameters}) {
    return Uri.parse('$projectUrl/rest/v1/$table').replace(
      queryParameters: queryParameters,
    );
  }

  static Map<String, String> get defaultHeaders => {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
    'Content-Type': 'application/json',
  };
}
