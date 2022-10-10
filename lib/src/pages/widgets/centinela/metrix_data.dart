import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'lst_autopartes.dart';
import 'title_seccion.dart';
import '../texto.dart';
import '../invirt/tile_bandeja_entrada.dart';
import '../../../repository/inventario_repository.dart';
import '../../../providers/centinela_provider.dart';

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
  bool _isInit = false;
  late CentinelaProvider _prov;

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

            return Selector<CentinelaProvider, bool>(
              selector: (_, prov) => prov.refreshSeccMetrix,
              builder: (_, __, ___) => _body(),
            );
          }
          return _load();
        },
      ),
    );
  }

  ///
  Widget _body() {

    final mtrx = Map<String, dynamic>.from(_prov.data['metrik']);

    return Column(
      children: [
        TileBandejaEntrada(
          nomFile: widget.file,
          isSelected: true,
          withControls: false,
          onTap: (int sabe){},
        ),
        const Divider(),
        _row('Solicitante:', _prov.data['orden']['u_nombre']),
        _row('Status del Envio', _invEm.fromIntToStringStatusScm(mtrx['scmEst'])),
        _row('Cant. Msgs. Vistos', '${mtrx['see']}'),
        _row('Cant. de Respuestas', '${mtrx['rsp']}'),
        _row('Respondidas [No la Tengo]', '${mtrx['cnt']}'),
        _row('Cant. de Msgs. Enviados', _prov.extraerOfData('enviados')),
        _row('Cant. de Msgs. en Papelera', _prov.extraerOfData('pape')),
        _row('Cant. de Cotizadores', _prov.extraerOfData('cotz')),
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
            child: LstAutopartes(piezas: List<Map<String, dynamic>>.from(_prov.data['piezas'])),
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
  Future<void> _getData() async {

    if(!_isInit) {
      _isInit = true;
      _prov = context.read<CentinelaProvider>();
    }

    _prov.data = await _invEm.getContentFile(widget.file);
    
    if(_prov.cotz.isEmpty || _prov.data['orden']['o_id'] != _prov.idOrdenCurrent) {
      _prov.idOrdenCurrent = _prov.data['orden']['o_id'];
      _prov.cotz = [{}];
    }else{
      Future.microtask(() {
        _prov.addConsole('[!] Datos desde CACHE');
      });
      _prov.buildChartProv();
    }

  }

}