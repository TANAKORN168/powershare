import 'package:flutter/material.dart';
import 'package:powershare/pages/PromotionPage.dart';
import 'package:powershare/pages/categoryPage.dart';
import 'package:powershare/pages/userApprovalPage.dart';
import 'package:powershare/pages/addProductPage.dart';
import 'package:powershare/pages/PaymentSettingsPage.dart';
import 'package:powershare/pages/reservationApprovalPage.dart';
import 'package:powershare/services/apiServices.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<List<Map<String, dynamic>>> _reservationsFuture;

  void _refreshReservations() {
    _reservationsFuture = ApiServices.getReservations();
  }

  @override
  void initState() {
    super.initState();
    _refreshReservations();
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ ส่วนหัวโปรไฟล์
        Container(
          width: double.infinity,
          color: const Color(0xFF3ABDC5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: const Center(
            child: Text(
              'พื้นที่ผู้ดูแลระบบ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.how_to_reg,
                          color: Color(0xFF3ABDC5),
                        ),
                        title: const Text('ยืนยันผู้ใช้ขอเข้าใช้งานระบบ'),
                        subtitle: const Text(
                          'ตรวจสอบและอนุมัติ/ปฏิเสธคำขอของผู้ใช้',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const UserApprovalPage(),
                            ),
                          );
                        },
                      ),
                    ),

                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.shopping_cart,
                          color: Color(0xFF3ABDC5),
                        ),
                        title: const Text('อนุมัติการจอง'),
                        subtitle: const Text(
                          'อนุมัติการจองและอัพโหลดข้อมูลการส่ง',
                        ),
                        trailing: FutureBuilder<List<Map<String, dynamic>>>(
                          future: _reservationsFuture,
                          builder: (context, snapshot) {
                            Widget badge = const SizedBox.shrink();
                            if (snapshot.hasData) {
                              final data = snapshot.data!;
                              final pendingCount = data.where((r) {
                                final cartItem =
                                    r['cart_item'] as Map<String, dynamic>?;
                                final status = cartItem?['status']?.toString();
                                return status == 'RESERVED';
                              }).length;
                              if (pendingCount > 0) {
                                badge = _buildBadge(pendingCount);
                              }
                            }
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                badge,
                                if (badge is! SizedBox)
                                  const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            );
                          },
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ReservationApprovalPage(),
                            ),
                          ).then((_) {
                            if (!mounted) return;
                            setState(_refreshReservations);
                          });
                        },
                      ),
                    ),

                    // ย้ายหมวดหมู่ขึ้นมาก่อนสินค้า
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.category,
                          color: Color(0xFF3ABDC5),
                        ),
                        title: const Text('หมวดหมู่สินค้า'),
                        subtitle: const Text(
                          'จัดการหมวดหมู่สินค้า (เพิ่ม/แก้ไข/ลบ)',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CategoryPage(),
                            ),
                          );
                        },
                      ),
                    ),

                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.shopping_bag,
                          color: Color(0xFF3ABDC5),
                        ),
                        title: const Text('ข้อมูลสินค้าให้เช่า'),
                        subtitle: const Text(
                          'เพิ่มรายการสินค้าหรืออัพเดตข้อมูลสินค้า',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AddProductPage(),
                            ),
                          );
                        },
                      ),
                    ),

                    // Promotion management moved to bottom
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.campaign,
                          color: Color(0xFF3ABDC5),
                        ),
                        title: const Text('ข้อความโปรโมชั่น'),
                        subtitle: const Text(
                          'จัดการข้อความไหลหน้าแรก (เพิ่ม/แก้ไข/ปิดใช้งาน)',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PromotionPage(),
                            ),
                          );
                        },
                      ),
                    ),

                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.payment,
                          color: Color(0xFF3ABDC5),
                        ),
                        title: const Text('ตั้งค่า QR ชำระเงิน'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PaymentSettingsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
