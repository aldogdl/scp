import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'texto.dart';
import 'orden_tile.dart';
import '../../config/sng_manager.dart';
import '../../entity/orden_entity.dart';
import '../../entity/piezas_entity.dart';
import '../../providers/pages_provider.dart';
import '../../providers/items_selects_glob.dart';
import '../../providers/socket_conn.dart';
import '../../repository/socket_centinela.dart';
import '../../repository/ordenes_repository.dart';
import '../../repository/inventario_repository.dart';
import '../../services/get_path_images.dart';
import '../../services/status/est_stt.dart';
import '../../services/status/stts_cache.dart';
import '../../vars/globals.dart';

class LstOrdenes extends StatefulWidget {

  final ValueChanged<Map<String, dynamic>> onLoading;
  final bool asignadas;
  const LstOrdenes({
    Key? key,
    required this.asignadas,
    required this.onLoading,
  }) : super(key: key);

  @override
  State<LstOrdenes> createState() => _LstOrdenesState();
}

class _LstOrdenesState extends State<LstOrdenes> {

  final globals = getSngOf<Globals>();
  final sttsCache = getSngOf<SttsCache>();

  final _ordenEm = OrdenesRepository();
  final _invEm = InventarioRepository();
  final _scrollCtr = ScrollController();
  final _sockCenti = SocketCentinela();
  late final PageProvider pageProv;
  late ItemSelectGlobProvider provi;

  bool _isInit = false;
  bool _checkIntegri = true;
  bool _waitIsWorking = false;
  final _errCheckIntegrid = ValueNotifier<String>('Checando Integridad');

  @override
  void initState() {
    _checkIntegri = widget.asignadas;
    _recuperarTodasLasOrdenes();
    super.initState();
  }

  @override
  void dispose() {
    _scrollCtr.dispose();
    _errCheckIntegrid.dispose();
    provi.ordenes.clear();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {

    return Column(
      children: [

        if(_checkIntegri)
          ValueListenableBuilder<String>(
            valueListenable: _errCheckIntegrid,
            builder: (_, msg, __) {

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if(!msg.contains('Integra') && !msg.startsWith('[x]'))
                    ...[
                      const SizedBox(
                        width: 10, height: 10,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                    ],
                  Texto(
                    txt: msg, sz: 11,
                    txtC: (!msg.contains('Integra'))
                      ? const Color.fromARGB(255, 255, 235, 59)
                      : const Color.fromARGB(255, 180, 180, 180)
                  )
                ],
              );
            }
          ),
        const SizedBox(height: 8),
        Expanded(
          child: Selector<PageProvider, bool>(
            selector: (_, prov) => prov.refreshLsts,
            builder: (_, isR, __) {

              if(isR) {
                _recuperarTodasLasOrdenes();
                return const SizedBox();
              }

              return _body();
            },
          ),
        )
      ],
    );
  }

  ///
  Widget _body() {

    return Scrollbar(
      controller: _scrollCtr,
      thumbVisibility: true,
      radius: const Radius.circular(3),
      trackVisibility: true,
      child: Selector<ItemSelectGlobProvider, List<Map<String, dynamic>>>(
        selector: (_, proviSel) => proviSel.ordenes,
        builder: (_, ords, __) {

          return ListView.builder(
            controller: _scrollCtr,
            itemCount: ords.length,
            primary: false,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (_, index) {
              
              return GestureDetector(
                onTap: () => _selectedOrden(index),
                child: Center(
                  child: OrdenTile(
                    orden: provi.getOrden(index),
                    cantPzas: provi.ordenes[index][OrdCamp.piezas.name].length
                  ),
                ),
              );
            }
          );
        },
      )
    );
  }

  ///
  Future<void> _recuperarTodasLasOrdenes() async {

    if(!_isInit) {
      _isInit = true;
      provi = context.read<ItemSelectGlobProvider>();
      pageProv = context.read<PageProvider>();
      _sockCenti.init(context);
    }

    await sttsCache.hidratar();

    if(widget.asignadas) {
      await _getAsignadas();
    }else{
      widget.onLoading({'isLoading': true, 'msg': 'Ordenes'});
      await _getParaAsignar();
    }
    
    if(pageProv.refreshLsts) {
      pageProv.refreshLsts = false;
    }
    widget.onLoading({'isLoading': false, 'msg': 'Ordenes'});
    return;
  }

