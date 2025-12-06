import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:powershare/pages/cartPage.dart';
import 'package:powershare/pages/profilePage.dart';
import 'package:powershare/pages/savedProductsPage.dart';
import 'package:powershare/pages/homePage.dart';
import 'package:powershare/pages/productPage.dart';
import 'package:powershare/pages/rentalHistoryPage.dart';
import 'package:powershare/pages/adminPage.dart';
import 'basePage.dart';
import 'package:powershare/services/session.dart';
import 'package:powershare/services/apiServices.dart';

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
  Timer? _cartTimer;

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
    _isAdmin = widget.isAdmin;
    final user = Session.instance.user;
    if (user != null) {
      final role = (user['role'] as String?) ?? '';
      _isAdmin = role.toLowerCase() == 'admin';
    }
    if (_selectedIndex >= pages.length) _selectedIndex = 0;

    // โหลดจำนวนรายการตะกร้าจาก server
    _loadCartCount();
    // เริ่ม polling แบบเบา ๆ เพื่อให้ badge อัพเดตเป็น "real time"
    _cartTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _loadCartCount();
    });
  }

  @override
  void dispose() {
    _cartTimer?.cancel();
    super.dispose();
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

  int _cartItemCount = 0; // ตัวอย่างจำนวนสินค้าในตะกร้า

  @override
  Widget build(BuildContext context) {
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
                  // AnimatedSwitcher จะทำให้ตัวเลขเปลี่ยนด้วยอนิเมชัน (scale/fade)
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Text(
                      '$_cartItemCount',
                      // Key สำคัญ — ทำให้ AnimatedSwitcher แยกแยะการเปลี่ยนแปลง
                      key: ValueKey<int>(_cartItemCount),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
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

  Future<void> _loadCartCount() async {
    try {
      final user = Session.instance.user;
      if (kDebugMode) print('MainLayout._loadCartCount: session.user=$user');
      if (user == null) return;
      final userId = user['id']?.toString();
      if (userId == null || userId.isEmpty) {
        if (kDebugMode) print('MainLayout._loadCartCount: userId missing');
        return;
      }
      if (kDebugMode) print('MainLayout._loadCartCount: calling ApiServices.getCartItemCountForUser for userId=$userId');
      final count = await ApiServices.getCartItemCountForUser(userId);
      if (kDebugMode) print('MainLayout._loadCartCount: got count=$count (current=$_cartItemCount)');
      if (mounted && _cartItemCount != count) {
        setState(() {
          _cartItemCount = count;
        });
      }
    } catch (e) {
      if (kDebugMode) print('loadCartCount error: $e');
    }
  }

  // ให้เรียกแบบ: MainLayout.of(context)?.refreshCartCount();
  void refreshCartCount() => _loadCartCount();
}
