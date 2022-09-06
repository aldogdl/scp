import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../services/my_http.dart';
import '../services/get_paths.dart';

enum CPush {
  asignacion,
  reasignacion
}

class CentinelaFileProvider extends ChangeNotifier {

  Map<String, dynamic> result = {'abort': false, 'msg': 'ok', 'body':[]};

  ///
  void clean() { result = {'abort': false, 'msg': 'ok', 'body':[]}; }

  ///
  void myDispose() {
    _centinela.clear();
  }

  ///
  Map<String, dynamic> _centinela = {};
  Map<String, dynamic> get centinela => _centinela;
  set centinela(Map<String, dynamic> centi) {
    _centinela = centi;
    notifyListeners();
  }

  /// ->Guardamos los cambios solo en memoria.
  Future<void> commit(CPush msg, dynamic data) async {

    switch (msg) {
      case CPush.asignacion:
        await _persistAsignacion(Map<int, List<int>>.from(data));
        break;
      case CPush.reasignacion:
        await _persistReasignacion(List<int>.from(data));
        break;
      default:
    }
  }

  /// ->Enviamos los cambio realizados a los servidores.
  Future<void> push(CPush to, {bool isLocal = true}) async {

    switch (to) {
      case CPush.asignacion:
        await _saveToServerAsignaciones(isLocal);
        break;
      case CPush.reasignacion:
        await _saveToServerAsignaciones(isLocal);
        break;
      default:
    } 
  }

  ///
  void updateVersion() {

    final v = DateTime.now().millisecondsSinceEpoch;
    if(!_centinela.containsKey('version')) {
      _centinela.putIfAbsent('version', () => v);
    }else{
      _centinela['version'] = v;
    }
  }

  /// Tomamos la seccion AVO la cual nos indica las ordenes asignadas a los avos
  Map<String, dynamic> getAsignaciones() {

    if(_centinela.containsKey('avo')) {
      return Map<String, dynamic>.from(_centinela['avo']);
    }
    return {};
  }

  ///
  String getCantOrdenesDelAvo(int idAvo, {int recientes = 0}) {

    int suma = recientes;
    if(_centinela.isNotEmpty) {
      if(_centinela.containsKey('avo')) {
        if(_centinela['avo'].containsKey('$idAvo')) {
          suma = _centinela['avo']['$idAvo'].length + recientes;
        }
      }
    }
    return '$suma';
  }

  /// ana
  String getCantDePiezasDelAvo(int idAvo) {

    int cantT = 0;

    if(_centinela.isNotEmpty) {
      if(_centinela.containsKey('avo')) {
        if(_centinela['avo'].containsKey('$idAvo')) {
          for (var i = 0; i < _centinela['avo']['$idAvo'].length; i++) {
            if(_centinela['piezas'].containsKey('${ _centinela['avo']['$idAvo'][i] }')) {
              final lst = List.from(_centinela['piezas'][ '${_centinela['avo']['$idAvo'][i]}' ]);
              cantT = cantT + (lst.length);
            }
          }
        }
      }
    }
    
    return '$cantT';
  }

  /// dame el AVO de la orden seleccionada
  int getAvoOrdenSelected(int idOrden) {

    int idAvo = 0;
    if(_centinela.isNotEmpty) {
      if(_centinela.containsKey('avo')) {
        final avosOld = Map<String, dynamic>.from(_centinela['avo']);
        avosOld.forEach((key, value) {
          if(value.contains(idOrden)) {
            idAvo = int.tryParse(key) ?? 0;
          }
        });
      }
    }
    return idAvo;
  }

  /// Guardamos los cambios de asignacion
  Future<void> _persistAsignacion(Map<int, List<int>> asignaciones) async {

    if(!_centinela.containsKey('avo')){
      _centinela.putIfAbsent('avo', () => <String, List<String>>{});
    }

    asignaciones.forEach((idAvo, ordenes) async {
      if(ordenes.isNotEmpty) {

        if(!_centinela['avo'].containsKey('$idAvo')) {
          _centinela['avo'].putIfAbsent('$idAvo', () => <String>[]);
        }
        
        for (var i = 0; i < ordenes.length; i++) {
          if(!_centinela['avo']['$idAvo'].contains('${ordenes[i]}')) {
            _centinela['avo']['$idAvo'].add('${ordenes[i]}');
          }
        }

        var non = List<String>.from(_centinela['non']);
        for (var i = 0; i < ordenes.length; i++) {
          if(non.contains('${ordenes[i]}')) {
            non.remove('${ordenes[i]}');
          }
        }
        _centinela['non'] = non;
      }
    });
  }

  /// Guardamos los cambios en base a una reasignacion
  /// El parametro avoOrden contiene una lista de 2 enteros 1. el avo 2. la orden
  Future<void> _persistReasignacion(List<int> avoOrden) async {

    if(!_centinela.containsKey('avo')){
      _centinela.putIfAbsent('avo', () => <String, dynamic>{});
    }
    String idAvoOwn = '';
    List<String> newOrdenesOwn = [];
    _centinela['avo'].forEach((idAvo, ordenes) async {
      
      if(ordenes.isNotEmpty) {
        ordenes = List<String>.from(ordenes);
      }
      if(ordenes.contains('${avoOrden.last}')) {
        idAvoOwn = idAvo;
        bool make = ordenes.remove('${avoOrden.last}');
        if(make) {
          newOrdenesOwn = ordenes;
        }
      }
    });

    if(idAvoOwn.isNotEmpty) {
      _centinela['avo'][idAvoOwn] = newOrdenesOwn;
      _centinela['avo']['${avoOrden.first}'].insert(0, '${avoOrden.last}');
    }
  }

  ///
  Future<void> _saveToServerAsignaciones(bool isLocal) async {

    var asig = getAsignaciones();
    String pathTo = await GetPaths.getUri('ordenes_asignadas', isLocal: isLocal);
    await MyHttp.post(pathTo, {'info':asig, 'isLoc': isLocal, 'version':_centinela['version']});
    
    result = MyHttp.result;
    MyHttp.clean();
  }


}