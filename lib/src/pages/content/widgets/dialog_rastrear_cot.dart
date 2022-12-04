import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/repository/ordenes_repository.dart';

import '../../widgets/my_tool_tip.dart';
import '../../widgets/texto.dart';
import '../../widgets/widgets_utils.dart';
import '../../../config/sng_manager.dart';
import '../../../entity/orden_entity.dart';
import '../../../providers/items_selects_glob.dart';
import '../../../repository/inventario_repository.dart';
import '../../../services/scm/scm_entity.dart';
import '../../../services/scm/scm_repository.dart';
import '../../../services/status/est_stt.dart';
import '../../../vars/globals.dart';

class DialogRastrearCot extends StatefulWidget {

  final ValueChanged<void> onEmptyList;
  const DialogRastrearCot({
    Key? key,
    required this.onEmptyList
  }) : super(key: key);

  @override
  State<DialogRastrearCot> createState() => _DialogRastrearCotState();
}

class _DialogRastrearCotState extends State<DialogRastrearCot> {

  final globals = getSngOf<Globals>();
  final _scmEm = ScmRepository();

  /// Filtros basicos de rastreo
  bool _sendAll = true;
  bool _sendOLocal = false;
  bool _sendOForan = false;
  bool _isInit = false;
  late final ItemSelectGlobProvider itemProv;
  
  @override
  Widget build(BuildContext context) {

    if(!_isInit) {
      _isInit = true;
      itemProv = context.read<ItemSelectGlobProvider>();
    }

    return MyToolTip(
      msg: 'Enviar a Cotizar Orden [Ctr+Alt+R]',
      child: IconButton(
        icon: const Icon(Icons.slow_motion_video_sharp),
        iconSize: 18,
        color: const Color.fromRGBO(221, 221, 221, 1),
        constraints: const BoxConstraints(
          maxHeight: 25,
          maxWidth: 35
        ),
        onPressed: () async => await _rastrearCotizaciones()
      )
    );
  }