  ///
  Future<void> _getParaAsignar() async {

    if(_waitIsWorking) { return; }
    if(!mounted) { return; }
    late final SocketConn sock = context.read<SocketConn>();
    
    List<Map<String, dynamic>> recSer = [];
    _waitIsWorking = true;

    await _ordenEm.getAllOrdenesByAvoFromServer(0, hydra: 'array');
    if(_ordenEm.result['abort']) {
      if(_ordenEm.result['body'].contains('Host')) {
        sock.hasErrWithIpDbLocal = _ordenEm.result['body'];
        _ordenEm.result['body'] = '';
      }
    }

    if(_ordenEm.result['abort']) {
      if(_ordenEm.result['body'].contains('version')) {
        _ordenEm.result['body'] = '';
      }
    }

    if(_ordenEm.result['body'].isNotEmpty) {

      for (var i = 0; i < _ordenEm.result['body'].length; i++) {

        OrdenEntity ent = OrdenEntity();
        ent.fromArrayServer(_ordenEm.result['body'][i]);
        List<Map<String, dynamic>> pzas = [];
        final centi = _sockCenti.getContenCentinela();
        if(centi.isNotEmpty) {
          if(centi['piezas'].isNotEmpty) {
            if(centi['piezas'].containsKey('${ent.id}')) {
              for (var i = 0; i < centi['piezas']['${ent.id}'].length; i++) {
                pzas.add({'idP':centi['piezas']['${ent.id}'][i]});
              }
            }
          }
        }

        recSer.add(
          _invEm.buildMapFileOrden(orden: ent.toJson(), emisor: ent.uId, pzas: pzas)
        );
      }
      _waitIsWorking = false;
      _ordenEm.clear();
      provi.ordenes = recSer;
    }
  }

  ///
  Future<void> _getAsignadas() async {

    String? est = (pageProv.page == Paginas.solicitudes) ? '2' : null;
    provi.ordenes = await _invEm.getAllOrdenesByAvo(
      globals.user.id, est: est, from: 'files'
    );
    
    if(est != null) {
      if(_checkIntegri) { _checkIntegridad(est); }
    }
  }

  /// Descargamos las ordenes desde el servidor local y revisamos que coincidan
  /// con el centinela actual u con las existentes en los archivos.
  Future<void> _checkIntegridad(String est) async {
    
    if (!mounted) { return; }
    _errCheckIntegrid.value = 'Tomando Registros desde SL';
    _ordenEm.result.clear();
    await _ordenEm.getAllIdsOrdenesByAvoFromServer(globals.user.id);
    
    if(_ordenEm.result['abort']) {
      if(_ordenEm.result['body'].contains('Host')) {
        if (!mounted) { return; }
        _errCheckIntegrid.value = _ordenEm.result['body'];
        _ordenEm.result['body'] = '';
        return;
      }
    }

    if(_ordenEm.result['body'].isEmpty) {
      if (!mounted) { return; }
      _errCheckIntegrid.value = '[x] SIN ORDENES AÚN';
      return;
    }
    
    List<String> fromDb    = [];
    List<String> fromCenti = [];
    List<String> fromFiles = [];

    var tmp = List<Map<String, dynamic>>.from(_ordenEm.result['body']);
    for (var i = 0; i < tmp.length; i++) {
      if(tmp[i]['o_est'] == est) {
        if(!fromDb.contains('${tmp[i]['o_id']}')) {
          fromDb.add('${tmp[i]['o_id']}');
        }
      }
    }

    tmp = [];
    if (!mounted) { return; }
    _errCheckIntegrid.value = 'Actualizando Centinela/HARBI';
    await _wait();
   
    final res = await _sockCenti.getFromApiHarbi();
    if(res.containsKey('abort')) {
      if(res['abort']) {
        _errCheckIntegrid.value = res['body'];
        return;
      }
    }
    
    var centi = await _sockCenti.getFromFile(globals.currentVersion);
    globals.currentVersion = '${centi['version']}';

    if(centi.isNotEmpty) {
      if(centi.containsKey('avo')) {
        if(centi['avo'].containsKey('${globals.user.id}')) {
          var tmpC = List<String>.from(centi['avo']['${globals.user.id}']);
          for (var i = 0; i < tmpC.length; i++) {
            if(centi['stt'].containsKey(tmpC[i])) {
              if(centi['stt'][tmpC[i]]['e'] == '2') {
                fromCenti.add(tmpC[i]);
              }
            }
          }
          tmpC = [];
        }
      }
    }
    centi = {};

    if (!mounted) { return; }
    _errCheckIntegrid.value = 'Registros Locales';
    await _wait();

    if(provi.ordenes.isNotEmpty) {
      for (var i = 0; i < provi.ordenes.length; i++) {
        fromFiles.add('${provi.ordenes[i][OrdCamp.orden.name]['o_id']}');
      }
    }

    if (!mounted) { return; }
    _errCheckIntegrid.value = 'Cotejando Integridad';
    await _wait();
    
    if(fromDb.isNotEmpty) {
      await _checkIntegridOrdenesDesasignadas(fromDb, fromCenti, fromFiles);
      await _checkIntegridOrdenesAsignadas(fromDb, fromCenti, fromFiles);
    }else{
      // TODO no hay nada asignado o ya me quitaron todas las ordenes.
    }
    
    if (!mounted) { return; }
    _errCheckIntegrid.value = '[${fromDb.length}] Ordenes Revisadas e Integras.';
    await _wait();
  }

