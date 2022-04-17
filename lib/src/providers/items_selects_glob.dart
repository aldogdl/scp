import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../entity/contacto_entity.dart';
import '../entity/orden_entity.dart';
import '../entity/piezas_entity.dart';

class ItemSelectGlobProvider extends ChangeNotifier {

  ///
  void disposeMy() {
    _idPzaSelect = -1;
    _piezas = [];
    _fotosByPiezas = [];
    _ordenesAsignadas = {};
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
  List<ContactoEntity> _avos = [];
  List<ContactoEntity> get avos => _avos;
  set avos(List<ContactoEntity> avoslst) {
    _avos = avoslst;
    notifyListeners();
  }

  ///
  Map<int, List<int>> _ordenesAsignadas = {};
  Map<int, List<int>> get ordenesAsignadas => _ordenesAsignadas;
  set ordenesAsignadas(Map<int, List<int>> ordenlst) {
    _ordenesAsignadas = ordenlst;
    notifyListeners();
  }

  ///
  void ordenesAsignadasInsert(int idAvo, int idOrden) {

    if(_ordenesAsignadas.containsKey(idAvo)) {
      _ordenesAsignadas[idAvo]!.insert(0, idOrden);
    }else{
      _ordenesAsignadas.putIfAbsent(idAvo, () => [idOrden]);
    }
    notifyListeners();
  }

  ///
  void ordenesAsignadasRemove(int idAvo, int idOrden) {
    if(_ordenesAsignadas.containsKey(idAvo)) {
      _ordenesAsignadas[idAvo]!.remove(idOrden);
      if(_ordenesAsignadas[idAvo]!.isEmpty) {
        _ordenesAsignadas.remove(idAvo);
      }
    }
    notifyListeners();
  }

  ///
  List<OrdenEntity> _ordenes = [];
  List<OrdenEntity> get ordenes => _ordenes;
  set ordenes(List<OrdenEntity> ordenlst) {
    _ordenes = ordenlst;
    notifyListeners();
  }

  ///
  set ordenInsert(Map<String, dynamic> ordenlst) {
    final ord = OrdenEntity();
    ord.fromServer(ordenlst);
    _ordenes.insert(0, ord);
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