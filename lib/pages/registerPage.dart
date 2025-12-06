import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:powershare/models/singupModel.dart';
import 'package:powershare/services/apiServices.dart';
import 'package:powershare/services/emailServices.dart';
import 'package:powershare/validates/textFieldValidate.dart';
import 'package:powershare/widgets/dateWidget.dart';
import 'package:powershare/widgets/imageWidget.dart';
import 'package:powershare/widgets/passwordWidget.dart';
import 'package:powershare/widgets/redirectTextButtonWidget.dart';
import 'package:powershare/widgets/textFieldWidget.dart';
import '../loginPage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return RegisterPageState();
  }
}

class RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _idCardNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _subdistrictController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  File? _idCardImage;
  File? _faceImage;

  bool _acceptTerms = false;

  List<Map<String, dynamic>> _addressData = [];
  List<String> _provinces = [];
  List<String> _amphures = [];
  List<String> _districts = [];

  String? _selectedProvince;
  String? _selectedAmphure;
  String? _selectedDistrict;

  Future<void> _loadAddressData() async {
    final String jsonString = await rootBundle.loadString(
      'assets/datas/geography.json',
    );
    final List<dynamic> jsonData = json.decode(jsonString);
    setState(() {
      _addressData = jsonData.cast<Map<String, dynamic>>();
      _provinces =
          _addressData
              .map((e) => e['provinceNameTh'] as String)
              .toSet()
              .toList()
            ..sort();
    });
  }

  Widget _buildProvinceDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: DropdownSearch<String>(
        items: _provinces,
        selectedItem: _selectedProvince,
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: "จังหวัด",
            filled: true,
            fillColor: Color.fromARGB(255, 240, 240, 240),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Color.fromARGB(255, 200, 200, 200), // สีขอบเวลาปกติ
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Color.fromARGB(
                  255,
                  200,
                  200,
                  200,
                ), // สีขอบเวลาที่กดเลือก (focus)
              ),
            ),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _selectedProvince = value;
            _selectedAmphure = null;
            _selectedDistrict = null;
            _amphures =
                _addressData
                    .where((e) => e['provinceNameTh'] == value)
                    .map((e) => e['districtNameTh'] as String)
                    .toSet()
                    .toList()
                  ..sort();
          });
        },
      ),
    );
  }

  Widget _buildAmphureDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: DropdownSearch<String>(
        items: _amphures,
        selectedItem: _selectedAmphure,
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: "อำเภอ/เขต",
            filled: true,
            fillColor: Color.fromARGB(255, 240, 240, 240),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Color.fromARGB(255, 200, 200, 200), // สีขอบเวลาปกติ
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Color.fromARGB(
                  255,
                  200,
                  200,
                  200,
                ), // สีขอบเวลาที่กดเลือก (focus)
              ),
            ),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _selectedAmphure = value;
            _selectedDistrict = null;
            _districts =
                _addressData
                    .where(
                      (e) =>
                          e['provinceNameTh'] == _selectedProvince &&
                          e['districtNameTh'] == value,
                    )
                    .map((e) => e['subdistrictNameTh'] as String)
                    .toSet()
                    .toList()
                  ..sort();
          });
        },
      ),
    );
  }

  Widget _buildDistrictDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: DropdownSearch<String>(
        items: _districts,
        selectedItem: _selectedDistrict,
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: "ตำบล/แขวง",
            filled: true,
            fillColor: Color.fromARGB(255, 240, 240, 240),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Color.fromARGB(255, 200, 200, 200), // สีขอบเวลาปกติ
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Color.fromARGB(
                  255,
                  200,
                  200,
                  200,
                ), // สีขอบเวลาที่กดเลือก (focus)
              ),
            ),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _selectedDistrict = value;

            // หา record ที่ถูกต้องจาก JSON
            final selected = _addressData.firstWhere(
              (e) =>
                  e['provinceNameTh'] == _selectedProvince &&
                  e['districtNameTh'] == _selectedAmphure &&
                  e['subdistrictNameTh'] == value,
            );

            // แก้ตรงนี้ให้ตรงกัน: subdistrict <- subdistrictNameTh, province <- provinceNameTh
            _subdistrictController.text = selected['subdistrictNameTh'].toString();
            _districtController.text = selected['districtNameTh'].toString();
            _provinceController.text = selected['provinceNameTh'].toString();
            _postalCodeController.text = selected['postalCode'].toString();
          });
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAddressData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _idCardNumberController.dispose();
    _addressController.dispose();
    _subdistrictController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String htmlRegisterSucess = '''
      <!DOCTYPE html>
      <html lang="th">
        <head>
          <meta charset="UTF-8" />
          <title>ยินดีต้อนรับสู่ PowerShare</title>
        </head>
        <body style="font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 30px;">
          <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 600px; margin: auto; background-color: #ffffff; border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.05);">
            <tr>
              <td style="padding: 30px;">
                <h2 style="color: #33a57b; margin-top: 0;">👋 ยินดีต้อนรับสู่ PowerShare</h2>
                <p>สวัสดีคุณ <b>{{customer_name}}</b>,</p>

                <p>ขอบคุณที่ลงทะเบียนใช้งาน <b>PowerShare</b><br />
                บัญชีของคุณพร้อมใช้งานแล้ว โดยมีรายละเอียดการเข้าสู่ระบบดังนี้:</p>

                <table style="background-color: #f9f9f9; border: 1px solid #ddd; border-radius: 8px; padding: 15px; margin: 20px 0;">
                  <tr>
                    <td><b>🔐 Username:</b></td>
                    <td>{{username}}</td>
                  </tr>
                  <tr>
                    <td><b>🔑 Password:</b></td>
                    <td>{{password}}</td>
                  </tr>
                </table>

                <p>คุณสามารถเข้าสู่ระบบได้ที่แอป PowerShare บนอุปกรณ์ของคุณ หรือผ่านเว็บไซต์ <a href="https://powershare.app" style="color: #3e96c6;">powershare.app</a></p>

                <p>หากคุณมีคำถามหรือปัญหาใด ๆ สามารถติดต่อทีมงานได้ที่ <a href="mailto:support@powershare.app">support@powershare.app</a></p>

                <p style="margin-top: 40px;">ขอแสดงความนับถือ,<br />
                ทีมงาน PowerShare</p>
              </td>
            </tr>
          </table>
        </body>
      </html>
    ''';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(bottom: 50), // กันปุ่มล่างชนขอบ
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(height: 40),
                  Center(
                    child: Image.asset('assets/images/logo.png', width: 200),
                  ),
                  TextFieldWidget.buildTextField(_nameController, 'ชื่อ'),
                  TextFieldWidget.buildTextField(_surnameController, 'นามสกุล'),
                  DateWidget(
                    controller: _birthDateController,
                    onDateSelected: (date) {
                      print('เลือกวัน: $date');
                    },
                  ),
                  TextFieldWidget.buildTextField(
                    _phoneController,
                    'เบอร์มือถือ',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  TextFieldWidget.buildTextField(
                    _idCardNumberController,
                    'เลขบัตรประชาชน',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(13),
                    ],
                  ),
                  TextFieldWidget.buildTextField(_addressController, 'ที่อยู่'),
                  _buildProvinceDropdown(),
                  _buildAmphureDropdown(),
                  _buildDistrictDropdown(),
                  TextFieldWidget.buildTextField(
                    _postalCodeController,
                    'รหัสไปรษณีย์',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    readOnly: true,
                  ),
                  TextFieldWidget.buildEmailField(_emailController),
                  PasswordField(controller: _passwordController),
                  ImagePickerWidget(
                    label: 'รูปถ่ายบัตรประชาชน',
                    imageFile: _idCardImage,
                    isIdCard: true,
                    aspectRatio: 3 / 2,
                    onImagePicked: (file) {
                      setState(() {
                        _idCardImage = file;
                      });
                    },
                  ),
                  ImagePickerWidget(
                    label: 'รูปถ่ายหน้าตรง',
                    imageFile: _faceImage,
                    isIdCard: false,
                    aspectRatio: 3 / 4,
                    onImagePicked: (file) {
                      setState(() {
                        _faceImage = file;
                      });
                    },
                  ),
                  SizedBox(height: 30),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _acceptTerms,
                              onChanged: (bool? value) {
                                setState(() {
                                  _acceptTerms = value ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                'ฉันยอมรับเงื่อนไขและนโยบายความเป็นส่วนตัว',
                                style: TextStyle(fontSize: 15.0),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  '📄 ข้อตกลงและเงื่อนไขการใช้บริการ | PDPA & การยืนยันตัวตน',
                                ),
                                content: SingleChildScrollView(
                                  child: Text(
                                    'ผู้ใช้งานจะต้องอ่านและยอมรับข้อตกลงด้านล่างก่อนใช้งานแอปเพื่อดำเนินการเช่าสินค้า\n\n'
                                    '1. การให้ความยินยอมในการเก็บและใช้ข้อมูลส่วนบุคคล (PDPA)\n\n'
                                    '1.1 ผู้ใช้งานยินยอมให้แอปพลิเคชันเก็บ ใช้ และเปิดเผยข้อมูลส่วนบุคคล เช่น ชื่อ-นามสกุล, ที่อยู่, หมายเลขโทรศัพท์, เลขบัตรประชาชน หรือเอกสารยืนยันตัวตนอื่นๆ เพื่อวัตถุประสงค์ในการให้บริการ\n\n'
                                    '1.2 ข้อมูลส่วนบุคคลจะถูกใช้เพื่อวัตถุประสงค์ เช่น การยืนยันตัวตน, การติดต่อ, การประกันความเสียหาย และการปฏิบัติตามข้อกฎหมาย\n\n'
                                    '1.3 ผู้ใช้งานสามารถร้องขอให้ลบข้อมูล หรือถอนความยินยอมเมื่อใดก็ได้ (ตามขั้นตอนที่บริษัทกำหนด)\n\n'
                                    '\n\n'
                                    '2. การยืนยันตัวตนเพื่อใช้ทางกฎหมาย\n\n'
                                    '2.1 ผู้ใช้งานตกลงที่จะให้ข้อมูลที่เป็นความจริงและถูกต้อง เช่น รูปถ่ายบัตรประชาชน ใบขับขี่ หรือเอกสารราชการที่สามารถระบุตัวตนได้\n\n'
                                    '2.2 แอปมีสิทธิ์ในการตรวจสอบความถูกต้องของข้อมูล และปฏิเสธการให้บริการหากข้อมูลไม่ถูกต้องหรือมีเจตนาปกปิด\n\n'
                                    '2.3 หากเกิดเหตุการณ์สินค้าเสียหาย สูญหาย หรือถูกละเมิดข้อตกลงการเช่า ข้อมูลของผู้ใช้จะสามารถถูกนำไปใช้ในการดำเนินการทางกฎหมาย หรือเรียกร้องค่าเสียหายตามกฎหมายที่เกี่ยวข้อง\n\n'
                                    '\n\n'
                                    '3. การรับผิดชอบเมื่อสินค้าเสียหาย\n\n'
                                    '3.1 ผู้ใช้งานตกลงว่าจะรับผิดชอบค่าใช้จ่ายทั้งหมดที่เกิดจากความเสียหาย สูญหาย หรือการใช้งานผิดวัตถุประสงค์ของสินค้าที่เช่า\n\n'
                                    '3.2 ในกรณีที่ไม่สามารถชดใช้คืนสินค้าได้ตามเงื่อนไข แอปมีสิทธิ์เรียกเก็บค่าปรับ ค่าซ่อม หรือมูลค่าสินค้าทดแทน\n\n'
                                    '3.3 ผู้ใช้ยินยอมให้แอปใช้ข้อมูลที่ให้ไว้ในการดำเนินการติดตามหรือดำเนินคดีตามกฎหมาย หากเกิดการหลีกเลี่ยงความรับผิดชอบ\n\n'
                                    '\n\n'
                                    '4. ข้อตกลงทั่วไป\n\n'
                                    '4.1 ผู้ใช้งานต้องมีอายุ 18 ปีขึ้นไป\n\n'
                                    '4.2 แอปขอสงวนสิทธิ์ในการแก้ไขหรือเปลี่ยนแปลงข้อตกลงโดยไม่ต้องแจ้งให้ทราบล่วงหน้า\n\n'
                                    '4.3 การใช้งานแอปหลังจากมีการเปลี่ยนแปลงเงื่อนไข ถือว่าผู้ใช้ยอมรับเงื่อนไขที่แก้ไขแล้ว\n\n'
                                    '\n\n'
                                    '✅ โดยการกดยอมรับด้านล่างนี้ ถือว่าท่านได้อ่าน เข้าใจ และยินยอมในข้อตกลงทั้งหมดแล้ว\n',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('ปิด'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 48,
                            ), // ชิดกับข้อความด้านบน (เลื่อนจาก checkbox)
                            child: Text(
                              'อ่านรายละเอียด',
                              style: TextStyle(
                                color: Color(0xFF3ABDC5),
                                fontWeight: FontWeight
                                    .bold, // ทำเป็นลิงก์เหมือนขีดเส้นใต้
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            // แสดง Loading
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            await Future.delayed(Duration(milliseconds: 100));

                            // ตรวจสอบ checkbox ก่อน validate อื่นๆ
                            if (!_acceptTerms) {
                              Navigator.of(context, rootNavigator: true).pop(); // ปิด loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('กรุณายอมรับเงื่อนไขก่อนดำเนินการต่อ'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            String validatetionMessage = '';
                            validatetionMessage =
                                TextFieldValidate.validatePassword(
                                  _passwordController.text.trim(),
                                );
                            validatetionMessage =
                                TextFieldValidate.validateEmail(
                                  _emailController.text.trim(),
                                );
                            validatetionMessage =
                                TextFieldValidate.validateIdCardNumber(
                                  _idCardNumberController.text.trim(),
                                );
                            validatetionMessage =
                                TextFieldValidate.validateMobileNumber(
                                  _phoneController.text.trim(),
                                );
                            validatetionMessage =
                                TextFieldValidate.validateDate(
                                  _birthDateController.text.trim(),
                                  'วันเดือนปีเกิด',
                                );
                            validatetionMessage =
                                TextFieldValidate.validateRequired(
                                  _surnameController.text.trim(),
                                  'นามสกุล',
                                );
                            validatetionMessage =
                                TextFieldValidate.validateRequired(
                                  _nameController.text.trim(),
                                  'ชื่อ',
                                );

                            if (validatetionMessage != '') {
                              Navigator.of(context, rootNavigator: true).pop(); // ปิด loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(validatetionMessage),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final signupModel = SignupModel(
                              name: _nameController.text.trim(),
                              surname: _surnameController.text.trim(),
                              birthDate: _birthDateController.text.trim(),
                              phoneNumber: _phoneController.text.trim(),
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                              idCardImagePath:
                                  await ApiServices.uploadUserFiles(
                                    _idCardImage!,
                                  ),
                              faceImagePath:
                                  await ApiServices.uploadUserFiles(
                                    _faceImage!,
                                  ),
                              idCardNumber: _idCardNumberController.text
                                  .trim(),
                              address: _addressController.text.trim(),
                              subdistrict: _subdistrictController.text.trim(),
                              district: _districtController.text.trim(),
                              province: _provinceController.text.trim(),
                              postalCode: _postalCodeController.text.trim(),
                              avatarUrl: "",
                            );
                            var res = await ApiServices.signup(signupModel);

                            Navigator.of(context, rootNavigator: true).pop();

                            if (res.responseCode == 'SUCCESS') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res.responseMessage),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              // แทนที่ค่าจริงใน HTML template
                              final htmlContent = htmlRegisterSucess
                                  .replaceAll('{{customer_name}}', '${_nameController.text.trim()} ${_surnameController.text.trim()}')
                                  .replaceAll('{{username}}', _emailController.text.trim())
                                  .replaceAll('{{password}}', _passwordController.text.trim());

                              // ส่งอีเมลยืนยันการสมัครสมาชิก
                              EmailServices.sendEmailViaEdgeFunction(
                                to: _emailController.text.trim(),
                                subject: 'ยินดีต้อนรับสู่ PowerShare!',
                                html: htmlContent,
                              );

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginPage(),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res.responseMessage),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            Navigator.of(context, rootNavigator: true).pop();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('เกิดข้อผิดพลาด: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.all(15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          backgroundColor: Color(0xFF1E4F70),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'บันทึก',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontFamily: 'Prompt',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: RedirectTextButtonWidget(
                      text: 'กลับไปหน้าเข้าสู่ระบบ',
                      pageToNavigate: const LoginPage(),
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
