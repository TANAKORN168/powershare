import 'package:flutter/foundation.dart';

class ProductNotifier extends ChangeNotifier {
  static final ProductNotifier instance = ProductNotifier._();
  ProductNotifier._();

  void notifyProductChanged() {
    notifyListeners();
  }
}