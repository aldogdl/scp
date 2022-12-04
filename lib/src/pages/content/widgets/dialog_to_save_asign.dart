import 'package:flutter/material.dart';

import '../../widgets/texto.dart';
import '../../../config/sng_manager.dart';
import '../../../entity/orden_entity.dart';
import '../../../providers/centinela_file_provider.dart';
import '../../../providers/items_selects_glob.dart';
import '../../../vars/globals.dart';

class DialogToSaveAsign extends StatelessWidget {

  final ValueChanged<Map<String, List<OrdenEntity>>> onFinish;
  final ValueChanged<void> onError;
  final CentinelaFileProvider centiProv;
  final ItemSelectGlobProvider itemProv;
  final CPush cpushOrden;
  final Map<String, List<OrdenEntity>> ordenesAvo;
  final dynamic dataSaving;

  const DialogToSaveAsign({
    Key? key,
    required this.onFinish,
    required this.onError,
    required this.centiProv,
    required this.itemProv,
    required this.cpushOrden,
    required this.ordenesAvo,
    required this.dataSaving,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Texto(txt: 'GUARDANDO NUEVAS ASIGNACIONES', isBold: true, isCenter: true),
        const Divider(color: Colors.green),
        const SizedBox(height: 10),
        StreamBuilder<String>(
          stream: _saving(),
          initialData: 'Iniciando...',
          builder: (_, AsyncSnapshot<String> snap) {

            String result = snap.data ?? 'Cargando...';
            
            if(result.startsWith('ERROR')) {
              Future.delayed(const Duration(milliseconds: 250), (){
                onError(_);
              });
            }

            if(result.startsWith('ok')) {
              result = 'Listo!, Finalizando Proceso.';
              Future.delayed(const Duration(milliseconds: 250), (){
                onFinish(ordenesAvo);
              });
            }

            return _body(result);
          }
        )
      ],
    );
  }

  ///
  Widget _body(String result) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if(!result.startsWith('ERROR'))
          const Center(
            child: SizedBox(
              width: 40, height: 40,
              child: CircularProgressIndicator(),
            ),
          ),
        Texto(txt: result, isCenter: true, txtC: Colors.white),
        if(result.startsWith('ERROR'))
          ...[
            const Texto(
              txt: 'OCURRIO UN ERROR INESPERADO,\n¿Deseas Intentarlo nuevamente?',
              isCenter: true, txtC: Colors.amber,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _btnAlert(acc: 'NO', bg: Colors.red, fnc: false),
                _btnAlert(acc: 'SI', bg: Colors.purple, fnc: true),
              ],
            )
          ]
      ],
    );
  }

  ///
  Widget _btnAlert({
    required bool fnc,
    required String acc,
    required Color bg }) 
  {

    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(bg)
      ),
      onPressed: () => onFinish(ordenesAvo),
      child: Texto(txt: acc, isBold: true, isCenter: true, txtC: Colors.white)
    );
  }

  ///
  Stream<String> _saving() async* {
    
    final globals = getSngOf<Globals>();

    yield 'Preparando datos...';
    
    await centiProv.commit(cpushOrden, dataSaving);
    centiProv.updateVersion();

    Future.delayed(const Duration(milliseconds: 250));
    
    yield 'Guardando datos en Servidor LOCAL';
    await centiProv.push(cpushOrden, isLocal: true);
    
    if(globals.env != 'dev') {
      yield 'Guardando datos en Servidor REMOTO';
      await centiProv.push(cpushOrden, isLocal: false);
    }
    
    if(!centiProv.result['abort']) {

      if(cpushOrden == CPush.asignacion) {
        await _enviarAbajoLasOrdenesAsignadas();
        yield 'Limpiando Cache';
        await _limpiandoCache();
      }

      // Limpiamos las ordenes asignadas
      itemProv.ordenesAsignadas = {};
      yield 'ok';
      return;
    }
    
    yield '${centiProv.result['body']}';
  }

  /// Enviamos las ordenes asignadas a la parte inferior de la pantalla
  Future<void> _enviarAbajoLasOrdenesAsignadas() async {

    itemProv.ordenesAsignadas.forEach((idAvo, ordenesAsign) {

      // Convertir los ids en Entitys
      List<OrdenEntity> nords = [];
      for (var i = 0; i < ordenesAsign.length; i++) {
        final os = itemProv.ordenes.indexWhere((e) => e[OrdCamp.orden.name]['o_id'] == ordenesAsign[i]);
        if(os != -1) {
          nords.add( itemProv.getOrden(os) );
        }
      }

      if(ordenesAvo.containsKey('$idAvo')) {
        ordenesAvo['$idAvo']!.insertAll(0, nords);
      }else{
        ordenesAvo.putIfAbsent('$idAvo', () => nords);
      }
    });
  }

  /// Eliminamos las ordenes asignadas tambien en la variable _ordenes.
  Future<void> _limpiandoCache() async {

    itemProv.ordenesAsignadas.forEach((idAvo, ordenes) {

      List<Map<String, dynamic>> lstOld = List<Map<String, dynamic>>.from(itemProv.ordenes);
      for (var i = 0; i < ordenes.length; i++) {
        lstOld.removeWhere((e) => e[OrdCamp.orden.name]['o_id'] == ordenes[i]);
      }
      itemProv.ordenes = List<Map<String, dynamic>>.from(lstOld);
      lstOld = [];
    });
    
  }

}