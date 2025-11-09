import 'package:flutter/material.dart';
import 'package:powershare/pages/cartPage.dart';
import 'package:powershare/pages/profilePage.dart';
import 'package:powershare/pages/savedProductsPage.dart';
import 'package:powershare/pages/homePage.dart';
import 'package:powershare/pages/productPage.dart';
import 'package:powershare/pages/rentalHistoryPage.dart';
import 'basePage.dart';

class MainLayout extends StatefulWidget {
  final int currentIndex;

  const MainLayout({super.key, this.currentIndex = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();

  // ✅ เพิ่ม static method สำหรับเรียกเปลี่ยน tab
  static _MainLayoutState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainLayoutState>();
}

class _MainLayoutState extends State<MainLayout> {
  late int _selectedIndex;

  final List<Widget> _pages = [
    BasePage(child: Center(child: HomePage())),
    BasePage(child: Center(child: ProductPage())),
    BasePage(child: Center(child: CartPage())),
    BasePage(child: Center(child: RentalHistoryPage())),
    BasePage(child: Center(child: SavedProductsPage())),
    BasePage(child: Center(child: ProfilePage())),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
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
  @override
  Widget build(BuildContext context) {
    int _cartItemCount = 3; // ตัวอย่างจำนวนสินค้าในตะกร้า

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF3ABDC5),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
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
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'บัญชี',
          ),
        ],
      ),
    );
  }
}
