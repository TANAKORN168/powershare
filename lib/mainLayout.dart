import 'package:flutter/material.dart';
import 'package:powershare/pages/cartPage.dart';
import 'package:powershare/pages/profilePage.dart';
import 'package:powershare/pages/savedProductsPage.dart';
import 'package:powershare/pages/homePage.dart';
import 'package:powershare/pages/productPage.dart';
import 'package:powershare/pages/rentalHistoryPage.dart';
import 'package:powershare/pages/adminPage.dart';
import 'basePage.dart';
import 'package:powershare/services/session.dart';

class MainLayout extends StatefulWidget {
  final int currentIndex;
  final bool isAdmin; // เพิ่ม flag สำหรับแสดง tab ของ admin

  const MainLayout({super.key, this.currentIndex = 0, this.isAdmin = false});

  @override
  State<MainLayout> createState() => _MainLayoutState();

  // ✅ เพิ่ม static method สำหรับเรียกเปลี่ยน tab
  static _MainLayoutState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainLayoutState>();

  // แปลงชื่อหน้าเป็น index (รองรับชื่อภาษาอังกฤษ/ไทย)
  static int tabIndex(String name, {bool isAdmin = false}) {
    final n = name.toLowerCase();
    switch (n) {
      case 'home':
      case 'หน้าแรก':
        return 0;
      case 'product':
      case 'ค้นหา':
        return 1;
      case 'cart':
      case 'ตะกร้า':
        return 2;
      case 'rental':
      case 'การเช่า':
        return 3;
      case 'saved':
      case 'บันทึกไว้':
        return 4;
      case 'admin':
      case 'ผู้ดูแล':
        return isAdmin ? 5 : 0; // ถ้าไม่ใช่ admin จะกลับไปหน้าแรก
      case 'profile':
      case 'บัญชี':
      default:
        // ถ้ามี admin tab => profile อยู่ตำแหน่ง 6, ถ้าไม่มี => 5
        return isAdmin ? 6 : 5;
    }
  }
}

class _MainLayoutState extends State<MainLayout> {
  late int _selectedIndex;
  late bool _isAdmin; // เก็บสถานะจริงจาก session หรือ widget.isAdmin

  // เปลี่ยนจาก final list เป็น getter เพื่อรองรับการแสดง admin แบบ dynamic
  List<Widget> get pages => [
        BasePage(child: Center(child: HomePage())),
        BasePage(child: Center(child: ProductPage())),
        BasePage(child: Center(child: CartPage())),
        BasePage(child: Center(child: RentalHistoryPage())),
        BasePage(child: Center(child: SavedProductsPage())),
        if (_isAdmin) BasePage(child: Center(child: AdminPage())),
        BasePage(child: Center(child: ProfilePage())),
      ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;

    // เริ่มด้วยค่าที่ถูกส่งเข้ามาเป็น default
    _isAdmin = widget.isAdmin;

    // ถ้ามี user ใน session ให้ตั้งค่า isAdmin ตาม role ของ user
    final user = Session.instance.user;
    if (user != null) {
      final role = (user['role'] as String?) ?? '';
      _isAdmin = role.toLowerCase() == 'admin';
    }

    // ป้องกันค่า index เกินขอบเขต เมื่อมี/ไม่มี admin tab
    if (_selectedIndex >= pages.length) _selectedIndex = 0;
  }

  void switchToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    int _cartItemCount = 3; // ตัวอย่างจำนวนสินค้าในตะกร้า

    // สร้างรายการ BottomNavigationBarItem แบบ dynamic
    final items = <BottomNavigationBarItem>[
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าแรก'),
      BottomNavigationBarItem(icon: Icon(Icons.search), label: 'ค้นหา'),
      BottomNavigationBarItem(
        icon: Stack(
          children: [
            Icon(Icons.shopping_cart),
            if (_cartItemCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$_cartItemCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        label: 'ตะกร้า',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.event), label: 'การเช่า'),
      BottomNavigationBarItem(
        icon: Icon(Icons.favorite),
        label: 'บันทึกไว้',
      ),
    ];

    // ถ้าเป็น admin ให้เพิ่มปุ่ม Admin ก่อนปุ่มบัญชี
    if (_isAdmin) {
      items.add(BottomNavigationBarItem(
        icon: Icon(Icons.admin_panel_settings),
        label: 'Admin',
      ));
    }

    // เพิ่มปุ่มบัญชี (Profile) ท้ายสุด
    items.add(BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      label: 'บัญชี',
    ));
    
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF3ABDC5),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: items,
      ),
    );
  }
}
