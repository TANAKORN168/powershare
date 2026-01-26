import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:powershare/mainLayout.dart';
import 'package:powershare/services/apiServices.dart';
import 'package:powershare/services/session.dart';
import 'package:powershare/helps/formatHelper.dart';
import 'package:http/http.dart' as http; // เพิ่ม
import 'dart:convert'; // เพิ่ม
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> cartItems = [];
  bool _loading = true;
  String? _userId;

  // แก้ไขส่วนแสดง QR dialog ใน cartPage.dart

  // เพิ่ม state variable
  Map<String, dynamic>? _paymentSettings;

  // เพิ่ม method โหลดการตั้งค่า
  Future<void> _loadPaymentSettings() async {
    try {
      final Map<String, dynamic>? settings =
          await ApiServices.getPaymentSettings(); // ← เพิ่ม type
      if (kDebugMode) print('🔵 Payment settings loaded: $settings');
      if (mounted && settings != null) {
        setState(() => _paymentSettings = settings);
      }
    } catch (e) {
      if (kDebugMode) print('❌ loadPaymentSettings error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _userId = Session.instance.user?['id']?.toString();
    _loadCartItems();
    _loadPaymentSettings(); // ← เพิ่มบรรทัดนี้
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

      if (kDebugMode)
        print(
          "CartPage: loading cart for userId='$_userId' tokenLen=${Session.instance.accessToken?.length ?? 0}",
        );

      final items = await ApiServices.getCartItemsForUser(_userId!);

      if (kDebugMode) print('CartPage: got ${items.length} items from API');

      if (mounted) {
        setState(() {
          cartItems = items.map((it) {
            try {
              final priceRaw = it['price'];
              final price = (priceRaw is num)
                  ? priceRaw.toDouble()
                  : double.tryParse(priceRaw?.toString() ?? '0') ?? 0.0;
              final image = (it['image'] ?? '').toString();
              final rentalDays = (it['rental_days'] is int)
                  ? it['rental_days'] as int
                  : int.tryParse(it['rental_days']?.toString() ?? '1') ?? 1;

              return {
                'name': it['name'] ?? 'สินค้า',
                'price': price,
                'image': image.isNotEmpty ? image : null,
                'quantity': it['quantity'] ?? 1,
                'product_id': it['product_id'],
                'item_id': it['item_id'] ?? it['id']?.toString() ?? '',
                'cart_id': it['cart_id'] ?? '',
                'rent_start': it['rent_start'],
                'rent_end': it['rent_end'],
                'rental_days': rentalDays,
              };
            } catch (e) {
              if (kDebugMode) print('CartPage: failed to map item $it -> $e');
              return {
                'name': it['name'] ?? 'สินค้า',
                'price': 0.0,
                'image': null,
                'quantity': it['quantity'] ?? 1,
                'product_id': it['product_id'],
                'item_id': it['item_id'] ?? it['id']?.toString() ?? '',
                'cart_id': it['cart_id'] ?? '',
                'rent_start': it['rent_start'],
                'rent_end': it['rent_end'],
                'rental_days': 1,
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
        title: const Text('ลบรายการ'),
        content: Text('คุณต้องการลบ "${item['name']}" ออกจากตะกร้าหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final ok = await ApiServices.deleteCartItem(
        itemId ?? '',
        productId: productId,
        cartId: cartId,
      );
      if (ok) {
        if (mounted) {
          setState(() {
            cartItems.removeAt(index);
            _loading = false;
          });
          // อัปเดต badge ตะกร้าใน MainLayout
          MainLayout.of(context)?.refreshCartCount();
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ลบรายการเรียบร้อยแล้ว')));
      } else {
        if (mounted) {
          setState(() => _loading = false);
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ลบรายการไม่สำเร็จ')));
      }
    } catch (e) {
      if (kDebugMode) print('removeItem error: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาด')));
    }
  }

  Future<void> _editItem(int index) async {
    final item = cartItems[index];
    final itemId = item['item_id']?.toString();

    if (itemId == null || itemId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่พบรหัสรายการ')));
      return;
    }

    // Parse วันที่เดิม
    DateTime? currentStart;
    DateTime? currentEnd;

    try {
      if (item['rent_start'] != null) {
        currentStart = DateTime.parse(item['rent_start'].toString());
      }
      if (item['rent_end'] != null) {
        currentEnd = DateTime.parse(item['rent_end'].toString());
      }
    } catch (e) {
      if (kDebugMode) print('Error parsing dates: $e');
    }

    // เปิด dialog เลือกวันที่ใหม่
    final now = DateTime.now();
    final minStartDate = now.add(const Duration(days: 3));

    final result = await showDateRangePicker(
      context: context,
      firstDate: minStartDate,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: currentStart != null && currentEnd != null
          ? DateTimeRange(start: currentStart, end: currentEnd)
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

    if (result == null) return; // ยกเลิก

    // คำนวณจำนวนวัน
    final rentalDays = result.end.difference(result.start).inDays + 1;

    // อัปเดตข้อมูลไปยัง API
    try {
      final updateUrl = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/cart_items?id=eq.$itemId',
      );

      final token = Session.instance.accessToken ?? ApiConfig.apiKey;
      final headers = {
        'apikey': ApiConfig.apiKey,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final body = {
        'rent_start': result.start.toIso8601String().split('T')[0],
        'rent_end': result.end.toIso8601String().split('T')[0],
        'rental_days': rentalDays,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final resp = await http.patch(
        updateUrl,
        headers: headers,
        body: jsonEncode(body),
      );

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        // อัปเดต cart total
        final cartId = item['cart_id']?.toString();
        if (cartId != null && cartId.isNotEmpty) {
          await _updateCartTotal(cartId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('แก้ไขวันที่เรียบร้อย'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCartItems(); // โหลดข้อมูลใหม่
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('แก้ไขไม่สำเร็จ'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('editItem error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateCartTotal(String cartId) async {
    try {
      final token = Session.instance.accessToken ?? ApiConfig.apiKey;
      final headers = {
        'apikey': ApiConfig.apiKey,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      // ดึง cart_items ทั้งหมดของ cart นี้
      final itemsUrl = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/cart_items?cart_id=eq.$cartId',
      );
      final itemsResp = await http.get(itemsUrl, headers: headers);

      if (itemsResp.statusCode == 200) {
        final items = jsonDecode(itemsResp.body) as List<dynamic>;
        double total = 0;

        for (var item in items) {
          final unitPrice = (item['unit_price'] is num)
              ? (item['unit_price'] as num).toDouble()
              : double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0.0;
          final rentalDays = (item['rental_days'] is int)
              ? item['rental_days'] as int
              : int.tryParse(item['rental_days']?.toString() ?? '1') ?? 1;
          total += unitPrice * rentalDays;
        }

        // อัปเดต total_amount
        final cartUrl = Uri.parse(
          '${ApiConfig.baseUrl}/rest/v1/carts?id=eq.$cartId',
        );
        final cartBody = {
          'total_amount': total,
          'updated_at': DateTime.now().toIso8601String(),
        };

        await http.patch(cartUrl, headers: headers, body: jsonEncode(cartBody));
      }
    } catch (e) {
      if (kDebugMode) print('updateCartTotal error: $e');
    }
  }

  double get total => cartItems.fold(0.0, (sum, item) {
    final priceRaw = item['price'];
    final p = (priceRaw is num)
        ? priceRaw.toDouble()
        : double.tryParse(priceRaw?.toString() ?? '0') ?? 0.0;

    // คำนวณจำนวนวันจาก rent_start และ rent_end ถ้ามี
    int days = 1;
    if (item['rent_start'] != null && item['rent_end'] != null) {
      try {
        final startDate = DateTime.parse(item['rent_start'].toString());
        final endDate = DateTime.parse(item['rent_end'].toString());
        days = endDate.difference(startDate).inDays + 1;
      } catch (e) {
        days = item['rental_days'] as int? ?? 1;
      }
    } else {
      days = item['rental_days'] as int? ?? 1;
    }

    return sum + (p * days);
  });

  String _formatThaiDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year + 543}';
    } catch (e) {
      return dateStr.split('T')[0]; // fallback: แสดงแค่วันที่
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF3ABDC5),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Center(
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
                ? const Center(child: CircularProgressIndicator())
                : cartItems.isEmpty
                ? const Center(child: Text('ยังไม่มีสินค้าในตะกร้า'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      final image = item['image'] as String?;
                      final dailyPrice = (item['price'] is num)
                          ? (item['price'] as num).toDouble()
                          : double.tryParse(item['price']?.toString() ?? '0') ??
                                0.0;

                      final rentStart = item['rent_start'] as String?;
                      final rentEnd = item['rent_end'] as String?;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            if (image != null && image.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  image,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? 'สินค้า',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Builder(
                                    builder: (context) {
                                      // คำนวณจำนวนวันจาก rent_start และ rent_end ถ้ามี
                                      int days = 1;
                                      final rentStart = item['rent_start'];
                                      final rentEnd = item['rent_end'];

                                      if (rentStart != null &&
                                          rentEnd != null) {
                                        try {
                                          final startDate = DateTime.parse(
                                            rentStart.toString(),
                                          );
                                          final endDate = DateTime.parse(
                                            rentEnd.toString(),
                                          );
                                          days =
                                              endDate
                                                  .difference(startDate)
                                                  .inDays +
                                              1;
                                        } catch (e) {
                                          days =
                                              item['rental_days'] as int? ?? 1;
                                        }
                                      } else {
                                        days = item['rental_days'] as int? ?? 1;
                                      }

                                      final itemTotal = dailyPrice * days;

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${FormatHelper.formatPrice(dailyPrice)}/วัน × $days วัน',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'รวม: ${FormatHelper.formatPrice(itemTotal)}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF3ABDC5),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  if (rentStart != null && rentEnd != null) ...[
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: Colors.black54,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_formatThaiDate(rentStart)} - ${_formatThaiDate(rentEnd)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _editItem(
                                            index,
                                          ), // เพิ่ม logic ตรงนี้
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF3ABDC5,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'แก้ไข',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () => _removeItem(index),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'ลบ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3ABDC5), Color(0xFF2A9DA5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3ABDC5).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: cartItems.isEmpty
                      ? null
                      : () async {
                          final cartIdForPayment = cartItems.isNotEmpty
                              ? cartItems.first['cart_id']?.toString()
                              : null;

                          final ImagePicker picker = ImagePicker();
                          File? selectedSlip;
                          bool isUploadingSlip = false;
                          String? dialogError;

                          if (_paymentSettings == null) {
                            await _loadPaymentSettings();
                          }

                          final qrImageUrl = _paymentSettings?['qr_image_url']
                              ?.toString();
                          final promptpayName =
                              _paymentSettings?['promptpay_name']?.toString() ??
                              'ระบบเช่า';
                          final promptpayNumber =
                              _paymentSettings?['promptpay_number']?.toString();

                          final confirmed = await showDialog<bool>(
                            context: context,
                            barrierDismissible: true,
                            builder: (dialogContext) {
                              final screenH = MediaQuery.of(
                                dialogContext,
                              ).size.height;
                              final screenW = MediaQuery.of(
                                dialogContext,
                              ).size.width;
                              final dialogH = screenH * 0.9;
                              final dialogW = screenW < 520 ? screenW : 520.0;

                              return StatefulBuilder(
                                builder: (context, setDialogState) {
                                  return Dialog(
                                    insetPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 24,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: SizedBox(
                                      width: dialogW,
                                      height: dialogH,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            const Text(
                                              'QR Code ชำระเงิน',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Expanded(
                                              child: SingleChildScrollView(
                                                child: Column(
                                                  children: [
                                                    const Text(
                                                      'ยอดชำระทั้งหมด',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      FormatHelper.formatPrice(
                                                        total,
                                                      ),
                                                      style: const TextStyle(
                                                        fontSize: 28,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color(
                                                          0xFF3ABDC5,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 20),

                                                    // แสดง QR Code จริงจาก database
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            16,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        border: Border.all(
                                                          color: Colors.grey,
                                                          width: 2,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child:
                                                          qrImageUrl != null &&
                                                              qrImageUrl
                                                                  .isNotEmpty
                                                          ? Image.network(
                                                              qrImageUrl,
                                                              width: 240,
                                                              height: 240,
                                                              fit: BoxFit
                                                                  .contain,
                                                              errorBuilder:
                                                                  (
                                                                    _,
                                                                    __,
                                                                    ___,
                                                                  ) => const Icon(
                                                                    Icons
                                                                        .qr_code_2,
                                                                    size: 160,
                                                                    color: Color(
                                                                      0xFF3ABDC5,
                                                                    ),
                                                                  ),
                                                            )
                                                          : const Icon(
                                                              Icons.qr_code_2,
                                                              size: 160,
                                                              color: Color(
                                                                0xFF3ABDC5,
                                                              ),
                                                            ),
                                                    ),

                                                    const SizedBox(height: 16),
                                                    Text(
                                                      promptpayName,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    if (promptpayNumber !=
                                                        null) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'พร้อมเพย์: $promptpayNumber',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.black54,
                                                        ),
                                                      ),
                                                    ],
                                                    const SizedBox(height: 20),
                                                    const Text(
                                                      'กรุณาสแกน QR Code เพื่อชำระเงิน',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black54,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),

                                                    const SizedBox(height: 16),
                                                    const Divider(),
                                                    const SizedBox(height: 12),
                                                    const Text(
                                                      'แนบสลิปการชำระเงิน',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    if (selectedSlip != null)
                                                      Container(
                                                        width: 220,
                                                        height: 320,
                                                        decoration: BoxDecoration(
                                                          border: Border.all(
                                                            color: Colors.grey,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          child: Image.file(
                                                            selectedSlip!,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      )
                                                    else
                                                      Container(
                                                        width: 220,
                                                        height: 120,
                                                        decoration: BoxDecoration(
                                                          border: Border.all(
                                                            color: Colors.grey,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          color:
                                                              Colors.grey[200],
                                                        ),
                                                        child: const Center(
                                                          child: Text(
                                                            'ยังไม่ได้แนบสลิป',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .black54,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    const SizedBox(height: 12),
                                                    if (!isUploadingSlip)
                                                      ElevatedButton.icon(
                                                        onPressed: () async {
                                                          final XFile?
                                                          picked = await picker
                                                              .pickImage(
                                                                source:
                                                                    ImageSource
                                                                        .gallery,
                                                                maxWidth: 1920,
                                                                maxHeight: 1920,
                                                                imageQuality:
                                                                    85,
                                                              );
                                                          if (picked != null) {
                                                            setDialogState(() {
                                                              selectedSlip =
                                                                  File(
                                                                    picked.path,
                                                                  );
                                                              dialogError =
                                                                  null;
                                                            });
                                                          }
                                                        },
                                                        icon: const Icon(
                                                          Icons.image,
                                                        ),
                                                        label: Text(
                                                          selectedSlip == null
                                                              ? 'เลือกรูปสลิป'
                                                              : 'เปลี่ยนรูปสลิป',
                                                        ),
                                                        style:
                                                            ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  const Color(
                                                                    0xFF3ABDC5,
                                                                  ),
                                                              foregroundColor:
                                                                  Colors.white,
                                                            ),
                                                      )
                                                    else
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              top: 8,
                                                            ),
                                                        child: Column(
                                                          children: [
                                                            CircularProgressIndicator(),
                                                            SizedBox(height: 8),
                                                            Text(
                                                              'กำลังอัปโหลดสลิป...',
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            if (dialogError != null) ...[
                                              const SizedBox(height: 10),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withValues(
                                                    alpha: 0.08,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.red
                                                        .withValues(alpha: 0.4),
                                                  ),
                                                ),
                                                child: ConstrainedBox(
                                                  constraints:
                                                      const BoxConstraints(
                                                        maxHeight: 80,
                                                      ),
                                                  child: SingleChildScrollView(
                                                    child: Text(
                                                      dialogError!,
                                                      style: const TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton(
                                                    onPressed: isUploadingSlip
                                                        ? null
                                                        : () => Navigator.of(
                                                            dialogContext,
                                                          ).pop(false),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.grey,
                                                      side: const BorderSide(
                                                        color: Colors.grey,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 12,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                    ),
                                                    child: const Text('ยกเลิก'),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: isUploadingSlip
                                                        ? null
                                                        : () async {
                                                            if (cartIdForPayment ==
                                                                    null ||
                                                                cartIdForPayment
                                                                    .isEmpty) {
                                                              setDialogState(() {
                                                                dialogError =
                                                                    'ไม่พบรหัสตะกร้า';
                                                              });
                                                              return;
                                                            }
                                                            if (selectedSlip ==
                                                                null) {
                                                              setDialogState(() {
                                                                dialogError =
                                                                    'กรุณาแนบสลิปก่อนยืนยัน';
                                                              });
                                                              return;
                                                            }
                                                            setDialogState(() {
                                                              isUploadingSlip =
                                                                  true;
                                                              dialogError =
                                                                  null;
                                                            });
                                                            try {
                                                              final imageUrl =
                                                                  await ApiServices.uploadUserFiles(
                                                                    selectedSlip!,
                                                                    subfolder:
                                                                        'payment-slips',
                                                                  );
                                                              if (imageUrl
                                                                  .isEmpty) {
                                                                throw Exception(
                                                                  'อัปโหลดสลิปไม่สำเร็จ',
                                                                );
                                                              }
                                                              final updateUrl =
                                                                  Uri.parse(
                                                                    '${ApiConfig.baseUrl}/rest/v1/carts?id=eq.$cartIdForPayment',
                                                                  );
                                                              final token =
                                                                  Session
                                                                      .instance
                                                                      .accessToken ??
                                                                  ApiConfig
                                                                      .apiKey;
                                                              final headers = {
                                                                'apikey':
                                                                    ApiConfig
                                                                        .apiKey,
                                                                'Authorization':
                                                                    'Bearer $token',
                                                                'Content-Type':
                                                                    'application/json',
                                                              };
                                                              final body = jsonEncode({
                                                                'payment_slip_url':
                                                                    imageUrl,
                                                                'status':
                                                                    'PAID',
                                                                'paid_at':
                                                                    DateTime.now()
                                                                        .toIso8601String(),
                                                                'updated_at':
                                                                    DateTime.now()
                                                                        .toIso8601String(),
                                                              });
                                                              final resp =
                                                                  await http.patch(
                                                                    updateUrl,
                                                                    headers:
                                                                        headers,
                                                                    body: body,
                                                                  );
                                                              if (resp.statusCode ==
                                                                      200 ||
                                                                  resp.statusCode ==
                                                                      204) {
                                                                // แจ้งเตือน admin ว่ามีการชำระเงินแล้ว
                                                                ApiServices.notifyAdminsPayment(
                                                                  cartId:
                                                                      cartIdForPayment,
                                                                  totalAmount:
                                                                      total,
                                                                  slipUrl:
                                                                      imageUrl,
                                                                );
                                                                // แจ้งเตือนผู้ใช้ (push notification)
                                                                await ApiServices.sendPushNotificationToUser(
                                                                  userId:
                                                                      Session
                                                                          .instance
                                                                          .user?['id'] ??
                                                                      '',
                                                                  title:
                                                                      'แจ้งเตือนการชำระเงิน',
                                                                  body:
                                                                      'ระบบได้รับข้อมูลการชำระเงินของคุณแล้ว',
                                                                );
                                                                if (dialogContext
                                                                    .mounted) {
                                                                  Navigator.of(
                                                                    dialogContext,
                                                                  ).pop(true);
                                                                }
                                                              } else {
                                                                throw Exception(
                                                                  'บันทึกสลิปไม่สำเร็จ (${resp.statusCode}) ${resp.body}',
                                                                );
                                                              }
                                                            } catch (e) {
                                                              if (kDebugMode) {
                                                                print(
                                                                  '[CartPage] upload slip error: $e',
                                                                );
                                                              }
                                                              setDialogState(() {
                                                                isUploadingSlip =
                                                                    false;
                                                                dialogError =
                                                                    'เกิดข้อผิดพลาด: $e';
                                                              });
                                                            }
                                                          },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                            0xFF3ABDC5,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 12,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'ยืนยันการชำระเงิน',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );

                          if (!mounted) return;

                          if (kDebugMode) {
                            print(
                              '[CartPage] QR dialog result confirmed=$confirmed cartId=$cartIdForPayment',
                            );
                          }

                          if (confirmed == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ชำระเงินเรียบร้อย'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _loadCartItems();
                            MainLayout.of(context)?.refreshCartCount();
                          }
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.payment,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          cartItems.isEmpty
                              ? 'ตะกร้าว่าง'
                              : 'ชำระเงิน ${FormatHelper.formatPrice(total)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
