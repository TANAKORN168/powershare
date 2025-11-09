import 'package:flutter/material.dart';
import 'package:powershare/pages/productDetailPage.dart';

class SavedProductsPage extends StatefulWidget {
  const SavedProductsPage({super.key});

  @override
  State<SavedProductsPage> createState() => _SavedProductsPageState();
}

class _SavedProductsPageState extends State<SavedProductsPage> {
  final List<Map<String, String>> savedItems = [
    {
      'name': 'เครื่องดูดฝุ่น',
      'image': 'assets/images/vacuum.png',
      'description': 'เหมาะสำหรับทำความสะอาดในบ้านและสำนักงาน',
    },
    {
      'name': 'พัดลมอุตสาหกรรม',
      'image': 'assets/images/fan.png',
      'description': 'แรงลมเย็นสบาย ครอบคลุมพื้นที่กว้าง',
    },
    {
      'name': 'ไมโครเวฟ',
      'image': 'assets/images/microwave.png',
      'description': 'อุ่นอาหารได้อย่างรวดเร็วและง่ายดาย',
    },
  ];

  void _removeItem(int index) {
    final removedItem = savedItems[index];
    setState(() {
      savedItems.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ลบ "${removedItem['name']}" ออกจากรายการแล้ว'),
        duration: Duration(seconds: 2),
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
              'สินค้าที่บันทึกไว้',
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
            scrollDirection:
                Axis.vertical, // ✅ ไม่ต้องใส่ก็ได้เพราะเป็น default
            itemCount: savedItems.length,
            padding: EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final item = savedItems[index];
              return Stack(
                children: [
                  Card(
                    margin: EdgeInsets.only(bottom: 12),
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
                              item['image']!,
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
                                  item['name']!,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  item['description']!,
                                  style: TextStyle(color: Colors.grey[700]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '฿990/เดือน',
                                      style: TextStyle(
                                        color: Color(0xFF3ABDC5),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProductDetailPage(
                                                  name: item['name']!,
                                                  image: item['image']!,
                                                  description:
                                                      item['description']!,
                                                  price: '฿990/เดือน',
                                                ),
                                          ),
                                        );
                                      },
                                      child: Text('ดูรายละเอียด'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 🔥 ปุ่มลบถังขยะที่มุมขวาบน
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red, size: 20),
                      tooltip: 'ลบออก',
                      onPressed: () => _removeItem(index),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
