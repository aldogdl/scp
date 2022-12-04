import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/pages/widgets/texto.dart';
import 'package:scp/src/pages/widgets/widgets_utils.dart';

import '../../../providers/invirt_provider.dart';
import '../../../providers/window_cnf_provider.dart';
import '../../../repository/inventario_repository.dart';
import '../../../repository/piezas_repository.dart';
import '../../../providers/socket_conn.dart';

class QuerysProcess extends StatefulWidget {

  const QuerysProcess({Key? key}) : super(key: key);

  @override
  State<QuerysProcess> createState() => _QuerysProcessState();
}

class _QuerysProcessState extends State<QuerysProcess> {

  final _invEm = InventarioRepository();
  late InvirtProvider _invVir;
  late SocketConn _sock;

  bool _isInit = false;
  // Usado para bloquear descargas repetitivas en el QueryProcess
  // bool _isDownResp = false;
  // Usadas para descargar respuestas desde QueryProcess
  final List<List<String>> _idsPiezas = [];

  @override
  Widget build(BuildContext context) {

    if(!_isInit) {
      _isInit = true;
      _invVir = context.read<InvirtProvider>();
      _sock = context.read<SocketConn>();
    }

    return Row(
      children: [
        _receptorDeQuerys(),
        _procesadorDeQuerys()
      ],
    );
  }

