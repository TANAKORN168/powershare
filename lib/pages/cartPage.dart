import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:powershare/services/apiServices.dart';
import 'package:powershare/services/session.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> cartItems = [];
  bool _loading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = Session.instance.user?['id']?.toString();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    setState(() {
      _loading = true;
    });

    try {
      if (_userId == null || _userId!.isEmpty) {
        if (kDebugMode) print('CartPage: no userId in session');
        if (mounted) {
          setState(() {
            cartItems = [];
            _loading = false;
          });
        }
        return;
      }

      if (kDebugMode) print("CartPage: loading cart for userId='$_userId' tokenLen=${Session.instance.accessToken?.length ?? 0}");

      final items = await ApiServices.getCartItemsForUser(_userId!);

      if (kDebugMode) print('CartPage: got ${items.length} items from API');

      if (mounted) {
        setState(() {
          cartItems = items.map((it) {
            try {
              final priceRaw = it['price'];
              final price = (priceRaw is int)
                  ? priceRaw
                  : (priceRaw is double ? priceRaw.toInt() : int.tryParse(priceRaw?.toString() ?? '0') ?? 0);
              final image = (it['image'] ?? '').toString();
              return {
                'name': it['name'] ?? 'สินค้า',
                'price': price,
                'image': image.isNotEmpty ? image : null,
                'quantity': it['quantity'] ?? 1,
                'product_id': it['product_id'],
                'item_id': it['item_id'] ?? it['id']?.toString() ?? '',
                'cart_id': it['cart_id'] ?? '',
              };
            } catch (e) {
              if (kDebugMode) print('CartPage: failed to map item $it -> $e');
              return {
                'name': it['name'] ?? 'สินค้า',
                'price': 0,
                'image': null,
                'quantity': it['quantity'] ?? 1,
                'product_id': it['product_id'],
                'item_id': it['item_id'] ?? it['id']?.toString() ?? '',
                'cart_id': it['cart_id'] ?? '',
              };
            }
          }).toList();
          _loading = false;
        });
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('loadCartItems error: $e');
        print(st);
      }
      if (mounted) {
        setState(() {
          cartItems = [];
          _loading = false;
        });
      }
    }
  }

  Future<void> _removeItem(int index) async {
    final item = cartItems[index];
    final itemId = item['item_id']?.toString();
    final productId = item['product_id']?.toString();
    final cartId = item['cart_id']?.toString();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('ลบรายการ'),
        content: Text('คุณต้องการลบ "${item['name']}" ออกจากตะกร้าหรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('ลบ', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    // Optimistic UI: show progress
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final ok = await ApiServices.deleteCartItem(itemId ?? '', productId: productId, cartId: cartId);
      if (ok) {
        if (mounted) {
          setState(() {
            cartItems.removeAt(index);
            _loading = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ลบรายการเรียบร้อยแล้ว')));
      } else {
        if (mounted) {
          setState(() => _loading = false);
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ลบรายการไม่สำเร็จ')));
      }
    } catch (e) {
      if (kDebugMode) print('removeItem error: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด')));
    }
  }

  double get total =>
      cartItems.fold(0.0, (sum, item) {
        final priceRaw = item['price'];
        final p = (priceRaw is num) ? priceRaw.toDouble() : double.tryParse(priceRaw?.toString() ?? '0') ?? 0.0;
        return sum + p;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Color(0xFF3ABDC5),
            padding: EdgeInsets.symmetric(vertical: 12),
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
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : cartItems.isEmpty
                    ? Center(child: Text('ยังไม่มีสินค้าในตะกร้า'))
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          final image = item['image'] as String?;
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: image != null && image.isNotEmpty
                                  ? (image.startsWith('http')
                                      ? Image.network(image, width: 60, fit: BoxFit.cover)
                                      : Image.asset(image, width: 60, fit: BoxFit.cover))
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey.shade200,
                                      child: Icon(Icons.image_not_supported),
                                    ),
                              title: Text(item['name']),
                              subtitle: Text('฿${((item['price'] is num) ? (item['price'] as num).toDouble() : double.tryParse(item['price']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}/วัน'),
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
                      '฿${total.toStringAsFixed(2)}',
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
                          title: const Text('QR Code ชำระเงิน'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('ยอดชำระทั้งหมด', style: TextStyle(fontSize: 16)),
                              const SizedBox(height: 8),
                              Text(
                                '฿${total.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3ABDC5)),
                              ),
                              const SizedBox(height: 14),
                              const Icon(Icons.qr_code_2, size: 100),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('ปิด'),
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
