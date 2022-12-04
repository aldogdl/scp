import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../texto.dart';
import '../../../entity/metrix_entity.dart';
import '../../../repository/inventario_repository.dart';
import '../../../providers/socket_conn.dart';

class TileBandejaMetricas extends StatefulWidget {

  final int idOrden;
  final String filename;
  final ValueChanged<void>? onOpenDashboard;
  const TileBandejaMetricas({
    Key? key,
    required this.idOrden,
    required this.filename,
    required this.onOpenDashboard,
  }) : super(key: key);

  @override
  State<TileBandejaMetricas> createState() => _TileBandejaMetricasState();
}

class _TileBandejaMetricasState extends State<TileBandejaMetricas> {

  final _invEm = InventarioRepository();
  late Future<MetrixEntity> _getMetrik;
  MetrixEntity? metrik;
  int _idOrden = 0;
  int lastUpdate = 0;

  @override
  void initState() {
    _idOrden = widget.idOrden;
    _getMetrik = _getMetricas(true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    final prov = context.read<SocketConn>();

    return Selector<SocketConn, int>(
      selector: (_, prov) => prov.irisUpdate,
      builder: (_, val, child) {
        if(prov.idsOrdsIris.contains(_idOrden)) {
          prov.idsOrdsIris.remove(_idOrden);
          return _futureWidget(true, true);
        }
        return child!;
      },
      child: _futureWidget(false, true),
    );
  }

  ///
  Widget _futureWidget(bool force, bool isSensor) {

    return FutureBuilder<MetrixEntity>(
      future: (force) ? _getMetricas(true) : _getMetrik,
      builder: (_, AsyncSnapshot<MetrixEntity> mtr) {
        
        if(mtr.connectionState == ConnectionState.done) {
          if(mtr.hasData && mtr.data != null) {
            metrik = mtr.data!;
            return _body(mtr.data!);
          }
          return _sinData();
        }
        return (force) ? _body(metrik!) : _load();
      }
    );
  }

  ///
  Widget _body(MetrixEntity metrix) {

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if(metrix.stt < 3)
          _setState('stt', '${metrix.stt}')
        else
          InkWell(
            onTap: () => widget.onOpenDashboard!(null),
            child: _setState('stt', '${metrix.stt}'),
          ),
        _setState('cotz', '${metrix.sended.length}/${metrix.toTot.length}', wval: true),
        _setState('tpz', '${metrix.tpz}', wval: true),
        _setState('rsp', '${metrix.rsp}', wval: true),
        _setState('see', '${metrix.see}', wval: true),
        _setState('ntg', '${metrix.ntg}', wval: true),
      ],
    );
  }

  ///
  Widget _setState
    (String campo, String value, {bool wval = false})
  {
    Map<String, dynamic> state = _stateIcon(campo, value);
    return _ico(
      state['ico'], (wval) ? value : '', state['tip'],
      color: state['clr']
    );
  }
  
  ///
  Widget _ico
    (IconData ico, String value, String msg,
    {Color color = const Color.fromARGB(255, 243, 240, 72) })
  {

    return Tooltip(
      message: msg,
      child: Row(
        children: [
          Icon(ico, size: 15, color: color),
          const SizedBox(width: 3),
          Texto(txt: value, sz: 13),
        ],
      ),
    );
  }

  ///
  Widget _load() {

    return const Center(
      child: SizedBox(
        width: 40, height: 40,
        child: CircularProgressIndicator(),
      ),
    );
  }

  ///
  Widget _sinData() => const Texto(txt: 'Sin datos');

  ///
  Map<String, dynamic> _stateIcon(String campo, String value) {

    const inactive = Color.fromARGB(255, 65, 65, 65);
    const active = Color.fromARGB(255, 17, 219, 10);
    const listo = Color.fromARGB(255, 12, 80, 228);

    switch (campo) {

      case 'stt':

        switch(value) {
          case '0':
            return _getMap('EN STAGE', Icons.email_outlined, inactive);
          case '1':
            return _getMap('ENVIANDOSE', Icons.save_alt_sharp, listo);
          case '2':
            return _getMap('PAPELERA', Icons.watch_outlined, Colors.grey);
          case '3':
            return _getMap('ENVIADO-DASHBOARD', Icons.android, const Color.fromARGB(255, 106, 175, 108));
        }
        break;

      case 'tpz':
        if(value == '0') {
            return _getMap('Total de Piezas', Icons.extension_off, inactive);
        }else{
          return _getMap('Total de Piezas', Icons.extension, const Color.fromARGB(255, 55, 110, 57));
        }
      case 'rsp':
        if(value == '0') {
          return _getMap('RESPUESTAS', Icons.comments_disabled_outlined, inactive);
        }else{
          return _getMap('RESPUESTAS', Icons.comment, listo);
        }
      case 'cotz':

        if(value == '0') {
            return _getMap('COTIZADORES', Icons.hourglass_top_rounded, inactive);
        }else{
          return _getMap('COTIZADORES', Icons.person_pin, active);
        }
      case 'see':
        if(value == '0') {
            return _getMap('IGNORADO', Icons.remove_red_eye, inactive);
        }else{
          return _getMap('VISTOS', Icons.done_all, active);
        }
      case 'ntg':

        if(value == '0') {
            return _getMap('NO LA TIENEN', Icons.hourglass_top_rounded, inactive);
        }else{
          return _getMap('NO LA TIENEN', Icons.visibility_off, active);
        }
      default:
    }

    return _getMap('DESCONOCIDO', Icons.help, inactive);
  }

  ///
  Map<String, dynamic> _getMap(String tip, IconData ico, Color color) {

    return {'tip': tip, 'ico': ico, 'clr': color};
  }

  ///
  Future<MetrixEntity> _getMetricas(bool force) async {
    return await _invEm.getMetriksFromFile(widget.filename, force: force);
  }

}