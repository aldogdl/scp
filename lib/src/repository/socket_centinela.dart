import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart' show BuildContext;
import 'package:provider/provider.dart';

import '../config/sng_manager.dart';
import '../entity/contacto_entity.dart';
import '../repository/inventario_repository.dart';
import '../providers/centinela_file_provider.dart';
import '../services/get_paths.dart';
import '../services/my_http.dart';
import '../vars/globals.dart';

class SocketCentinela {

  final _globals = getSngOf<Globals>();
  final _invEm = InventarioRepository();
  CentinelaFileProvider? _centiProv;

  ///
  Map<String, dynamic> getContenCentinela() {
    if(_centiProv != null) {
      return _centiProv!.centinela;
    }
    return {};
  }

  ///
  void init(BuildContext context) {
    _centiProv = context.read<CentinelaFileProvider>();
  }

  /// ->Obtenemos los datos del centinela desde el archivo.
  Future<Map<String, dynamic>> getContentFile() async {

    String pathTo = await GetPaths.getFileByPath('centinela');
    File centi = File(pathTo);

    if(centi.existsSync()) {
      return Map<String, dynamic>.from( json.decode(centi.readAsStringSync()) );
    }
    return {};
  }

  /// ->Obtenemos los datos del centinela desde el arcivo.
  Future<Map<String, dynamic>> getFromFile(String currentVersion) async {

    Map<String, dynamic> centi = await getContentFile();
    if(centi.isEmpty) {
      centi = await getFromApiHarbi();
    }else{
      if(centi.containsKey('version')) {
        if('${centi['version']}' != currentVersion) {
          centi = await getFromApiHarbi();
        }
      }
      if(_centiProv != null) {
        _centiProv!.centinela = centi;
      }
    }
    return centi;
  }

  /// Recuperamos el centinela mas actualizado desde harbi.
  Future<Map<String, dynamic>> getFromApiHarbi({bool onlyVersion = false}) async {

    Uri uri = await GetPaths.getUriApiHarbi('get_centinela', '');
    await MyHttp.getHarbi(uri);
    if(!MyHttp.result['abort']) {

      final content = Map<String, dynamic>.from(MyHttp.result['body']);
      String pathTo = await GetPaths.getFileByPath('centinela');
      File centi = File(pathTo);
      centi.writeAsStringSync(json.encode(content));
      if(_centiProv != null) {
        _centiProv!.centinela = content;
      }
      if(onlyVersion) {
        return {'ver': content['version']};
      }
      return content;
    }else{
      if(!onlyVersion) {
        final res = MyHttp.result['body'];
        if(res.contains('El Host')) {
          return MyHttp.result;
        }
      }
    }
    return {};
  }

  ///
  Future<void> delOrdenInCentinela(List<String> ordDelete, int idUser) async {

    final centi = await getContentFile();
    if(centi.isNotEmpty) {
      if(centi.containsKey('avo')) {
        if(centi['avo'].containsKey(idUser)) {
          for (var i = 0; i < ordDelete.length; i++) {
            if(centi['avo'][idUser].containsKey(ordDelete[i])) {
              centi['avo'][idUser].remove(ordDelete[i]);
            }
          }
        }
      }
    }
    if(_centiProv != null) {
      _centiProv!.centinela = centi;
    }
  }

  /// Revisamos si hay asignaciones para el usuario que esta usando esta SCP.
  /// centi son los datos del nuevo centinela.
  Future<Map<String, dynamic>> checkNewAsigns
  ({String from = 'cache', bool onlyCheck = false}) async
  {
    final centi = await getContentFile();
    
    if(centi.isEmpty){ return {}; }

    final user = _globals.user;
    Map<String, dynamic> manifest = {};

    // Analizamos las asignaciones.
    if(user.roles.contains('ROLE_AVO')) {
      if(centi.containsKey('avo')) {
        if(centi['avo'].containsKey('${user.id}')) {

          List<String> asignsNuevas = List<String>.from(centi['avo']['${user.id}']);
          // Recuperamos las ordenes asignadas actuales para comparar
          List<String> asignsOlds = [];
          final aOld = await _invEm.getAllOrdenesByAvo(
            user.id, onlyIdOrden: true, from: from
          );

          if(aOld.isNotEmpty) {
            aOld.map((e) {
              asignsOlds.add(e['id']);
            }).toList();
          }

          manifest = await _checkOnlyAvo(
            asignsOlds, asignsNuevas, onlyCheck: onlyCheck
          );
        }
      }
    }

    return manifest;
  }

