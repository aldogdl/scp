import 'dart:convert';
import 'dart:io';

import 'package:scp/src/entity/piezas_entity.dart';

import '../entity/orden_entity.dart';
import '../services/get_paths.dart';
import '../services/my_http.dart';
import 'piezas_repository.dart';

class OrdenesRepository {

  final String myAsigns = 'my_asigns';
  final _piezaEm = PiezasRepository();
  Map<String, dynamic> result = {'abort':false, 'msg': 'ok', 'body':{}};

  ///
  void clear() {
    result = {'abort':false, 'msg': 'ok', 'body':{}};
  }

  ///
  Future<void> getOrdenById(int id, {bool isLocal = true}) async {

    String uri = await GetPaths.getUri('get_orden_by_id', isLocal: isLocal);
    await MyHttp.get('$uri$id/');
    result = Map<String, dynamic>.from(MyHttp.result);
    MyHttp.clean();
  }

  ///
  Future<void> editarDataPieza(Map<String, dynamic> data, {bool isLocal = true}) async {

    String uri = await GetPaths.getUri('editar_data_pieza', isLocal: isLocal);
    await MyHttp.post(uri, data);
    result = MyHttp.result;
  }

  /// Cambiar el nuevo status en el Servidor remoto asi como el archivo Centinela
  Future<void> changeSttToServers(Map<String, dynamic> data) async {
    
    String uriLoc = await GetPaths.getUri('change_stt_to_orden', isLocal: true);
    String uriRem = await GetPaths.getUri('change_stt_to_orden', isLocal: false);
    MyHttp.post(uriRem, data);
    await MyHttp.post(uriLoc, data);
  }

  /// Cambiar el nuevo status en el Servidor remoto asi como el archivo Centinela
  Future<void> changeStatusToServer(Map<String, dynamic> data, {bool isLocal = true}) async {
    
    String uri = await GetPaths.getUri('change_stt_to_orden', isLocal: isLocal);
    await MyHttp.post(uri, data);
    result = MyHttp.result;
  }

  ///
  String getPathToAsigns() {

    String root = GetPaths.getPathRoot();
    final dir = Directory('$root/$myAsigns');
    if(!dir.existsSync()) {
      dir.createSync();
    }
    return dir.path;
  }

  /// Recuperamos todas las ordenes del avo desde el servidor
  Future<void> getAllOrdenesByAvoFromServer(int avo, {bool isLocal = true}) async {

    String uri = await GetPaths.getUri('get_ordenes_by_avo', isLocal: isLocal);
    await MyHttp.get('$uri$avo/');
    result = MyHttp.result;
  }

  /// Recuperamos todas las ordenes del avo desde los archivos
  Future<List<Map<String, dynamic>>> getAllOrdenesByAvo(int avo, {String? est}) async {

    List<Map<String, dynamic>> ordenes = [];

    String root = GetPaths.getPathRoot();
    final dir = Directory('$root/$myAsigns');
    if(dir.existsSync()) {

      dir.listSync().map((filename) {

        if(filename.path.endsWith('$avo.json')) {
          final file = File(filename.path);
          final cnt  = Map<String, dynamic>.from(json.decode(file.readAsStringSync()));
          if(est != null) {
            // entra si Requiere un filtro de estacion
            if(cnt[OrdCamp.orden.name]['o_est'] == est) {
              ordenes.add(cnt);
            }
          }else{
            ordenes.add(cnt);
          }
        }

      }).toList();
    }

    return ordenes;
  }

  ///
  Future<void> delOrdenAsignadas(List<String> ordDelete, int idUser) async {

    final dir = getPathToAsigns();
    for (var i = 0; i < ordDelete.length; i++) {

      final file = File('$dir/${ordDelete[i]}-$idUser.json');
      if(file.existsSync()) {
        file.deleteSync();
      }
    }
  }

  ///
  Future<void> setOrdenAsignadas(List<String> ordAsign, int idUser) async {

    final dir = getPathToAsigns();

    for (var i = 0; i < ordAsign.length; i++) {

      await getOrdenById(int.parse(ordAsign[i]));
      if(!result['abort']) {

        OrdenEntity ent = OrdenEntity();
        ent.fromServer(result['body']);
        clear();

        List<Map<String, dynamic>> pzas = [];
        await _piezaEm.getPiezasByOrden(ent.id);
        if(!_piezaEm.result['abort']) {

          PiezasEntity pza = PiezasEntity();
          for (var i = 0; i < _piezaEm.result['body'].length; i++) {
            pza.fromServer(_piezaEm.result['body'][i]);
            pzas.add(pza.toJson());
          }
        }
        Map<String, dynamic> content = buildMapFileOrden(
          emisor: ent.uId, orden: ent.toJson(), pzas: pzas
        );

        final file = File('$dir/${ent.id}-$idUser.json');
        if(!file.existsSync()) {
          file.createSync();
        }
        file.writeAsStringSync(json.encode(content));
      }
    }

  }

  ///
  Map<String, dynamic> buildMapFileOrden({
    required Map<String, dynamic> orden, required int emisor,
    required List<Map<String, dynamic>> pzas, bool isVista = false,
    List<Map<String, dynamic>> resps = const [],
    List<Map<String, dynamic>> respToSolz = const [],
  }) {

    return {
      OrdCamp.emisor.name: emisor, OrdCamp.orden.name: orden,
      OrdCamp.piezas.name: pzas, OrdCamp.resps.name: resps,
      OrdCamp.respToSolz.name: respToSolz
    };
  }

}