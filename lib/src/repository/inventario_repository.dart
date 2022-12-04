import 'dart:io';
import 'dart:convert';

import 'ordenes_repository.dart';
import 'piezas_repository.dart';
import '../config/sng_manager.dart';
import '../entity/orden_entity.dart';
import '../entity/piezas_entity.dart';
import '../entity/metrix_entity.dart';
import '../services/my_http.dart';
import '../services/get_paths.dart';
import '../vars/ordenes_cache.dart';

// enum Mtrik { pzas, scmEst, cotz, see, cam, rsp, cnt, cron }

class InventarioRepository {

  final int conteo = 30;
  final String myAsigns = 'my_asigns';
  final _piezaEm= PiezasRepository();
  final _ordEm  = OrdenesRepository();
  final _oCache = getSngOf<OrdenesCache>();

  String pathAsign = '';
  Map<String, dynamic> result = {'abort':false, 'msg': 'ok', 'body':{}};

  ///
  List<Map<String, dynamic>> get oCache => _oCache.ordenes;
  ///
  int get totPzas => _oCache.totPzas;
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
    final dir = Directory('$root${ GetPaths.getSep() }$myAsigns');
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
      final dir = Directory('$root${GetPaths.getSep()}$myAsigns');
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
    ordenes.sort((a, b) => a['orden']['o_id'].compareTo(b['orden']['o_id']));
    return ordenes;
  }

  /// Recuperamos todas las ordenes del avo desde los archivos
  Future<List<Map<String, dynamic>>> getAllOrdenesByAvo
    (int avo, {
      String? est, bool onlyFile = false, bool onlyIdOrden = false,
      String from = 'cache' }) async
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
                if(onlyIdOrden) {
                  resultados.add({'id':'${ordenes[i]['orden']['o_id']}'});
                }else{
                  resultados.add(ordenes[i]);
                }
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
  Future<MetrixEntity> getMetriksFromFile
    (String filename, {int perIdPza = 0, bool force = false}) async
  {

    Map<String, dynamic> content= {};
    final indC = oCache.indexWhere(
      (ords) => ords[OrdCamp.filename.name] == filename
    );
    if(oCache.isNotEmpty && !force) {
      if(indC != -1) {
        content = oCache[indC];
      }
    }
    
    if(content.isEmpty) { content = await getContentFile(filename); }
    final metrix = MetrixEntity();
    if(content.containsKey(OrdCamp.metrik.name)) {
      metrix.fromJson(content[OrdCamp.metrik.name]);
      if(indC != -1) {
        oCache[indC] = content;
      }
    }
    return metrix;
  }

  /// Cuando el AVO revisa el centinela de cada orden, esta trae datos desde HARBI,
  /// estos datos actualizan la info local del archivo de la orden y guarda tambien
  /// todos los datos obtenidos para mostrarlos la siguiente ves que se revice el centinela
  /// Retorna verdadero de la seccion que se encontro el cambio para actualizar pantalla
  // Future<Map<String, dynamic>> updateDataCentinela(Map<String, dynamic> data, String filename) async {

  //   Map<String, dynamic> seccs = {'metrix':false, 'provs': true, 'newData': {}};
  //   final dir = getPathToAsigns();
  //   final file = File('$dir/$filename');

  //   if(file.existsSync()) {

  //     var content = Map<String, dynamic>.from(json.decode(file.readAsStringSync()));

  //     if(!content.containsKey(OrdCamp.metrik.name)) {
  //       Map<String, dynamic> m = _schemaMetrica();
  //       m[Mtrik.pzas.name] = content[OrdCamp.piezas.name].length;
  //       content[OrdCamp.metrik.name] = m;
  //     }else{

  //       if(data.containsKey('metas')) {
          
  //         String estScm = fromFolderToStringStatusScm(data['metas']['folder']);
  //         if(estScm != content[OrdCamp.metrik.name]['scmEst']) {
  //           content[OrdCamp.metrik.name]['scmEst'] = estScm;
  //           seccs['metrix'] = true;
  //         }
  //         if(data['metas'].containsKey('camp')) {
  //           content['campaings'] = [data['metas']['camp']];
  //         }
  //       }

  //       if(data.containsKey('notengo')) {
  //         if(data['notengo'].isNotEmpty) {
  //           var cnt = 0;
  //           final nt = Map<String, dynamic>.from(data['notengo']);
  //           nt.forEach((key, value) {
  //             final idP = List<String>.from(value);
  //             cnt = cnt + idP.length;
  //           });
  //           if(content[OrdCamp.metrik.name]['cnt'] != cnt) {
  //             content[OrdCamp.metrik.name]['cnt'] = cnt;
  //             seccs['metrix'] = true;
  //           }
  //         }
  //       }

  //       if(data.containsKey('resps')) {
  //         final listResp = List<Map<String, dynamic>>.from(data['resps']);
  //         if(content[OrdCamp.metrik.name]['rsp'] != listResp.length) {
  //           content[OrdCamp.metrik.name]['rsp'] = listResp.length;
  //             seccs['metrix'] = true;
  //         }
  //       }
  //     }

  //     content['centinela'] = data;
  //     file.writeAsStringSync(json.encode(content));
  //     seccs['newData'] = content;
  //   }

  //   return seccs;
  // }

  ///
  Future<Map<String, dynamic>> getContentFile(String filename) async {

    final dir = getPathToAsigns();
    final file = File('$dir${GetPaths.getSep()}$filename');
    if(file.existsSync()) {
      var content = Map<String, dynamic>.from(json.decode(file.readAsStringSync()));
      if(content.isNotEmpty) {
        return content;
      }
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

    if(pathAsign.isEmpty) {
      pathAsign = getPathToAsigns();
    }

    _ordEm.result.clear();
    for (var i = 0; i < ordAsign.length; i++) {
      final res = await _goForOrdenToServer(ordAsign[i], '$idUser');
      if(res == '0') {
        continue;
      }
    }
    return;
  }

  /// Descargamos desde el servidor local la orden y guardamos en archivos.
  Future<String> setOrdenAsignada(String idOrd, int idUser) async {

    final res = await _goForOrdenToServer(idOrd, '$idUser');
    return (res != '1')
      ? 'Error al descargar orden $idOrd' : 'Orden $idOrd Descargada.';
  }

  ///
  Future<String> _goForOrdenToServer(String idO, String idUser) async {

    if(pathAsign.isEmpty) { pathAsign = getPathToAsigns(); }

    _ordEm.result.clear();
    await _ordEm.getOrdenById('_goForOrdenToServer', int.parse(idO));
    if(_ordEm.result.isEmpty) {
      return '0';
    }
    
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

        final sep = GetPaths.getSep();
        final file = File('$pathAsign$sep$filename');
        if(!file.existsSync()) {
          file.createSync();
        }
        
        file.writeAsStringSync(json.encode(content));
        return '1';
      }
    }
    return '2';
  }

  /// Actualizamos las metricas de una orden
  Future<void> updateMetrix(Map<String, dynamic> data, Map<String, dynamic> metrix) async {
    
    final filename = '${data['id']}-${data['avo']}.json';
    final sep = GetPaths.getSep();
    if(pathAsign.isEmpty) { pathAsign = getPathToAsigns(); }

    final file = File('$pathAsign$sep$filename');
    if(file.existsSync()) {

      final content = Map<String, dynamic>.from(json.decode(file.readAsStringSync()));
      content[OrdCamp.metrik.name] = metrix;
      // Crear el campo camping si no existe
      if(!content.containsKey('campings')) {
        content['campings'] = {};
      }

      if(data['manifest'] == 'main') {
        content['campings'][data['manifest']] = data['idCamp'];
      }else{

        // actualizar el campo en caso de existir
        final current = List<Map<String, dynamic>>.from(
          content['campings'][data['manifest']]
        );
        final has = current.indexWhere((e) => e.keys.contains('${data['idCamp']}'));
        if(has != -1) {
          current[has]['${data['idCamp']}'] = data['manifest'];
        }else{
          current.add({'${data['idCamp']}':data['manifest']});
        }
        content['campings'][data['manifest']] = current;
      }
      file.writeAsStringSync(json.encode(content));
    }

    return;
  }

  /// Actualizamos los datos del IRIS de una orden desde una notificacion
  Future<void> updateIris(Map<String, dynamic> data, Map<String, dynamic> iris) async {
    
    final filename = '${data['idOrd']}-${iris['avo']}.json';
    
    final sep = GetPaths.getSep();
    if(pathAsign.isEmpty) { pathAsign = getPathToAsigns(); }

    final file = File('$pathAsign$sep$filename');
    Map<String, dynamic> myAsign = {};
    if(file.existsSync()) {

      myAsign = Map<String, dynamic>.from(json.decode(file.readAsStringSync()));
      if(myAsign.isEmpty){ return; }

      if(data.containsKey('file')) {
        if(!data['file'].toString().endsWith( sep )) {
          data['file'] = '${data['file']}$sep';
        }
        myAsign['iris_file'] = data['file'];
      }
      if(data.containsKey('exp')) {
        if(!data['exp'].toString().endsWith( sep )) {
          data['exp'] = '${data['exp']}$sep';
        }
        myAsign['exp_file'] = data['exp'];
      }
      myAsign['iris'] = iris;

      final metrix = MetrixEntity();
      metrix.fromJson(myAsign[OrdCamp.metrik.name]);

      // Actualizar los campos de metrix
      // No tengo
      if(iris.containsKey('ntg')) {

        iris['ntg'].forEach((idCot, value) {
          final vals = List<Map<String, dynamic>>.from(value);
          for (var p = 0; p < vals.length; p++) {
            if(metrix.ntpp.containsKey(vals[p]['idPieza'])) {
              if(!metrix.ntpp[ vals[p]['idPieza'] ].contains(idCot)) {
                metrix.ntpp[ vals[p]['idPieza'] ].add(idCot);
              }
            }else{
              metrix.ntpp.putIfAbsent(vals[p]['idPieza'], () => [idCot]);
            }
          }
        });
      }

      // Respuestas
      if(iris.containsKey('rsp')) {
        
        List<Map<String, dynamic>> irPorResps = [];

        iris['rsp'].forEach((idPza, value) {

          final vals = List<Map<String, dynamic>>.from(value);
          for (var p = 0; p < vals.length; p++) {

            // Buscamos para ver si cada pieza tiene la respuesta indicada en IRIS
            final pid = int.tryParse(idPza);
            final misPzas = List<Map<String, dynamic>>.from(myAsign['piezas']);

            final ixpz = misPzas.indexWhere((p) => p['id'] == pid);
            if(ixpz != -1) {

              bool getPorPza = true;
              final pzaMap = Map<String, dynamic>.from(myAsign['piezas'][ixpz]);
              if(pzaMap.containsKey('rsps')) {
                final existe = List<Map<String, dynamic>>.from(pzaMap['rsps']).where(
                  (r) => r['id'] == vals[p]['idResp']
                );
                if(existe.isNotEmpty) { getPorPza = false; }
              }

              if(getPorPza) {
                irPorResps.add({
                  'idOrd': myAsign['orden']['o_id'], 'idPza': pid,
                  'idResp': vals[p]['idResp'], 'idCot': vals[p]['idCot'],
                  'inxPza': ixpz
                });
              }
            }
          }
        });

        // Para garantizar un refresh del dashboard, cambiamos la version de iris
        // en caso de que halla una nueva respuesta.
        bool forceChangeVer = false;
        final nver = '${DateTime.now().millisecondsSinceEpoch}';

        if(irPorResps.isNotEmpty) {

          for (var i = 0; i < irPorResps.length; i++) {

            final res = await _getRespuestasByIds(
              '${irPorResps[i]['idOrd']}i'
              '${irPorResps[i]['idPza']}i'
              '${irPorResps[i]['idResp']}i'
              '${irPorResps[i]['idCot']}'
            );

            if(res.isNotEmpty) {
              forceChangeVer = true;
              if(myAsign['piezas'][irPorResps[i]['inxPza']].containsKey('rsps')) {
                myAsign['piezas'][irPorResps[i]['inxPza']]['rsps'].add(res);
              }else{
                myAsign['piezas'][irPorResps[i]['inxPza']]['rsps'] = [res];
              }
            }
          }
        }

        if(forceChangeVer) {
          myAsign['iris']['version'] = nver;
        }
      }


      // Calculamos los que han visto por medio de los que han atendido
      List<String> losSee = [];

      // Repetimos el bucle ahora para hidratar las metricas ya despues de haber
      // hidratado las respuestas faltantes desde Harbi
      if(iris.containsKey('rsp')) {

        metrix.rsp = 0;

        iris['rsp'].forEach((idPza, value) {

          final lstVals = List<Map<String, dynamic>>.from(value);
          for (var i = 0; i < lstVals.length; i++) {
            if(metrix.rpp.containsKey(lstVals[i]['idPieza'])) {
              if(!metrix.rpp[ lstVals[i]['idPieza'] ].contains(lstVals[i]['idResp'])) {
                metrix.rpp[ lstVals[i]['idPieza'] ].add(lstVals[i]['idResp']);
              }
            }else{
              metrix.rpp.putIfAbsent(lstVals[i]['idPieza'], () => [lstVals[i]['idResp']]);
            }

            if(!losSee.contains(lstVals[i]['idCot'])) {
              losSee.add(lstVals[i]['idCot']);
            }
          }

          metrix.rpp.forEach((idPza, value) {
            metrix.rsp = metrix.rsp + List<int>.from(value).length;
          });
        });
      }

      // Apartadas
      if(iris.containsKey('apr')) {

        iris['apr'].forEach((idCot, value) {

          final vals = List<Map<String, dynamic>>.from(value);

          for (var p = 0; p < vals.length; p++) {
            if(metrix.aprp.containsKey(vals[p]['idPieza'])) {
              if(!metrix.aprp[ vals[p]['idPieza'] ].contains(idCot)) {
                metrix.aprp[ vals[p]['idPieza'] ].add(idCot);
              }
            }else{
              metrix.aprp.putIfAbsent(vals[p]['idPieza'], () => [idCot]);
            }
          }
        });

        // Eliminar todos los cotizadores de APARTADOS si es que tienen respuestas
        final respMp = Map<String, dynamic>.from(iris['rsp']);
        for (var i = 0; i <  myAsign['piezas'].length; i++) {
          
          final idPza = '${myAsign['piezas'][i]['id']}';
          List<Map<String, dynamic>> respI = [];
          if(respMp.containsKey(idPza)) {
            respI = List<Map<String, dynamic>>.from(respMp[idPza]);
          }
          if(metrix.aprp.containsKey(idPza)) {
            final idCz = List<String>.from(metrix.aprp[idPza]);
            final rota = idCz.length;
            for (var i = 0; i < rota; i++) {
              final exist = respI.firstWhere((r) => r['idCot'] == idCz[i], orElse: () => {});
              if(exist.isNotEmpty) {
                idCz.removeWhere((r) => r == exist['idCot']);
              }
            }
            metrix.aprp[idPza] = idCz;
          }
        }

      }

      // Eliminar todos los cotizadores de APARTADOS si es que existen en NO TENGO
      for (var i = 0; i <  myAsign['piezas'].length; i++) {
        
        final idPza = '${myAsign['piezas'][i]['id']}';
        if(metrix.aprp.containsKey(idPza)) {
          if(metrix.ntpp.containsKey(idPza)) {
            var icx = List<String>.from(metrix.aprp[idPza]);
            icx.removeWhere((element) => metrix.ntpp[idPza].contains(element));
            metrix.aprp[idPza] = icx;
          }
        }
      }

      // Calculamos las cantidades resultantes de las piezas NO TENGO
      metrix.ntg = 0;
      metrix.ntpp.forEach((idP, cotz) {
        final tc = List<String>.from(cotz);
        metrix.ntg = metrix.ntg + tc.length;
      });
      
      // Calculamos las cantidades resultantes de las piezas APARTADAS
      metrix.apr = 0;
      metrix.aprp.forEach((idP, cotz) {
        final tc = List<String>.from(cotz);
        metrix.apr = metrix.apr + tc.length;
      });

      // Rectificar drash contra envios
      for (var i = 0; i < metrix.drash.length; i++) {
        if(metrix.sended.contains(metrix.drash[i])) {
          metrix.drash.removeAt(i);
        }
      }

      // Le restamos a todos los que han APARTADO
      metrix.aprp.forEach((idPza, idsCots) {
        final ids = List<String>.from(idsCots);
        for (var c = 0; c < ids.length; c++) {
          if(!losSee.contains(ids[c])) {
            losSee.add(ids[c]);
          }
        }
      });
      
      // Le restamos a todos los que han dicho NO TENGO
      metrix.ntpp.forEach((idPza, idsCots) {
        final ids = List<String>.from(idsCots);
        for (var c = 0; c < ids.length; c++) {
          if(!losSee.contains(ids[c])) {
            losSee.add(ids[c]);
          }
        }
      });

      if(iris.containsKey('see')) {
        iris['see'].forEach((idCot, value) {
          if(!losSee.contains(idCot)) {
            losSee.add(idCot);
          }
        });
      }

      metrix.see = losSee.length;

      myAsign[OrdCamp.metrik.name] = metrix.toJson();
      file.writeAsStringSync(json.encode(myAsign));
    }

    return;
  }

  ///
  Future<Map<String, dynamic>> _getRespuestasByIds(String queryIds) async {

    final query = 'get_resp_by_ids=$queryIds';
    final uri = await GetPaths.getUriApiHarbi('centinela_get', query);
    await MyHttp.getHarbi(uri);

    if(!MyHttp.result['abort']) {
      final res = MyHttp.result['body'];
      if(res.isNotEmpty) {
        MyHttp.clean();
        return Map<String, dynamic>.from(res);
      }
    }
    return {};
  }

  // /// Guardamos las respuestas en su respetivo archivo
  // Future<void> setRespuestasByPieza(List<Map<String, dynamic>> resps) async {

  //   if(resps.isNotEmpty) {

  //     Map<int, Map<String, dynamic>> sortResp = {};
  //     List<int> ordenes = [];
      
  //     // Organizar las respuestas nuevas en sus respectivas ordenes.
  //     for (var i = 0; i < resps.length; i++) {

  //       final ord = resps[i]['o_id'];
  //       Map<String, dynamic> item = {
  //         'filename': '$ord-${resps[i]['a_id']}.json',
  //         'resps' : resps.where((element) => element['o_id'] == ord).toList()
  //       };
        
  //       if(sortResp.containsKey(ord)) {
  //         sortResp[ord] = item;
  //       }else{
  //         sortResp.putIfAbsent(ord, () => item);
  //       }
  //       if(!ordenes.contains(ord)) {
  //         ordenes.add(ord);
  //       }
  //     }
      
  //     if(ordenes.isNotEmpty) {

  //       for (var i = 0; i < ordenes.length; i++) {
          
  //         final ordFile = await getContentFile(sortResp[ordenes[i]]!['filename']);
  //         List<Map<String, dynamic>> respOldis = [];
  //         if(ordFile.isNotEmpty) {
  //           if(ordFile.containsKey(OrdCamp.resps.name)) {
  //             respOldis = List<Map<String, dynamic>>.from(ordFile[OrdCamp.resps.name]);
  //           }
  //         }
  //         List<Map<String, dynamic>> respNews = [];
  //         List<Map<String, dynamic>> respToAdd = [];
  //         respNews.addAll(List<Map<String, dynamic>>.from(sortResp[ordenes[i]]!['resps']));

  //         if(respOldis.isNotEmpty) {

  //           respToAdd.addAll(respOldis);
  //           for (var a = 0; a < respNews.length; a++) {
  //             final index = respToAdd.indexWhere((element) => element['r_id'] == respNews[a]['r_id']);
  //             if(index == -1) {
  //               respToAdd.add(respNews[a]);
  //             }
  //           }

  //         }else{
  //           respToAdd.addAll(respNews);
  //         }

  //         ordFile[OrdCamp.resps.name] = respToAdd;

  //         await setContentFile('setRespuestasByPieza', sortResp[ordenes[i]]!['filename'], ordFile);
  //         respNews = []; respToAdd = [];
  //       }

  //     }
  //   }
  // }

  // /// Guardamos la respuesta obtenida por medio del query en su respetivo archivo
  // Future<void> setRespuestaToFile(List<Map<String, dynamic>> resps) async {

  //   if(resps.isNotEmpty) {

  //     Map<int, Map<String, dynamic>> sortResp = {};
  //     List<int> ordenes = [];
  //     // Organizar las respuestas nuevas en sus respectivas ordenes.
  //     for (var i = 0; i < resps.length; i++) {

  //       final ord = resps[i]['o_id'];

  //       Map<String, dynamic> item = {
  //         'filename': '$ord-${resps[i]['a_id']}.json',
  //         'resps' : resps.where((element) => element['o_id'] == ord).toList()
  //       };

  //       if(sortResp.containsKey(ord)) {
  //         sortResp[ord] = item;
  //       }else{
  //         sortResp.putIfAbsent(ord, () => item);
  //       }

  //       if(!ordenes.contains(ord)) {
  //         ordenes.add(ord);
  //       }
  //     }

  //     if(ordenes.isNotEmpty) {

  //       for (var i = 0; i < ordenes.length; i++) {

  //         final ordFile = await getContentFile(sortResp[ordenes[i]]!['filename']);
  //         List<Map<String, dynamic>> respsAlls = [];
  //         if(ordFile.containsKey(OrdCamp.resps.name)) {
  //           respsAlls.addAll(List<Map<String, dynamic>>.from(
  //             ordFile[OrdCamp.resps.name]
  //           ));
  //         }

  //         respsAlls.addAll(List<Map<String, dynamic>>.from(sortResp[ordenes[i]]!['resps']));
  //         ordFile[OrdCamp.resps.name] = respsAlls;
  //         int indx  = oCache.indexWhere(
  //           (element) => element['filename'] == sortResp[ordenes[i]]!['filename']
  //         );
  //         if(indx != -1) {
  //           oCache[indx] = ordFile;
  //         }
  //         await setContentFile('setRespuestaToFile', sortResp[ordenes[i]]!['filename'], ordFile);
  //       }
  //     }
  //   }
  // }

  ///
  Future<Map<String, dynamic>> getOrdenMapTile(String filename) async {

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

      int nP = 0;
      if(elMap.containsKey(OrdCamp.metrik.name)) {
        if(elMap[OrdCamp.metrik.name].containsKey('scmEst')) {
          elMap[OrdCamp.metrik.name] = MetrixEntity().toJson();
        }
        nP = elMap[OrdCamp.metrik.name]['tpz'];
      }
      
      var resultado = {
        'id':elMap[OrdCamp.orden.name]['o_id'],
        'mod': elMap[OrdCamp.orden.name]['md_nombre'],
        'mrk': elMap[OrdCamp.orden.name]['mk_nombre'],
        'anio': elMap[OrdCamp.orden.name]['o_anio'],
        'nPzas': nP,
        'sol': elMap[OrdCamp.orden.name]['e_nombre'],
        'solNom': elMap[OrdCamp.orden.name]['u_nombre'],
        'solId': elMap[OrdCamp.orden.name]['u_id'],
        'created': elMap[OrdCamp.orden.name]['o_createdAt'],
        'file': elMap[OrdCamp.filename.name],
        OrdCamp.metrik.name: {
          'hIni': elMap[OrdCamp.metrik.name]['hIni'],
          'hFin': elMap[OrdCamp.metrik.name]['hFin']
        }
      };
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
    return {
      OrdCamp.filename.name: filename, OrdCamp.metrik.name: MetrixEntity().toJson(),
      OrdCamp.emisor.name: emisor, OrdCamp.orden.name: orden,
      OrdCamp.piezas.name: pzas, OrdCamp.resps.name: resps,
      OrdCamp.respToSolz.name: respToSolz
    };
  }

  // ///
  // Future<void> setCronos(Map<int, dynamic> cronos) async {

  //   cronos.forEach((idOrden, data) async {

  //     final filename = data['filename'];
  //     final cast = Map<String, dynamic>.from(data);
  //     var content = await getContentFile(filename);
  //     cast.remove('filename');
  //     content[OrdCamp.metrik.name][Mtrik.cron.name] = cast;
  //     await setContentFile('setCronos', filename, content);
  //   });
  // }

  ///
  Future<int> determinarAccByQuery(String query) async {
    
    if(query.isNotEmpty) {

      final map = toJsonQuery(query);
      switch (map['query']) {
        case 'scm':
          // return await _proccQueryFromScm(map);
          break;
        case 'harbi':
          return await _proccQueryFromHarbi(map);
        default:
      }
    }
    return 0;
  }

  ///
  Map<String, dynamic> toJsonQuery(String query) => json.decode(query);

  // ///
  // Future<int> _proccQueryFromScm(Map<String, dynamic> query) async {

  //   String filename = '';
  //   if(query.containsKey('orden') && query.containsKey('avo')) {
  //     filename = '${query['orden']}-${query['avo']}.json';
  //   }

  //   if(filename.isNotEmpty) {

  //     Map<String, dynamic> elMap = {};
  //     int fromCache = -1;
  //     if(oCache.isNotEmpty) {
  //       fromCache = oCache.indexWhere(
  //         (ords) => ords[OrdCamp.filename.name] == filename
  //       );
  //       if(fromCache != -1) {
  //         elMap = oCache[fromCache];
  //       }
  //     }

  //     if(elMap.isEmpty) {
  //       elMap = await getContentFile(filename);
  //     }

  //     if(elMap.isEmpty) { return 0; }

  //     if(elMap.containsKey(query['secc'])) {

  //       if(query.containsKey('est')) {
  //         elMap[OrdCamp.metrik.name][Mtrik.scmEst.name] = query['est'];
  //       }
  //       if(query.containsKey('cotz')) {
  //         elMap[OrdCamp.metrik.name][Mtrik.cotz.name] = query['cotz'];
  //       }
  //       if(query.containsKey('see')) {
  //         int cant = elMap[OrdCamp.metrik.name][Mtrik.see.name];
  //         if(cant == 0) {
  //           elMap[OrdCamp.metrik.name][Mtrik.cron.name] = getSchemaCron(
  //             elMap['filename'], conteo, 0
  //           );
  //           elMap[OrdCamp.metrik.name][Mtrik.cam.name] = query['cam'];
  //         }
  //         elMap[OrdCamp.metrik.name][Mtrik.see.name] = cant+1;
  //       }
  //       if(query.containsKey('rsp')) {
  //         int cant = elMap[OrdCamp.metrik.name][Mtrik.rsp.name];
  //         elMap[OrdCamp.metrik.name][Mtrik.rsp.name] = cant+1;
  //       }

  //       await setContentFile('_proccQueryFromScm', filename, elMap);
  //       if(fromCache != -1) {
  //         oCache[fromCache] = elMap;
  //       }
  //     }
  //   }

  //   if(query['orden'].runtimeType == String) {
  //     return int.parse(query['orden']);
  //   }
  //   return query['orden'];
  // }

  ///
  Map<String, dynamic> schemaBandeja() {

    return {
      'id':0, 'mod': 'MODELO', 'mrk': 'MARCA', 'anio': '0000',
      'nPzas':0, 'solNom':'DESCONOCIDO', 'sol': 'SOLICITANTE EMPRESA', 'solId':0,
      'created': DateTime.now().toIso8601String(),
    };
  }

  ///
  String fromIntToStringStatusScm(int stt) {

    switch (stt) {
      case 0: return 'EN BANDEJA';
      case 1: return 'ENVIANDOSE';
      case 2: return 'EN PAPELERA';
      case 3: return 'ENVIADO';
      default:
      return 'Desconocido';
    }
  }

  ///
  String fromFolderToStringStatusScm(String stt) {

    switch (stt) {
      case 'scm_await': return '2';
      case 'scm_tray': return '3';
      case 'scm_werr': return '4';
      case 'scm_hist': return '5';
      default:
      return '0';
    }
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