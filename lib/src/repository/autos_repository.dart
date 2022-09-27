import 'dart:convert';
import 'dart:io';

import 'package:scp/src/entity/marcas_entity.dart';
import 'package:scp/src/entity/modelos_entity.dart';
import 'package:scp/src/services/get_paths.dart';

import '../services/my_http.dart';
import '../services/scranet/get_paths_scranet.dart';

class AutosRepository {

  Map<String, dynamic> result = {};
  void cleanResult() {
    result = {'abort': false, 'msg': 'ok', 'body': []};
    MyHttp.clean();
  }

  /// Recuperamos todas las marcas 
  Future<List<MarcasEntity>> getMarcasFromFile() async {

    List<MarcasEntity> marcas = [];
    final autosP = await GetPaths.getFileByPath('autos');
    if(autosP.isNotEmpty) {
      File? autos = File(autosP);
      if(autos.existsSync()) {
        var m = autos.readAsStringSync();
        if(m.isNotEmpty) {
          final data = List<Map<String, dynamic>>.from(json.decode(m));
          if(data.isNotEmpty) {
            for (var i = 0; i < data.length; i++) {
              data[i].remove('modelos');
              final e = MarcasEntity();
              e.fromFileAuto(data[i]);
              marcas.add(e);
            }
          }
        }
        autos = null;
        m = '';
      }
    }

    return marcas;
  }

  /// Recuperamos todos los modelos
  Future<List<ModelosEntity>> getModelosFromFile(MarcasEntity marca) async {

    List<ModelosEntity> modelos = [];
    final autosP = await GetPaths.getFileByPath('autos');

    if(autosP.isNotEmpty) {
      File? autos = File(autosP);
      if(autos.existsSync()) {
        var m = autos.readAsStringSync();
        if(m.isNotEmpty) {
          var data = List<Map<String, dynamic>>.from(json.decode(m));
          if(data.isNotEmpty) {
            int idMrk = marca.id;
            idMrk = (idMrk == 0) ? 1 : idMrk;
            final fetch = data.where((element) => element['id'] == idMrk).toList();

            if(fetch.isNotEmpty) {
              data = List<Map<String, dynamic>>.from(fetch.first['modelos']);
              for (var i = 0; i < data.length; i++) {
                final e = ModelosEntity();
                e.fromFileAuto(data[i], idMrk);
                modelos.add(e);
              }
            }
          }
        }
        autos = null;
        m = '';
      }
    }

    return modelos;
  }

  ///
  Future<List<Map<String, dynamic>>> getMarcasAutoparnet() async {

    final uri = GetPathScranet.getUri('get_marcas', isLocal: false);
    
    await MyHttp.get(uri);
    if(!MyHttp.result['abort']) {
      return List<Map<String, dynamic>>.from(MyHttp.result['body']);
    }
    return [];
  }

  ///
  Future<List<Map<String, dynamic>>> getModelosByIdMarca(int idMrk) async {

    final uri = GetPathScranet.getUri('get_modelos_by_idmrk', isLocal: false);

    await MyHttp.get('$uri$idMrk/');
    if(!MyHttp.result['abort']) {
      if(MyHttp.result['body'].isNotEmpty) {
        return List<Map<String, dynamic>>.from(MyHttp.result['body']);
      }
    }
    return [];
  }

  /// Agregamos o editamos la marca.
  /// Este metodo se basa en el Id de la marca si es 0 significa que hay que ADD.
  Future<void> editMarca(Map<String, dynamic> marca, {bool isLocal = true}) async {
    
    final uri = GetPathScranet.getUri('set_marca', isLocal: isLocal);
    await MyHttp.post(uri, marca);
    result = MyHttp.result;
  }

  /// Agregamos o editamos el Modelo.
  /// Este metodo se basa en el Id del modelo si es 0 significa que hay que ADD.
  Future<void> editModelo(Map<String, dynamic> modelo, {bool isLocal = true}) async {
    
    final uri = GetPathScranet.getUri('set_modelo', isLocal: isLocal);
    await MyHttp.post(uri, modelo);
    result = MyHttp.result;
  }

  ///
  Future<void> delMarca(Map<String, dynamic> marca, {bool isLocal = true}) async {

    // final uri = GetPathScranet.getUri('set_marca', isLocal: isLocal);
    
    // await MyHttp.get(uri);
    // result = MyHttp.result['abort'];
  }
}