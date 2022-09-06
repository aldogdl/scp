import 'package:flutter/material.dart';

import 'controles.dart';
import 'tile_bandeja_metricas.dart';
import 'tile_titulo_orden.dart';
import '../../../repository/inventario_repository.dart';

class TileBandejaEntrada extends StatefulWidget {

  final String nomFile;
  final bool isSelected;
  final ValueChanged<int> onTap;
  const TileBandejaEntrada({
    Key? key,
    required this.nomFile,
    required this.onTap,
    required this.isSelected,
  }) : super(key: key);

  @override
  State<TileBandejaEntrada> createState() => _TileBandejaEntradaState();
}

class _TileBandejaEntradaState extends State<TileBandejaEntrada> {

  final _invEm = InventarioRepository();

  late Future _getFromFile;
  Map<String, dynamic> dataOrd = {};
  bool _isInit = false;

  @override
  void initState() {
    dataOrd = _invEm.schemaBandeja();
    _getFromFile = _getOrden();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    if(!_isInit) {
      _isInit = true;
    }
    
    return FutureBuilder(
      future: _getFromFile,
      builder: (_, AsyncSnapshot snap) {

        if(snap.connectionState == ConnectionState.done) {
          if(dataOrd['id'] != 0) {
            return _buildChild();
          }
        }

        return _buildChild();
      },
    );
  }

  ///
  Widget _buildChild() {

    return Column(
      children: [
        _body(),
        _losControles(),
        const SizedBox(height: 10)
      ],
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
            marca: '', modelo: dataOrd['mod'], anio: '${dataOrd['anio']}',
            nResp: 0, nOrd: dataOrd['id'], active: false,
            solicitante: dataOrd['sol'], created: dataOrd['created'],
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
            child: TileBandejaMetricas(filename: widget.nomFile),
          )
        ],
      ),
    );
  }

  ///
  Widget _losControles() {

    if(dataOrd['id'] != 0) {
      
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Controles(
          filename: widget.nomFile,
          idOrd: dataOrd['id'],
          nPzas: dataOrd['nPzas'],
          created: dataOrd['created'],
          onSendProcess: (_) async {
            
          }
        ),
      );
    }

    return const SizedBox();
  }
  
  ///
  Future<void> _getOrden() async {
    
    dataOrd = await _invEm.getOrdenMapTile(widget.nomFile);
  }

}