  /// Pendiente de analizar para borrar este metodo
  /// 
  /// Revisamos si hay cambios relacionados al usuario que esta usando esta SCP
  /// centi son los datos del nuevo centinela el user es el que usa esta app.
  Future<Map<String, dynamic>> checkCambiosInCentinelaFile(ContactoEntity user) async {

    final oldCenti = await getContentFile();
    final centi = await getFromApiHarbi();
    if(centi.isEmpty){ return {}; }
    
    final t = DateTime.now();
    final created = '[${t.day}-${t.month}-${t.year}  ${t.hour}-${t.minute}-${t.second}]';
    Map<String, dynamic> manifest = {
      'created': created, 'ver' : '0', 'cambios': <String>[],
    };

    // Analizamos si hay nuevas ordenes.
    if(user.roles.contains('ROLE_ADMIN')) {
      manifest = await _checkOnlyAdmin(centi, oldCenti, manifest);
    }

    // Analizamos las asignaciones.
    if(user.roles.contains('ROLE_AVO')) {
      if(centi.containsKey('avo')) {
        if(centi['avo'].containsKey('${user.id}')) {

          List<String> asignsOlds = [];
          if(oldCenti.containsKey('avo')) {
            if(oldCenti['avo'].containsKey('${user.id}')) {
              asignsOlds = List<String>.from(oldCenti['avo']['${user.id}']);
            }
          }

          List<String> asignsNuevas = [];
          if(centi.containsKey('avo')) {
            if(centi['avo'].containsKey('${user.id}')) {
              asignsNuevas = List<String>.from(centi['avo']['${user.id}']);
            }
          }

          // manifest = await _checkOnlyAvo(
          //   user.id, manifest, asignsOlds, asignsNuevas
          // );
        }
      }
    }

    if(manifest['cambios'].isNotEmpty) {
      manifest['ver'] = centi['version'];
    }
    
    return (manifest['ver'] == '0') ? {} : manifest;
  }

  /// parte del analisis de la creacion del manifiesto [ADMIN]
  Future<Map<String, dynamic>> _checkOnlyAdmin(
    Map<String, dynamic> centi, Map<String, dynamic> oldCenti,
    Map<String, dynamic> manifest) async
  {

    bool save = false;
    String msg = 'Nueva Orden de Cotización [IN]';

    if(centi.containsKey('ordenes')) {
      save = true;
      if(oldCenti.isNotEmpty) {
        if(oldCenti.containsKey('ordenes')) {
          if(centi['ordenes'].length <= oldCenti['ordenes'].length) {
            save = false;
          }
        }
      }

      if(save) {
        manifest['ver'] = centi['version'];
        manifest['cambios'].add(msg);
      }
    }

    return manifest;
  }

  /// parte del analisis de la creacion del manifiesto [AVO]
  Future<Map<String, dynamic>> _checkOnlyAvo(
    List<String> asignsOlds, List<String> asignsNuevas, {bool onlyCheck = false}) async 
  {

    List<String> ordAsign = [];
    List<String> ordDelete = [];
    
    bool save = false;
    int idUser = _globals.user.id;

    // Revisamos si hay ordenes que no tenga con anterioridad
    if(asignsNuevas.isNotEmpty) {

      for (var i = 0; i < asignsNuevas.length; i++) {
        if(!asignsOlds.contains(asignsNuevas[i])) {
          ordAsign.add(asignsNuevas[i]);
        }
      }

      if(ordAsign.isNotEmpty) {
        save = true;
      }
    }

    // Revisamos si hay ordenes que han sido desasignadas
    if(asignsOlds.isNotEmpty) {

      for (var i = 0; i < asignsOlds.length; i++) {
        if(!asignsNuevas.contains(asignsOlds[i])) {
          ordDelete.add(asignsOlds[i]);
        }
      }

      if(ordDelete.isNotEmpty) {
        save = true;
      }
    }

    if(save && !onlyCheck) {

      if(ordDelete.isNotEmpty) {
        // TODO Hacer un respaldo hacia harbi, ya que en el archivo de la orden
        // se guardan metricas que seran necesarias para el AVO aquien se le
        // reasigno esta orden.
        await _invEm.delOrdenAsignadas(ordDelete, idUser);
        // manifest['cambios'].add('Se han Reasignado orden(es) [NT]');
      }

      if(ordAsign.isNotEmpty) {
        await _invEm.setOrdenAsignadas(ordAsign, idUser);
        // manifest['cambios'].add('Cuentas con ordenes Asignadas [IN]');
      }
    }
    return {'ordAsign':ordAsign, 'ordDelete':ordDelete};
  }

