import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ เพิ่มบรรทัดนี้
import 'package:powershare/services/apiServices.dart';
import 'package:powershare/services/session.dart';

class UserApprovalDetailPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const UserApprovalDetailPage({super.key, required this.user});

  @override
  State<UserApprovalDetailPage> createState() => _UserApprovalDetailPageState();
}

class _UserApprovalDetailPageState extends State<UserApprovalDetailPage> {
  bool _processing = false;
  late String _selectedRole;
  late bool _currentIsAdmin;

  String? _idCardUrl() {
    return (widget.user['id_card_image_path'] as String?) ??
        (widget.user['idCardUrl'] as String?) ??
        (widget.user['id_card_image'] as String?);
  }

  String? _selfieUrl() {
    return (widget.user['face_image_path'] as String?) ??
        (widget.user['selfieUrl'] as String?) ??
        (widget.user['selfie_image'] as String?);
  }

  @override
  void initState() {
    super.initState();
    _selectedRole = ((widget.user['role'] as String?) ?? 'USER').toUpperCase();
    final currentUser = Session.instance.user;
    _currentIsAdmin =
        (currentUser != null &&
        ((currentUser['role'] as String?) ?? '').toLowerCase() == 'admin');
  }

  Future<void> _approve(bool approve) async {
    setState(() => _processing = true);
    try {
      final userId = widget.user['id']?.toString();
      if (kDebugMode) {
        print('🔴 Approve/Reject - approve: $approve');
        print('🔴 userId: $userId');
        print('🔴 User data: ${widget.user}');
      }
      
      if (userId == null || userId.isEmpty) {
        throw Exception('User ID is null or empty');
      }

      // ถ้าปฏิเสธ ให้เรียก rejectUser แทน
      if (!approve) {
        await ApiServices.rejectUser(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ปฏิเสธผู้ใช้เรียบร้อย'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop(false);
        return;
      }

      // อัปเดต role ของ user ใน object ปัจจุบัน
      widget.user['role'] = _selectedRole.toLowerCase();

      // เรียก API จริง (สำหรับอนุมัติ)
      final success = await ApiServices.setUserApproval(
        userId,
        approve: approve,
        role: _selectedRole.toLowerCase(),
      );

      if (!success) {
        throw Exception('Update failed');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อนุมัติผู้ใช้เรียบร้อย'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (kDebugMode) {
        print('🔴 Error in _approve: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Widget _buildImage(String? url, String label) {
    if (url == null || url.isEmpty) {
      return Column(
        children: [
          const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
          const SizedBox(height: 8),
          Text('ไม่มี $label'),
        ],
      );
    }

    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (ctx, _, __) => Column(
              children: const [
                Icon(Icons.broken_image, size: 64, color: Colors.grey),
                SizedBox(height: 8),
                Text('ไม่สามารถโหลดรูปได้'),
              ],
            ),
            loadingBuilder: (ctx, child, loadingProgress) {
              if (loadingProgress == null) return child;
              final expected = loadingProgress.expectedTotalBytes;
              final loaded = loadingProgress.cumulativeBytesLoaded;
              final value = (expected != null && expected > 0)
                  ? (loaded / expected)
                  : null;
              return SizedBox(
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(
                    value: value,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF3ABDC5),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    // แสดงชื่อประกอบด้วย name + surname (fallback ไป fullName หรือ 'ไม่มีชื่อ')
    final firstName = (u['name'] as String?) ?? '';
    final surname =
        (u['surname'] as String?) ??
        (u['lastname'] as String?) ??
        (u['family_name'] as String?) ??
        '';
    final fullFromParts = (firstName + ' ' + surname).trim();
    final name = fullFromParts.isNotEmpty
        ? fullFromParts
        : ((u['fullName'] as String?) ?? 'ไม่มีชื่อ');
    final email = (u['email'] as String?) ?? '-';
    final phone =
        (u['phone_number'] as String?) ?? (u['tel'] as String?) ?? '-';

    // กำหนดตัวเลือก role ตามสิทธิ์ผู้ใช้งานปัจจุบัน
    final List<String> roleItems = _currentIsAdmin
        ? ['USER', 'ADMIN']
        : [_selectedRole];

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดคำขอผู้ใช้'),
        backgroundColor: const Color(0xFF3ABDC5),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              child: ListTile(
                // ชื่อเป็นตัวหนา (ไม่มี CircleAvatar)
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                isThreeLine: true,
                subtitle: Builder(
                  builder: (context) {
                    final addr =
                        (u['address'] as String?) ??
                        (u['addr'] as String?) ??
                        '';
                    final subdistrict =
                        (u['subdistrict'] as String?) ??
                        (u['subdistrictName'] as String?) ??
                        (u['subdistrict_name'] as String?) ??
                        '';
                    final district =
                        (u['district'] as String?) ??
                        (u['districtName'] as String?) ??
                        (u['district_name'] as String?) ??
                        '';
                    final province =
                        (u['province'] as String?) ??
                        (u['provinceName'] as String?) ??
                        (u['province_name'] as String?) ??
                        '';
                    final postcode =
                        (u['postal_code'] as String?) ??
                        (u['postalCode'] as String?) ??
                        (u['postcode'] as String?) ??
                        '';

                    final parts = <String>[];
                    if (addr.trim().isNotEmpty) parts.add(addr.trim());
                    if (subdistrict.trim().isNotEmpty)
                      parts.add(subdistrict.trim());
                    if (district.trim().isNotEmpty) parts.add(district.trim());
                    if (province.trim().isNotEmpty) parts.add(province.trim());
                    if (postcode.trim().isNotEmpty) parts.add(postcode.trim());

                    final addressString = parts.isNotEmpty
                        ? parts.join(', ')
                        : '-';
                    final idCard =
                        (u['id_card_number'] as String?) ??
                        (u['idCardNumber'] as String?) ??
                        (u['id_card_no'] as String?) ??
                        '-';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(email),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black,
                            ),
                            children: [
                              const TextSpan(
                                text: 'ที่อยู่: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: addressString),
                            ],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black,
                            ),
                            children: [
                              const TextSpan(
                                text: 'เลขที่บัตรประชาชน: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: idCard),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                trailing: Text(phone),
              ),
            ),
            const SizedBox(height: 12),

            // Role + action buttons grouped together
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        filled: true,
                        fillColor: const Color.fromARGB(255, 240, 240, 240),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: _currentIsAdmin
                            ? null
                            : 'เฉพาะผู้ดูแลระบบเท่านั้นที่สามารถตั้งเป็น ADMIN ได้',
                      ),
                      items: roleItems
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                      onChanged: _currentIsAdmin
                          ? (val) {
                              if (val == null) return;
                              setState(() => _selectedRole = val);
                            }
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _processing ? null : () => _approve(false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: _processing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('ปฏิเสธ'),
                        ),
                        ElevatedButton(
                          onPressed: _processing ? null : () => _approve(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3ABDC5),
                            foregroundColor: Colors.white,
                          ),
                          child: _processing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('อนุมัติ'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      'บัตรประชาชน',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildImage(_idCardUrl(), ''),
                    const SizedBox(height: 16),
                    Text(
                      'รูปถ่ายหน้าตัวเอง',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildImage(_selfieUrl(), ''),
                    const SizedBox(height: 24),
                    // (ปุ่มถูกย้ายขึ้นมาแล้ว)
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
