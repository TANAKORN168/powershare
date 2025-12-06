import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:powershare/services/session.dart';
import 'package:powershare/services/apiServices.dart';

class ProductDetailPage extends StatefulWidget {
  final String? productId; // new, optional
  final String name;
  final String image;
  final String description;
  final String price;

  const ProductDetailPage({
    super.key,
    this.productId, // new
    required this.name,
    required this.image,
    required this.description,
    this.price = '฿990/เดือน',
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    _initLikeState();
  }

  Future<void> _initLikeState() async {
    final user = Session.instance.user;
    if (user == null || user['id'] == null) return;
    final userId = user['id'].toString();

    try {
      // ดึง list ของ product_id ที่ user ถูกใจ (จาก DB)
      final ids = await ApiServices.getUserLikedProductIds(userId);
      if (!mounted) return;

      // ถ้ามี productId ที่ส่งเข้ามา ให้เช็คด้วย productId
      final pid = (widget.productId != null && widget.productId!.isNotEmpty) ? widget.productId! : widget.name;
      setState(() {
        isLiked = ids.contains(pid);
      });

      if (kDebugMode) {
        debugPrint('ProductDetailPage: userId=$userId, productId=$pid, liked=${isLiked}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('ProductDetailPage _initLikeState error: $e');
    }
  }

  Future<void> _toggleLike() async {
    final user = Session.instance.user;
    if (user == null || user['id'] == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนทำรายการ')));
      }
      return;
    }
    final userId = user['id'].toString();

    // ผลิต productId ที่จะใช้ (fallback เป็น name ถ้าไม่มี)
    final productId = (widget.productId != null && widget.productId!.isNotEmpty) ? widget.productId! : widget.name;

    // optimistically update UI
    setState(() {
      isLiked = !isLiked;
    });

    if (kDebugMode) {
      debugPrint('_toggleLike: userId=$userId, productId=$productId, newState=$isLiked, tokenLen=${Session.instance.accessToken?.length ?? 0}');
    }

    try {
      bool ok = false;
      if (isLiked) {
        ok = await ApiServices.createLike(userId, productId);
      } else {
        ok = await ApiServices.deleteLike(userId, productId);
      }

      if (!ok) {
        // rollback UI on failure
        setState(() {
          isLiked = !isLiked;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ทำรายการไม่สำเร็จ ลองใหม่อีกครั้ง')));
        }
      } else {
        // ถ้าสำเร็จ อาจอยากอัปเดต local cache ของหน้าก่อนหน้า (HomePage) แต่ต้องสื่อด้วย navigator/pop หรือ event
        if (kDebugMode) debugPrint('_toggleLike: success');
      }
    } catch (e) {
      // rollback on exception
      setState(() {
        isLiked = !isLiked;
      });
      if (kDebugMode) debugPrint('_toggleLike error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาด ลองใหม่อีกครั้ง')));
      }
    }
  }

  Widget _buildImage(String image) {
    if (image.startsWith('http')) {
      return Image.network(
        image,
        width: double.infinity,
        height: 300,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.broken_image, size: 48)),
        ),
      );
    } else if (image.isNotEmpty) {
      return Image.asset(
        image,
        width: double.infinity,
        height: 300,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.broken_image, size: 48)),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: 300,
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.image, size: 48)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดสินค้า'),
        backgroundColor: const Color(0xFF3ABDC5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // เพิ่ม top padding เพื่อไม่ให้รูปติดกับ AppBar
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 300,
                    child: _buildImage(widget.image),
                  ),
                  Positioned(
                    top: 8,
                    right: 12,
                    child: IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey,
                        size: 36,
                      ),
                      onPressed: _toggleLike,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.price, style: const TextStyle(fontSize: 20, color: Color(0xFF3ABDC5), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(widget.description, style: TextStyle(color: Colors.grey[800])),
                  const SizedBox(height: 24),

                  // ปุ่มกลางหน้าจอ ขนาดเหมาะสม และมี padding สวยงาม
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final user = Session.instance.user;
                            if (user == null || user['id'] == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเข้าสู่ระบบ')));
                              return;
                            }

                            // Debug: แสดงข้อมูล session (ปลอดภัยเพราะเช็คแล้ว)
                            if (kDebugMode) debugPrint('addToCart: session.user = $user');

                            final userId = user['id'].toString();
                            if (kDebugMode) debugPrint('addToCart: userId=$userId, email=${user['email'] ?? ''}');

                            final pid = widget.productId ?? '';
                            if (pid.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบรหัสสินค้านี้')));
                              return;
                            }

                            // parse price -> number
                            double unitPrice = 0.0;
                            try {
                              final priceStr = widget.price.replaceAll(RegExp(r'[^0-9\.\-]'), '');
                              unitPrice = double.tryParse(priceStr) ?? 0.0;
                            } catch (_) {
                              unitPrice = 0.0;
                            }

                            final items = [
                              {
                                'product_id': pid,
                                'quantity': 1,
                                'unit_price': unitPrice,
                              }
                            ];

                            // เรียก addToCart (REST fallback)
                            final ok = await ApiServices.addToCart(userId, items);

                            if (ok) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เพิ่มลงตะกร้าแล้ว')));
                              setState(() {});
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่สามารถเพิ่มลงตะกร้าได้')));
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text('เช่าสินค้า', style: TextStyle(fontSize: 18)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3ABDC5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
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
  }
}