  ///
  Future<void> _wait({int int = 250}) async => await Future.delayed(Duration(milliseconds: int));

  /// Checamos las ordenes Desasignadas.
  Future<bool> _checkIntegridOrdenesDesasignadas
    (List<String> fromDb, List<String> fromCenti, List<String> fromFiles) async
  {

    _errCheckIntegrid.value = 'Ordenes Desasignadas';
    // Estas NO deben estar presentes en fromFiles.
    fromDb.sort();
    bool makeSetState = false;
    List<String> toDelIn = [];

    if(fromFiles.isNotEmpty) {

      fromFiles.sort();
      for (var i = 0; i < fromFiles.length; i++) {
        if(!fromDb.contains(fromFiles[i])) {
          toDelIn.add(fromFiles[i]);
        }
      }

      if(toDelIn.isNotEmpty) {

        await _invEm.delOrdenAsignadas(toDelIn, globals.user.id);
        await _invEm.delCacheIfExist(toDelIn, globals.user.id);

        var inScreen = List<Map<String, dynamic>>.from(provi.ordenes);
        for (var i = 0; i < toDelIn.length; i++) {
          final inx = provi.ordenes.indexWhere(
            (c) => '${c[OrdCamp.orden.name]['o_id']}' == toDelIn[i]
          );
          if(inx != -1) {
            inScreen.removeAt(inx);
            makeSetState = true;
          }
        }
        if(makeSetState) {
          provi.ordenes.clear();
          await _wait();
          provi.ordenes = inScreen;
        }
        inScreen = [];
      }

      // Estas NO deben estar presentes en fromCenti.
      toDelIn = [];
      if(fromCenti.isNotEmpty) {
        fromCenti.sort();
        for (var i = 0; i < fromCenti.length; i++) {
          if(!fromDb.contains(fromCenti[i])) {
            toDelIn.add(fromCenti[i]);
          }
        }
      }

      if(toDelIn.isNotEmpty) {
        await _sockCenti.delOrdenInCentinela(toDelIn, globals.user.id);
      }
    }

    return makeSetState;
  }

  /// Checamos las ordenes Asignadas.
  Future<bool> _checkIntegridOrdenesAsignadas
    (List<String> fromDb, List<String> fromCenti, List<String> fromFiles) async
  {

    _errCheckIntegrid.value = 'Ordenes Asignadas';
    bool makeSetState = false;
    List<String> toAddIn = [];

    // Agregamos todas las que esten en la base de datos pero no en los archivos
    if(fromFiles.isNotEmpty) {
      for (var i = 0; i < fromDb.length; i++) {
        if(!fromFiles.contains(fromDb[i])) {
          toAddIn.add(fromDb[i]);
        }
      }
    }else{
      toAddIn = List<String>.from(fromDb);
    }
    
    // Estas deben estar presentes en el Centinela (fromCenti).
    List<String> toIn = [];
    for (var i = 0; i < fromDb.length; i++) {
      if(!fromCenti.contains(fromDb[i])) {
        toIn.add(fromDb[i]);
      }
    }

    if(toIn.isNotEmpty) {
      for (var i = 0; i < toIn.length; i++) {
        if(!toAddIn.contains(toIn[i])) {
          toAddIn.add(toIn[i]);
        }
      }
    }
    
    if(toAddIn.isNotEmpty) {
      
      _errCheckIntegrid.value = 'Descargando Ordenes nuevas';
      await _invEm.setOrdenAsignadas(toAddIn, globals.user.id);

      await _invEm.setInCacheIfAbsent(toAddIn, globals.user.id);
      var inScreen = List<Map<String, dynamic>>.from(provi.ordenes);

      for (var i = 0; i < toAddIn.length; i++) {
        final inx = provi.ordenes.indexWhere(
          (c) => '${c[OrdCamp.orden.name]['o_id']}' == toAddIn[i]
        );
        if(inx == -1) {
          final filename = '${toAddIn[i]}-${globals.user.id}.json';
          final newOrd = await _invEm.getContentFile(filename);
          if(newOrd.isNotEmpty) {
            final existe = inScreen.indexWhere(
              (element) => element['filename'] == filename
            );

            if(existe != -1) {
              inScreen[existe] = newOrd;
            }else{
              inScreen.add(newOrd);
            }
            makeSetState = true;
          }
        }
      }

      if(makeSetState) {
        provi.ordenes.clear();
        await _wait();
        provi.ordenes = List<Map<String, dynamic>>.from(inScreen);
      }
      inScreen = [];
    }

    return makeSetState;
  }

