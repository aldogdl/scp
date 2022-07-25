import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'orden_tile.dart';
import '../../config/sng_manager.dart';
import '../../entity/orden_entity.dart';
import '../../entity/piezas_entity.dart';
import '../../providers/pages_provider.dart';
import '../../providers/items_selects_glob.dart';
import '../../providers/socket_conn.dart';
import '../../repository/socket_centinela.dart';
import '../../repository/ordenes_repository.dart';
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

  final Globals globals = getSngOf<Globals>();
  final OrdenesRepository _ordenEm = OrdenesRepository();
  final SttsCache sttsCache = getSngOf<SttsCache>();
  final ScrollController _scrollCtr = ScrollController();
  final _sockCenti = SocketCentinela();
  late final PageProvider pageProv;
  late ItemSelectGlobProvider provi;

  bool _isInit = false;

  @override
  void initState() {

    _recuperarTodasLasOrdenes();
    super.initState();
  }

  @override
  void dispose() {
    _scrollCtr.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {

    return Selector<PageProvider, bool>(
      selector: (_, prov) => prov.refreshLsts,
      builder: (_, isR, __) {

        if(isR) {
          _recuperarTodasLasOrdenes();
          return const SizedBox();
        }

        return _body();
      },
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
      _sockCenti.init(context);
      pageProv = context.read<PageProvider>();
    }

    await sttsCache.hidratar();
    await _sockCenti.getFromFile(globals.ipHarbi);

    provi.ordenes = [];
    widget.onLoading({'isLoading': true, 'msg': 'Ordenes'});

    if(widget.asignadas) {
      await _getAsignadas();
    }else{
      await _getParaAsignar();
    }
    
    if(pageProv.refreshLsts) {
      pageProv.refreshLsts = false;
    }

    widget.onLoading({'isLoading': false, 'msg': 'Ordenes'});
  }

  ///
  Future<void> _getParaAsignar() async {

    late final SocketConn sock = context.read<SocketConn>();
    
    List<Map<String, dynamic>> recSer = [];

    await _ordenEm.getAllOrdenesByAvoFromServer(0, isLocal: globals.isLocalConn);
    if(_ordenEm.result['abort']) {
      if(_ordenEm.result['body'].contains('Host')) {
        sock.hasErrWithIpDbLocal = _ordenEm.result['body'];
        _ordenEm.result['body'] = '';
      }
    }

    if(_ordenEm.result['body'].isNotEmpty) {

      for (var i = 0; i < _ordenEm.result['body'].length; i++) {
        OrdenEntity ent = OrdenEntity();
        ent.fromServer(_ordenEm.result['body'][i]);
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
          _ordenEm.buildMapFileOrden(orden: ent.toJson(), emisor: ent.uId, pzas: pzas)
        );
      }

      provi.ordenes = recSer;
    }
  }

  ///
  Future<void> _getAsignadas() async {

    String? est;
    if(pageProv.page == Paginas.solicitudes) {
      est = '2';
    }
    provi.ordenes = await _ordenEm.getAllOrdenesByAvo(globals.user.id, est: est);
  }

  // ///
  // Future<void> _recuperarTodasLasOrdenes() async {

  //   late final SocketConn sock;

  //   if(!_isInit) {
  //     _isInit = true;
  //     provi = context.read<ItemSelectGlobProvider>();
  //     sock = context.read<SocketConn>();
  //     _centiProv = context.read<CentinelaFileProvider>();
  //     _sockCenti.init(context);
  //     pageProv = context.read<PageProvider>();
  //   }

  //   await sttsCache.hidratar();
  //   await _sockCenti.getFromFile(globals.ipHarbi);

  //   provi.ordenes = [];
  //   int avo = (widget.asignadas) ? globals.user.id : 0;
    
  //   widget.onLoading({'isLoading': true, 'msg': 'Ordenes'});
  //   await _ordenEm.getAllOrdenesByAvo(avo, isLocal: globals.isLocalConn);

  //   List<OrdenEntity> recSer = [];
  //   if(_ordenEm.result['abort']) {
  //     if(_ordenEm.result['body'].contains('Host')) {
  //       sock.hasErrWithIpDbLocal = _ordenEm.result['body'];
  //       _ordenEm.result['body'] = '';
  //     }
  //   }

  //   if(_ordenEm.result['body'].isNotEmpty) {
  //     for (var i = 0; i < _ordenEm.result['body'].length; i++) {
  //       OrdenEntity ent = OrdenEntity();
  //       ent.fromServer(_ordenEm.result['body'][i]);
  //       recSer.add(ent);
  //     }
  //     provi.ordenes = recSer;
  //   }

  //   if(pageProv.refreshLsts) {
  //     pageProv.refreshLsts = false;
  //   }

  //   widget.onLoading({'isLoading': false, 'msg': 'Ordenes'});
  // }

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

      // Estamos en la seccion de no asignadas
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
    await Future.delayed(const Duration(milliseconds: 200));

    widget.onLoading({'isLoading': true, 'msg': 'Piezas'});

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

    if(nStt.isNotEmpty) {
      provi.ordenes[inxOrd][OrdCamp.orden.name]['o_est'] = nStt['est'];
      provi.ordenes[inxOrd][OrdCamp.orden.name]['o_stt'] = nStt['stt'];
      nStt['orden'] = provi.ordenes[inxOrd][OrdCamp.orden.name]['o_id'];
      nStt['version'] = DateTime.now().millisecondsSinceEpoch;
      await _ordenEm.changeSttToServers(nStt);
      await _ordenEm.setOrdenAsignadas(['${nStt['orden']}'], globals.user.id);
    }

    widget.onLoading({'isLoading': false, 'msg': 'Piezas'});
  }

}