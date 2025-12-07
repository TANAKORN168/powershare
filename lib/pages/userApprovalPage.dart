// filepath: d:\Projects\powershare\lib\pages\userApprovalPage.dart
import 'package:flutter/material.dart';
import 'package:powershare/services/apiServices.dart';
import 'userApprovalDetailPage.dart';

// (เดิมมี mock data ที่นี่ ถูกลบออกเพื่อใช้ข้อมูลจริงจาก ApiServices.getPendingUsers)

class UserApprovalPage extends StatefulWidget {
  const UserApprovalPage({super.key});

  @override
  State<UserApprovalPage> createState() => _UserApprovalPageState();
}

class _UserApprovalPageState extends State<UserApprovalPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _pendingUsers = [];

  @override
  void initState() {
    super.initState();
    _loadPendingUsers();
  }

  Future<void> _loadPendingUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // เรียก API ที่ดึงข้อมูลผู้ใช้ที่ยังไม่ได้อนุมัติจากตาราง users (is_approve = false)
      final users = await ApiServices.getPendingUsers();
      setState(() {
        _pendingUsers = (users ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (e) {
      setState(() {
        _error = 'ไม่สามารถโหลดข้อมูลได้: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onDetailResult(int index, bool approved) {
    // ลบรายการออกจากลิสต์เมื่ออนุมัติหรือปฏิเสธ
    setState(() {
      _pendingUsers.removeAt(index);
    });

    // แสดง SnackBar แจ้งผลลัพธ์
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(approved ? 'อนุมัติผู้ใช้เรียบร้อย' : 'ปฏิเสธผู้ใช้เรียบร้อย'),
        backgroundColor: approved ? Colors.green : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ยืนยันผู้ใช้ขอเข้าใช้งานระบบ'),
        backgroundColor: const Color(0xFF3ABDC5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingUsers,
          )
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3ABDC5)),
              ),
            )
          : _error != null
              ? Center(child: Text(_error!))
              : _pendingUsers.isEmpty
                  ? const Center(child: Text('ไม่มีคำขอที่รอการยืนยัน'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _pendingUsers.length,
                      itemBuilder: (ctx, i) {
                        final u = _pendingUsers[i];
                        final name = (u['name'] as String?) ?? (u['fullName'] as String?) ?? 'ไม่มีชื่อ';
                        final email = (u['email'] as String?) ?? '-';
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF3ABDC5),
                              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                            ),
                            title: Text(name),
                            subtitle: Text(email),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () async {
                              final result = await Navigator.of(context).push<bool?>(
                                MaterialPageRoute(
                                  builder: (_) => UserApprovalDetailPage(user: Map<String, dynamic>.from(u)),
                                ),
                              );
                              if (result == true) {
                                _onDetailResult(i, true);
                              } else if (result == false) {
                                _onDetailResult(i, false);
                              }
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
