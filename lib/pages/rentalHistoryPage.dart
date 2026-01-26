import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:powershare/services/apiServices.dart';
import 'package:powershare/services/session.dart';
import 'package:intl/intl.dart';

class RentalHistoryPage extends StatefulWidget {
  const RentalHistoryPage({super.key});

  @override
  State<RentalHistoryPage> createState() => _RentalHistoryPageState();
}

class _RentalHistoryPageState extends State<RentalHistoryPage> {
  List<Map<String, dynamic>> rentalHistory = [];
  bool _loading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = Session.instance.user?['id']?.toString();
    _loadRentalHistory();
  }

  Future<void> _loadRentalHistory() async {
    setState(() => _loading = true);

    try {
      if (_userId == null || _userId!.isEmpty) {
        if (kDebugMode) print('RentalHistoryPage: no userId');
        setState(() {
          rentalHistory = [];
          _loading = false;
        });
        return;
      }

      // ดึงข้อมูลจาก carts และ cart_items
      final carts = await ApiServices.getUserReservations(userId: _userId);
      if (kDebugMode) print('RentalHistoryPage: got ${carts.length} carts');

      // แปลงข้อมูล carts เป็น rentalHistory
      final history = <Map<String, dynamic>>[];
      for (final cart in carts) {
        final cartItems = cart['cart_items'] as List<dynamic>? ?? [];

        for (final item in cartItems) {
          final cartItem = item as Map<String, dynamic>;
          final product = cartItem['products'] as Map<String, dynamic>?;

          if (product != null) {
            // กำหนดสถานะตามเงื่อนไข
            String status = 'รอชำระเงิน'; // ค่าเริ่มต้น
            Color statusColor = Colors.orange;
            String? rejectNote;

            final cartStatus = cart['status']?.toString() ?? '';
            final cartItemStatus = cartItem['status']?.toString() ?? 'RESERVED';
            final paidAt = cart['paid_at'];

            final isRejectStatus =
                cartItemStatus.toUpperCase() == 'REJECT' ||
                cartItemStatus.toLowerCase() == 'reject';

            if (isRejectStatus) {
              status = 'ปฏิเสธการเช่า';
              statusColor = Colors.red;
              rejectNote = cartItem['rejection_reason']?.toString();
            } else if (paidAt != null && paidAt.toString().isNotEmpty) {
              // carts->paid (paid_at is not null)
              if (cartItemStatus == 'RESERVED') {
                status = 'รอจัดส่ง';
                statusColor = Colors.blue;
              } else if (cartItemStatus == 'RENTED') {
                status = 'กำลังเช่าอยู่';
                statusColor = Colors.green;
              }
            } else if (cartStatus == 'RESERVED' ||
                cartItemStatus == 'RESERVED') {
              status = 'รอชำระเงิน';
              statusColor = Colors.orange;
            }

            history.add({
              'id': cartItem['id'],
              'cart_id': cart['id'],
              'name': product['name']?.toString() ?? 'สินค้า',
              'image': product['image']?.toString() ?? '',
              'rent_start': cartItem['rent_start'],
              'rent_end': cartItem['rent_end'],
              'status': status,
              'status_color': statusColor,
              'is_active': status == 'กำลังเช่าอยู่',
              'rejection_reason': rejectNote,
            });
          }
        }
      }

      if (kDebugMode)
        print('RentalHistoryPage: processed ${history.length} items');

      if (mounted) {
        setState(() {
          rentalHistory = history;
          _loading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('loadRentalHistory error: $e');
      if (mounted) {
        setState(() {
          rentalHistory = [];
          _loading = false;
        });
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy', 'th').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  void _reportProblem(BuildContext context, String itemName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('แจ้งปัญหา'),
        content: Text('คุณต้องการแจ้งปัญหาสำหรับ "$itemName" หรือไม่?'),
        actions: [
          TextButton(
            child: const Text('ยกเลิก'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('แจ้งปัญหา'),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ระบบได้รับแจ้งปัญหาของ "$itemName"')),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFF3ABDC5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: const Center(
            child: Text(
              'ประวัติการเช่า',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : rentalHistory.isEmpty
              ? const Center(
                  child: Text(
                    'ยังไม่มีประวัติการเช่า',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRentalHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rentalHistory.length,
                    itemBuilder: (context, index) {
                      final item = rentalHistory[index];
                      final isActive = item['is_active'] ?? false;
                      final imageUrl = item['image']?.toString() ?? '';
                      final statusColor = item['status_color'] ?? Colors.grey;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.image_not_supported,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.shopping_bag),
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] ?? 'สินค้า',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'เริ่มเช่า: ${_formatDate(item['rent_start'])}',
                                    ),
                                    Text(
                                      'สิ้นสุด: ${_formatDate(item['rent_end'])}',
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['status'] ?? '',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if ((item['status'] ?? '') ==
                                            'ปฏิเสธการเช่า' &&
                                        (item['rejection_reason'] != null &&
                                            item['rejection_reason']
                                                .toString()
                                                .trim()
                                                .isNotEmpty))
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Text(
                                          'หมายเหตุ: 	${item['rejection_reason'].toString().trim()}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
