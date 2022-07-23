import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart' show BuildContext;
import 'package:provider/provider.dart';

import '../entity/contacto_entity.dart';
import '../providers/centinela_file_provider.dart';
import '../services/get_paths.dart';
import '../services/my_http.dart';

class SocketCentinela {

  CentinelaFileProvider? _centiProv;

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

    final centi = await getContentFile();
    if(centi.isNotEmpty) {
      if(_centiProv != null) {
        _centiProv!.centinela = centi;
      }else{
        return centi;
      }
    }else{
      return await getFromApiHarbi(ipHarbi);
    }
    return {};
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
      }else{
        return content;
      }
    }
    return {};
  }

  /// Revisamos si hay cambios relacionados al usuario que esta usando esta SCP
  /// centi son los datos del nuevo centinela el user es el que usa esta app.
  Future<Map<String, dynamic>> buildManifest(String ipHarbi, ContactoEntity user) async {

    final oldCenti = await getContentFile();
    final centi = await getFromApiHarbi(ipHarbi);
    if(centi.isEmpty){ return {}; }
    
    String role = '';
    String msg = '';
    final t = DateTime.now();
    final created = '[${t.day}-${t.month}-${t.year}  ${t.hour}-${t.minute}-${t.second}]';
    Map<String, dynamic> manifest = {
      'created': created,
      'ver'    : '0',
      'cambios': <String>[],
    };

    bool save = false;
    role= 'ROLE_ADMIN';
    msg = 'Nueva Orden de Cotización [I]';

    // Analizamos si hay nuevas ordenes.
    if(user.roles.contains(role)) {

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
    }

    // Analizamos si hay nuevas asignaciones.
    if(centi.containsKey('avo')) {
      save = false;
      role = 'ROLE_AVO';
      msg = 'Cuentas con ordenes Asignadas [I]';
      
      if(user.roles.contains(role)) {

        if(oldCenti.containsKey('avo')) {

          if(centi['avo'].containsKey('${user.id}')) {

            // si el viejo centinela no contiene mi ID, es que me asignaron nueva orden 
            if(!oldCenti['avo'].containsKey('${user.id}')) {
              save = true;
            }else{
              
              final asigns = List<String>.from(centi['avo']['${user.id}']);
              for (var i = 0; i < asigns.length; i++) {
                // Revisamos cada orden nueva para ver si hay algo nuevo
                if(!oldCenti['avo']['${user.id}'].contains(asigns[i])) {
                  save = true;
                  break;
                }
              }

              // Si save sigue siendo false y las ordenes son diferentes es que
              // me quitaron algunas.
              if(!save && oldCenti['avo']['${user.id}'].length > asigns.length) {
                msg = 'Se han Reasignado orden(es) [IN]';
                save = true;
              }
            }
          }

        }else{
          if(centi['avo'].containsKey('${user.id}')) { save = true; }
        }

        if(save) {
          manifest['ver'] = centi['version'];
          manifest['cambios'].add(msg);
        }
      }
    }
    
    return (manifest['ver'] == '0') ? {} : manifest;
  }

}