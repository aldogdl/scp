

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:scp/src/entity/orden_entity.dart';
import 'package:scp/src/entity/piezas_entity.dart';

class ItemSelectGlobProvider extends ChangeNotifier {

  ///
  void disposeMy() {
    _idPzaSelect = -1;
    _piezas = [];
    _fotosByPiezas = [];
  }

  ///
  int _idOrdenSelect = -1;
  int get idOrdenSelect => _idOrdenSelect;
  set idOrdenSelect(int id) {
    _idOrdenSelect = id;
    notifyListeners();
  }

  OrdenEntity? _ordenEntitySelect;
  OrdenEntity? get ordenEntitySelect => _ordenEntitySelect;
  void setOrdenEntitySelect(OrdenEntity orden) => _ordenEntitySelect = orden;

  ///
  int _idPzaSelect = -1;
  int get idPzaSelect => _idPzaSelect;
  set idPzaSelect(int id) {
    _idPzaSelect = id;
    notifyListeners();
  }

  ///
  List<PiezasEntity> _piezas = [];
  List<PiezasEntity> get piezas => _piezas;
  set piezas(List<PiezasEntity> pzas) {
    _piezas = pzas;
    notifyListeners();
  }

  ///
  List<Map<String, dynamic>> _fotosByPiezas = [];
  List<Map<String, dynamic>> get fotosByPiezas => _fotosByPiezas;
  set fotosByPiezas(List<Map<String, dynamic>> fPzas) {
    _fotosByPiezas = fPzas;
    notifyListeners();
  }

}