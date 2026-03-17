import 'package:flutter/foundation.dart';

class MainNavController {
  final ValueNotifier<int> currentIndex = ValueNotifier<int>(0);

  void setIndex(int index) {
    currentIndex.value = index;
  }

  void dispose() {
    currentIndex.dispose();
  }
}
