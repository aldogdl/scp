import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../entity/marcas_entity.dart';
import '../entity/modelos_entity.dart';
import '../entity/orden_entity.dart';
import '../entity/piezas_entity.dart';

class CotizaProvider extends ChangeNotifier {

  void myDispose() {

    orden = OrdenEntity();
    piezas = [];
    lMarcas = [];
    lModelos = [];
    lAnios = [];
    _fotoThubm = '';
    _indexPzaCurren = -1;
    _taps = 'auto';
    _seccion = 'marcas';
    _refreshLstPzasOrden = 0;
  }

  String inicialDir = '';
  OrdenEntity orden = OrdenEntity();
  List<PiezasEntity> piezas = [];
  
  List<MarcasEntity> lMarcas = [];
  List<ModelosEntity> lModelos = [];
  List<int> lAnios = [];

  
  // El token server para hacer petiones a la API de cotiza
  String _tokenServer = '';
  String get tokenServer => _tokenServer;
  set tokenServer(String token) {
    _tokenServer = token;
    notifyListeners();
  }

  // Utilizado para resetear el FRM y dar de alta otra solicitud
  String _isOrdFinish = '';
  String get isOrdFinish => _isOrdFinish;
  set isOrdFinish(String acc) {
    if(acc == 'clean') {
      _isOrdFinish = '';
      return;
    }
    _isOrdFinish = acc;
    notifyListeners();
  }

  // Utilizado para editar una piezas de la orden
  String _fotoThubm = '';
  String get fotoThubm => _fotoThubm;
  set fotoThubm(String index) {
    _fotoThubm = index;
    notifyListeners();
  }

  // Utilizado para editar una piezas de la orden
  int _indexPzaCurren = -1;
  int get indexPzaCurren => _indexPzaCurren;
  set indexPzaCurren(int index) {
    _indexPzaCurren = index;
    notifyListeners();
  }

  // Utilizado para refrescar la lista de las piezas de la orden
  int _refreshLstPzasOrden = 0;
  int get refreshLstPzasOrden => _refreshLstPzasOrden;
  set refreshLstPzasOrden(int cantP) {
    _refreshLstPzasOrden = cantP;
    notifyListeners();
  }

  // Utilizado para buscar un elemento entre las diferentes listas
  String _search = '';
  String get search => _search;
  set search(String busk) {
    _search = busk;
    notifyListeners();
  }

  // Utilizado para saber en que pestaña estamos
  String _taps = 'auto';
  String get taps => _taps;
  set taps(String secc) {
    _taps = secc;
    notifyListeners();
  }

  // Utilizado para mostrar las distintas listas
  String _seccion = 'marcas';
  String get seccion => _seccion;
  set seccion(String secc) {
    _seccion = secc;
    notifyListeners();
  }

}