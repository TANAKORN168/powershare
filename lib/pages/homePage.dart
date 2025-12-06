import 'package:marquee/marquee.dart';
import 'package:powershare/services/apiServices.dart';
import 'package:powershare/pages/productDetailPage.dart';
import 'package:powershare/services/session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // liked product ids ของผู้ใช้ (เก็บเป็น string ของ product_id)
  final Set<String> _likedProductIds = {};

  // promotions
  List<Map<String, dynamic>> _promotions = [];
  bool _loadingPromotions = true;
  String _promotionsText = '';

  // popular from supabase
  List<Map<String, dynamic>> _popularItems = [];
  bool _loadingPopular = true;

  // recommended (available)
  List<Map<String, dynamic>> _recommendedItems = [];
  bool _loadingRecommended = true;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
    _loadPopular();
    _loadRecommended();
    _loadUserLikes();
  }

  Future<void> _loadUserLikes() async {
    final user = Session.instance.user;
    if (user == null || user['id'] == null) return;
    final userId = user['id'].toString();
    try {
      final ids = await ApiServices.getUserLikedProductIds(userId);
      if (!mounted) return;
      setState(() {
        _likedProductIds.clear();
        _likedProductIds.addAll(ids);
      });
    } catch (e) {
      if (kDebugMode) debugPrint('loadUserLikes error: $e');
    }
  }

  Future<void> _loadPromotions() async {
    setState(() {
      _loadingPromotions = true;
      _promotions = [];
      _promotionsText = '';
    });
    try {
      final data = await ApiServices.getPromotions(onlyActive: true);
      _promotions = data.map((e) => Map<String, dynamic>.from(e)).toList();
      final texts = _promotions
          .map((p) => (p['text']?.toString() ?? '').trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (texts.isNotEmpty) {
        _promotionsText = texts.join('   •   ');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('loadPromotions error: $e');
      _promotions = [];
      _promotionsText = '';
    } finally {
      if (mounted) setState(() => _loadingPromotions = false);
    }
  }

  Future<void> _loadPopular() async {
    setState(() {
      _loadingPopular = true;
      _popularItems = [];
    });
    try {
      final data = await ApiServices.getPopularProducts(limit: 10, onlyActive: true);
      _popularItems = data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('loadPopular error: $e');
      _popularItems = [];
    } finally {
      if (mounted) setState(() => _loadingPopular = false);
    }
  }

  Future<void> _loadRecommended() async {
    setState(() {
      _loadingRecommended = true;
      _recommendedItems = [];
    });
    try {
      final data = await ApiServices.getAvailableProducts(limit: 20);
      _recommendedItems = data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('loadRecommended error: $e');
      _recommendedItems = [];
    } finally {
      if (mounted) setState(() => _loadingRecommended = false);
    }
  }

  // toggle like: ถ้ายังไม่ถูกใจ -> createLike, ถ้าถูกใจแล้ว -> deleteLike
  Future<void> _toggleLike(String productId) async {
    final user = Session.instance.user;
    if (user == null || user['id'] == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนทำรายการ')));
      }
      return;
    }
    final userId = user['id'].toString();

    final currentlyLiked = _likedProductIds.contains(productId);

    // optimistically update UI
    setState(() {
      if (currentlyLiked) {
        _likedProductIds.remove(productId);
      } else {
        _likedProductIds.add(productId);
      }
    });

    try {
      bool ok;
      if (currentlyLiked) {
        ok = await ApiServices.deleteLike(userId, productId);
      } else {
        ok = await ApiServices.createLike(userId, productId);
      }
      if (!ok) {
        // rollback UI change on failure
        setState(() {
          if (currentlyLiked) {
            _likedProductIds.add(productId);
          } else {
            _likedProductIds.remove(productId);
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ทำรายการไม่สำเร็จ ลองใหม่อีกครั้ง')));
        }
      }
    } catch (e) {
      // rollback on exception
      setState(() {
        if (currentlyLiked) {
          _likedProductIds.add(productId);
        } else {
          _likedProductIds.remove(productId);
        }
      });
      if (kDebugMode) debugPrint('_toggleLike error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาด ลองใหม่อีกครั้ง')));
      }
    }
  }

  void _goToDetail(BuildContext context, Map<String, dynamic> item) async {
    final productId = (item['id'] ?? '').toString();
    final name = (item['name'] ?? 'ไม่มีชื่อ').toString();
    final image = (item['image'] ?? '').toString();
    final description = (item['description'] ?? '').toString();
    final priceVal = item['price'] ?? item['rent_amount'] ?? '';
    final priceText = _formatPrice(priceVal);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(
          productId: productId,
          name: name,
          image: image,
          description: description,
          price: priceText,
        ),
      ),
    );

    // เมื่อกลับมาจากหน้า detail ให้รีโหลดสถานะ like ของ user จาก DB
    if (!mounted) return;
    _loadUserLikes();
  }

  Widget _buildImageWidget(String image, {double size = 60}) {
    if (image.startsWith('http')) {
      return Image.network(
        image,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
      );
    } else if (image.isNotEmpty) {
      return Image.asset(
        image,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image),
      );
    } else {
      return const Icon(Icons.image, size: 40);
    }
  }

  Widget _buildLikeButton(String productId) {
    final liked = _likedProductIds.contains(productId);
    return Material(
      color: Colors.transparent,
      child: IconButton(
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
        icon: Icon(
          liked ? Icons.favorite : Icons.favorite_border,
          color: liked ? Colors.red : Colors.grey,
          size: 20,
        ),
        onPressed: () => _toggleLike(productId),
      ),
    );
  }

  // ฟอร์แมตราคาเป็นทศนิยม 2 ตำแหน่ง และต่อด้วย "/วัน"
  String _formatPrice(dynamic priceVal) {
    if (priceVal == null) return '';
    double? value;
    if (priceVal is num) {
      value = priceVal.toDouble();
    } else {
      value = double.tryParse(priceVal.toString());
    }
    if (value == null) {
      // ถ้าไม่สามารถแปลงเป็นตัวเลขได้ ให้คืนค่าตามเดิม (string)
      final s = priceVal.toString();
      return s.isNotEmpty ? '$s/วัน' : '';
    }
    return '฿${value.toStringAsFixed(2)}/วัน';
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
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),
        // รายการสินค้าแนวนอน
        SizedBox(
          height: 120,
          child: _loadingPopular
              ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator()))
              : _popularItems.isEmpty
                  ? const Center(child: Text('ยังไม่มีข้อมูลสินค้ายอดนิยม'))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _popularItems.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final item = _popularItems[index];
                        final productId = (item['id'] ?? '').toString();
                        final name = (item['name'] ?? 'ไม่มีชื่อ').toString();
                        final image = (item['image'] ?? '').toString();

                        return GestureDetector(
                          onTap: () => _goToDetail(context, item),
                          child: Container(
                            width: 90,
                            margin: const EdgeInsets.only(right: 16),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.white,
                                  child: ClipOval(
                                    child: _buildImageWidget(image, size: 60),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
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
        const SizedBox(height: 8),
        SizedBox(
          height: 28,
          child: Builder(builder: (_) {
            if (_loadingPromotions) {
              return const Center(
                  child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)));
            }
            if (_promotionsText.isEmpty) {
              return const Center(
                child: Text(
                  'ไม่มีโปรโมชั่นในขณะนี้',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }
            return Marquee(
              text: _promotionsText,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              scrollAxis: Axis.horizontal,
              blankSpace: 50.0,
              velocity: 50.0,
              pauseAfterRound: const Duration(seconds: 1),
              startPadding: 10.0,
              accelerationDuration: const Duration(seconds: 1),
              accelerationCurve: Curves.linear,
              decelerationDuration: const Duration(milliseconds: 500),
              decelerationCurve: Curves.easeOut,
            );
          }),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          color: const Color(0xFF3ABDC5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: const Center(
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

        // Recommended list -> ใช้ข้อมูลจาก Supabase: last_status = 'Available'
        Expanded(
          child: _loadingRecommended
              ? const Center(child: CircularProgressIndicator())
              : _recommendedItems.isEmpty
                  ? const Center(child: Text('ยังไม่มีสินค้าที่พร้อมให้คืนตอนนี้'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _recommendedItems.length,
                      itemBuilder: (context, index) {
                        final item = _recommendedItems[index];
                        final productId = (item['id'] ?? '').toString();
                        final name = (item['name'] ?? 'ไม่มีชื่อ').toString();
                        final description = (item['description'] ?? '').toString();
                        final image = (item['image'] ?? '').toString();
                        final priceVal = item['price'] ?? item['rent_amount'] ?? '';
                        final priceText = _formatPrice(priceVal);

                        return Stack(
                          children: [
                            Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    ClipRRect(borderRadius: BorderRadius.circular(8), child: _buildImageWidget(image, size: 80)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            description,
                                            style: TextStyle(color: Colors.grey[700]),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                priceText.isNotEmpty ? priceText : 'ราคาไม่ระบุ',
                                                style: const TextStyle(color: Color(0xFF3ABDC5), fontWeight: FontWeight.bold),
                                              ),
                                              TextButton(
                                                onPressed: () => _goToDetail(context, item),
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
                            // ปุ่มถูกใจที่มุมขวาบนของ Card (แสดงเฉพาะใน Recommended)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: _buildLikeButton(productId),
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