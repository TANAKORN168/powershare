import 'package:powershare/services/session.dart';

class ApiConfig {
  static const String baseUrl = 'https://lizyjuvbyuygsezyhpwr.supabase.co';
  static const String apiKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxpenlqdXZieXV5Z3NlenlocHdyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNTUyMzksImV4cCI6MjA2NzczMTIzOX0.91fgESB0_0P_9X7qDd-YfCGYgBywcE5hWYd6aX6kIRg';

  static Map<String, String> get headers {
    final token = Session.instance.accessToken;
    final bearer = token != null && token.isNotEmpty ? token : apiKey;
    return {
      'apikey': apiKey,
      'Authorization': 'Bearer $bearer',
      'Content-Type': 'application/json',
    };
  }
}