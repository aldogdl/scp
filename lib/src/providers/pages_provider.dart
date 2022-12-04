import 'package:flutter/foundation.dart' show ChangeNotifier;

enum Paginas {
  solicitudesNon,
  solicitudes,
  cotizadores,
  solicitantes,
  almacenVirtual,
  dataScranet,
  cotiza,
  config
}

enum Consola {
  alertas,
  notiff,
  scm
}

class PageProvider extends ChangeNotifier {

  bool _isSplash = true;
  bool get isSplash => _isSplash;
  set isSplash(bool p) {
    _isSplash = p;
    notifyListeners();
  }

  ///
  Paginas _page = Paginas.config;
  Paginas get page => _page;
  set page(Paginas p) {
    _page = p;
    notifyListeners();
  }
  void resetPage() {
    _page = Paginas.config;
    _confSecction = 'home';
  }

  ///
  int _sttConsole = 1;
  int get sttConsole => _sttConsole;
  set sttConsole(int isstt) {
    _sttConsole = isstt;
    notifyListeners();
  }

  Consola _consola = Consola.alertas;
  Consola get consola => _consola;
  void putValue(Consola val) => _consola = val;
  set consola(Consola p) {
    _consola = p;
    notifyListeners();
  }

  // Secciones para la pagina de config
  String _confSecction = 'home';
  String get confSecction => _confSecction;
  set confSecction(String p) {
    _confSecction = p;
    notifyListeners();
  }

  bool _refreshLsts = false;
  bool get refreshLsts => _refreshLsts;
  set refreshLsts(bool isR) {
    _refreshLsts = isR;
    notifyListeners();
  }

}