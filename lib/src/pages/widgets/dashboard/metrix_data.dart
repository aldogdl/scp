import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'lst_autopartes.dart';
import 'title_seccion.dart';
import '../texto.dart';
import '../invirt/tile_bandeja_entrada.dart';
import '../../../entity/metrix_entity.dart';
import '../../../entity/orden_entity.dart';
import '../../../providers/socket_conn.dart';
import '../../../providers/centinela_provider.dart';
import '../../../repository/inventario_repository.dart';

class MetrixData extends StatefulWidget {

  final String file;
  const MetrixData({
    Key? key,
    required this.file
  }) : super(key: key);

  @override
  State<MetrixData> createState() => _MetrixDataState();
}

class _MetrixDataState extends State<MetrixData> {

  final _invEm = InventarioRepository();
  
  late Future _getDataFromFile;
  late CentinelaProvider _prov;
  
  bool _isInit = false;
  int lastUpdate = -1;

  @override
  void initState() {
    _getDataFromFile = _getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return SizedBox.expand(
      child: FutureBuilder(
        future: _getDataFromFile,
        builder: (_, AsyncSnapshot snap) {

          if(snap.connectionState == ConnectionState.done) {

            if(_prov.data.isEmpty) {
              return const Texto(txt: 'No se encontró la Orden');
            }

            return Selector<SocketConn, int>(
              selector: (_, prov) => prov.irisUpdate,
              builder: (_, val, ___) => _body(val),
            );
          }
          return _load();
        },
      ),
    );
  }

  ///
  Widget _body(int newUpdate) {

    final mtrx = MetrixEntity();
    mtrx.fromJson(Map<String, dynamic>.from(_prov.data[OrdCamp.metrik.name]));

    return Column(
      children: [
        if(newUpdate != lastUpdate)
          FutureBuilder(
            future: _getData(),
            builder: (_, AsyncSnapshot snap) {

              if(snap.hasData && snap.data) {
                if(mounted) {
                  Future.microtask((){
                    setState(() { lastUpdate = newUpdate; });
                  });
                }
              }
              return const SizedBox();
            }
          ),
        TileBandejaEntrada(
          nomFile: widget.file,
          isSelected: true,
          offOpenDash: true,
          onTap: (int sabe){},
        ),
        const Divider(),
        _row('Solicitante:', _prov.data['orden']['u_nombre']),
        _row('Cant. de Msgs. Enviados', '${mtrx.sended.length} de ${mtrx.toTot.length}'),
        const Divider(),
        _row('Cant. Msgs. Vistos', '${mtrx.see}'),
        _row('Pieza en [APARTADOS]', '${mtrx.apr}'),
        _row('Respondidas [No la Tengo]', '${mtrx.ntg}'),
        const Divider(),
        _row('Cant. de Respuestas', '${mtrx.rsp}'),
        const SizedBox(height: 8),
        const TitleSeccion(
          child: Texto(txt: 'LISTA DE AUTOPARTES',
            isBold: true, isCenter: true,
            txtC: Colors.black,
          )
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: LstAutopartes(
              piezas: List<Map<String, dynamic>>.from(_prov.data['piezas'])
            ),
          ),
        )
      ],
    );
  }

  ///
  Widget _load() {

    return const SizedBox(
      width: 50, height: 50,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  ///
  Widget _row(String label, String value) {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          Texto(txt: label),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(50)
            ),
            child: Texto(txt: value, txtC: Colors.greenAccent),
          )
        ],
      ),
    );
  }

  ///
  Future<bool> _getData() async {

    if(!_isInit) {
      _isInit = true;
      _prov = context.read<CentinelaProvider>();
      _prov.isUpdateCots = false;
    }

    String verIris = '';
    if(_prov.data.isNotEmpty) {
      if(_prov.data.containsKey(OrdCamp.iris.name)) {
        verIris = _prov.data[OrdCamp.iris.name]['version'];
      }
    }
    
    _prov.data = await _invEm.getContentFile(widget.file);

    if(_prov.data.isNotEmpty) {
      if(_prov.data.containsKey(OrdCamp.iris.name)) {
        if(verIris != _prov.data[OrdCamp.iris.name]['version']) {
          // Hay una version distinta de iris, hay que refrescar cotizadores
          _prov.isUpdateCots = true;
        }
      }
    }
    
    bool reset = false;
    if(!_prov.isUpdateCots) {
      if(_prov.cotz.isEmpty || _prov.data['orden']['o_id'] != _prov.idOrdenCurrent) {
        reset = true;
      }
    }

    if(reset || _prov.isUpdateCots) {
      _prov.idOrdenCurrent = _prov.data['orden']['o_id'];
      if(!_prov.isUpdateCots) {
        _prov.cotz = [{}];
      }else{
        _prov.forceRefreshCotz();
      }
      return true;
    }

    return false;
  }

}