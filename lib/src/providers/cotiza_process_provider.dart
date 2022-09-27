import 'package:flutter/foundation.dart' show ChangeNotifier;

class CotizaProcessProvider extends ChangeNotifier {

  /// El mensaje de proceso para el archivo actual que se esta procesando
  Map<int, String> _msgProc = {};
  Map<int, String> get msgProc => _msgProc;
  set msgProc(Map<int, String> msg) {
    _msgProc = msg;
    notifyListeners();
  }

  /// La lista de paths de los archivos que se estan procesando
  List<String> _fileProc = [];
  List<String> get fileProc => _fileProc;
  set fileProc(List<String> files) {
    _fileProc = files;
    notifyListeners();
  }
}