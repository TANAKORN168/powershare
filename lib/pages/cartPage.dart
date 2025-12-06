import 'package:flutter/material.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> cartItems = [
    {
      'name': 'เครื่องตัดหญ้า',
      'price': 990,
      'image': 'assets/images/lawnmower.png',
    },
    {'name': 'พัดลมอุตสาหกรรม', 'price': 690, 'image': 'assets/images/fan.png'},
  ];

  void _removeItem(int index) {
    setState(() {
      cartItems.removeAt(index);
    });
  }

  int get total =>
      cartItems.fold(0, (sum, item) => sum + (item['price'] as int));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity, // กว้างเต็มหน้าจอ
            color: Color(0xFF3ABDC5), // สีพื้นหลังที่ต้องการ ปรับได้
            padding: EdgeInsets.symmetric(vertical: 12), // ระยะห่างบนล่าง
            child: Center(
              child: Text(
                'ตะกร้าสินค้า',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: cartItems.isEmpty
                ? Center(child: Text('ยังไม่มีสินค้าในตะกร้า'))
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Image.asset(item['image'], width: 60),
                          title: Text(item['name']),
                          subtitle: Text('฿${item['price']}/เดือน'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeItem(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Divider(thickness: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'รวมทั้งหมด:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '฿$total',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF3ABDC5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.qr_code),
                    label: Text(
                      'ชำระเงินด้วย QR Code',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3ABDC5),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('QR Code ชำระเงิน'),
                          content: Container(
                            height: 200,
                            child: Center(
                              child: Icon(Icons.qr_code_2, size: 100),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('ปิด'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
