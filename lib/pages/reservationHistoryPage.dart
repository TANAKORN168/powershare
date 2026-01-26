import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:powershare/services/apiServices.dart';
import 'package:powershare/helps/formatHelper.dart';

class ReservationHistoryPage extends StatefulWidget {
  final String? userId;

  const ReservationHistoryPage({this.userId, super.key});

  @override
  State<ReservationHistoryPage> createState() => _ReservationHistoryPageState();
}

class _ReservationHistoryPageState extends State<ReservationHistoryPage> {
  List<Map<String, dynamic>> reservations = [];
  bool _loading = true;
  String _selectedStatus = 'All';

  List<String> get _statusFilters {
    return [
      'All',
      'RESERVED',
      'Confirmed',
      'Shipped',
      'Completed',
      'Cancelled',
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() => _loading = true);
    try {
      final res = await ApiServices.getUserReservations(userId: widget.userId);
      if (mounted) {
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

  List<Map<String, dynamic>> _getFilteredReservations() {
    if (_selectedStatus == 'All') {
      return reservations;
    }
    return reservations
        .where((r) => r['status']?.toString() == _selectedStatus)
        .toList();
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'RESERVED':
        return 'รอการอนุมัติ';
      case 'Confirmed':
        return 'อนุมัติแล้ว';
      case 'Shipped':
        return 'กำลังส่ง';
      case 'Completed':
        return 'เสร็จสิ้น';
      case 'Cancelled':
        return 'ยกเลิก';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'RESERVED':
        return Colors.orange;
      case 'Confirmed':
        return Colors.blue;
      case 'Shipped':
        return Colors.purple;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredReservations();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการจอง'),
        backgroundColor: const Color(0xFF3ABDC5),
      ),
      body: Column(
        children: [
          // ตัวกรองสถานะ
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: _statusFilters.map((status) {
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      status == 'All' ? 'ทั้งหมด' : _getStatusLabel(status),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = status;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF3ABDC5),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF3ABDC5) : Colors.grey,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // รายการจอง
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'ไม่มีการจอง',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadReservations,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (context, index) {
                        final reservation = filtered[index];
                        return _buildReservationCard(reservation);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> reservation) {
    // ดึงข้อมูลจาก carts table
    final cartItems = reservation['cart_items'] as List? ?? [];
    final status = reservation['status']?.toString() ?? 'Unknown';
    final createdDate = reservation['created_at']?.toString() ?? '-';

    // ดึงสินค้าจากรายการแรกใน cart_items
    Map<String, dynamic>? firstItem;
    if (cartItems.isNotEmpty) {
      firstItem = cartItems[0] as Map<String, dynamic>;
    }

    final productMap = firstItem?['products'] as Map<String, dynamic>?;
    final productName = productMap?['name']?.toString() ?? 'สินค้า';
    final deliveryDate = firstItem?['delivery_date']?.toString() ?? '-';
    final returnDate = firstItem?['return_date']?.toString() ?? '-';
    final trackingNumber = reservation['tracking_number']?.toString();
    final shipmentImages = reservation['shipment_images'] as List? ?? [];

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
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'สถานะ: ${_getStatusLabel(status)}',
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                            ),
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
                        color: _getStatusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _getStatusColor(status)),
                      ),
                      child: Text(
                        _getStatusLabel(status),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getStatusColor(status),
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
                      _buildInfoRow(
                        'วันส่ง:',
                        FormatHelper.formatDateTime(deliveryDate),
                      ),
                      _buildInfoRow(
                        'วันคืน:',
                        FormatHelper.formatDateTime(returnDate),
                      ),
                      if (trackingNumber != null)
                        _buildInfoRow('เลขติดตาม:', trackingNumber),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // แสดงรูปพัสดุถ้ามีการส่งแล้ว
          if (shipmentImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'รูปพัสดุ:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: shipmentImages.length,
                    itemBuilder: (context, index) {
                      final imageUrl = shipmentImages[index].toString();
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          if (status == 'RENTED' || status == 'Returned')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showTrackingDialog(context, reservation);
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
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  void _showTrackingDialog(
    BuildContext context,
    Map<String, dynamic> reservation,
  ) {
    final trackingNumber = reservation['tracking_number']?.toString() ?? '-';
    final images = reservation['shipment_images'] as List? ?? [];

    final imageUrls = images
        .map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    showDialog(
      context: context,
      builder: (context) => _TrackingDetailsDialog(
        trackingNumber: trackingNumber,
        imageUrls: imageUrls,
      ),
    );
  }
}

class _TrackingDetailsDialog extends StatefulWidget {
  final String trackingNumber;
  final List<String> imageUrls;

  const _TrackingDetailsDialog({
    required this.trackingNumber,
    required this.imageUrls,
  });

  @override
  State<_TrackingDetailsDialog> createState() => _TrackingDetailsDialogState();
}

class _TrackingDetailsDialogState extends State<_TrackingDetailsDialog> {
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
            SelectableText(
              widget.trackingNumber,
              style: const TextStyle(fontSize: 14),
            ),
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
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: widget.imageUrls.length,
                itemBuilder: (context, index) {
                  final imageUrl = widget.imageUrls[index];
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
                      child: _LoadingNetworkImage(
                        url: imageUrl,
                        fit: BoxFit.cover,
                        onCompleted: () => _markCompleted(imageUrl),
                      ),
                    ),
                  );
                },
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
