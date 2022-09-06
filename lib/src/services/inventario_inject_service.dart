
import '../config/sng_manager.dart';
import '../entity/orden_entity.dart';
import '../repository/inventario_repository.dart';
import '../repository/contacts_repository.dart';
import '../providers/invirt_provider.dart';
import '../vars/globals.dart';

/// Esta clase es llamada directamente desde los widget:
/// c_invent_virtual, invent_virtual
class InventarioInjectService {

  final _globals = getSngOf<Globals>();

  bool returnData = false;
  final InventarioRepository em;
  final InvirtProvider prov;
  InventarioInjectService({required this.em, required this.prov});
  Map<int, dynamic> costosSel = {};
  List<String> _queSelectedTmp = [];

  /// Semi revisada
  /// Hacemos lo que nos indica el comando recibido por parametro
  /// [RETURN] La lista de nombres de los archivos correspondientes a las
  /// ordenes, para ser enlistadas.
  Future<List<String>> make() async {

    final cmd = Map<String, dynamic>.from(prov.cmd);
    returnData = false;
    costosSel = {};
    if(cmd['clv'] == 'refresh_list') {
      prov.queSelected = ['cc'];
      return await getAllOrds('files');
    }

    List<Map<String, dynamic>> pzasAndResps = await _procesarComando(cmd);
    
    // Mute lo uso, para saber cuando no es necesario propagar el comando a
    // la lista de resultados de ordenes sin procesar (La Bandeja de entrada)
    if(pzasAndResps.isNotEmpty && pzasAndResps.first.containsKey('mute')) {
      return [];
    }

    // Tomamos solo los nombres de los archivos del resultado
    List<String> files = [];
    if(pzasAndResps.isNotEmpty) {
      for (var i = 0; i < pzasAndResps.length; i++) {
        files.add(pzasAndResps[i][OrdCamp.filename.name]);
      }
    }

    // Si el resultado es bacio, X nose...
    if(files.isEmpty) {
      return prov.ordInvBEFiles;
    }

    // Agregamos las piezas resultantes a la lista correspondiente.
    if(cmd.containsKey('tipo')) {
      if(cmd['tipo'] == 'proceso') {
        
        prov.queSelected = List<String>.from(_queSelectedTmp);
        _queSelectedTmp = [];
        if(pzasAndResps.first.containsKey(OrdCamp.piezas.name)) {
          Future.microtask((){
            prov.pzaResults = pzasAndResps.first[OrdCamp.piezas.name];
            if(costosSel.isNotEmpty) {
              prov.costosSel = costosSel;
            }
          });
        }
      }
    }

    return files;
  }

  ///
  Future<Map<String, dynamic>> makeGetMap(Map<String, dynamic> cmd) async {

    returnData = true;
    List<Map<String, dynamic>> result = [];
    result = await _procesarComando(cmd);
    return (result.isNotEmpty) ? result.first : {};
  }

  ///
  Future<List<String>> getAllOrds(String from) async {

    final filesNames = await em.getAllOrdenesByAvo(
      _globals.user.id, est: '3', onlyFile: false, from: from
    );

    if(filesNames.isNotEmpty) {

      List<String> ordenes = [];

      filesNames.map((e) {
        ordenes.add(e[OrdCamp.filename.name]);
      }).toList();
      
      prov.ordInvBEFiles= List<String>.from(ordenes);
      prov.cantOrdBanEnt = '${prov.ordInvBEFiles.length}/${filesNames.length}';
      ordenes = [];

    }else{

      prov.ordInvBEFiles= [];
      prov.cantOrdBanEnt = '${prov.ordInvBEFiles.length}/${filesNames.length}';
    }
    
    return prov.ordInvBEFiles;
  }