  ///
  Future<void> _selectedOrden(int indexOrden) async {

    // Evitar que se gasten recursos al precionar la misma orden
    if(provi.idOrdenSelect == provi.ordenes[indexOrden][OrdCamp.orden.name]['o_id']) {
      if(provi.piezas.isNotEmpty) {
        return;
      }
    }
    
    if(widget.asignadas) {

      await _determinarAccionSegunStatus(indexOrden);
    }else{

      // Estamos en la seccion de NO ASIGNADAS
      provi.piezas = [];
      provi.fotosByPiezas = [];
      provi.idPzaSelect = 0;
      provi.idOrdenSelect = provi.ordenes[indexOrden][OrdCamp.orden.name]['o_id'];
      provi.setOrdenEntitySelect(provi.getOrden(indexOrden));
    }
  }

  ///
  Future<void> _determinarAccionSegunStatus(int index) async {

    var cStt = {
      'est' : provi.ordenes[index][OrdCamp.orden.name]['o_est'],
      'stt': provi.ordenes[index][OrdCamp.orden.name]['o_stt']
    };
    var nStt = <String, dynamic>{};

    // Si el status esta entre los casos siguientes su cambio de Status es en
    // automático en caso contrario el cambio es manual realizado por el usuario
    // en VER: 2 de las rutas la EST 2 es: Orden en Procesamiento
    if(cStt['est'] == '2') {

      switch (cStt['stt']) {
        case "1": // Orden en Fila
          // Buscamos el siguiente status de la estación
          nStt = await EstStt.getNextSttByEst(cStt);
          break;
        default:
          // La reaccion normal de esta seccion es visualizar las piezas.
          await _getPiezasByIndexOrden(index);
      }
    }

    if(nStt.isNotEmpty && !nStt.containsKey('error')) {
      
      // Acciones automáticas según el status
      switch (nStt['stt']) {
        case "2": // Orden en revisión
          await _getPiezasByIndexOrden(index, nStt: nStt);
          break;
        default:
      }
    }
  }

  /// Cuando el status requiere que revisemos los datos de las piezas
  Future<void> _getPiezasByIndexOrden(int inxOrd, {Map<String, dynamic> nStt = const {}}) async {

    provi.fotosByPiezas = [];
    await _wait();

    widget.onLoading({'msg': 'Piezas', 'isLoading': true});

    List<PiezasEntity> pzas = [];
    List<Map<String, dynamic>> fpzas = [];
    final pzasMap = provi.ordenes[inxOrd][OrdCamp.piezas.name];
    
    for (var i = 0; i < pzasMap.length; i++) {

      PiezasEntity ent = PiezasEntity();
      ent.fromFile(pzasMap[i], inxOrd);
      if(ent.fotos.isNotEmpty) {
        for (var i = 0; i < ent.fotos.length; i++) {    
          var fp = <String, dynamic>{
            'id' : ent.id,
            'foto': await GetPathImages.getPathPzaTmp(ent.fotos[i])
          };
          fpzas.add(fp);
        }
      }
      pzas.add(ent);
    }
    
    if(pzas.isNotEmpty) {
      provi.piezas = pzas;
      provi.fotosByPiezas = fpzas;
      provi.idPzaSelect = fpzas.first['id'];

      provi.idOrdenSelect = provi.ordenes[inxOrd][OrdCamp.orden.name]['o_id'];
      provi.setOrdenEntitySelect(provi.getOrden(inxOrd));
      pzas = [];
      fpzas= [];
    }
    
    if(nStt.isEmpty) {
      
      // provi.ordenes[inxOrd][OrdCamp.orden.name]['o_est'] = nStt['est'];
      // provi.ordenes[inxOrd][OrdCamp.orden.name]['o_stt'] = nStt['stt'];
      // nStt['orden'] = provi.ordenes[inxOrd][OrdCamp.orden.name]['o_id'];
      
      // nStt['version'] = 0;
      // await _ordenEm.changeStatusToServer(nStt, isLocal: true);

      // nStt['version'] = DateTime.now().millisecondsSinceEpoch;
      // await _ordenEm.changeStatusToServer(nStt, isLocal: false);
      
      // await _invEm.setOrdenAsignadas(['${nStt['orden']}'], globals.user.id);
     Future.microtask(() => setState(() {}));
    }

    widget.onLoading({'isLoading': false, 'msg': 'Piezas'});
  }

}