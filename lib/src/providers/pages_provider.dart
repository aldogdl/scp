import 'package:flutter/foundation.dart' show ChangeNotifier;

enum Paginas {
  solicitudesNon,
  solicitudes,
  cotizadores,
  solicitantes,
  config
}

enum Consola {
  harbi,
  centinela,
  alertas,
  errores,
  scm
}

class PageProvider extends ChangeNotifier {

  Paginas _page = Paginas.solicitudes;
  Paginas get page => _page;
  set page(Paginas p) {
    _page = p;
    notifyListeners();
  }
  void resetPage() {
    _page = Paginas.solicitudes;
    _confSecction = 'home';
  }

  ///
  bool _closeConsole = true;
  bool get closeConsole => _closeConsole;
  set closeConsole(bool isClose) {
    _closeConsole = isClose;
    notifyListeners();
  }

  Consola _consola = Consola.harbi;
  Consola get consola => _consola;
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

}