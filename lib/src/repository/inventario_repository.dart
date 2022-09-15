import 'dart:io';
import 'dart:convert';

import 'package:scp/src/services/my_http.dart';

import 'ordenes_repository.dart';
import 'piezas_repository.dart';
import '../config/sng_manager.dart';
import '../entity/orden_entity.dart';
import '../entity/piezas_entity.dart';
import '../services/get_paths.dart';
import '../vars/ordenes_cache.dart';

enum Mtrik { pzas, scmEst, cotz, see, cam, rsp, cnt, cron }

class InventarioRepository {

  final int conteo = 30;
  final String myAsigns = 'my_asigns';
  final _piezaEm= PiezasRepository();
  final _ordEm  = OrdenesRepository();
  final _oCache = getSngOf<OrdenesCache>();

  List<Map<String, dynamic>> get oCache => _oCache.ordenes;
  int get totPzas => _oCache.totPzas;
  
  Map<String, dynamic> result = {'abort':false, 'msg': 'ok', 'body':{}};
  ///
  void clear() {
    result = {'abort':false, 'msg': 'ok', 'body':{}};
  }

  ///
  void cleanOrdenes() {
    _oCache.ordenes.clear();
    _oCache.totPzas = 0;
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

  ///
  Future<void> setOrdenesEnCache({
    required int byAvo,
    required String est
  }) async => _oCache.ordenes = await getAllOrdenesByAvo(byAvo, est: est, from: 'file');

  /// Si tipo = cache, buscamos en cache, si no estan, buscamos en archivos
  Future<List<Map<String, dynamic>>> recoveryOrdenesFromFile(String tipo) async {

    List<Map<String, dynamic>> ordenes = [];
    if(tipo == 'cache') {
      if(_oCache.ordenes.isNotEmpty) {
        ordenes = _oCache.ordenes;
      }
    }

    if(ordenes.isEmpty) {

      String root = GetPaths.getPathRoot();
      final dir = Directory('$root/$myAsigns');
      if(dir.existsSync()) {

        dir.listSync().map((filename) {

          final file = File(filename.path);
          final cnt  = Map<String, dynamic>.from(json.decode(file.readAsStringSync()));
          if(cnt.isNotEmpty) {

              // colocamos el nombre del archivo en caso de no contar con el
            if(!cnt.containsKey(OrdCamp.filename.name)) {
              cnt[OrdCamp.filename.name] = filename.uri.pathSegments.last;
              file.writeAsStringSync(json.encode(cnt));
            }

            final pzasTotal = List<Map<String, dynamic>>.from(cnt[OrdCamp.piezas.name]);
            _oCache.totPzas = _oCache.totPzas + pzasTotal.length;
            ordenes.add(cnt);
          }
        }).toList();
      }
    }

    return ordenes;
  }

  /// Recuperamos todas las ordenes del avo desde los archivos
  Future<List<Map<String, dynamic>>> getAllOrdenesByAvo
    (int avo, { String? est, bool onlyFile = false, String from = 'cache' }) async
  {
    
    List<Map<String, dynamic>> ordenes = await recoveryOrdenesFromFile(from);
    List<Map<String, dynamic>> resultados = [];

    if(ordenes.isNotEmpty) {

      for (var i = 0; i < ordenes.length; i++) {

        bool meter = true;
        if(ordenes[i][OrdCamp.filename.name].endsWith('$avo.json')) {

          if(est != null) {
            // entra si Requiere un filtro de estacion
            if(ordenes[i][OrdCamp.orden.name]['o_est'] != est) {
              meter = false;
            }
          }

          if(meter) {
            if(onlyFile) {
              final has = resultados.firstWhere(
                (el) => el['filename'] == ordenes[i][OrdCamp.filename.name],
                orElse: () => {}
              );
              if(has.isEmpty) {
                resultados.add({'filename': ordenes[i][OrdCamp.filename.name]});
              }
            }else{
              final has = resultados.firstWhere(
                (el) => el['filename'] == ordenes[i][OrdCamp.filename.name],
                orElse: () => {}
              );
              if(has.isEmpty) {
                resultados.add(ordenes[i]);
              }
            }
          }
        }
      }
    }

    ordenes = [];
    _oCache.ordenes = resultados;
    return resultados;
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
  Future<void> delCacheIfExist(List<String> ordDelete, int idUser) async {

    if(_oCache.ordenes.isNotEmpty) {
      
      for (var i = 0; i < ordDelete.length; i++) {
        final inx = _oCache.ordenes.indexWhere(
          (c) => '${c[OrdCamp.orden.name]}' == ordDelete[i]
        );
        if(inx != -1) {
          _oCache.ordenes.removeAt(inx);
        }
      }
    }
  }

  ///
  Future<void> setInCacheIfAbsent(List<String> ordToAdd, int idUser) async {

    if(_oCache.ordenes.isNotEmpty) {
      
      for (var i = 0; i < ordToAdd.length; i++) {

        final filename = '${ordToAdd[i]}-$idUser.json';
        final content = await getContentFile(filename);
        if(content.isNotEmpty) {
          final existe = _oCache.ordenes.indexWhere((e) => e['filename'] == filename);
          if(existe != -1) {
            _oCache.ordenes[existe] = content;
          }else{
            _oCache.ordenes.add(content);
          }
        }
      }
    }
  }

  ///
  Future<Map<String, dynamic>> getMetriksFromFile
    (String filename, {int perIdPza = 0}) async
  {

    Map<String, dynamic> metrix = {};
    Map<String, dynamic> content= {};

    if(oCache.isNotEmpty) {
      final ordC = oCache.where(
        (ords) => ords[OrdCamp.filename.name] == filename
      ).toList();
      if(ordC.isNotEmpty) {
        content = ordC.first;
      }
    }
    
    if(content.isEmpty) {
      content = await getContentFile(filename);
    }
    
    if(!content.containsKey(OrdCamp.metrik.name)) {
      content[OrdCamp.metrik.name] = _schemaMetrica();
    }
    
    // Revisamos algunas metricas.
    final pzas = content[OrdCamp.piezas.name].length;
    int resp = content[OrdCamp.resps.name].length;

    if(perIdPza != 0 && resp > 0) {
      final lstR = List<Map<String, dynamic>>.from(content[OrdCamp.resps.name]);
      final cant = lstR.where((element) => element['p_id'] == perIdPza);
      resp = cant.length;
    }

    if(perIdPza != 0) {
      // Retornamos si el la metrica es por cada pieza.
      metrix = Map<String, dynamic>.from(content[OrdCamp.metrik.name]);
      metrix['idOrden'] = content[OrdCamp.orden.name]['o_id'];

      return metrix;
    }

    bool save = false;
    if(pzas != content[OrdCamp.metrik.name][Mtrik.pzas.name]) {
      save = true;
      content[OrdCamp.metrik.name][Mtrik.pzas.name] = pzas;
    }
    if(perIdPza != 0) {
      content[OrdCamp.metrik.name][Mtrik.rsp.name] = resp;
    }else{
      if(resp != content[OrdCamp.metrik.name][Mtrik.rsp.name]) {
        save = true;
        content[OrdCamp.metrik.name][Mtrik.rsp.name] = resp;
      }
    }

    if(save) { await setContentFile('getMetriksFromFile', filename, content); }

    metrix = Map<String, dynamic>.from(content[OrdCamp.metrik.name]);
    metrix['idOrden'] = content[OrdCamp.orden.name]['o_id'];

    return metrix;
  }

  ///
  Future<Map<String, dynamic>> getContentFile(String filename) async {

    final dir = getPathToAsigns();
    final file = File('$dir/$filename');
    bool save = false;
    if(file.existsSync()) {
      var content = Map<String, dynamic>.from(json.decode(file.readAsStringSync()));
      if(!content.containsKey(OrdCamp.metrik.name)) {
        Map<String, dynamic> m = _schemaMetrica();
        m[Mtrik.pzas.name] = content[OrdCamp.piezas.name].length;
        content[OrdCamp.metrik.name] = m;
        save = true;
      }
      if(save) {
        file.writeAsStringSync(json.encode(content));
      }
      return content;
    }
    return {};
  }

  /// El from solo es para depurar, y saber desde donde es llamada esta funcion.
  Future<void> setContentFile(String from, String filename, Map<String, dynamic> content) async {

    final dir = getPathToAsigns();
    final file = File('$dir/$filename');
    if(file.existsSync()) {
      file.writeAsStringSync(json.encode(content));
    }
  }

  /// Descargamos desde el servidor local las ordenes y guardamos en archivos.
  Future<void> setOrdenAsignadas(List<String> ordAsign, int idUser) async {

    final dir = getPathToAsigns();

    _ordEm.result.clear();
    for (var i = 0; i < ordAsign.length; i++) {

      await _ordEm.getOrdenById(int.parse(ordAsign[i]));

      if(!_ordEm.result['abort']) {

        if(_ordEm.result['body'].isNotEmpty) {
          
          OrdenEntity ent = OrdenEntity();
          ent.fromServer(_ordEm.result['body']);
          _ordEm.clear();

          List<Map<String, dynamic>> pzas = [];
          await _piezaEm.getPiezasByOrden(ent.id);
          if(!_piezaEm.result['abort']) {

            PiezasEntity pza = PiezasEntity();
            for (var i = 0; i < _piezaEm.result['body'].length; i++) {
              pza.fromServer(_piezaEm.result['body'][i]);
              pzas.add(pza.toJson());
            }
          }
          _piezaEm.clear();
          final filename = '${ent.id}-$idUser.json';
          Map<String, dynamic> content = buildMapFileOrden(
            emisor: ent.uId, orden: ent.toJson(), pzas: pzas, filename: filename
          );

          final file = File('$dir/$filename');
          if(!file.existsSync()) {
            file.createSync();
          }
          
          file.writeAsStringSync(json.encode(content));
        }
      }
    }

  }

  ///
  Future<void> getRespuestasByIds(List<String> idsResp) async {

    String uri = await GetPaths.getUri('get_resp_por_ids', isLocal: true);
    await MyHttp.get('$uri${idsResp.join(',')}/');
    result = MyHttp.result;
    MyHttp.clean();
  }

  /// Guardamos las respuestas en su respetivo archivo
  Future<void> setRespuestasByPieza(List<Map<String, dynamic>> resps) async {

    if(resps.isNotEmpty) {

      Map<int, Map<String, dynamic>> sortResp = {};
      List<int> ordenes = [];
      
      // Organizar las respuestas nuevas en sus respectivas ordenes.
      for (var i = 0; i < resps.length; i++) {

        final ord = resps[i]['o_id'];
        Map<String, dynamic> item = {
          'filename': '$ord-${resps[i]['a_id']}.json',
          'resps' : resps.where((element) => element['o_id'] == ord).toList()
        };
        
        if(sortResp.containsKey(ord)) {
          sortResp[ord] = item;
        }else{
          sortResp.putIfAbsent(ord, () => item);
        }
        if(!ordenes.contains(ord)) {
          ordenes.add(ord);
        }
      }
      
      if(ordenes.isNotEmpty) {

        for (var i = 0; i < ordenes.length; i++) {
          
          final ordFile = await getContentFile(sortResp[ordenes[i]]!['filename']);

          final respOldis = List<Map<String, dynamic>>.from(ordFile[OrdCamp.resps.name]);
          List<Map<String, dynamic>> respNews = [];
          List<Map<String, dynamic>> respToAdd = [];
          respNews.addAll(List<Map<String, dynamic>>.from(sortResp[ordenes[i]]!['resps']));

          if(ordFile.containsKey(OrdCamp.metrik.name)) {
            ordFile[OrdCamp.metrik.name][Mtrik.rsp.name] = respNews.length;
          }

          if(respOldis.isNotEmpty) {

            respToAdd.addAll(respOldis);
            for (var a = 0; a < respNews.length; a++) {

              final index = respToAdd.indexWhere((element) => element['r_id'] == respNews[a]['r_id']);
              if(index == -1) {
                respToAdd.add(respNews[a]);
              }
            }

          }else{
            respToAdd.addAll(respNews);
          }

          ordFile[OrdCamp.resps.name] = respToAdd;

          await setContentFile('setRespuestasByPieza', sortResp[ordenes[i]]!['filename'], ordFile);
          respNews = []; respToAdd = [];
        }

      }
    }
  }

  /// Guardamos la respuesta obtenida por medio del query en su respetivo archivo
  Future<void> setRespuestaToFile(List<Map<String, dynamic>> resps) async {

    if(resps.isNotEmpty) {

      Map<int, Map<String, dynamic>> sortResp = {};
      List<int> ordenes = [];
      // Organizar las respuestas nuevas en sus respectivas ordenes.
      for (var i = 0; i < resps.length; i++) {

        final ord = resps[i]['o_id'];

        Map<String, dynamic> item = {
          'filename': '$ord-${resps[i]['a_id']}.json',
          'resps' : resps.where((element) => element['o_id'] == ord).toList()
        };

        if(sortResp.containsKey(ord)) {
          sortResp[ord] = item;
        }else{
          sortResp.putIfAbsent(ord, () => item);
        }

        if(!ordenes.contains(ord)) {
          ordenes.add(ord);
        }
      }

      if(ordenes.isNotEmpty) {

        for (var i = 0; i < ordenes.length; i++) {

          final ordFile = await getContentFile(sortResp[ordenes[i]]!['filename']);
          List<Map<String, dynamic>> respsAlls = [];
          if(ordFile.containsKey(OrdCamp.resps.name)) {
            respsAlls.addAll(List<Map<String, dynamic>>.from(
              ordFile[OrdCamp.resps.name]
            ));
          }

          respsAlls.addAll(List<Map<String, dynamic>>.from(sortResp[ordenes[i]]!['resps']));

          if(ordFile.containsKey(OrdCamp.metrik.name)) {
            ordFile[OrdCamp.metrik.name][Mtrik.rsp.name] = respsAlls.length;
          }
          ordFile[OrdCamp.resps.name] = respsAlls;
          int indx  = oCache.indexWhere(
            (element) => element['filename'] == sortResp[ordenes[i]]!['filename']
          );
          if(indx != -1) {
            oCache[indx] = ordFile;
          }
          await setContentFile('setRespuestaToFile', sortResp[ordenes[i]]!['filename'], ordFile);
        }
      }
    }
  }

  ///
  Future<Map<String, dynamic>> getOrdenMapTile(String filename, {bool metrik = false}) async {

    Map<String, dynamic> elMap = {};
    if(oCache.isNotEmpty) {
      final ordC = oCache.where(
        (ords) => ords[OrdCamp.filename.name] == filename
      ).toList();
      if(ordC.isNotEmpty) {
        elMap = ordC.first;
      }
    }

    if(elMap.isEmpty) {
      elMap = await getContentFile(filename);
    }
    
    if(elMap.isNotEmpty) {
      var resultado = {
        'id':elMap[OrdCamp.orden.name]['o_id'],
        'mod': elMap[OrdCamp.orden.name]['md_nombre'],
        'mrk': elMap[OrdCamp.orden.name]['mk_nombre'],
        'anio': elMap[OrdCamp.orden.name]['o_anio'],
        'nPzas': elMap[OrdCamp.metrik.name][Mtrik.pzas.name],
        'sol': elMap[OrdCamp.orden.name]['e_nombre'],
        'solNom': elMap[OrdCamp.orden.name]['u_nombre'],
        'solId': elMap[OrdCamp.orden.name]['u_id'],
        'created': elMap[OrdCamp.orden.name]['o_createdAt'],
        'file': elMap[OrdCamp.filename.name]
      };
      if(metrik) {
        resultado['metrik'] = elMap[OrdCamp.metrik.name];
        var items = List<Map<String, dynamic>>.from(elMap[OrdCamp.resps.name]);
        resultado['metrik']['rsp'] = items.length;
        items = [];
      }
      elMap = {};
      return resultado;
    }else{
      elMap = {};
      return schemaBandeja();
    }
  }

  /// Cambiamos la orden a otra seccion es decir: Bandeja de entrada | En proceso
  Future<void> changeOrdenToOtherSecc(String filename, int secc) async {

    Map<String, dynamic> elMap = {};
    int fromCache = -1;
    if(oCache.isNotEmpty) {
      fromCache = oCache.indexWhere(
        (ords) => ords[OrdCamp.filename.name] == filename
      );
      if(fromCache != -1) {
        elMap = oCache[fromCache];
      }
    }

    if(elMap.isEmpty) {
      elMap = await getContentFile(filename);
    }

    await setContentFile('changeOrdenToOtherSecc', filename, elMap);
    if(fromCache != -1) {
      oCache[fromCache] = elMap;
    }
    elMap = {};
  }

  ///
  Future<List<Map<String, dynamic>>> getAllCotsByFilename(String filename) async {

    Map<String, dynamic> elMap = {};
    int fromCache = -1;
    if(oCache.isNotEmpty) {
      fromCache = oCache.indexWhere(
        (ords) => ords[OrdCamp.filename.name] == filename
      );
      if(fromCache != -1) {
        elMap = oCache[fromCache];
      }
    }

    if(elMap.isEmpty) {
      elMap = await getContentFile(filename);
    }

    if(elMap.isNotEmpty) {
      return List<Map<String, dynamic>>.from(elMap[OrdCamp.resps.name]);
    }
    return [];
  }

  ///
  Future<List<Map<String, dynamic>>> getCotsByIdPza(int idPza, String filename) async {

    Map<String, dynamic> elMap = {};
    int fromCache = -1;
    if(oCache.isNotEmpty) {
      fromCache = oCache.indexWhere(
        (ords) => ords[OrdCamp.filename.name] == filename
      );
      if(fromCache != -1) {
        elMap = oCache[fromCache];
      }
    }

    if(elMap.isEmpty) {
      elMap = await getContentFile(filename);
    }

    if(elMap.isNotEmpty) {
      final resps = List<Map<String, dynamic>>.from(elMap[OrdCamp.resps.name]);
      if (resps.isNotEmpty) {
        final cots = resps.where((c) => c['p_id'] == idPza).toList();
        if(cots.isNotEmpty) {
          return List<Map<String, dynamic>>.from(cots);
        }
      }
    }
    return [];
  }

  ///
  Map<String, dynamic> buildMapFileOrden
    ({required Map<String, dynamic> orden, required int emisor,
    required List<Map<String, dynamic>> pzas, bool isVista = false,
    List<Map<String, dynamic>> resps = const [], String filename = '0',
    List<Map<String, dynamic>> respToSolz = const [] })
  {
    final metrix = _schemaMetrica();
    metrix[Mtrik.pzas.name] = pzas.length;
    return {
      OrdCamp.filename.name: filename, OrdCamp.metrik.name: metrix,
      OrdCamp.emisor.name: emisor, OrdCamp.orden.name: orden,
      OrdCamp.piezas.name: pzas, OrdCamp.resps.name: resps,
      OrdCamp.respToSolz.name: respToSolz
    };
  }

  ///
  Future<void> setCronos(Map<int, dynamic> cronos) async {

    cronos.forEach((idOrden, data) async {

      final filename = data['filename'];
      final cast = Map<String, dynamic>.from(data);
      var content = await getContentFile(filename);
      cast.remove('filename');
      content[OrdCamp.metrik.name][Mtrik.cron.name] = cast;
      await setContentFile('setCronos', filename, content);
    });
  }

  ///
  Future<int> determinarAccByQuery(String query) async {
    
    if(query.isNotEmpty) {

      final map = toJsonQuery(query);
      switch (map['query']) {
        case 'scm':
          return await _proccQueryFromScm(map);
        case 'harbi':
          return await _proccQueryFromHarbi(map);
        default:
      }
    }
    return 0;
  }

  ///
  Map<String, dynamic> toJsonQuery(String query) => json.decode(query);

  ///
  Future<int> _proccQueryFromScm(Map<String, dynamic> query) async {

    String filename = '';
    if(query.containsKey('orden') && query.containsKey('avo')) {
      filename = '${query['orden']}-${query['avo']}.json';
    }

    if(filename.isNotEmpty) {

      Map<String, dynamic> elMap = {};
      int fromCache = -1;
      if(oCache.isNotEmpty) {
        fromCache = oCache.indexWhere(
          (ords) => ords[OrdCamp.filename.name] == filename
        );
        if(fromCache != -1) {
          elMap = oCache[fromCache];
        }
      }

      if(elMap.isEmpty) {
        elMap = await getContentFile(filename);
      }

      if(elMap.isEmpty) { return 0; }

      if(elMap.containsKey(query['secc'])) {

        if(query.containsKey('est')) {
          elMap[OrdCamp.metrik.name][Mtrik.scmEst.name] = query['est'];
        }
        if(query.containsKey('cotz')) {
          elMap[OrdCamp.metrik.name][Mtrik.cotz.name] = query['cotz'];
        }
        if(query.containsKey('see')) {
          int cant = elMap[OrdCamp.metrik.name][Mtrik.see.name];
          if(cant == 0) {
            elMap[OrdCamp.metrik.name][Mtrik.cron.name] = getSchemaCron(
              elMap['filename'], conteo, 0
            );
            elMap[OrdCamp.metrik.name][Mtrik.cam.name] = query['cam'];
          }
          elMap[OrdCamp.metrik.name][Mtrik.see.name] = cant+1;
        }
        if(query.containsKey('rsp')) {
          int cant = elMap[OrdCamp.metrik.name][Mtrik.rsp.name];
          elMap[OrdCamp.metrik.name][Mtrik.rsp.name] = cant+1;
        }

        await setContentFile('_proccQueryFromScm', filename, elMap);
        if(fromCache != -1) {
          oCache[fromCache] = elMap;
        }
      }
    }

    if(query['orden'].runtimeType == String) {
      return int.parse(query['orden']);
    }
    return query['orden'];
  }

  ///
  Map<String, dynamic> schemaBandeja() {

    return {
      'id':0, 'mod': 'MODELO', 'mrk': 'MARCA', 'anio': '0000',
      'nPzas':0, 'solNom':'DESCONOCIDO', 'sol': 'SOLICITANTE EMPRESA', 'solId':0,
      'created': DateTime.now().toIso8601String(),
    };
  }

  ///
  Map<String, dynamic> _schemaMetrica() {

    // cnt => Cantidad de "no la tengo".
    // scmEst -> 0 = EN STAGE, 1 = EN BANDEJA, 2 = EN COLA, 3 = ENVIANDOSE
    //        -> 4 = EN PAPELERA, 5 = ENVIADO

    return {
      Mtrik.pzas.name: 0,
      Mtrik.scmEst.name: 0,
      Mtrik.cam.name: 0,
      Mtrik.see.name: 0,
      Mtrik.rsp.name: 0,
      Mtrik.cnt.name: 0,
      Mtrik.cotz.name: 0,
      Mtrik.cron.name: {}
    };
  }

  ///
  Map<String, dynamic> getSchemaCron
    (String filename, int min, int seg, {bool isPause = false, int ronda = 1})
  {
    return {
      'filename': filename,
      'timer':DateTime.now().toIso8601String(),
      'pausa':isPause,
      'rondas': ronda,
      'min': min,
      'seg': seg
    };
  }

  ///
  Future<int> _proccQueryFromHarbi(Map<String, dynamic> query) async {

    if(query.containsKey('secc')) {
      switch (query['secc']) {
        case 'file_update':
          // Actualizamos el file de la orden local.
          if(query.containsKey('orden') && query.containsKey('avo')) {

            List<Map<String, dynamic>> currentCamps = [];
            int avo = int.parse('${query['avo']}');
            final nameFile = '${query['orden']}-${query['avo']}.json';

            // Actualizamos la informacion desde el SL.
            var content = await getContentFile(nameFile);
            if(content.containsKey('campaings')) {
              currentCamps = List<Map<String, dynamic>>.from(content['campaings']);
            }
            await setOrdenAsignadas(['${query['orden']}'], avo);

            content = await getContentFile(nameFile);
            if(content.isNotEmpty) {

              final String fileCamp = query['fileCamp'];
              final item = {'orden': query['orden'], 'idCamp': query['idCamp'], 'fileCamp': fileCamp.replaceAll('~', '-')};

              if(currentCamps.isEmpty) {
                content.putIfAbsent('campaings', () => [item]);
              }else{
                
                final has = currentCamps.indexWhere((element) => element['idCamp'] == query['idCamp']);
                if(has == -1) {
                  currentCamps.add(item);
                }else{
                  currentCamps[has] = item;
                }
                content['campaings'] = currentCamps;
              }

              await setContentFile('_proccQueryFromHarbi', nameFile, content);
            }
          }
          break;
        default:
      }
    }
    return 0;
  }
}