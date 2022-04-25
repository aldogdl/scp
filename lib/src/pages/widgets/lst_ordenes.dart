import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/providers/socket_conn.dart';

import 'orden_tile.dart';
import '../../config/sng_manager.dart';
import '../../vars/globals.dart';
import '../../entity/orden_entity.dart';
import '../../entity/piezas_entity.dart';
import '../../providers/items_selects_glob.dart';
import '../../repository/ordenes_repository.dart';
import '../../repository/piezas_repository.dart';
import '../../services/get_path_images.dart';
import '../../services/rutas/est_stt.dart';
import '../../services/rutas/rutas_cache.dart';

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
  final PiezasRepository _pzasEm = PiezasRepository();
  final RutasCache rutasCache = getSngOf<RutasCache>();

  final ScrollController _scrollCtr = ScrollController();
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

    if(!_isInit) {
      _isInit = true;
      provi = context.read<ItemSelectGlobProvider>();
    }

    return Selector<ItemSelectGlobProvider, List<OrdenEntity>>(
      selector: (_, proviSel) => proviSel.ordenes,
      builder: (_, ords, __) {
        
        return Scrollbar(
          controller: _scrollCtr,
          isAlwaysShown: true,
          radius: const Radius.circular(3),
          showTrackOnHover: true,
          trackVisibility: true,
          child: ListView.builder(
            controller: _scrollCtr,
            itemCount: ords.length,
            itemBuilder: (_, index) {
              
              return GestureDetector(
                onTap: () => _selectedOrden(index),
                child: Center(
                  child: OrdenTile(orden: ords[index]),
                ),
              );
            }
          ),
        );
      },
    );
  }

  ///
  Future<void> _recuperarTodasLasOrdenes() async {

    await rutasCache.hidratar();
    provi.ordenes = [];
    int avo = (widget.asignadas) ? globals.idUser : 0;
    
    widget.onLoading({'isLoading': true, 'msg': 'Ordenes'});
    await _ordenEm.getAllOrdenesByAvo(avo);

    List<OrdenEntity> recSer = [];
    if(_ordenEm.result['abort']) {
      if(_ordenEm.result['body'].contains('Host')) {
        context.read<SocketConn>().hasErrWithIpDbLocal = _ordenEm.result['body'];
        _ordenEm.result['body'] = '';
      }
    }

    if(_ordenEm.result['body'].isNotEmpty) {
      for (var i = 0; i < _ordenEm.result['body'].length; i++) {
        OrdenEntity ent = OrdenEntity();
        ent.fromServer(_ordenEm.result['body'][i]);
        recSer.add(ent);
      }
      provi.ordenes = recSer;
    }
    widget.onLoading({'isLoading': false, 'msg': 'Ordenes'});
  }

  ///
  Future<void> _selectedOrden(int indexOrden) async {

    // Evitar que se gasten recursos al precionar la misma orden
    if(provi.idOrdenSelect == provi.ordenes[indexOrden].id) {
      if(provi.piezas.isNotEmpty) {
        return;
      }
    }

    if(widget.asignadas) {
      // Visualizamos las ordenes que estan asignadas al AVO
      await _determinarAccionSegunStatus(indexOrden);
    }else{
      // Estamos en la seccion de no asignadas
      provi.piezas = [];
      provi.fotosByPiezas = [];
      provi.idPzaSelect = 0;
      provi.idOrdenSelect = provi.ordenes[indexOrden].id;
      provi.setOrdenEntitySelect(provi.ordenes[indexOrden]);
    }
  }

  ///
  Future<void> _determinarAccionSegunStatus(int index) async {

    var cStt = provi.ordenes[index].status();
    var nStt = <String, dynamic>{};
    
    // Si el status esta entre los casos siguientes su cambio de Status es en
    // automático en caso contrario el cambio es manual realizado por el usuario
    switch (cStt['stt']) {
      case "1": // Orden en Fila
        // Buscamos el siguiente status de la estación
        nStt = await EstStt.getNextSttByEst(cStt);
        break;
      default:
        // La reaccion normal de esta seccion es visualizar las piezas.
        await _recuperarPiezasFromDb(index);
    }

    if(nStt.isNotEmpty && !nStt.containsKey('error')) {

      bool changeStt = true;
      // Acciones automáticas según el status
      switch (nStt['stt']) {
        case "2": // Orden en revisión
          await _recuperarPiezasFromDb(index);
          break;
        default:
          changeStt = false;
      }

      if(changeStt) {
        provi.ordenes[index].est = nStt['est'];
        provi.ordenes[index].stt = nStt['stt'];
        nStt['orden'] = provi.ordenes[index].id;
        nStt['version'] = DateTime.now().millisecondsSinceEpoch;
        _ordenEm.changeStatusToServer(nStt, isLocal: true);
        _ordenEm.changeStatusToServer(nStt, isLocal: false);
      }
    }
  }

  /// Cuando el status requiere que revisemos los datos de las piezas
  Future<void> _recuperarPiezasFromDb(int inxOrd) async {

    provi.fotosByPiezas = [];
    await Future.delayed(const Duration(milliseconds: 200));

    widget.onLoading({'isLoading': true, 'msg': 'Piezas'});

    await _pzasEm.getPiezasByOrden(provi.ordenes[inxOrd].id);
    if(_pzasEm.result['body'].isNotEmpty) {

      List<PiezasEntity> pzas = [];
      List<Map<String, dynamic>> fpzas = [];

      for (var i = 0; i < _pzasEm.result['body'].length; i++) {
        PiezasEntity ent = PiezasEntity();
        ent.fromServer(_pzasEm.result['body'][i]);
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
        provi.idOrdenSelect = provi.ordenes[inxOrd].id;
        provi.setOrdenEntitySelect(provi.ordenes[inxOrd]);
        pzas = [];
        fpzas= [];
      }
    }

    widget.onLoading({'isLoading': false, 'msg': 'Ordenes'});
  }

}