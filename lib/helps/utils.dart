class Utils {
  static String ConvertToIso8601(String inputDate) {
    // แปลง string เป็น DateTime โดยใช้รูปแบบ dd/MM/yyyy
    final parts = inputDate.split('/');
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);

    final date = DateTime(year, month, day);
    return date.toIso8601String();
  }
}