  /// Semi revisada
  /// Revisamos el comando para ver que campos requiere para su procesamiento,
  /// buscamos la orden sus piezas y respuestas
  /// [RETURN] Lista de piezas y respuestas
  Future<List<Map<String, dynamic>>> _procesarComando(Map<String, dynamic> cmd) async {

    if(cmd.isEmpty){ return []; }
    if(em.oCache.isEmpty) {
      await em.setOrdenesEnCache(byAvo: _globals.user.id, est: '3');
    }
    if(em.oCache.isEmpty || !cmd.containsKey('tipo')) {
      return [];
    }

    if(cmd['tipo'] == 'proceso') {

      // ORDENES
      // Obligatoriamente se require un retorno de una sola orden, sus piezas
      // y solo las tres respuestas ordenadas por costo
      if(cmd['campo'] == OrdCamp.orden.name) {
        cmd['where'] = 'o_id';
        return [await _getOrdenPzasAndResps(cmd)];
      }

      // PIEZAS
      // Obligatoriamente se require un retorno de una sola orden, sus piezas
      // y todas sus respuestas ordenadas por costo
      if(cmd['campo'] == OrdCamp.piezas.name) {
        cmd['where'] = 'id';
        return [await _procesarCmdByIdPieza(cmd)];
      }

      // COTIZACIONES
      if(cmd['campo'] == OrdCamp.resps.name) {
        cmd['where'] = 'r_id';
        return _procesarCmdByIdCot(cmd);
      }
      
    }else{

      // Buscar por: orden > nombre de empresa, contacto, modelo
      if(cmd['campo'] == OrdCamp.orden.name) {
        return _procesarCmdOrdenBy(cmd);  
      }

      // Buscar por: piezas > nombre de pieza
      if(cmd['campo'] == OrdCamp.piezas.name) {
        return _procesarCmdPiezaBy(cmd);  
      }
      
      // Buscar por: resp > curc
    }

    return [];
  } 

  /// Revisada
  /// Buscamos la orden por ID
  Future<Map<String, dynamic>> _getOrdenPzasAndResps(Map<String, dynamic> cmd) async {

    final orden = em.oCache.firstWhere(
      (ord) => ord[cmd['campo']][cmd['where']] == cmd['eval'],
      orElse: () => <String, dynamic>{}
    );

    if(orden.isNotEmpty){
      _queSelectedTmp = ['Orden ID > ${cmd['eval']}'];
      return _getPiezasOfOrden(orden);
    }
    
    _queSelectedTmp = ['cc'];
    return {};
  }

  /// Revisada
  /// Buscamos la pieza por ID
  Future<Map<String, dynamic>> _procesarCmdByIdPieza(Map<String, dynamic> cmd) async {

    Map<String, dynamic> orden = {};
    Map<String, dynamic> itemPza = {};
    for (var i = 0; i < em.oCache.length; i++) {
      itemPza = em.oCache[i][OrdCamp.piezas.name].firstWhere(
        (pza) => pza[cmd['where']] == cmd['eval'], orElse: () => <String, dynamic>{}
      );

      if(itemPza.isNotEmpty) {
        orden = em.oCache[i];
        itemPza = {};
        break;
      }
    }

    if(orden.isNotEmpty){
      _queSelectedTmp.add('Orden ID > ${orden[OrdCamp.orden.name]['o_id']}');
      _queSelectedTmp.add('Pieza ID > ${cmd['eval']}');
      return _getPiezasOfOrden(orden, idP: cmd['eval']);
    }
    _queSelectedTmp = ['cc'];
    return {};
  }

  /// Revisada
  Future<Map<String, dynamic>> _getPiezasOfOrden
  (Map<String, dynamic> orden, {int idP = 0}) async
  {
    List<Map<String, dynamic>> piezas = [];
    List<Map<String, dynamic>> pzsFormat = [];
    
    if(orden.containsKey(OrdCamp.piezas.name)) {
      piezas = List<Map<String, dynamic>>.from(orden[OrdCamp.piezas.name]);
    }
    
    if(piezas.isNotEmpty) {
      for(var i = 0; i < piezas.length; i++) {
        final pzaF = await _getRespOfPieza(piezas[i], orden, i, idP);
        pzsFormat.add(pzaF);
      }
    }

    return {
      OrdCamp.filename.name: orden[OrdCamp.filename.name],
      OrdCamp.piezas.name: pzsFormat,
    };
  }

