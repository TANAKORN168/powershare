import 'package:flutter/material.dart';
import 'package:powershare/services/apiServices.dart';
import 'package:powershare/services/session.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await ApiServices.getCategories();
      setState(() => _categories = list.map((e) => Map<String, dynamic>.from(e)).toList());
    } catch (e) {
      setState(() => _error = 'ไม่สามารถโหลดหมวดหมู่ได้: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<bool?> _confirmDelete(BuildContext ctx, String name) {
    return showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('ลบหมวดหมู่'),
        content: Text('ต้องการลบหมวดหมู่ "$name" ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('ลบ')),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _showAddEditDialog({Map<String, dynamic>? category, int? index}) {
    final _formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: category != null ? (category['name'] ?? '') : '');
    final descCtrl = TextEditingController(text: category != null ? (category['description'] ?? '') : '');
    bool isActiveLocal = (category != null) ? (category['is_active'] == true) : true;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext sbCtx, StateSetter setState) {
          return AlertDialog(
            title: Text(category != null ? 'แก้ไขหมวดหมู่' : 'เพิ่มหมวดหมู่'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'ชื่อหมวดหมู่'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณาใส่ชื่อหมวดหมู่' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'คำอธิบาย (ไม่บังคับ)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('ใช้งาน'),
                    value: isActiveLocal,
                    onChanged: (v) {
                      setState(() => isActiveLocal = v ?? true);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('ยกเลิก')),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.of(dialogContext).pop(); // ปิด dialog ก่อนทำงานเครือข่าย

                  final user = Session.instance.user;
                  final userId = user != null ? (user['id'] ?? user['user_id'] ?? user['uid']) : null;

                  try {
                    if (category != null && category['id'] != null) {
                      // update
                      await ApiServices.updateCategory(
                        category['id'].toString(),
                        name: controller.text.trim(),
                        description: descCtrl.text.trim(),
                        isActive: isActiveLocal,
                        userUpdates: userId?.toString(),
                      );
                      // รีโหลดรายการจาก server เพื่อให้ UI แสดงสถานะล่าสุดแน่นอน
                      await _loadCategories();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('แก้ไขหมวดหมู่เรียบร้อย')));
                    } else {
                      // create
                      await ApiServices.createCategory(
                        name: controller.text.trim(),
                        description: descCtrl.text.trim(),
                        isActive: isActiveLocal,
                        userCreated: userId?.toString(),
                      );
                      // รีโหลดรายการ
                      await _loadCategories();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เพิ่มหมวดหมู่เรียบร้อย')));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
                  }
                },
                child: const Text('บันทึก'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('หมวดหมู่สินค้า'),
        backgroundColor: const Color(0xFF3ABDC5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      body: Builder(builder: (ctx) {
        if (_loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _loadCategories, child: const Text('ลองใหม่')),
              ],
            ),
          );
        }
        if (_categories.isEmpty) {
          return const Center(child: Text('ยังไม่มีหมวดหมู่'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final c = _categories[i];
            return Dismissible(
              key: ValueKey(c['id'] ?? '$i'),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                final confirmed = await _confirmDelete(ctx, (c['name'] ?? '').toString());
                if (confirmed == true) {
                  try {
                    final id = c['id']?.toString();
                    if (id != null && id.isNotEmpty) {
                      final ok = await ApiServices.deleteCategory(id);
                      if (!ok) throw Exception('ลบไม่สำเร็จ');
                    }
                    setState(() => _categories.removeAt(i));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ลบหมวดหมู่ "${c['name']}" แล้ว')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e')));
                    return false;
                  }
                }
                return confirmed;
              },
              child: Card(
                child: ListTile(
                  title: Text(c['name'] ?? ''),
                  subtitle: Builder(builder: (_) {
                    final desc = (c['description'] ?? '').toString();
                    final rawActive = c['is_active'];
                    final isActive = rawActive == true ||
                        rawActive == 1 ||
                        (rawActive != null && rawActive.toString().toLowerCase() == 'true');
                    final statusText = isActive ? 'ใช้งาน' : 'ไม่ใช้งาน';
                    final statusColor = isActive ? Colors.green : Colors.red;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (desc.isNotEmpty) Text(desc),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  }),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF3ABDC5)),
                    onPressed: () async {
                      await _showAddEditDialog(category: c, index: i);
                    },
                  ),
                  onTap: () async {
                    await _showAddEditDialog(category: c, index: i);
                  },
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _showAddEditDialog();
        },
        label: const Text('เพิ่มหมวดหมู่'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF3ABDC5),
      ),
    );
  }
}