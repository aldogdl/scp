import 'package:flutter/foundation.dart' show ChangeNotifier;

enum Paginas {
  solicitudes,
  cotizadores,
  solicitantes,
  config
}

enum Consola {
  harbi,
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