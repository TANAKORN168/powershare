import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:powershare/services/rental_service.dart';
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

      final history = await RentalService.getRentalHistory(_userId!);
      if (kDebugMode) print('RentalHistoryPage: got ${history.length} rentals');

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
                          final isActive = item['status'] == 'เช่าอยู่';
                          final imageUrl = item['image']?.toString() ?? '';

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
                                              child: const Icon(Icons.image_not_supported),
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
                                        Text('เริ่มเช่า: ${_formatDate(item['rent_start'])}'),
                                        Text('สิ้นสุด: ${_formatDate(item['rent_end'])}'),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['status'] ?? '',
                                          style: TextStyle(
                                            color: isActive ? Colors.green : Colors.grey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (isActive)
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton.icon(
                                              onPressed: () =>
                                                  _reportProblem(context, item['name']),
                                              icon: const Icon(
                                                Icons.build_circle,
                                                color: Colors.orange,
                                              ),
                                              label: const Text('แจ้งซ่อม/เปลี่ยน'),
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
