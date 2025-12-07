import 'package:flutter/material.dart';
import 'package:powershare/services/session.dart';
import 'addEditProductPage.dart';
import 'package:powershare/services/apiServices.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  // products from Supabase
  List<Map<String, dynamic>> _products = [];
  bool _loadingProducts = true;
  String? _productsError;

  // categories from Supabase
  List<Map<String, dynamic>> _categories = [];
  Map<String, String> _categoryMap = {};
  bool _loadingCategories = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();

    ApiServices.listBuckets().then((b) => debugPrint('Supabase buckets: $b')).catchError((e) => debugPrint('listBuckets error: $e'));
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loadingProducts = true;
      _productsError = null;
    });

    try {
      final list = await ApiServices.getProducts(); // ensure this method exists in ApiServices
      _products = list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _products = [];
      _productsError = 'ไม่สามารถโหลดสินค้าได้: $e';
    } finally {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final list = await ApiServices.getCategories();
      _categories = list.map((e) => Map<String, dynamic>.from(e)).toList();
      _categoryMap = {
        for (final c in _categories) (c['id']?.toString() ?? ''): (c['name']?.toString() ?? '')
      };
    } catch (e) {
      // ignore errors for now or show a snackbar if desired
      _categories = [];
      _categoryMap = {};
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _openAddEdit([Map<String, dynamic>? product, int? index]) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>?>(
      MaterialPageRoute(
        builder: (_) => AddEditProductPage(product: product),
      ),
    );

    if (result == null) return;

    setState(() {
      if (index != null) {
        // update
        _products[index] = result;
      } else {
        // add (generate id)
        result['id'] = 'p${DateTime.now().millisecondsSinceEpoch}';
        _products.insert(0, result);
      }
    });
  }

  Future<bool?> _confirmDelete(BuildContext ctx, String name) {
    return showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('ลบสินค้า'),
        content: Text('ต้องการลบ "$name" ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('ลบ')),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String? categoryId) {
    final id = categoryId?.toString() ?? '';
    final name = _categoryMap[id] ?? '-';
    if (name == '-') {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(name, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อมูลสินค้าให้เช่า'),
        backgroundColor: const Color(0xFF3ABDC5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
            tooltip: 'รีโหลดหมวดหมู่',
          ),
        ],
      ),
      body: Builder(builder: (ctx) {
        if (_loadingProducts) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_productsError != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_productsError!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _loadProducts, child: const Text('ลองใหม่')),
              ],
            ),
          );
        }
        if (_products.isEmpty) {
          return const Center(child: Text('ยังไม่มีสินค้า'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: _products.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final p = _products[i];
            final categoryId = p['category_id']?.toString();
            final categoryName = (categoryId != null && categoryId.isNotEmpty) ? (_categoryMap[categoryId] ?? '-') : null;

            return Dismissible(
              key: ValueKey(p['id']),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                final confirmed = await _confirmDelete(ctx, p['name'] ?? '');
                if (confirmed != true) return false;

                final id = p['id']?.toString();
                try {
                  // ส่ง user id ถ้ามี
                  final user = Session.instance.user;
                  final userId = user != null ? (user['id'] ?? user['user_id'] ?? user['uid']) : null;
                  final ok = (id != null && id.isNotEmpty)
                      ? await ApiServices.deleteProduct(id, userUpdates: userId?.toString())
                      : false;

                  if (!ok) throw Exception('ลบไม่สำเร็จ (server)');

                  setState(() => _products.removeAt(i));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ลบสินค้า "${p['name']}" แล้ว')),
                  );
                  return true;
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ลบไม่สำเร็จ: $e')),
                  );
                  return false;
                }
              },
              child: Card(
                child: ListTile(
                  leading: SizedBox(
                    width: 64,
                    height: 64,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        p['image'] ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                  ),
                  title: Text(p['name'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if ((p['subtitle'] ?? '').toString().isNotEmpty)
                        Text(
                          p['subtitle']?.toString() ?? '',
                          style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black87),
                        ),
                      if ((p['description'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          p['description'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                      ],
                      const SizedBox(height: 6),
                      if (_loadingCategories)
                        const Text('กำลังโหลดหมวดหมู่...', style: TextStyle(fontSize: 12, color: Colors.grey))
                      else if (categoryName != null && categoryName != '-')
                        _buildCategoryChip(categoryId)
                      else
                        const Text('หมวดหมู่: ไม่ระบุ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF3ABDC5)),
                    onPressed: () => _openAddEdit(p, i),
                  ),
                  onTap: () => _openAddEdit(p, i),
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEdit(),
        label: const Text('เพิ่มสินค้า'),
        icon: const Icon(Icons.add_box),
        backgroundColor: const Color(0xFF3ABDC5),
        foregroundColor: Colors.white,
      ),
    );
  }
}