import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart' show BuildContext;
import 'package:provider/provider.dart';

import 'ordenes_repository.dart';
import '../entity/contacto_entity.dart';
import '../providers/centinela_file_provider.dart';
import '../services/get_paths.dart';
import '../services/my_http.dart';

class SocketCentinela {

  final _ordenEm = OrdenesRepository();

  CentinelaFileProvider? _centiProv;

  ///
  Map<String, dynamic> getContenCentinela() {

    if(_centiProv != null) {
      return _centiProv!.centinela;
    }
    return {};
  }

  void init(BuildContext context) {
    _centiProv = context.read<CentinelaFileProvider>();
  }

  /// ->Obtenemos los datos del centinela desde el arcivo.
  Future<Map<String, dynamic>> getContentFile() async {

    String pathTo = await GetPaths.getFileByPath('centinela');
    File centi = File(pathTo);
    if(centi.existsSync()) {
      return Map<String, dynamic>.from( json.decode(centi.readAsStringSync()) );
    }
    return {};
  }

  /// ->Obtenemos los datos del centinela desde el arcivo.
  Future<Map<String, dynamic>> getFromFile(String ipHarbi) async {

    Map<String, dynamic> centi = await getContentFile();
    if(centi.isEmpty) {
      centi = await getFromApiHarbi(ipHarbi);
    }else{
      if(centi.isNotEmpty) {
        if(_centiProv != null) {
          _centiProv!.centinela = centi;
        }
      }
    }
    return centi;
  }

  ///
  Future<Map<String, dynamic>> getFromApiHarbi(String ipHarbi) async {

    String uri = await GetPaths.getApiHarbi('get_centinela', ipHarbi);
    await MyHttp.get(uri);
    if(!MyHttp.result['abort']) {

      final content = Map<String, dynamic>.from(MyHttp.result['body']);

      String pathTo = await GetPaths.getFileByPath('centinela');
      File centi = File(pathTo);
      centi.writeAsStringSync(json.encode(content));
      if(_centiProv != null) {
        _centiProv!.centinela = content;
      }
      return content;
    }
    return {};
  }

  /// Revisamos si hay cambios relacionados al usuario que esta usando esta SCP
  /// centi son los datos del nuevo centinela el user es el que usa esta app.
  Future<Map<String, dynamic>> buildManifest(String ipHarbi, ContactoEntity user) async {

    final oldCenti = await getContentFile();
    final centi = await getFromApiHarbi(ipHarbi);
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

          manifest = await _checkOnlyAvo(
            user.id, manifest, asignsOlds, asignsNuevas
          );
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
    Map<String, dynamic> manifest
  ) async {

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
    int idUser, Map<String, dynamic> manifest,
    List<String> asignsOlds, List<String> asignsNuevas
  ) async {

    List<String> ordAsign = [];
    List<String> ordDelete = [];
    
    bool save = false;
    String msg = 'Cuentas con ordenes Asignadas [IN]';

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

    msg = 'Se han Reasignado orden(es) [NT]';
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

    if(save) {

      if(ordAsign.isNotEmpty) {
        await _ordenEm.setOrdenAsignadas(ordAsign, idUser);
      }
      if(ordDelete.isNotEmpty) {
        await _ordenEm.delOrdenAsignadas(ordDelete, idUser);
      }
      manifest['cambios'].add(msg);
    }

    return manifest;
  }

}