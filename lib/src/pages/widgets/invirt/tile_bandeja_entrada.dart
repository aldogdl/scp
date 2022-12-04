import 'package:flutter/material.dart';

import 'tile_bandeja_metricas.dart';
import 'tile_titulo_orden.dart';
import '../texto.dart';
import '../dashboard/dashboard.dart';
import '../../../repository/inventario_repository.dart';
import '../../../entity/orden_entity.dart' show OrdCamp;

class TileBandejaEntrada extends StatefulWidget {

  final String nomFile;
  final bool isSelected;
  final bool offOpenDash;
  final ValueChanged<int> onTap;
  const TileBandejaEntrada({
    Key? key,
    required this.nomFile,
    required this.onTap,
    required this.isSelected,
    this.offOpenDash = false
  }) : super(key: key);

  @override
  State<TileBandejaEntrada> createState() => _TileBandejaEntradaState();
}

class _TileBandejaEntradaState extends State<TileBandejaEntrada> {

  final _invEm = InventarioRepository();

  late Future _getFromFile;
  Map<String, dynamic> dataOrd = {};

  @override
  void initState() {
    dataOrd = _invEm.schemaBandeja();
    _getFromFile = _getOrden();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
      future: _getFromFile,
      builder: (_, AsyncSnapshot snap) {
        if(snap.connectionState == ConnectionState.done) {
          if(dataOrd['id'] != 0) { return _body(); }
        }
        return const SizedBox();
      }
    );
  }

  ///
  Widget _body() {

    return Container(
      margin: const EdgeInsets.only(
        top: 8, right: 8, bottom: 2, left: 8
      ),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5), topRight: Radius.circular(5),
        ),
        color: (widget.isSelected)
          ? const Color.fromARGB(255, 32, 32, 32)
          : Colors.transparent,
        border: Border.all(
          color: const Color.fromARGB(255, 65, 65, 65), width: 1
        )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          TileTituloOrden(
            marca: '> ${dataOrd['mrk']}', modelo: dataOrd['mod'],
            anio: '${dataOrd['anio']}',
            nResp: 0, nOrd: dataOrd['id'], active: false,
            solEmp: dataOrd['sol'],
            solNom: dataOrd['solNom'],
            created: dataOrd['created'],
            nPzas: dataOrd['nPzas'],
            onTap: (int idOrd) => widget.onTap(idOrd)
          ),

          const SizedBox(height: 3),

          Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color.fromARGB(255, 65, 65, 65))
              )
            ),
            child: (widget.offOpenDash)
            ? _putTiempos()
            : TileBandejaMetricas(
              idOrden: dataOrd['id'],
              filename: widget.nomFile,
              onOpenDashboard: (widget.offOpenDash)
                ? null
                : (_) async => await _onOpenDashboard()
            ),
          )
        ],
      ),
    );
  }

  ///
  Widget _putTiempos() {

    if(dataOrd.isEmpty) { return const SizedBox(); }

    return Row(
      children: [
        const Texto(txt: 'INI: '),
        Texto(
          txt: dataOrd[OrdCamp.metrik.name]['hIni'], isFecha: true,
          sz: 13, txtC: Colors.green,
        ),
        const Spacer(),
        const Texto(txt: 'FIN: '),
        Texto(
          txt: dataOrd[OrdCamp.metrik.name]['hFin'], isFecha: true,
          sz: 13, txtC: Colors.green,
        )
      ],
    );
  }

  ///
  Future<void> _onOpenDashboard() async {

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.all(0),
        content: Dashboard( orden: dataOrd ),
      )
    );
  }
  
  ///
  Future<void> _getOrden() async {
    dataOrd = await _invEm.getOrdenMapTile(widget.nomFile);
  }

}