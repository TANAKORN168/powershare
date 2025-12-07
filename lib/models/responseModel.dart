class ResponseModel {
  final String responseCode;
  final String responseMessage;
  final String? user; // เพิ่มบรรทัดนี้

  ResponseModel({
    required this.responseCode,
    required this.responseMessage,
    this.user, // เพิ่มบรรทัดนี้
  });
}