  ///
  Future<String> setOrdenAsignada(String ordAsignId) async {
    return _invEm.setOrdenAsignada(ordAsignId, _globals.user.id);
  }

  /// Actualizamos las metricas de una orden
  Future<void> updateMetrix(Map<String, dynamic> data) async {

    final query = 'get_metrix_by_orden=${data['id']}:${data['idCamp']}';
    final uri = await GetPaths.getUriApiHarbi('centinela_get', query);

    await MyHttp.getHarbi(uri);
    if(!MyHttp.result['abort']) {
      final res = MyHttp.result['body'];
      if(res.isNotEmpty) {
        final metrix = Map<String, dynamic>.from(json.decode(res));
        await _invEm.updateMetrix(data, metrix);
      }
    }
    
    return;
  }

  /// Actualizamos las metricas de una orden
  Future<List<int>> updateIris(Map<String, dynamic> data) async {

    List<Map<String, dynamic>> irisData = [];
    List<int> irisIds = [];
    if(data.containsKey('iris')) {
      irisData = List<Map<String, dynamic>>.from(data['iris']);
    }else{
      if(data.containsKey('id')) {
        if(data['id'].toString().endsWith('rsp')) {
          // Se trata de una notificacion de respuesta
          irisData.add(data);
        }
      }
    }

    if(irisData.isEmpty){ return []; }

    for (var i = 0; i < irisData.length; i++) {
      
      final query = 'get_iris_by_orden=${irisData[i]['idOrd']}';
      final uri = await GetPaths.getUriApiHarbi('centinela_get', query);
      await MyHttp.getHarbi(uri);
      
      if(!MyHttp.result['abort']) {
        final res = MyHttp.result['body'];
        if(res.isNotEmpty) {
          final iris = Map<String, dynamic>.from(json.decode(res));
          int? idO = int.tryParse('${irisData[i]['idOrd']}');
          if(idO != null) {
            if(!irisIds.contains(idO)) {
              irisIds.add(idO);
            }
          }
          await _invEm.updateIris(irisData[i], iris);
        }
      }
    }

    return irisIds;
  }

  /// Enviamos un push a harbi
  Future<Map<String, dynamic>> sendPushToHarbi(String uri, String query) async {

    Uri url = await GetPaths.getUriApiHarbi(uri, query);
    await MyHttp.getHarbi(url);
    return MyHttp.result;
  }

  ///
  Future<List<String>> getIdsMyPiezas() async {

    List<dynamic> idsF = [];
    // Recuperar los ids de todas las piezas que tengo
    Map<String, dynamic> centinela = getContenCentinela();
    if(centinela.isEmpty) {
      centinela = await getContentFile();
    }

    if(centinela.isNotEmpty) {
      int idAvo = _globals.user.id;
      if(idAvo != 0) {
        if(centinela.containsKey('avo')) {
          if(centinela['avo'].containsKey('$idAvo')) {
            for (var i = 0; i < centinela['avo']['$idAvo'].length; i++) {

              if(centinela['piezas'].containsKey('${ centinela['avo']['$idAvo'][i] }')) {
                final lst = List.from(
                  centinela['piezas'][ '${centinela['avo']['$idAvo'][i]}' ]
                );
                idsF.addAll(lst);
              }
            }
          }
        }
      }
    }

    List<int> ids = [];
    if (idsF.isNotEmpty) {
      idsF.map((e) {
        if(!ids.contains(e)) {
          ids.add(int.parse('$e'));
        }
      }).toList();
    }
    ids.sort();
    return ids.map((e) => e.toString()).toList();
  }
}