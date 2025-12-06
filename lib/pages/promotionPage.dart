import 'package:flutter/material.dart';
// import 'package:powershare/pages/PromotionPage.dart';
import 'package:powershare/services/apiServices.dart';
import 'package:powershare/services/session.dart';

class PromotionPage extends StatefulWidget {
  const PromotionPage({super.key});

  @override
  State<PromotionPage> createState() => _PromotionPageState();
}

class _PromotionPageState extends State<PromotionPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiServices.getPromotions();
      _items = data.map((e) => Map<String, dynamic>.from(e)).toList();
      // เรียงลำดับตามฟิลด์ order (น้อยแสดงก่อน) แล้ว fallback เป็น created_at desc
      _items.sort((a, b) {
        final ao = int.tryParse((a['order']?.toString() ?? '999')) ?? 999;
        final bo = int.tryParse((b['order']?.toString() ?? '999')) ?? 999;
        if (ao != bo) return ao.compareTo(bo);
        final aCreated = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bCreated = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bCreated.compareTo(aCreated);
      });
    } catch (e) {
      _error = 'โหลดไม่สำเร็จ: $e';
      _items = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool?> _confirmDelete(BuildContext ctx, String text) {
    return showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('ลบข้อความโปรโมชั่น'),
        content: Text('ต้องการลบข้อความนี้?\n"$text"'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('ลบ')),
        ],
      ),
    );
  }

  Future<void> _showAddEdit({Map<String, dynamic>? item, int? index}) {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController(text: item != null ? (item['text'] ?? '') : '');
    bool isActive = item != null ? (item['is_active'] == true) : true;
    final orderCtrl = TextEditingController(text: item != null ? (item['order']?.toString() ?? '') : '');

    return showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setState) => AlertDialog(
          title: Text(item != null ? 'แก้ไขข้อความโปรโมชั่น' : 'เพิ่มข้อความโปรโมชั่น'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: ctrl,
                  decoration: const InputDecoration(labelText: 'ข้อความ (จะแสดงหน้าหลัก)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณาใส่ข้อความ' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: orderCtrl,
                  decoration: const InputDecoration(labelText: 'ลำดับ (ตัวเลข, ยิ่งน้อยแสดงก่อน)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('เปิดใช้งาน'),
                  value: isActive,
                  onChanged: (v) => setState(() => isActive = v ?? true),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(ctx).pop();
                try {
                  final user = Session.instance.user;
                  final uid = user != null ? (user['id']?.toString()) : null;
                  if (item != null && item['id'] != null) {
                    await ApiServices.updatePromotion(
                      item['id'].toString(),
                      text: ctrl.text.trim(),
                      isActive: isActive,
                      order: int.tryParse(orderCtrl.text.trim()),
                      userUpdates: uid,
                    );
                  } else {
                    await ApiServices.createPromotion(
                      text: ctrl.text.trim(),
                      isActive: isActive,
                      order: int.tryParse(orderCtrl.text.trim()) ?? 999,
                      userCreated: uid,
                    );
                  }
                  await _load();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกเรียบร้อย')));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ผิดพลาด: $e')));
                }
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อความโปรโมชั่น'),
        backgroundColor: const Color(0xFF3ABDC5),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'รีโหลด',
            onPressed: _load,
          ),
        ],
      ),
      body: Builder(builder: (ctx) {
        if (_loading) return const Center(child: CircularProgressIndicator());
        if (_error != null) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('ลองใหม่')),
            ]),
          );
        }
        if (_items.isEmpty) return const Center(child: Text('ยังไม่มีข้อความโปรโมชั่น'));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (c, i) {
            final it = _items[i];
            final text = it['text']?.toString() ?? '';
            final isActive = it['is_active'] == true;
            return Dismissible(
              key: ValueKey(it['id'] ?? '$i'),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                final confirmed = await _confirmDelete(ctx, text);
                if (confirmed != true) return false;
                try {
                  final id = it['id']?.toString();
                  final user = Session.instance.user;
                  final uid = user != null ? (user['id']?.toString()) : null;
                  if (id != null) {
                    final ok = await ApiServices.deletePromotion(id, userUpdates: uid);
                    if (!ok) throw Exception('ไม่สามารถลบจาก server');
                  }
                  setState(() => _items.removeAt(i));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบเรียบร้อย')));
                  return true;
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ผิดพลาด: $e')));
                  return false;
                }
              },
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // แถวที่ 1: เลขลำดับ
                      Text(
                        'ลำดับ ${it['order']?.toString() ?? '-'}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 6),
                      // แถวที่ 2: ข้อความโปรโมชั่น
                      Text(
                        text,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // แถวที่ 3: สถานะ และปุ่มแก้ไข (จัดชิดขวา)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isActive ? 'ใช้งาน' : 'ไม่ใช้งาน',
                              style: TextStyle(
                                color: isActive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF3ABDC5)),
                            onPressed: () => _showAddEdit(item: it, index: i),
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
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEdit(),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มข้อความ'),
        backgroundColor: const Color(0xFF3ABDC5),
      ),
    );
  }
}