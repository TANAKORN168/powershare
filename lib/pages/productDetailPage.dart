import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:powershare/services/session.dart';
import 'package:powershare/services/apiServices.dart';
import 'package:powershare/mainLayout.dart';
import 'package:powershare/helps/formatHelper.dart';
import 'package:powershare/services/productNotifier.dart';

class ProductDetailPage extends StatefulWidget {
  final String? productId;
  final String name;
  final String image;
  final String description;
  final String price;
  final String? status; // เพิ่ม parameter สำหรับรับสถานะ

  const ProductDetailPage({
    super.key,
    this.productId,
    required this.name,
    required this.image,
    required this.description,
    this.price = '฿990/เดือน',
    this.status,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool isLiked = false;
  DateTime? _rentStart;
  DateTime? _rentEnd;
  String? _productStatus;
  bool _loadingStatus = true;

  @override
  void initState() {
    super.initState();
    _initLikeState();
    _loadProductStatus();
  }

  Future<void> _loadProductStatus() async {
    setState(() => _loadingStatus = true);

    try {
      // ถ้ามี status ส่งมาจาก constructor ให้ใช้เลย
      if (widget.status != null) {
        setState(() {
          _productStatus = widget.status;
          _loadingStatus = false;
        });
        return;
      }

      // ถ้าไม่มี ให้ดึงจาก database
      if (widget.productId != null && widget.productId!.isNotEmpty) {
        final product = await ApiServices.getProductById(widget.productId!);
        if (mounted && product != null) {
          setState(() {
            _productStatus = product['last_status']?.toString() ?? 'Available';
            _loadingStatus = false;
          });
        } else if (mounted) {
          setState(() {
            _productStatus = 'Available'; // default
            _loadingStatus = false;
          });
        }
      } else {
        setState(() {
          _productStatus = 'Available'; // default
          _loadingStatus = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('loadProductStatus error: $e');
      if (mounted) {
        setState(() {
          _productStatus = 'Available';
          _loadingStatus = false;
        });
      }
    }
  }

  Future<void> _initLikeState() async {
    final user = Session.instance.user;
    if (user == null || user['id'] == null) return;
    final userId = user['id'].toString();

    try {
      final ids = await ApiServices.getUserLikedProductIds(userId);
      if (!mounted) return;

      final pid = (widget.productId != null && widget.productId!.isNotEmpty) ? widget.productId! : widget.name;
      setState(() {
        isLiked = ids.contains(pid);
      });

      if (kDebugMode) {
        debugPrint('ProductDetailPage: userId=$userId, productId=$pid, liked=$isLiked');
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
    final productId = (widget.productId != null && widget.productId!.isNotEmpty) ? widget.productId! : widget.name;

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
        setState(() {
          isLiked = !isLiked;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ทำรายการไม่สำเร็จ ลองใหม่อีกครั้ง')));
        }
      } else {
        if (kDebugMode) debugPrint('_toggleLike: success');
      }
    } catch (e) {
      setState(() {
        isLiked = !isLiked;
      });
      if (kDebugMode) debugPrint('_toggleLike error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาด ลองใหม่อีกครั้ง')));
      }
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final minStartDate = now.add(const Duration(days: 3)); // บวก 3 วัน

    final result = await showDateRangePicker(
      context: context,
      firstDate: minStartDate, // เปลี่ยนจาก now เป็น now + 3 วัน
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _rentStart != null && _rentEnd != null
          ? DateTimeRange(start: _rentStart!, end: _rentEnd!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3ABDC5),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        _rentStart = result.start;
        _rentEnd = result.end;
      });
    }
  }

  int get _rentalDays {
    if (_rentStart == null || _rentEnd == null) return 1;
    return _rentEnd!.difference(_rentStart!).inDays + 1;
  }

  double get _dailyRate {
    try {
      final priceStr = widget.price.replaceAll(RegExp(r'[^0-9\.\-]'), '');
      return double.tryParse(priceStr) ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  double get _totalPrice => _dailyRate * _rentalDays;

  bool get _isAvailable => _productStatus == 'Available';

  String _getStatusText(String status) {
    switch (status) {
      case 'Available':
        return 'พร้อมให้เช่า';
      case 'Reserved':
        return 'สินค้ากำลังถูกจอง';
      case 'Rented':
        return 'สินค้ากำลังถูกเช่าอยู่';
      case 'Maintenance':
        return 'สินค้าอยู่ระหว่างซ่อมบำรุง';
      case 'Unavailable':
        return 'สินค้าไม่พร้อมให้บริการ';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Reserved':
        return Colors.orange;
      case 'Rented':
        return Colors.red;
      case 'Maintenance':
        return Colors.blue;
      case 'Unavailable':
        return Colors.grey;
      default:
        return Colors.grey;
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
      body: _loadingStatus
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        const SizedBox(height: 8),
                        
                        // แสดงสถานะสินค้า
                        if (_productStatus != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_productStatus!).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _getStatusColor(_productStatus!)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isAvailable ? Icons.check_circle : Icons.info,
                                  size: 16,
                                  color: _getStatusColor(_productStatus!),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getStatusText(_productStatus!),
                                  style: TextStyle(
                                    color: _getStatusColor(_productStatus!),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        Text(widget.description, style: TextStyle(color: Colors.grey[800])),
                        const SizedBox(height: 24),

                        // ช่วงวันที่เช่า (แสดงเฉพาะถ้า Available)
                        if (_isAvailable)
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            child: InkWell(
                              onTap: _pickDateRange,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: Color(0xFF3ABDC5)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('ช่วงวันที่เช่า', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                          const SizedBox(height: 4),
                                          Text(
                                            _rentStart != null && _rentEnd != null
                                                ? '${_rentStart!.day}/${_rentStart!.month}/${_rentStart!.year + 543} - ${_rentEnd!.day}/${_rentEnd!.month}/${_rentEnd!.year + 543} ($_rentalDays วัน)'
                                                : 'เลือกวันที่',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        if (_isAvailable) const SizedBox(height: 16),

                        // สรุปราคา (แสดงเฉพาะถ้า Available และเลือกวันแล้ว)
                        if (_isAvailable && _rentStart != null && _rentEnd != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('ราคาต่อวัน:', style: TextStyle(fontSize: 16)),
                                    Text(FormatHelper.formatPrice(_dailyRate), style: const TextStyle(fontSize: 16)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('จำนวนวัน:', style: TextStyle(fontSize: 16)),
                                    Text('$_rentalDays วัน', style: const TextStyle(fontSize: 16)),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('ยอดรวม:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text(
                                      FormatHelper.formatPrice(_totalPrice),
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3ABDC5)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // ปุ่มเช่าสินค้า (แสดงเฉพาะเมื่อ Available)
                        if (_isAvailable)
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

                                    if (_rentStart == null || _rentEnd == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกช่วงวันที่เช่า')));
                                      return;
                                    }

                                    if (kDebugMode) debugPrint('addToCart: session.user = $user');

                                    final userId = user['id'].toString();
                                    final pid = widget.productId ?? '';
                                    if (pid.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบรหัสสินค้านี้')));
                                      return;
                                    }

                                    final items = [
                                      {
                                        'product_id': pid,
                                        'quantity': 1,
                                        'unit_price': _dailyRate,
                                        'rent_start': _rentStart!.toIso8601String().split('T')[0],
                                        'rent_end': _rentEnd!.toIso8601String().split('T')[0],
                                        'rental_days': _rentalDays,
                                      }
                                    ];

                                    final ok = await ApiServices.addToCart(userId, items);

                                    if (ok) {
                                      ProductNotifier.instance.notifyProductChanged();
                                      MainLayout.of(context)?.refreshCartCount();
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เพิ่มลงตะกร้าแล้ว'), duration: Duration(seconds: 1)));
                                      // กลับไปหน้า Home และ clear navigation stack
                                      await Future.delayed(const Duration(milliseconds: 300));
                                      if (!mounted) return;
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => const MainLayout(currentIndex: 0)),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่สามารถเพิ่มลงตะกร้าได้')));
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3ABDC5),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    child: Text('เช่าสินค้า', style: TextStyle(fontSize: 18)),
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
