import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../texto.dart';
import '../../../repository/inventario_repository.dart';
import '../../../providers/invirt_provider.dart';

class TileBandejaMetricas extends StatefulWidget {
  
  final String filename;
  const TileBandejaMetricas({
    Key? key,
    required this.filename,
  }) : super(key: key);

  @override
  State<TileBandejaMetricas> createState() => _TileBandejaMetricasState();
}

class _TileBandejaMetricasState extends State<TileBandejaMetricas> {

  final _invEm = InventarioRepository();
  late Future<Map<String, dynamic>> _getMetrik;
  int _idOrden = 0;

  @override
  void initState() {
    _getMetrik = _getMetricas();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<Map<String, dynamic>>(
      future: _getMetrik,
      builder: (_, AsyncSnapshot<Map<String, dynamic>> metrix) {
        
        if(metrix.connectionState == ConnectionState.done) {
          if(metrix.hasData && metrix.data != null) {
            if(metrix.data!.isNotEmpty) {
              return _sensorDeCambios(metrix.data!);
            }
          }
          return _sinData();
        }
        return _load();
      }
    );
  }

  ///
  Widget _sensorDeCambios(Map<String, dynamic> metrix) {

    return Selector<InvirtProvider, List<int>>(
      selector: (_, prov) => prov.trigger,
      builder: (_, idOrds, child) {

        if(idOrds.contains(_idOrden)) {
          return FutureBuilder<Map<String, dynamic>>(
            future: _getMetricas(),
            builder: (_, AsyncSnapshot<Map<String, dynamic>> metrix) {
              if(metrix.connectionState == ConnectionState.done) {
                if(metrix.hasData && metrix.data != null) {
                  if(metrix.data!.isNotEmpty) {
                    return _body(metrix.data!);
                  }
                }
                return _sinData();
              }
              return child!;
            },
          );
        }

        return child!;
      },
      child: _body(metrix),
    );
  }

  ///
  Widget _body(Map<String, dynamic> metrix) {

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _setState(metrix, Mtrik.scmEst.name),
        _setState(metrix, Mtrik.see.name, wval: true),
        _setState(metrix, Mtrik.cnt.name, wval: true),
        _setState(metrix, Mtrik.cotz.name, wval: true),
      ],
    );
  }

  ///
  Widget _setState
    (Map<String, dynamic> metrix, String campo, {bool wval = false})
  {
    Map<String, dynamic> state = _stateIcon(campo, '${metrix[campo]}');
    return _ico(
      state['ico'], (wval) ? '${metrix[campo]}' : '', state['tip'],
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
  Widget _sinData() {

    return const Texto(txt: 'Sin datos');
  }

  ///
  Future<Map<String, dynamic>> _getMetricas() async {

    final metrik = await _invEm.getMetriksFromFile(widget.filename);
    if(metrik.isNotEmpty) {
      _idOrden = metrik['idOrden'];
    }
    return metrik;
  }

  ///
  Map<String, dynamic> _stateIcon(String campo, String value) {

    const inactive = Color.fromARGB(255, 65, 65, 65);
    const active = Color.fromARGB(255, 17, 219, 10);
    const listo = Color.fromARGB(255, 12, 80, 228);

    switch (campo) {

      case 'scmEst':

        switch(value) {
          case '0':
            return _getMap('EN STAGE', Icons.email_outlined, inactive);
          case '1':
            return _getMap('EN BANDEJA', Icons.save_alt_sharp, listo);
          case '2':
            return _getMap('EN COLA', Icons.watch_outlined, Colors.grey);
          case '3':
            return _getMap('ENVIANDOSE', Icons.send, active);
          case '4':
            return _getMap('PAPELERA', Icons.delete_forever_outlined, const Color.fromARGB(255, 248, 114, 4));
          case '5':
            return _getMap('ENVIADO', Icons.folder_special, listo);
        }
        break;
      case 'see':

        if(value == '0') {
            return _getMap('IGNORADO', Icons.remove_red_eye, inactive);
        }else{
          return _getMap('VISTOS', Icons.done_all, active);
        }
      case 'cnt':

        if(value == '0') {
            return _getMap('NO LA TIENEN', Icons.hourglass_top_rounded, inactive);
        }else{
          return _getMap('NO LA TIENEN', Icons.visibility_off, active);
        }
      case 'cotz':

        if(value == '0') {
            return _getMap('COTIZADORES', Icons.hourglass_top_rounded, inactive);
        }else{
          return _getMap('COTIZADORES', Icons.person_pin, active);
        }
      case 'pzas':
        if(value == '0') {
            return _getMap('PIEZAS', Icons.extension_off, inactive);
        }else{
          return _getMap('PIEZAS', Icons.extension, active);
        }
      default:
    }

    return _getMap('DESCONOCIDO', Icons.help, inactive);
  }

  ///
  Map<String, dynamic> _getMap(String tip, IconData ico, Color color) {

    return {'tip': tip, 'ico': ico, 'clr': color};
  }


}