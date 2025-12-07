import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:powershare/services/apiServices.dart';
import 'package:powershare/services/session.dart';
import 'package:flutter/material.dart';

class AddEditProductPage extends StatefulWidget {
  final Map<String, dynamic>? product;
  const AddEditProductPage({super.key, this.product});

  @override
  State<AddEditProductPage> createState() => _AddEditProductPageState();
}

class _AddEditProductPageState extends State<AddEditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _subtitleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _imageCtrl;
  bool _saving = false;

  // image picker
  final ImagePicker _picker = ImagePicker();
  File? _pickedImageFile;

  // categories
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p != null ? p['name'] : '');
    _subtitleCtrl = TextEditingController(text: p != null ? (p['subtitle'] ?? '') : '');
    // ใช้ field ชื่อจริงใน DB: "description"
    _descCtrl = TextEditingController(text: p != null ? p['description'] : '');
    _priceCtrl = TextEditingController(
      text: p != null ? (p['price']?.toString() ?? '') : '',
    );
    _imageCtrl = TextEditingController(text: p != null ? p['image'] : '');
    // initial category from product (if edit)
    _selectedCategoryId = p != null ? (p['category_id']?.toString()) : null;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
    });
    try {
      final list = await ApiServices.getCategories();
      _categories = list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _categories = [];
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subtitleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  // เพิ่ม: เลือกรูป
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? xfile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (xfile == null) return;
      setState(() => _pickedImageFile = File(xfile.path));
    } catch (e) {
      debugPrint('pickImage error: $e');
    }
  }

  // แก้ _save ให้เรียก upload ก่อนส่ง payload
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      String? imageUrl;
      if (_pickedImageFile != null) {
        // ใช้ฟังก์ชันเดียวกับหน้า register (uploadUserFiles) หรือเรียก ApiServices.uploadFile(...) ถ้าต้องการ path/custom bucket
        // เรียกด้วย named parameter 'subfolder'
        imageUrl = await ApiServices.uploadProductFile(_pickedImageFile!);
        // หรือใช้ helper ที่เตรียมไว้:
        // imageUrl = await ApiServices.uploadProductFile(_pickedImageFile!);
      } else if (_imageCtrl.text.trim().isNotEmpty) {
        imageUrl = _imageCtrl.text.trim();
      }

      final payload = {
        'name': _nameCtrl.text.trim(),
        'subtitle': _subtitleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
        'image': imageUrl ?? '',
        'category_id': _selectedCategoryId,
        'last_status': widget.product == null ? 'Available' : (widget.product!['last_status'] ?? 'Available'),
      };

      // ถ้าเป็นการสร้างใหม่ ให้ตั้ง last_status เป็น Available
      if (widget.product == null) {
        payload['last_status'] = 'Available';
      }

      Map<String, dynamic> saved;
      final idRaw = widget.product?['id']?.toString();
      final uuidReg = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$');

      if (widget.product != null && idRaw != null) {
        // กรณีแก้ไข: ถ้า id เป็น UUID -> update, ถ้าไม่ใช่ -> ถามผู้ใช้ก่อนสร้างใหม่
        if (uuidReg.hasMatch(idRaw)) {
          saved = await ApiServices.updateProduct(idRaw, payload);
        } else {
          final createNew = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('ไอดีไม่ถูกต้อง'),
              content: const Text('รายการนี้ไม่มีไอดีของฐานข้อมูล (ไม่สามารถอัพเดตได้)\nต้องการสร้างเป็นสินค้าใหม่หรือไม่?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('ยกเลิก')),
                ElevatedButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('สร้างใหม่')),
              ],
            ),
          );

          if (createNew != true) {
            // ยกเลิกการบันทึก
            if (mounted) setState(() => _saving = false);
            return;
          }

          final user = Session.instance.user;
          if (user != null && user['id'] != null) payload['user_created'] = user['id'];
          saved = await ApiServices.createProduct(payload);
        }
      } else {
        // สร้างใหม่ตามปกติ
        final user = Session.instance.user;
        if (user != null && user['id'] != null) payload['user_created'] = user['id'];
        saved = await ApiServices.createProduct(payload);
      }

      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (e, st) {
      debugPrint('AddEditProductPage._save error: $e\n$st');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color.fromARGB(255, 240, 240, 240),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color.fromARGB(255, 200, 200, 200)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color.fromARGB(255, 200, 200, 200)),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 14.0,
        horizontal: 16.0,
      ),
    );
  }

  Widget _buildImagePreview() {
    final double previewHeight = 260;

    Widget buildContent() {
      if (_pickedImageFile != null) {
        return Image.file(
          _pickedImageFile!,
          width: double.infinity,
          height: previewHeight,
          fit: BoxFit.cover,
        );
      }

      final text = _imageCtrl.text.trim();
      final isUrl = text.startsWith('http://') || text.startsWith('https://');
      if (isUrl) {
        return Image.network(
          text,
          width: double.infinity,
          height: previewHeight,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: previewHeight,
            color: Colors.grey.shade200,
            child: const Icon(Icons.image_not_supported, size: 48),
          ),
        );
      }

      return Container(
        height: previewHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Icon(Icons.image, size: 48, color: Colors.grey),
        ),
      );
    }

    // ถ้ามีรูปจริงให้สามารถแตะเพื่อดูรูปใหญ่ได้
    return GestureDetector(
      onTap: () {
        final text = _imageCtrl.text.trim();
        final isUrl = text.startsWith('http://') || text.startsWith('https://');
        ImageProvider? provider;
        if (_pickedImageFile != null) {
          provider = FileImage(_pickedImageFile!);
        } else if (isUrl) {
          provider = NetworkImage(text);
        }
        if (provider == null) return;

        showDialog(
          context: context,
          builder: (c) {
            final prov = provider!; // ยืนยัน non-null ที่นี่
            return Dialog(
              insetPadding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: () => Navigator.of(c).pop(),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Container(
                    color: Colors.black,
                    child: Image(
                      image: prov,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: buildContent(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'แก้ไขสินค้า' : 'เพิ่มสินค้า'),
        backgroundColor: const Color(0xFF3ABDC5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // รูปและฟอร์มจะมี margin ซ้าย/ขวาเท่ากัน
              _buildImagePreview(),
              const SizedBox(height: 10),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('เลือกรูปจากเครื่อง'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3ABDC5),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('ถ่ายรูป'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E4F70),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _inputDecoration('ชื่อสินค้า'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณาใส่ชื่อสินค้า' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _subtitleCtrl,
                      decoration: _inputDecoration('Subtitle (ย่อ)'),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: _inputDecoration('รายละเอียด'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceCtrl,
                      decoration: _inputDecoration('ราคา/วัน (บาท)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'กรุณาใส่ราคา';
                        final val = double.tryParse(v.trim());
                        if (val == null) return 'รูปแบบราคาผิด';
                        if (val <= 0) return 'ราคาต้องมากกว่า 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    // หมวดหมู่ (บังคับเลือก)
                    _loadingCategories
                        ? const SizedBox(height: 56, child: Center(child: CircularProgressIndicator()))
                        : DropdownButtonFormField<String>(
                            initialValue: _selectedCategoryId,
                            decoration: _inputDecoration('หมวดหมู่'),
                            items: _categories
                                .map((c) => DropdownMenuItem(
                                      value: c['id']?.toString(),
                                      child: Text(c['name']?.toString() ?? ''),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedCategoryId = v;
                              });
                            },
                            validator: (v) => (v == null) ? 'กรุณาเลือกหมวดหมู่' : null,
                          ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _save,
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('บันทึกข้อมูล'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: const Color(0xFF3ABDC5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('ยกเลิก'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