  /// Revisada
  /// nmCall => Es un candado para no gastar tantos recursos, es decir...
  /// Este metodo es llamado varias veces destro de un ciclo for, por lo tanto
  /// solo necesitamos que la primera llamada sea para hidratar la lista de
  /// respuestas en el almacen virtual. 
  Future<Map<String, dynamic>> _getRespOfPieza(
    Map<String, dynamic> pieza, Map<String, dynamic> orden, int nmCall, int idP) async 
  {
    if(nmCall == 0) {
      orden = await _setDataCotizadorToResps(orden);
    }

    List<Map<String, dynamic>> resps = [];
    if(orden.containsKey(OrdCamp.resps.name)) {
      resps = List<Map<String, dynamic>>.from(orden[OrdCamp.resps.name]);
    }

    if(pieza.isEmpty || resps.isEmpty) {
      pieza['resp'] = '0';
      pieza['resps'] = [];
      pieza['filename'] = orden[OrdCamp.filename.name];
      return pieza;
    }

    // Hidratamos la seccion de almacen virtual, solo la primer ves que se llama
    // a este metodo gracias a la variable 
    if(nmCall == 0) {
      resps = List<Map<String, dynamic>>.from(prov.sortCotsByPriceMinToMax(resps));
      
      if(idP != 0) {
        Future.microtask(() {
          prov.cotsAlmacen = resps.where((element) => element['p_id'] == idP).toList();
          prov.rebuildLstAlmacen = !prov.rebuildLstAlmacen;
        });
      }else{
        Future.microtask(() {
          prov.cotsAlmacen = resps;
          prov.rebuildLstAlmacen = !prov.rebuildLstAlmacen;
        });
      }
    }

    // Teniendo los datos del cotizador listos proseguimos a ordenar
    // las respuestas por precio
    List<Map<String, dynamic>> respRs = resps.where(
      (element) => element['p_id'] == pieza['id']
    ).toList();

    String respCant = '${respRs.length}';
    respRs = List<Map<String, dynamic>>.from(prov.sortCotsByPrice(respRs));

    if(respRs.isNotEmpty) {
      costosSel[respRs.first['p_id']] = {'r_id':respRs.first['r_id'], 'r_costo':respRs.first['r_costo']};
    }

    return {
      'id': pieza['id'],
      'orden': pieza['orden'],
      'piezaName': pieza['piezaName'],
      'lado': pieza['lado'],
      'posicion': pieza['posicion'],
      'origen': pieza['origen'],
      'fotos': pieza['fotos'],
      'obs': pieza['obs'],
      'resp': respCant,
      'resps': respRs,
      'filename': orden[OrdCamp.filename.name]
    };
  }

  /// Revisada
  /// Le pedimos a harbi los datos del cotizador que no tengamos entre las
  /// respuestas de la orden enviada por parametro.
  Future<Map<String, dynamic>> _setDataCotizadorToResps(Map<String, dynamic> orden) async {

    List<Map<String, dynamic>> resps = [];
    if(orden.containsKey(OrdCamp.resps.name)) {
      resps = List<Map<String, dynamic>>.from(orden[OrdCamp.resps.name]);
    }

    if(resps.isEmpty) {return orden; }

    List<Map<String, int>> irPorCotz = [];

    // Primero recuperamos los datos del cotizador
    for (var i = 0; i < resps.length; i++) {
      if(!resps[i].containsKey('cotz')) {
        irPorCotz.add({'index': i, 'id': resps[i]['c_id']});
      }
    }

    if(irPorCotz.isNotEmpty) {

      final cotEm = ContactsRepository();
      Map<String, dynamic> cotzCache = {};
      for (var i = 0; i < irPorCotz.length; i++) {

        if(cotzCache.containsKey('${irPorCotz[i]['id']!}')) {
          resps[irPorCotz[i]['index']!]['cotz'] = cotzCache['${irPorCotz[i]['id']!}'];
        }else{
          await cotEm.getCotizadorByIdFromHarbi(irPorCotz[i]['id']!);
          if(!cotEm.result['abort']) {
            final coz = Map<String, dynamic>.from(cotEm.result['body']);
            cotzCache['${irPorCotz[i]['id']!}'] = coz;
            resps[irPorCotz[i]['index']!]['cotz'] = coz;
          }
        }
      }
      
      orden[OrdCamp.resps.name] = resps;
      await em.setContentFile('_buildJsonPerPieza', orden[OrdCamp.filename.name], orden);
      cotzCache = {};
    }

    return orden;
  }

  
  /// Buscamos la orden por textos
  List<Map<String, dynamic>> _procesarCmdOrdenBy(Map<String, dynamic> cmd) {

    final criterio = cmd['eval'].toString().trim().toLowerCase();
  
    final items = em.oCache.where((element) {
      final search = element[OrdCamp.orden.name][cmd['where']].toString().trim().toLowerCase();
      return (search.contains(criterio)) ? true : false;
    }).toList();
    
    if(items.isNotEmpty){
      // _queSelectedTmp = ['Orden ID > ${cmd['eval']}'];
      return _buildResults(items, null);
    }
    _queSelectedTmp = ['cc'];
    return [];
  }

