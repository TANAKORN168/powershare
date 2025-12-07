import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:powershare/pages/productDetailPage.dart';
import 'package:powershare/services/like_service.dart';
import 'package:powershare/services/session.dart';
import 'package:powershare/helps/formatHelper.dart';

class SavedProductsPage extends StatefulWidget {
  const SavedProductsPage({super.key});

  @override
  State<SavedProductsPage> createState() => _SavedProductsPageState();
}

class _SavedProductsPageState extends State<SavedProductsPage> {
  List<Map<String, dynamic>> savedItems = [];
  bool _loading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = Session.instance.user?['id']?.toString();
    _loadLikedProducts();
  }

  Future<void> _loadLikedProducts() async {
    setState(() => _loading = true);

    try {
      if (_userId == null || _userId!.isEmpty) {
        if (kDebugMode) print('SavedProductsPage: no userId');
        setState(() {
          savedItems = [];
          _loading = false;
        });
        return;
      }

      final products = await LikeService.getLikedProducts(_userId!);
      if (kDebugMode) print('SavedProductsPage: got ${products.length} liked products');

      if (mounted) {
        setState(() {
          savedItems = products;
          _loading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('loadLikedProducts error: $e');
      if (mounted) {
        setState(() {
          savedItems = [];
          _loading = false;
        });
      }
    }
  }

  Future<void> _removeItem(int index) async {
    final removedItem = savedItems[index];
    final productId = removedItem['product_id']?.toString();

    if (productId == null || _userId == null) return;

    // ลบออกจาก UI ทันที
    setState(() {
      savedItems.removeAt(index);
    });

    // ลบออกจาก database
    final success = await LikeService.removeLike(_userId!, productId);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบ "${removedItem['name']}" ออกจากรายการแล้ว'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // ถ้าลบไม่สำเร็จ ให้เพิ่มกลับเข้าไป
      setState(() {
        savedItems.insert(index, removedItem);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ลบไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : savedItems.isEmpty
                  ? const Center(
                      child: Text(
                        'ยังไม่มีสินค้าที่บันทึกไว้',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLikedProducts,
                      child: ListView.builder(
                        itemCount: savedItems.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final item = savedItems[index];
                          final imageUrl = item['image']?.toString() ?? '';
                          final price = item['price'] ?? 0;

                          return Stack(
                            children: [
                              Card(
                                margin: const EdgeInsets.only(bottom: 12),
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
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              item['description'] ?? '',
                                              style: TextStyle(color: Colors.grey[700]),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '${FormatHelper.formatPrice(price)}/วัน',
                                                  style: const TextStyle(
                                                    color: Color(0xFF3ABDC5),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => ProductDetailPage(
                                                          productId: item['product_id']?.toString(),
                                                          name: item['name'] ?? 'สินค้า',
                                                          image: imageUrl,
                                                          description: item['description'] ?? '',
                                                          price: '${FormatHelper.formatPrice(price)}/วัน',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: const Text('ดูรายละเอียด'),
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
                              // ปุ่มลบ
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  tooltip: 'ลบออก',
                                  onPressed: () => _removeItem(index),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
