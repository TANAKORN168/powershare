import 'package:flutter/material.dart';

class RentalHistoryPage extends StatelessWidget {
  RentalHistoryPage({super.key});

  final List<Map<String, dynamic>> rentalHistory = [
    {
      'name': 'เครื่องฉีดน้ำแรงดันสูง',
      'image': 'assets/images/washer.png',
      'dateStart': '01 ก.ค. 2567',
      'dateEnd': '10 ก.ค. 2567',
      'status': 'เช่าอยู่',
    },
    {
      'name': 'สว่านไฟฟ้า',
      'image': 'assets/images/drill.png',
      'dateStart': '20 มิ.ย. 2567',
      'dateEnd': '25 มิ.ย. 2567',
      'status': 'คืนแล้ว',
    },
  ];

  void _reportProblem(BuildContext context, String itemName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('แจ้งปัญหา'),
        content: Text('คุณต้องการแจ้งปัญหาสำหรับ "$itemName" หรือไม่?'),
        actions: [
          TextButton(
            child: Text('ยกเลิก'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('แจ้งปัญหา'),
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
          width: double.infinity, // กว้างเต็มหน้าจอ
          color: Color(0xFF3ABDC5), // สีพื้นหลังที่ต้องการ ปรับได้
          padding: EdgeInsets.symmetric(vertical: 12), // ระยะห่างบนล่าง
          child: Center(
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
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: rentalHistory.length,
            itemBuilder: (context, index) {
              final item = rentalHistory[index];
              final isActive = item['status'] == 'เช่าอยู่';

              return Card(
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          item['image'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text('เริ่มเช่า: ${item['dateStart']}'),
                            Text('สิ้นสุด: ${item['dateEnd']}'),
                            SizedBox(height: 4),
                            Text(
                              item['status'],
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
                                  icon: Icon(
                                    Icons.build_circle,
                                    color: Colors.orange,
                                  ),
                                  label: Text('แจ้งซ่อม/เปลี่ยน'),
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
      ],
    );
  }
}
