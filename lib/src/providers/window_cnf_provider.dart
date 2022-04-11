import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart' show ChangeNotifier, Size, Color;

class WindowCnfProvider extends ChangeNotifier {

  final double tamToolBar = 50;
  final double tamMiddle  = 300;

  final sttBarrColorOn = const Color.fromARGB(255, 7, 151, 43);
  final sttBarrColorOff = const Color.fromARGB(255, 31, 81, 245);
  final borderColor = const Color.fromARGB(255, 0, 0, 0);
  final sidebarColor = const Color.fromARGB(255, 51, 51, 51);
  final middleColor = const Color.fromARGB(255, 37, 37, 38);
  final backgroundStartColor = const Color.fromARGB(255, 30, 30, 30);
  final backgroundEndColor = const Color.fromARGB(255, 51, 51, 51);
  final buttonColors = WindowButtonColors(
      iconNormal: const Color.fromARGB(255, 199, 199, 199),
      mouseOver: const Color.fromARGB(255, 63, 63, 63),
      mouseDown: const Color.fromARGB(255, 128, 83, 6),
      iconMouseOver: const Color.fromARGB(255, 199, 199, 199),
      iconMouseDown: const Color.fromARGB(255, 255, 255, 255)
  );

  final closeButtonColors = WindowButtonColors(
      mouseOver: const Color.fromARGB(255, 211, 47, 47),
      mouseDown: const Color.fromARGB(255, 183, 28, 28),
      iconNormal: const Color.fromARGB(255, 128, 83, 6),
      iconMouseOver: const Color.fromARGB(255, 255, 255, 255)
  );

  ///
  Size _windowSize = const Size(1376.0, 784.0);
  Size get windowSize => _windowSize;
  setWindowSize(Size size) {
    _windowSize = size;
  }

  ///
  Size _contentSize = const Size(1376.0, 784.0);
  Size get contentSize => _contentSize;
  set contentSize(Size size) {
    double w = size.width - (tamToolBar+tamMiddle);
    _contentSize = Size(w, size.height);
    notifyListeners();
  }

  ///
  bool _closeConsole = true;
  bool get closeConsole => _closeConsole;
  set closeConsole(bool isClose) {
    _closeConsole = isClose;
    notifyListeners();
  }
}