  ///
  Widget _receptorDeQuerys() {

    return Selector<SocketConn, String>(
      selector: (_, prov) => prov.query,
      builder: (_, query, __) {

        _analizamosQueryDeEntrada(query);
        Future.delayed(const Duration(milliseconds: 100), (){
          _sock.query = '';
        });

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Icon(
            Icons.circle, size: 5,
            color: (query.isNotEmpty)
            ? const Color.fromARGB(255, 207, 253, 0)
            : const Color.fromARGB(255, 75, 88, 0),
          )
        );
      }
    );
  }

  ///
  Widget _procesadorDeQuerys() {

    return Selector<InvirtProvider, List<String>>(
      selector: (_, prov) => prov.querys,
      builder: (_, lstQuerys, __) {

        if(lstQuerys.isNotEmpty) {
          _procesarQuery(lstQuerys);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Row(
            children: [
              Text(
                '[ ${lstQuerys.length} ]',
                textScaleFactor: 1,
                style: _styleFont()
              ),
              const SizedBox(width: 15),
              Selector<SocketConn, String>(
                selector: (_, prov) => prov.isQueryAn,
                builder: (_, val, child) {
                  
                  if(val.isEmpty){ return child!; }

                  if(val == 'Analizando...') {
                    _checkNotificaciones(100);
                  }

                  return Row(
                    children: [
                      SizedBox(
                        width: 10, height: 10,
                        child: CircularProgressIndicator(
                          color: context.read<WindowCnfProvider>().sttBarrColorOn,
                          backgroundColor: Colors.white,
                          strokeWidth: 1,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(val, textScaleFactor: 1, style: _styleFont())
                    ],
                  );
                },
                child: const SizedBox(),
              )
            ],
          ),
        );
      }
    );
  }

  ///
  TextStyle _styleFont() {
    return GoogleFonts.inconsolata(
      fontSize: 12,
      color: const Color(0xFFFFFFFF)
    );
  }

  ///
  void _checkNotificaciones(int time){

    Future.delayed(Duration(milliseconds: time), () async {
      await _sock.chechNotiffCurrents();
      _checkNewAsigns(500);
    });
  }

  ///
  void _checkNewAsigns(int time) async {

    /// Checamos ordenes asigandas que no esten en archivo.
    Future.delayed(Duration(milliseconds: time), () async {

      final ids = await _sock.centi.checkNewAsigns(
        from: 'file', onlyCheck: true
      );
      if(ids.containsKey('ordAsign')) {
        if(ids['ordAsign'].isNotEmpty) {
          await _downNewAsigns(ids['ordAsign']);
        }
      }
      _checkNewResp(1000);
    });
  }

  ///
  void _checkNewResp(int time) async {

    /// Checamos ordenes asigandas que no esten en archivo.
    Future.delayed(Duration(milliseconds: time), () async {

      // if(!_isDownResp) {
      //   _isDownResp = true;
        
      //   Future.delayed(const Duration(milliseconds: 1000), () async {

      //     final ids = await _sock.centi.getIdsMyPiezas();
      //     _idsPiezas = _getBloquesIdsPiezas(ids);
      //     _sock.isQueryAn = 'Espera un momento.';
      //     await Future.delayed(const Duration(milliseconds: 500));
      //     _recuperarDatosFromServer();
      //   });

      // }
      _sock.isQueryAn = '';
    });
  }

  /// Revisamos el el query en cuestion no exista en la lista en cache y lo
  /// agregamos para ser procesada.
  void _analizamosQueryDeEntrada(String query) {

    if(query.isNotEmpty) {

      if(query != 'cc') {
        if(!existeQueryInCache(_invVir.querys, query)) {
          // print('no exite add $query');
          Future.microtask(() => _invVir.addQuerys(query));
        }
      }
    }
  }

  ///
  bool existeQueryInCache(List<String> querys, String query) {

    if(query.isNotEmpty) {
      final map1 = _invEm.toJsonQuery(query);
      for (var i = 0; i < querys.length; i++) {
        if(querys[i].isNotEmpty) {
          final map2 = _invEm.toJsonQuery(querys[i]);
          if(map1.containsKey('idMsg') && map2.containsKey('idMsg')) {
            if(map1['idMsg'] == map2['idMsg']) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  ///
  void _procesarQuery(List<String> lstQuerys) async {

    if(lstQuerys.isNotEmpty) {
      
      _invVir.query = lstQuerys.removeLast();

      if(_invVir.query.isNotEmpty) {
        _invVir.idOrdenAfectada = 0;
        _invVir.idOrdenAfectada = await _invEm.determinarAccByQuery(_invVir.query);
        
        // Revisamos que sea una respuesta, ya que esta merece un trato especial
        final map = _invEm.toJsonQuery(_invVir.query);
        if(map.containsKey('rsp')) {
          await _procesarQueryDeRespuesta(map);
        }else{
          // if(_invVir.idOrdenAfectada != 0) {
          //   Future.microtask(() => _invVir.addTrigger(_invVir.idOrdenAfectada));
          // }
          _invVir.querys = lstQuerys;
        }
      }
    }
  }

  /// Recuperamos los datos de las respuestas desde el SL
  void _recuperarDatosFromServer() async
  {

    if(_idsPiezas.isNotEmpty) {

      _sock.isQueryAn = 'Descargando respuestas del bloque ${_idsPiezas.length}';
      
      final res = await _recoveryRespuestas(_idsPiezas.first);
      if(res.isNotEmpty) {
        _sock.isQueryAn = 'Almacenando ${res.length} respuestas del bloque ${_idsPiezas.length}.';
        await Future.delayed(const Duration(milliseconds: 500));
        // await _invEm.setRespuestasByPieza(res);
      }
      _idsPiezas.removeAt(0);
      _recuperarDatosFromServer();
      return;
    }

    _sock.isQueryAn = 'Listo...';
    await Future.delayed(const Duration(milliseconds: 1000), (){
      _sock.isQueryAn = '';
      // _isDownResp = false;
    });

  }

  /// Construimos bloques de 3 para descargar los datos y no saturar el S.R.
  List<List<String>> _getBloquesIdsPiezas(List<String> misPiezas) {

    if(misPiezas.isEmpty) { return []; }
    const factor = 3;
    // Recuperar los ids de todas las piezas que tengo
    double veces = misPiezas.length / factor;
    int rota = veces.ceil();
    List<List<String>> result = [];
    for (var i = 0; i < rota; i++) {

      var block = <String>[];
      try {
        block = misPiezas.getRange(0, factor).toList();
      } catch (e) {
        block = misPiezas;
      }
      if(block.isNotEmpty) {
        result.add(block);
      }
      try {
        misPiezas.removeRange(0, factor);
      } catch (_) {
        break;
      }
    }
    return result;
  }

  // Descargar las nueva respuesta por id de respuesta
  Future<void> _procesarQueryDeRespuesta(Map<String, dynamic> query) async
  {
    // String msgFin = 'Listo...';
    // _sock.isQueryAn = 'Recuperando respuesta ID: ${query['rsp']}.';
    // _invEm.result.clear();

    // await _invEm.getRespuestasByIds([query['rsp']]);
    // if(!_invEm.result['abort']) {

    //   List<Map<String, dynamic>> res = [];
    //   try {
    //     res = List<Map<String, dynamic>>.from(_invEm.result['body']);
    //     if(res.isNotEmpty) {
    //       _sock.isQueryAn = 'Almacenando respuesta ID: ${query['rsp']}.';
    //       await _invEm.setRespuestaToFile(res);
    //       int? ord = int.tryParse('${query['orden']}');
    //       if(ord != null) {
    //         _invVir.addTriggerResp(ord);
    //       }
    //     }
    //   } catch (e) {
    //     msgFin = 'Error al Descargar Respuesta';
    //   }
    // }
    
    // _sock.isQueryAn = msgFin;
    // await Future.delayed(const Duration(milliseconds: 1000), (){
    //   _sock.isQueryAn = '';
    //   _isDownResp = false;
    // });

  }

  ///
  Future<List<Map<String, dynamic>>> _recoveryRespuestas(List<String> idsPzas) async {

    List<Map<String, dynamic>> resultado = [];

    final pzEm = PiezasRepository();
    await pzEm.getRespuestasByIdPiezas(idsPzas.join(','));

    if(!pzEm.result['abort']) {
      if(pzEm.result['body'].isNotEmpty) {
        resultado = List<Map<String, dynamic>>.from(pzEm.result['body']);
        pzEm.clear();
      }
    }

    return resultado;
  }

  ///
  Future<void> _downNewAsigns(List<String> ids) async {
    
    await WidgetsAndUtils.showAlertBody(
      context,
      dismissible: false,
      titulo: 'ORDENES ASIGNADAS',
      body: StreamBuilder(
        stream: _getOrdenesAsigns(ids),
        initialData: 'Buscando Ordenes.',
        builder: (_, AsyncSnapshot snap) {

          if(snap.data.toString().contains('Listo...')) {
            Future.delayed(const Duration(milliseconds: 500), (){
              Navigator.of(context).pop();
            });
          }

          return Container(
            width: MediaQuery.of(context).size.width * 0.5,
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const Texto(
                  txt: 'Se encontraron ordenes asignadas en tu repositorio '
                  'que aún no están en tus expedientes, espera un momento '
                  'para actualizar tus ordenes.',
                  txtC: Colors.white, isCenter: true,
                ),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Texto(
                  txt: snap.data, txtC: Colors.green, sz: 18, isCenter: true,
                )
              ],
            ),
          );
        }
      )
    );
  }

  ///
  Stream<String> _getOrdenesAsigns(List<String> ids) async* {

    List<String> downsOk = [];
    for (String id in ids) {
      yield 'Descargando Orden ID: $id  ${downsOk.length+1} de ${ids.length}';
      yield await _getOrdenesByID(id);
      downsOk.add(id);
      if(downsOk.length == ids.length) {
        yield 'Listo...';
      }
    }
  }

  ///
  Future<String> _getOrdenesByID(String id) async {

    return await _sock.centi.setOrdenAsignada(id);
  }


}

