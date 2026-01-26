import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:powershare/pages/productDetailPage.dart';
import 'package:powershare/services/apiServices.dart';
import 'package:powershare/helps/formatHelper.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  bool _loadingCategories = true;
  bool _loadingProducts = true;

  String? _selectedCategoryId;
  bool _showOnlyAvailable = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final cats = await CategoryService.getCategories();
      if (mounted) {
        setState(() {
          categories = cats;
          _loadingCategories = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('loadCategories error: $e');
      if (mounted) {
        setState(() {
          categories = [];
          _loadingCategories = false;
        });
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);
    try {
      // ดึงสินค้าทุกสถานะ (ไม่กรอง onlyActive)
      final prods = await ApiServices.getProducts(onlyActive: false);
      if (mounted) {
        setState(() {
          products = prods;
          _filterProducts();
          _loadingProducts = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('loadProducts error: $e');
      if (mounted) {
        setState(() {
          products = [];
          filteredProducts = [];
          _loadingProducts = false;
        });
      }
    }
  }

  void _filterProducts() {
    List<Map<String, dynamic>> filtered = products;

    // กรองตามสถานะ (แสดงเฉพาะที่พร้อมให้เช่า)
    if (_showOnlyAvailable) {
      filtered = filtered.where((p) {
        final status = p['last_status']?.toString() ?? 'AVAILABLE';
        return status == 'AVAILABLE';
      }).toList();
    }

    // กรองตามหมวดหมู่
    if (_selectedCategoryId != null) {
      filtered = filtered.where((p) {
        return p['category_id']?.toString() == _selectedCategoryId;
      }).toList();
    }

    // กรองตามชื่อสินค้า
    final searchText = _searchController.text.trim().toLowerCase();
    if (searchText.isNotEmpty) {
      filtered = filtered.where((p) {
        final name = (p['name'] ?? p['title'] ?? '').toString().toLowerCase();
        return name.contains(searchText);
      }).toList();
    }

    setState(() {
      filteredProducts = filtered;
    });
  }

  void _onCategoryTap(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId == _selectedCategoryId
          ? null
          : categoryId;
      _filterProducts();
    });
  }

  void _onSearchChanged() {
    _filterProducts();
  }

  String _formatPrice(dynamic priceVal) {
    if (priceVal == null) return '฿0/วัน';

    double? value;
    if (priceVal is num) {
      value = priceVal.toDouble();
    } else {
      value = double.tryParse(priceVal.toString());
    }

    if (value == null) {
      final s = priceVal.toString();
      return s.isNotEmpty ? s : '฿0/วัน';
    }

    return '${FormatHelper.formatPrice(value)}/วัน';
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'AVAILABLE':
        return 'พร้อมให้เช่า';
      case 'RESERVED':
        return 'ถูกจอง';
      case 'RENTED':
        return 'ถูกเช่า';
      case 'Returned':
        return 'คืนแล้ว';
      case 'MAINTENANCE':
        return 'กำลังซ่อมบำรุง';
      case 'UNAVAILABLE':
        return 'ไม่พร้อมให้เช่า';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return Colors.green;
      case 'RESERVED':
        return Colors.blue;
      case 'RENTED':
        return Colors.orange;
      case 'Returned':
        return Colors.purple;
      case 'MAINTENANCE':
        return Colors.red;
      case 'UNAVAILABLE':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // หัวข้อและช่องค้นหา
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'สินค้าให้เช่า',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // ช่องค้นหา
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _onSearchChanged(),
                  decoration: InputDecoration(
                    hintText: 'ค้นหาสินค้า...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF3ABDC5),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3ABDC5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF3ABDC5),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // ตัวกรองแสดงเฉพาะสินค้าพร้อมให้เช่า
              Row(
                children: [
                  Checkbox(
                    value: _showOnlyAvailable,
                    onChanged: (value) {
                      setState(() {
                        _showOnlyAvailable = value ?? false;
                        _filterProducts();
                      });
                    },
                    activeColor: const Color(0xFF3ABDC5),
                  ),
                  const Text(
                    'แสดงเฉพาะสินค้าพร้อมให้เช่า',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),

        // รายการกลุ่มสินค้าแนวนอน
        if (_loadingCategories)
          const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (categories.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final category = categories[index];
                final categoryId = category['id']?.toString();
                final isSelected = _selectedCategoryId == categoryId;
                final imageUrl = category['image_url']?.toString() ?? '';

                return GestureDetector(
                  onTap: () => _onCategoryTap(categoryId),
                  child: Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF3ABDC5)
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: isSelected
                                ? const Color(0xFF3ABDC5).withValues(alpha: 0.1)
                                : Colors.grey[200],
                            child: imageUrl.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      imageUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.category,
                                        size: 24,
                                        color: Color(0xFF3ABDC5),
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.category,
                                    size: 24,
                                    color: Color(0xFF3ABDC5),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category['name']?.toString() ?? 'หมวดหมู่',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF3ABDC5)
                                : Colors.black,
                          ),
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

        const SizedBox(height: 4),

        // แถบหัวข้อรายการสินค้า
        Container(
          width: double.infinity,
          color: const Color(0xFF3ABDC5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              _selectedCategoryId != null || _searchController.text.isNotEmpty
                  ? 'ผลการค้นหา (${filteredProducts.length})'
                  : 'รายการสินค้าทั้งหมด (${filteredProducts.length})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // รายการสินค้า
        Expanded(
          child: _loadingProducts
              ? const Center(child: CircularProgressIndicator())
              : filteredProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'ไม่พบสินค้า',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      if (_selectedCategoryId != null ||
                          _searchController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedCategoryId = null;
                              _searchController.clear();
                              _filterProducts();
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('แสดงทั้งหมด'),
                        ),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  child: ListView.builder(
                    itemCount: filteredProducts.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final productId = product['id']?.toString();
                      final imageUrl =
                          product['image']?.toString() ??
                          product['image_url']?.toString() ??
                          '';
                      final priceVal =
                          product['price'] ?? product['rent_amount'] ?? 0;
                      final status =
                          product['last_status']?.toString() ?? 'AVAILABLE';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailPage(
                                  productId: productId,
                                  name:
                                      product['name']?.toString() ??
                                      product['title']?.toString() ??
                                      'สินค้า',
                                  image: imageUrl,
                                  description:
                                      product['description']?.toString() ?? '',
                                  price: _formatPrice(priceVal),
                                  status: status,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                width: 60,
                                                height: 60,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                ),
                                              ),
                                        )
                                      : Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.shopping_bag),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name']?.toString() ??
                                            product['title']?.toString() ??
                                            'สินค้า',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        product['description']?.toString() ??
                                            '',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _formatPrice(priceVal),
                                                style: const TextStyle(
                                                  color: Color(0xFF3ABDC5),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              // แสดงสถานะ
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(
                                                    status,
                                                  ).withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: _getStatusColor(
                                                      status,
                                                    ),
                                                  ),
                                                ),
                                                child: Text(
                                                  _getStatusLabel(status),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: _getStatusColor(
                                                      status,
                                                    ),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey,
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
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