  ///
  Future<void> _rastrearCotizaciones() async {

    int codeStatus = 1;

    await WidgetsAndUtils.showAlertBody(
      context,
      titulo: 'RASTREAR Cotizaciones',
      dismissible: false,
      body: StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateIn) {
          
          return Container(
            width: MediaQuery.of(context).size.width * 0.5,
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if(codeStatus == 1)
                  ..._dialogBskOkTask(
                    onTap: (value) {
                      setStateIn((){
                        codeStatus = 2;
                      });
                    },
                    onState: (_) => setStateIn((){})
                  ),
                if(codeStatus == 2)
                  ..._dialogBskLoading()
              ]
            ),
          );
        }
      )
    );
  }

  ///
  List<Widget> _dialogBskOkTask
    ({required ValueChanged<void> onTap, required ValueChanged<void> onState})
  {

    String msg = 'Estás a punto de enviar esta solicitud '
    'al Servidor Central de Mensajería con el objetivo '
    'de encontrar entre los cotizadores el mejor costo.';

    return [
      Texto(txt: msg, isCenter: true, sz: 16,),
      const SizedBox(height: 8),
      const Texto(
        txt: '¿Estás segur@ de continuar?',
        txtC: Colors.white, isCenter: true
      ),
      const SizedBox(height: 15),
      const Divider(color: Colors.grey),
      const Texto(
        txt: 'FILTROS DE RASTREO BÁSICOS',
        txtC: Colors.amber, isCenter: true, isBold: true,
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Checkbox(
            value: _sendAll,
            checkColor: Colors.black,
            onChanged: (val) {
              _sendOForan = false;
              _sendOLocal = false;
              _sendAll = val ?? false;
              onState(null);
            }
          ),
          const Texto(
            txt: 'Enviar a Todos',
            txtC: Colors.white, isCenter: true, isBold: false,
          ),
          const SizedBox(width: 15),
          Checkbox(
            value: _sendOLocal,
            checkColor: Colors.black,
            onChanged: (val) {
              _sendAll = false;
              _sendOForan = false;
              _sendOLocal = val ?? false;
              onState(null);
            }
          ),
          const Texto(
            txt: 'Sólo a Locales',
            txtC: Colors.white, isCenter: true, isBold: false,
          ),
          const SizedBox(width: 15),
          Checkbox(
            value: _sendOForan,
            checkColor: Colors.black,
            onChanged: (val) {
              _sendAll = false;
              _sendOLocal = false;
              _sendOForan = val ?? false;
              onState(null);
            }
          ),
          const Texto(
            txt: 'Sólo a Foraneos',
            txtC: Colors.white, isCenter: true, isBold: false,
          ),
        ]
      ),
      const Divider(color: Colors.grey),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.red)
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Texto(txt: 'NO ENVIAR', txtC: Colors.white)
          ),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.purple)
            ),
            onPressed: () => onTap(null),
            child: const Texto(txt: 'SI ENVIAR', txtC: Colors.white)
          ),
        ],
      ),
      const SizedBox(height: 10),
    ];
  }

  ///
  List<Widget> _dialogBskLoading() {

    return [
      const Texto(
        txt: 'Estamos actualizando las Base de Datos, espera un momento por favor',
        isCenter: true
      ),
      const SizedBox(height: 10),
      StreamBuilder<String>(
        initialData: 'Iniciando',
        stream: _sendToCotizar(),
        builder: (_, AsyncSnapshot<String> snap) {

          if(snap.data!.contains('ok')) {
            Navigator.of(context).pop();
          }
          if(snap.data!.contains('ERROR') || snap.data!.isEmpty) {
            return _dialogBskHasError(snap.data);
          }else{
            return _dialogBskInProcess(snap.data);
          }
        }
      )
    ];
  }

  ///
  Widget _dialogBskInProcess(String? txt) {

    return Column(
      children: [
        const SizedBox(
          width: 40, height: 40,
          child: CircularProgressIndicator()
        ),
        const SizedBox(height: 10),
        Texto(txt: txt ?? '', isCenter: true, txtC: Colors.white)
      ],
    );
  }

  ///
  Widget _dialogBskHasError(String? txt) {

    return Column(
      children: [
        Texto(txt: txt ?? '', isCenter: true),
        const SizedBox(height: 15),
        const Texto(
          txt: 'POR FAVOR INTÉNTALO DE NUEVO',
          txtC: Colors.amber,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.red)
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Texto(txt: 'ENTENDIDO', txtC: Colors.white)
        ),
      ],
    );
  }

  ///
  Stream<String> _sendToCotizar() async* {

    final scm = ScmEntity();
    scm.slugCamp = 'busk_cots';
    scm.emiterId = itemProv.ordenEntitySelect!.uId;
    scm.remiterId = globals.user.id;
    scm.target = 'orden';
    scm.src = {'id':itemProv.idOrdenSelect};

    scm.filter['zona'] = 'all';
    scm.filter['zona'] = (_sendOLocal) ? 'loc' : scm.filter['zona'];
    scm.filter['zona'] = (_sendOForan) ? 'for' : scm.filter['zona'];
    scm.filter['receivers'] = [];

    yield 'Enviando y Actualizando datos...';
    final stt = await EstStt.getFirstSttByEstBusqueda(itemProv.ordenEntitySelect!.status());

    Map<String, dynamic> toSendData = scm.toJson();
    toSendData['stt'] = {'est': stt['est'], 'stt': stt['stt']};
    toSendData['created'] = DateTime.now().millisecondsSinceEpoch;
    
    // Las campañas se guardan en archivos en el servidor.
    bool isLocal = false;
    if(globals.env == 'dev') {
      isLocal = true;
    }
    await _scmEm.setCampaingInDb(toSendData, isLocal: isLocal);

    if(!_scmEm.result['abort']) {

      _scmEm.clean();
      String avo = '${toSendData['avo']}';
      toSendData = {
        'version': 'none',
        'ordenes': [ { 'orden': itemProv.ordenEntitySelect!.id, 'stt': stt } ]
      };
      await OrdenesRepository().changeStatusOrdsAndPzasToServer(toSendData, isLocal: true);
      int inxOrd = itemProv.ordenes.indexWhere(
        (e) => e[OrdCamp.orden.name]['o_id'] == itemProv.ordenEntitySelect!.id
      );

      if(inxOrd != -1) {
        // Cambiando los status de las ordenes
        itemProv.ordenes[inxOrd][OrdCamp.orden.name]['o_est'] = stt['est'];
        itemProv.ordenes[inxOrd][OrdCamp.orden.name]['o_stt'] = stt['stt'];
        final invEm = InventarioRepository();
        final filename = '${itemProv.ordenEntitySelect!.id}-$avo.json';
        invEm.setContentFile('_sendToCotizar', filename, itemProv.ordenes[inxOrd]);
        await _limpiandoCache(inxOrd);
      }

      yield 'ok';
    }else{
      yield '${_scmEm.result['body']}';
    }
  }

  /// Eliminamos las ordenes asignadas tambien en la variable _ordenes.
  Future<void> _limpiandoCache(int indexOrd) async {

    List<Map<String, dynamic>> ordenes = List<Map<String, dynamic>>.from(itemProv.ordenes);
    
    ordenes.removeAt(indexOrd);
    itemProv.disposeMy();
    itemProv.ordenes = List<Map<String, dynamic>>.from(ordenes);
    if(ordenes.isEmpty) {
      widget.onEmptyList(null);
    }
  }
}