  /// Buscamos la pieza por Textos
  List<Map<String, dynamic>> _procesarCmdPiezaBy(Map<String, dynamic> cmd) {

    List<Map<String, dynamic>> resPiezas = [];

    final criterio = cmd['eval'].toString().trim().toLowerCase();

    final items = em.oCache.where((element) {

      final lasPzas = List<Map<String, dynamic>>.from(element[OrdCamp.piezas.name]);

      final search = lasPzas.where((pza) => 
        pza[cmd['where']].toString().trim().toLowerCase().contains(criterio)
      ).toList();
      
      if(search.isNotEmpty) {
        resPiezas.addAll(search);
        return true;
      }

      return false;
    }).toList();
    
    return (items.isNotEmpty) ? _buildResults(items, resPiezas) : [];
  }

  /// Buscamos la respuesta por su ID
  List<Map<String, dynamic>> _procesarCmdByIdCot(Map<String, dynamic> cmd) {

    final orden = em.oCache.where((element) {
      final lasResps = List<Map<String, dynamic>>.from(element[OrdCamp.resps.name]);
      final search = lasResps.where((res) => res[cmd['where']] == cmd['eval']).toList();
      return (search.isNotEmpty) ? true : false;
    }).toList();

    return (orden.isNotEmpty) ? [orden.first] : [];
  }

  ///
  List<Map<String, dynamic>> _buildResults(
    List<Map<String, dynamic>> ords, List<Map<String, dynamic>>? lstPzas)
  {

    List<Map<String, dynamic>> results = [];
    List<Map<String, dynamic>> pzas = (lstPzas != null)
      ? List<Map<String, dynamic>>.from(lstPzas)
      : [];
    
    for (var i = 0; i < ords.length; i++) {

      if(lstPzas == null) {
        pzas = List<Map<String, dynamic>>.from(ords[i][OrdCamp.piezas.name]);
      }
      
      results.add({
        OrdCamp.filename.name: ords[i][OrdCamp.filename.name],
        OrdCamp.piezas.name: (pzas.isEmpty)
          ? [] : pzas.map((pieza) {
            final lstRes = List<Map<String, dynamic>>.from(ords[i][OrdCamp.resps.name]);
            final respCant = lstRes.where((element) => element['p_id'] == pieza['id']).toList();
            return _toJsonFromPieza(
              pieza, ords[i][OrdCamp.filename.name], respCant
            );
          }).toList()
      });
    }

    return results;
  }

  ///
  Map<String, dynamic> _toJsonFromPieza(
    Map<String, dynamic> fromFile, String filename, List<Map<String, dynamic>> resps) 
  {

    List<Map<String, dynamic>> respRs = [];
    String respCant = '0';

    if(resps.isNotEmpty) {
      
      List<Map<String, int>> irPor = [];
      respRs = resps.where((element) => element['p_id'] == fromFile['id']).toList();
      if(respRs.isNotEmpty) {
        for (var i = 0; i < respRs.length; i++) {
          if(!respRs[i].containsKey('cotz')) {
            irPor.add({'index': i, 'id': respRs[i]['c_id']});
          }
        }
      }

      respCant = '${respRs.length}';
      respRs = List<Map<String, dynamic>>.from(prov.sortCotsByPrice(respRs));
    }

    return {
      'id': fromFile['id'],
      'orden': fromFile['orden'],
      'piezaName': fromFile['piezaName'],
      'lado': fromFile['lado'],
      'posicion': fromFile['posicion'],
      'origen': fromFile['origen'],
      'fotos': fromFile['fotos'],
      'obs': fromFile['obs'],
      'resp': respCant,
      'resps': respRs,
      'filename': filename
    };
  }


}