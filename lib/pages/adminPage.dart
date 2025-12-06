import 'package:flutter/material.dart';
import 'package:powershare/pages/PromotionPage.dart';
import 'package:powershare/pages/categoryPage.dart';
import 'package:powershare/pages/userApprovalPage.dart';
import 'package:powershare/pages/addProductPage.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

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

                    // ย้ายหมวดหมู่ขึ้นมาก่อนสินค้า
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.category,
                          color: Color(0xFF3ABDC5),
                        ),
                        title: const Text('หมวดหมู่สินค้า'),
                        subtitle: const Text('จัดการหมวดหมู่สินค้า (เพิ่ม/แก้ไข/ลบ)'),
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
                        subtitle: const Text('จัดการข้อความไหลหน้าแรก (เพิ่ม/แก้ไข/ปิดใช้งาน)'),
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
