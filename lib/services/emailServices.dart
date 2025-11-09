import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailServices {
  static const String baseUrl =
      'https://lizyjuvbyuygsezyhpwr.supabase.co/functions/v1/resend-email';
  static const String apiKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxpenlqdXZieXV5Z3NlenlocHdyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNTUyMzksImV4cCI6MjA2NzczMTIzOX0.91fgESB0_0P_9X7qDd-YfCGYgBywcE5hWYd6aX6kIRg';

  static Map<String, String> get _headers => {
    'apikey': apiKey,
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<void> sendEmailViaEdgeFunction({
    required String to,
    required String subject,
    required String html,
  }) async {
    final url = Uri.parse(baseUrl);
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'to': to, 'subject': subject, 'html': html}),
    );

    if (response.statusCode == 200) {
      print("📨 ส่งอีเมลสำเร็จ!");
    } else {
      print("❌ ส่งอีเมลล้มเหลว: ${response.statusCode}");
    }
    print(response.body);
  }
}
