import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:powershare/services/apiServices.dart';

class PaymentSettingsPage extends StatefulWidget {
  const PaymentSettingsPage({super.key});

  @override
  State<PaymentSettingsPage> createState() => _PaymentSettingsPageState();
}

class _PaymentSettingsPageState extends State<PaymentSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _promptpayNumberCtrl = TextEditingController();
  final _promptpayNameCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  File? _pickedQRImage;
  String? _currentQRImageUrl;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _promptpayNumberCtrl.dispose();
    _promptpayNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    try {
      if (kDebugMode) print('🔵 Loading payment settings...');
      
      final settings = await ApiServices.getPaymentSettings();
      
      if (kDebugMode) {
        print('🔵 Settings received: $settings');
        print('🔵 Settings type: ${settings.runtimeType}');
      }
      
      if (settings != null && mounted) {
        if (kDebugMode) {
          print('✅ PromptPay Number from DB: ${settings['promptpay_number']}');
          print('✅ PromptPay Name from DB: ${settings['promptpay_name']}');
          print('✅ QR Image URL from DB: ${settings['qr_image_url']}');
        }
        
        setState(() {
          _promptpayNumberCtrl.text = settings['promptpay_number']?.toString() ?? '';
          _promptpayNameCtrl.text = settings['promptpay_name']?.toString() ?? '';
          _currentQRImageUrl = settings['qr_image_url']?.toString();
        });
        
        // ตรวจสอบหลัง setState
        if (kDebugMode) {
          print('✅ TextField Number: ${_promptpayNumberCtrl.text}');
          print('✅ TextField Name: ${_promptpayNameCtrl.text}');
          print('✅ Current QR URL: $_currentQRImageUrl');
        }
      } else {
        if (kDebugMode) print('⚠️ No settings found in database');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ยังไม่มีการตั้งค่า กรุณากรอกข้อมูลและบันทึก'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ loadSettings error: $e');
        print('Stack trace: $stackTrace');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('โหลดข้อมูลไม่สำเร็จ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickQRImage() async {
    try {
      final XFile? xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 90,
      );
      if (xfile != null) {
        setState(() => _pickedQRImage = File(xfile.path));
      }
    } catch (e) {
      if (kDebugMode) print('pickQRImage error: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      // **CRITICAL DEBUG: Print controller values BEFORE any operation**
      if (kDebugMode) {
        print('═══════════════════════════════════════');
        print('🔍 BEFORE SAVE - Controller Values:');
        print('   PromptPay Number: "${_promptpayNumberCtrl.text}"');
        print('   PromptPay Name: "${_promptpayNameCtrl.text}"');
        print('   Picked QR Image: ${_pickedQRImage?.path}');
        print('   Current QR URL: $_currentQRImageUrl');
        print('═══════════════════════════════════════');
      }

      String? qrImageUrl = _currentQRImageUrl;

      // อัปโหลดรูป QR ถ้ามีการเลือกใหม่
      if (_pickedQRImage != null) {
        if (kDebugMode) print('🔵 Uploading QR image...');
        qrImageUrl = await ApiServices.uploadUserFiles(
          _pickedQRImage!,
          subfolder: 'payment/qr',
        );
        if (qrImageUrl.isEmpty) {
          throw Exception('อัปโหลดรูป QR ไม่สำเร็จ');
        }
        if (kDebugMode) print('✅ QR uploaded: $qrImageUrl');
      }

      // ตรวจสอบว่ามีข้อมูลอยู่แล้วหรือไม่
      final existing = await ApiServices.getPaymentSettings();
      
      if (kDebugMode) {
        print('🔵 Existing settings: $existing');
        print('🔵 Will ${existing == null ? "CREATE" : "UPDATE"}');
      }

      bool success = false;

      if (existing == null) {
        // ถ้ายังไม่มีข้อมูล ให้ CREATE
        if (kDebugMode) {
          print('🔵 Creating new payment settings...');
          print('   - Number: "${_promptpayNumberCtrl.text.trim()}"');
          print('   - Name: "${_promptpayNameCtrl.text.trim()}"');
          print('   - QR URL: "$qrImageUrl"');
        }
        
        final created = await ApiServices.createPaymentSettings(
          promptpayNumber: _promptpayNumberCtrl.text.trim(),
          promptpayName: _promptpayNameCtrl.text.trim(),
          qrImageUrl: qrImageUrl,
        );
        
        success = created != null;
        if (kDebugMode) {
          print('🔵 Create result: $created');
          print('🔵 Create success: $success');
        }
      } else {
        // ถ้ามีข้อมูลแล้ว ให้ UPDATE
        if (kDebugMode) print('🔵 Updating existing payment settings...');
        
        final payload = {
          'promptpay_number': _promptpayNumberCtrl.text.trim(),
          'promptpay_name': _promptpayNameCtrl.text.trim(),
          'qr_image_url': qrImageUrl ?? '',
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        if (kDebugMode) {
          print('🔵 Update payload: $payload');
          print('   - Number being sent: "${payload['promptpay_number']}"');
          print('   - Name being sent: "${payload['promptpay_name']}"');
        }
        
        success = await ApiServices.updatePaymentSettings(payload);
        
        if (kDebugMode) print('🔵 Update success: $success');
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกข้อมูลสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
        
        if (kDebugMode) print('🔵 Reloading settings after save...');
        await _loadSettings(); // รีโหลดข้อมูลใหม่
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกไม่สำเร็จ กรุณาลองใหม่'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ save error: $e');
        print('Stack trace: $stackTrace');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildQRPreview() {
    Widget content;

    if (_pickedQRImage != null) {
      content = Image.file(
        _pickedQRImage!,
        width: 200,
        height: 200,
        fit: BoxFit.contain,
      );
    } else if (_currentQRImageUrl != null && _currentQRImageUrl!.isNotEmpty) {
      content = Image.network(
        _currentQRImageUrl!,
        width: 200,
        height: 200,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
      );
    } else {
      content = Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: const Icon(Icons.qr_code_2, size: 80, color: Colors.grey),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่าการชำระเงิน'),
        backgroundColor: const Color(0xFF3ABDC5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSettings,
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'QR Code PromptPay',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildQRPreview(),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickQRImage,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('เลือกรูป QR Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3ABDC5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _promptpayNumberCtrl,
                      decoration: InputDecoration(
                        labelText: 'เลขพร้อมเพย์ (เบอร์โทร/เลขบัตรประชาชน)',
                        prefixIcon: const Icon(Icons.phone_android),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'กรุณากรอกเลขพร้อมเพย์';
                        if (v.trim().length < 10) return 'เลขพร้อมเพย์ไม่ถูกต้อง';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _promptpayNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'ชื่อบัญชี',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'กรุณากรอกชื่อบัญชี';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3ABDC5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('บันทึกการตั้งค่า', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}