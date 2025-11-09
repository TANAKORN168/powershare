import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:powershare/pages/productDetailPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Set<int> likedIndexes = {}; // เก็บ index ที่กดหัวใจแล้ว

  // ข้อมูล mock สินค้าที่ถูกเช่าบ่อย
  final List<Map<String, String>> popularItems = [
    {'name': 'เครื่องตัดหญ้า', 'image': 'assets/images/lawnmower.png'},
    {'name': 'สว่านไฟฟ้า', 'image': 'assets/images/drill.png'},
    {'name': 'เครื่องฉีดน้ำ', 'image': 'assets/images/washer.png'},
    {'name': 'เลื่อยไฟฟ้า', 'image': 'assets/images/saw.png'},
    {'name': 'ทีวี', 'image': 'assets/images/tv.png'},
  ];

  final List<Map<String, String>> recommendedItems = [
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

  void _goToDetail(BuildContext context, String itemName) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('ไปยังหน้ารายละเอียด: $itemName')));
    // TODO: เปลี่ยนไปหน้า detail จริงในอนาคต
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // หัวข้อ
        Center(
          child: Text(
            'สินค้าที่ถูกเช่ามากที่สุด',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 20),
        // รายการสินค้าแนวนอน
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: popularItems.length,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final item = popularItems[index];
              return GestureDetector(
                onTap: () => _goToDetail(context, item['name']!),
                child: Container(
                  width: 90,
                  margin: EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Color.fromARGB(255, 255, 255, 255),
                        child: ClipOval(
                          child: Image.asset(
                            item['image']!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        item['name']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // ✅ โฆษณาแบบตัวหนังสือไหล
        SizedBox(
          height: 20,
          child: Marquee(
            text:
                '🔥 โปรโมชั่นพิเศษวันนี้! ลด 50% สำหรับเครื่องตัดหญ้า 🔧 และสว่านไฟฟ้า 💥 รีบเลย! สินค้ามีจำนวนจำกัด!',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            scrollAxis: Axis.horizontal,
            blankSpace: 50.0,
            velocity: 50.0,
            pauseAfterRound: Duration(seconds: 1),
            startPadding: 10.0,
            accelerationDuration: Duration(seconds: 1),
            accelerationCurve: Curves.linear,
            decelerationDuration: Duration(milliseconds: 500),
            decelerationCurve: Curves.easeOut,
          ),
        ),
        SizedBox(height: 10),
        // หัวข้อ
        Container(
          width: double.infinity, // กว้างเต็มหน้าจอ
          color: Color(0xFF3ABDC5), // สีพื้นหลังที่ต้องการ ปรับได้
          padding: EdgeInsets.symmetric(vertical: 12), // ระยะห่างบนล่าง
          child: Center(
            child: Text(
              'แนะนำสำหรับคุณ',
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
            itemCount: recommendedItems.length,
            padding: EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final item = recommendedItems[index];
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

                  // ❤️ ปุ่มหัวใจด้านขวาบน
                  Positioned(
                    top: 1,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        likedIndexes.contains(index)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: likedIndexes.contains(index)
                            ? Colors.red
                            : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          if (likedIndexes.contains(index)) {
                            likedIndexes.remove(index);
                          } else {
                            likedIndexes.add(index);
                          }
                        });
                      },
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
