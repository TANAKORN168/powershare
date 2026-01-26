import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:powershare/services/apiServices.dart';
import 'package:powershare/helps/formatHelper.dart';

class ReservationApprovalPage extends StatefulWidget {
  const ReservationApprovalPage({super.key});

  @override
  State<ReservationApprovalPage> createState() =>
      _ReservationApprovalPageState();
}

class _ReservationApprovalPageState extends State<ReservationApprovalPage> {
  List<Map<String, dynamic>> reservations = [];
  bool _loading = true;

  bool _isRejectStatus(String? status) {
    if (status == null) return false;
    return status.toUpperCase() == 'REJECT' || status.toLowerCase() == 'reject';
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() => _loading = true);
    try {
      final res = await ApiServices.getReservations();
      if (mounted) {
        if (kDebugMode) {
          print('=== DEBUG ReservationApprovalPage ===');
          print('Loaded reservations: ${res.length}');
          for (var i = 0; i < res.length; i++) {
            print(
              '[$i] id: ${res[i]['id']}, product: ${res[i]['product']}, cart_item: ${res[i]['cart_item']}',
            );
          }
        }
        setState(() {
          reservations = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('loadReservations error: $e');
      if (mounted) {
        setState(() {
          reservations = [];
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ตัวแรก แสดงทั้งหมดที่ได้มาเพื่อ debug
    if (kDebugMode) {
      print('=== ReservationApprovalPage Debug ===');
      print('Total reservations: ${reservations.length}');
      for (var i = 0; i < reservations.length; i++) {
        print(
          '[$i] status: ${reservations[i]['status']}, id: ${reservations[i]['id']}, cart_items: ${reservations[i]['cart_items']}',
        );
      }
    }

    // แยกเป็นสองแท็บตามสถานะ cart_item
    final pendingReservations = reservations.where((r) {
      final cartItem = r['cart_item'] as Map<String, dynamic>?;
      final status = cartItem?['status']?.toString();
      return status == 'RESERVED';
    }).toList();

    final approvedReservations = reservations.where((r) {
      final cartItem = r['cart_item'] as Map<String, dynamic>?;
      final status = cartItem?['status']?.toString();
      return status == 'RENTED';
    }).toList();

    final rejectedReservations = reservations.where((r) {
      final cartItem = r['cart_item'] as Map<String, dynamic>?;
      final status = cartItem?['status']?.toString();
      return _isRejectStatus(status);
    }).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('อนุมัติการจอง'),
          backgroundColor: const Color(0xFF3ABDC5),
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('รอการอนุมัติ'),
                    const SizedBox(width: 6),
                    _buildCountBadge(pendingReservations.length),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('อนุมัติแล้ว'),
                    const SizedBox(width: 6),
                    _buildCountBadge(approvedReservations.length),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('ปฏิเสธ'),
                    const SizedBox(width: 6),
                    _buildCountBadge(rejectedReservations.length),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // แท็บรอการอนุมัติ
            _buildPendingReservations(pendingReservations),
            // แท็บอนุมัติแล้ว
            _buildApprovedReservations(approvedReservations),
            // แท็บปฏิเสธ
            _buildRejectedReservations(rejectedReservations),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingReservations(List<Map<String, dynamic>> pending) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (kDebugMode) {
      print('PendingReservations count: ${pending.length}');
      print('All reservations count: ${reservations.length}');
      print('Reservations data: ${reservations.toString()}');
    }

    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'ไม่มีสินค้าที่ถูกจอง',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(
              'รวมข้อมูล: ${reservations.length} รายการ',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.builder(
        itemCount: pending.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final reservation = pending[index];
          return _buildReservationCard(context, reservation, isPending: true);
        },
      ),
    );
  }

  Widget _buildApprovedReservations(List<Map<String, dynamic>> approved) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (approved.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'ไม่มีการจองที่อนุมัติแล้ว',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.builder(
        itemCount: approved.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final reservation = approved[index];
          return _buildReservationCard(context, reservation, isPending: false);
        },
      ),
    );
  }

  Widget _buildRejectedReservations(List<Map<String, dynamic>> rejected) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (rejected.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'ไม่มีการจองที่ถูกปฏิเสธ',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.builder(
        itemCount: rejected.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final reservation = rejected[index];
          return _buildReservationCard(
            context,
            reservation,
            isPending: false,
            isRejected: true,
          );
        },
      ),
    );
  }

  Widget _buildReservationCard(
    BuildContext context,
    Map<String, dynamic> reservation, {
    required bool isPending,
    bool isRejected = false,
  }) {
    assert(!(isPending && isRejected));

    // ดึง user info จาก reservation.user
    final user = reservation['user'] as Map<String, dynamic>?;
    final userName = user != null
        ? '${user['name']?.toString() ?? ''} ${user['surname']?.toString() ?? ''}'
              .trim()
        : 'ผู้ใช้ไม่ระบุ';

    final createdDate = reservation['created_at']?.toString() ?? '-';
    final slipUrl = (reservation['payment_slip_url'] ?? '').toString();

    // ดึงข้อมูล product และ cart_item
    final product = reservation['product'] as Map<String, dynamic>? ?? {};
    final cartItem = reservation['cart_item'] as Map<String, dynamic>? ?? {};

    final productName = product['name']?.toString() ?? 'สินค้าไม่ระบุ';
    final deliveryDate = cartItem['delivery_date']?.toString() ?? '-';
    final rejectionReason =
        cartItem['rejection_reson']?.toString() ??
        cartItem['rejection_reason']?.toString() ??
        cartItem['cancellation_reason']?.toString() ??
        '-';

    final statusLabel = isPending
        ? 'รอการอนุมัติ'
        : (isRejected ? 'ปฏิเสธแล้ว' : 'อนุมัติแล้ว');

    final statusColor = isPending
        ? Colors.orange
        : (isRejected ? Colors.red : Colors.green);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ผู้จอง: $userName',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        'วันที่จอง:',
                        FormatHelper.formatDateTime(createdDate),
                      ),
                      if (!isPending && !isRejected)
                        _buildInfoRow(
                          'วันส่ง:',
                          FormatHelper.formatDateTime(deliveryDate),
                        ),
                      if (isRejected)
                        _buildInfoRow('เหตุผลปฏิเสธ:', rejectionReason),
                    ],
                  ),
                ),

                if (slipUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'สลิปการชำระเงิน:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            insetPadding: const EdgeInsets.all(16),
                            child: InteractiveViewer(
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: _LoadingNetworkImage(
                                  url: slipUrl,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 160,
                          height: 160,
                          child: _LoadingNetworkImage(
                            url: slipUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isPending)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showRejectDialog(context, reservation);
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('ปฏิเสธ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showApprovalDialog(context, reservation);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('อนุมัติ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: isRejected
                  ? const SizedBox.shrink()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showShipmentDetailsDialog(context, reservation);
                        },
                        icon: const Icon(Icons.local_shipping),
                        label: const Text('ดูรายละเอียดการส่ง'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3ABDC5),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showApprovalDialog(
    BuildContext context,
    Map<String, dynamic> reservation,
  ) {
    final pageContext = context;
    showDialog(
      context: context,
      builder: (context) => ApprovalDialog(
        reservation: reservation,
        onApprove: (trackingNumber, images, shippedBy, deliveryDate) async {
          try {
            // อนุมัติการจองและบันทึกข้อมูลการส่ง
            await _approveReservation(
              reservation,
              trackingNumber,
              images,
              shippedBy,
              deliveryDate,
            );
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(pageContext).showSnackBar(
                const SnackBar(
                  content: Text('อนุมัติการจองสำเร็จ'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
              _loadReservations();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(pageContext).showSnackBar(
                SnackBar(
                  content: Text('เกิดข้อผิดพลาด: $e'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            if (kDebugMode) print('Approval error: $e');
          }
        },
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    Map<String, dynamic> reservation,
  ) {
    final reasonController = TextEditingController();
    final pageContext = context;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ปฏิเสธการจอง'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'ระบุเหตุผล (ถ้ามี)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _rejectReservation(reservation, reasonController.text);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  const SnackBar(content: Text('ปฏิเสธการจองสำเร็จ')),
                );
                _loadReservations();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ปฏิเสธ'),
          ),
        ],
      ),
    );
  }

  void _showShipmentDetailsDialog(
    BuildContext context,
    Map<String, dynamic> reservation,
  ) {
    final cartItem = reservation['cart_item'] as Map<String, dynamic>?;
    final trackingNumber = cartItem?['tracking_number']?.toString() ?? '-';
    final images = cartItem?['shipment_images'] as List? ?? [];

    final imageUrls = images
        .map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    showDialog(
      context: context,
      builder: (dialogContext) => _ShipmentDetailsDialog(
        trackingNumber: trackingNumber,
        imageUrls: imageUrls,
      ),
    );
  }

  Future<void> _approveReservation(
    Map<String, dynamic> reservation,
    String trackingNumber,
    List<File> images,
    String shippedBy,
    DateTime deliveryDate,
  ) async {
    try {
      final cartItem = reservation['cart_item'] as Map<String, dynamic>?;
      final cartItemId = cartItem?['id']?.toString();
      if (cartItemId == null || cartItemId.isEmpty) {
        throw Exception('cart_item.id missing');
      }

      await ApiServices.updateReservationItemStatus(
        cartItemId: cartItemId,
        status: 'RENTED',
        trackingNumber: trackingNumber,
        images: images,
        shippedBy: shippedBy,
        deliveryDate: deliveryDate,
      );
    } catch (e) {
      if (kDebugMode) print('approveReservation error: $e');
    }
  }

  Future<void> _rejectReservation(
    Map<String, dynamic> reservation,
    String reason,
  ) async {
    try {
      final cartItem = reservation['cart_item'] as Map<String, dynamic>?;
      final cartItemId = cartItem?['id']?.toString();
      if (cartItemId == null || cartItemId.isEmpty) {
        throw Exception('cart_item.id missing');
      }

      await ApiServices.updateReservationItemStatus(
        cartItemId: cartItemId,
        status: 'REJECT',
        reason: reason,
      );
    } catch (e) {
      if (kDebugMode) print('rejectReservation error: $e');
    }
  }
}

class ApprovalDialog extends StatefulWidget {
  final Map<String, dynamic> reservation;
  final Future<void> Function(
    String trackingNumber,
    List<File> images,
    String shippedBy,
    DateTime deliveryDate,
  )
  onApprove;

  const ApprovalDialog({
    required this.reservation,
    required this.onApprove,
    super.key,
  });

  @override
  State<ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ShipmentDetailsDialog extends StatefulWidget {
  final String trackingNumber;
  final List<String> imageUrls;

  const _ShipmentDetailsDialog({
    required this.trackingNumber,
    required this.imageUrls,
  });

  @override
  State<_ShipmentDetailsDialog> createState() => _ShipmentDetailsDialogState();
}

class _ShipmentDetailsDialogState extends State<_ShipmentDetailsDialog> {
  final Set<String> _completedUrls = <String>{};

  void _markCompleted(String url) {
    if (_completedUrls.contains(url)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_completedUrls.contains(url)) return;
      setState(() {
        _completedUrls.add(url);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.imageUrls.length;
    final loaded = _completedUrls.length;
    final stillLoading = total > 0 && loaded < total;

    return AlertDialog(
      title: const Text('รายละเอียดการส่ง'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'เลขติดตามพัสดุ:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(widget.trackingNumber),
            const SizedBox(height: 16),
            const Text(
              'รูปพัสดุ:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (widget.imageUrls.isEmpty)
              const Text('ไม่มีรูปพัสดุ')
            else ...[
              if (stillLoading) ...[
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text('กำลังโหลดรูป... ($loaded/$total)')),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: total == 0 ? null : loaded / total,
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.imageUrls
                    .map((imageUrl) {
                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              insetPadding: const EdgeInsets.all(16),
                              child: InteractiveViewer(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: _LoadingNetworkImage(
                                    url: imageUrl,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 140,
                            height: 140,
                            child: _LoadingNetworkImage(
                              url: imageUrl,
                              fit: BoxFit.cover,
                              onCompleted: () => _markCompleted(imageUrl),
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ปิด'),
        ),
      ],
    );
  }
}

class _LoadingNetworkImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final VoidCallback? onCompleted;

  const _LoadingNetworkImage({
    required this.url,
    required this.fit,
    this.onCompleted,
  });

  @override
  State<_LoadingNetworkImage> createState() => _LoadingNetworkImageState();
}

class _LoadingNetworkImageState extends State<_LoadingNetworkImage> {
  bool _reported = false;

  void _reportCompleted() {
    if (_reported) return;
    _reported = true;
    widget.onCompleted?.call();
  }

  Widget _placeholder({double? progressValue}) {
    return Container(
      color: Colors.grey[100],
      child: Center(child: CircularProgressIndicator(value: progressValue)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(
      widget.url,
      fit: widget.fit,
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        final value = progress.expectedTotalBytes == null
            ? null
            : progress.cumulativeBytesLoaded / progress.expectedTotalBytes!;
        return _placeholder(progressValue: value);
      },
      frameBuilder: (ctx, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          _reportCompleted();
          return child;
        }
        if (frame == null) {
          return _placeholder();
        }
        _reportCompleted();
        return child;
      },
      errorBuilder: (_, __, ___) {
        _reportCompleted();
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        );
      },
    );
  }
}

class _ApprovalDialogState extends State<ApprovalDialog> {
  final TextEditingController _trackingController = TextEditingController();
  List<File> _images = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isPickingImage = false;
  bool _isUploading = false;
  String? _selectedShippingMethod;
  DateTime? _deliveryDate;
  TimeOfDay? _deliveryTime;

  final List<String> _shippingMethods = [
    'Kerry Express',
    'Flash Express',
    'J&T Express',
    'Thailand Post (ไปรษณีย์ไทย)',
    'SCG Express',
    'Ninja Van',
    'Best Express',
    'DHL Express',
    'Lalamove',
    'จัดส่งเอง',
    'ลูกค้ามารับเอง',
  ];

  @override
  void initState() {
    super.initState();
    if (kDebugMode) print('[Approval] Dialog state initialized');
  }

  @override
  void dispose() {
    if (kDebugMode) print('[Approval] Dialog state disposing');
    _trackingController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_isPickingImage) {
      if (kDebugMode) print('[Approval] Already picking images, ignoring call');
      return;
    }

    if (kDebugMode) print('[Approval] Starting image picker...');

    try {
      if (mounted) {
        setState(() => _isPickingImage = true);
      }

      if (kDebugMode) print('[Approval] Calling pickMultiImage');
      final pickedFiles = await _imagePicker.pickMultiImage(
        requestFullMetadata: false,
      );

      if (kDebugMode) print('[Approval] Picked ${pickedFiles.length} images');

      if (!mounted) {
        if (kDebugMode) print('[Approval] Widget not mounted after pick');
        return;
      }

      if (pickedFiles.isNotEmpty) {
        if (kDebugMode) print('[Approval] Processing picked files');

        final filesToAdd = <File>[];
        for (var i = 0; i < pickedFiles.length; i++) {
          final file = File(pickedFiles[i].path);
          final exists = await file.exists();

          if (kDebugMode) {
            print(
              '[Approval] Image $i: ${pickedFiles[i].path}, exists: $exists',
            );
          }

          if (exists) {
            filesToAdd.add(file);
          } else {
            if (kDebugMode)
              print(
                '[Approval] Warning: Image $i does not exist at ${pickedFiles[i].path}',
              );
          }
        }

        if (filesToAdd.isNotEmpty && mounted) {
          if (kDebugMode)
            print(
              '[Approval] Adding ${filesToAdd.length} valid images to state',
            );
          setState(() {
            _images.addAll(filesToAdd);
          });
          if (kDebugMode)
            print('[Approval] Total images now: ${_images.length}');
        }
      } else {
        if (kDebugMode) print('[Approval] No images selected');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[Approval] Error picking images: $e');
        print('[Approval] Stack trace: $stackTrace');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเลือกรูปได้: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        if (kDebugMode) print('[Approval] Setting _isPickingImage to false');
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _pickFromCamera() async {
    if (_isPickingImage) {
      if (kDebugMode) print('[Approval] Already picking, ignoring camera call');
      return;
    }

    if (kDebugMode) print('[Approval] Starting camera picker...');

    try {
      if (mounted) {
        setState(() => _isPickingImage = true);
      }

      if (kDebugMode) print('[Approval] Calling pickImage from camera');
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        requestFullMetadata: false,
      );

      if (kDebugMode)
        print('[Approval] Camera pick result: ${pickedFile?.path ?? "null"}');

      if (!mounted) {
        if (kDebugMode)
          print('[Approval] Widget not mounted after camera pick');
        return;
      }

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final exists = await file.exists();

        if (kDebugMode) {
          print('[Approval] Camera image: ${pickedFile.path}, exists: $exists');
        }

        if (exists && mounted) {
          if (kDebugMode) print('[Approval] Adding camera image to state');
          setState(() {
            _images.add(file);
          });
          if (kDebugMode)
            print('[Approval] Total images now: ${_images.length}');
        } else {
          if (kDebugMode)
            print(
              '[Approval] Warning: Camera image does not exist at ${pickedFile.path}',
            );
        }
      } else {
        if (kDebugMode) print('[Approval] Camera pick cancelled');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[Approval] Error picking from camera: $e');
        print('[Approval] Stack trace: $stackTrace');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถถ่ายรูปได้: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        if (kDebugMode) print('[Approval] Setting _isPickingImage to false');
        setState(() => _isPickingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode)
      print(
        '[Approval] Building dialog, picking=$_isPickingImage, uploading=$_isUploading, images=${_images.length}',
      );

    final screenSize = MediaQuery.of(context).size;
    final dialogHeight = screenSize.height * 0.9;
    final dialogWidth = screenSize.width < 520 ? screenSize.width : 520.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            // Title
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'อนุมัติการจอง',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_isPickingImage || _isUploading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'วันที่ส่ง:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final now = DateTime.now();
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _deliveryDate ?? now,
                              firstDate: DateTime(now.year - 1),
                              lastDate: DateTime(now.year + 2),
                            );
                            if (pickedDate != null) {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: _deliveryTime ?? TimeOfDay.now(),
                              );
                              if (pickedTime != null && mounted) {
                                setState(() {
                                  _deliveryDate = pickedDate;
                                  _deliveryTime = pickedTime;
                                });
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('กรุณาเลือกเวลาส่ง'),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.event),
                          label: Text(
                            (_deliveryDate == null || _deliveryTime == null)
                                ? 'เลือกวันที่/เวลาส่ง'
                                : FormatHelper.formatDateTime(
                                    DateTime(
                                      _deliveryDate!.year,
                                      _deliveryDate!.month,
                                      _deliveryDate!.day,
                                      _deliveryTime!.hour,
                                      _deliveryTime!.minute,
                                    ).toIso8601String(),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'จัดส่งโดย:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      hintText: 'เลือกวิธีการจัดส่ง...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _shippingMethods.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedShippingMethod = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'เลขติดตามพัสดุ:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _trackingController,
                    decoration: InputDecoration(
                      hintText: 'กรอกเลขติดตาม...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'รูปพัสดุ:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_isPickingImage)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('กำลังเลือกรูป...')),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.image),
                            label: const Text('เลือกรูป'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickFromCamera,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('ถ่ายรูป'),
                          ),
                        ),
                      ],
                    ),
                  if (_images.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'เลือกรูปแล้ว ${_images.length} รูป',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _images.clear();
                              });
                            },
                            child: const Text('ลบทั้งหมด'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: (_isPickingImage || _isUploading)
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('ยกเลิก'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: (_isPickingImage || _isUploading)
                        ? null
                        : () async {
                            if (_deliveryDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('กรุณาเลือกวันที่ส่ง'),
                                ),
                              );
                              return;
                            }
                            if (_deliveryTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('กรุณาเลือกเวลาส่ง'),
                                ),
                              );
                              return;
                            }
                            if (_selectedShippingMethod == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('กรุณาเลือกวิธีการจัดส่ง'),
                                ),
                              );
                              return;
                            }
                            if (_trackingController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('กรุณากรอกเลขติดตามพัสดุ'),
                                ),
                              );
                              return;
                            }
                            if (_images.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'กรุณาอัพโหลดรูปพัสดุอย่างน้อย 1 รูป',
                                  ),
                                ),
                              );
                              return;
                            }

                            setState(() => _isUploading = true);
                            try {
                              final combinedDeliveryDateTime = DateTime(
                                _deliveryDate!.year,
                                _deliveryDate!.month,
                                _deliveryDate!.day,
                                _deliveryTime!.hour,
                                _deliveryTime!.minute,
                              );
                              await widget.onApprove(
                                _trackingController.text,
                                _images,
                                _selectedShippingMethod!,
                                combinedDeliveryDateTime,
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _isUploading = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: _isPickingImage || _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('อนุมัติ'),
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
