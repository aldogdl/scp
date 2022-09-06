import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../texto.dart';
import '../../../providers/invirt_provider.dart';
import '../../../repository/inventario_repository.dart';

class TileRespsCant extends StatefulWidget {

  final String filename;
  final int idOrd;
  final int idPza;
  final String respCant;
  final String from;
  const TileRespsCant({
    Key? key,
    required this.filename,
    required this.idOrd,
    required this.from,
    this.idPza = 0,
    this.respCant = '0',
  }) : super(key: key);

  @override
  State<TileRespsCant> createState() => _TileRespsCantState();
}

class _TileRespsCantState extends State<TileRespsCant> {

  final _invEm = InventarioRepository();

  static const Color _inTime = Color.fromARGB(255, 65, 65, 65);
  static const Color _alert  = Color.fromARGB(255, 12, 80, 228);

  Map<String, dynamic> _metrix = {};
  late Future<void> _getResps;

  @override
  void initState() {
    super.initState();
    _getResps = _getCantResp();
  }

  @override
  Widget build(BuildContext context) {

    return Selector<InvirtProvider, List<int>>(
      selector: (_, prov) => prov.triggerResp,
      builder: (_, nval, child) {

        if(nval.isEmpty) { return child!; }
        if(!nval.contains(widget.idOrd)) { return child!; }
        _metrix = {};
        return FutureBuilder(
          future: _getCantResp(force: true),
          builder: (_, AsyncSnapshot snap) => _snapShot(snap),
        );
      },
      child: FutureBuilder(
        future: _getResps,
        builder: (_, AsyncSnapshot snap) => _snapShot(snap),
      ),
    );
  }

  ///
  Widget _icoLabel() {

    Widget child = const SizedBox();

    if(widget.from == 'cron') {
      child = Texto(txt: '${_metrix[Mtrik.rsp.name]}');
    }
    
    if(widget.from == 'tile') {
      child = Texto(
        txt: '${widget.respCant}/${_metrix[Mtrik.rsp.name]}', sz: 11, txtC: Colors.white.withOpacity(0.7)
      );
    }
    
    return Row(
      children: [
        Icon(
          Icons.sell, size: 13, color: _metrix[Mtrik.rsp.name] == 0 ? _inTime : _alert,
        ),
        _sbw(5),
        child
      ],
    );
  }

  ///
  Widget _sbw(double w) => SizedBox(width: w);

  ///
  Widget _snapShot(AsyncSnapshot snap) {

    if(snap.connectionState == ConnectionState.done) {
      return _icoLabel();
    }

    return const SizedBox(
      width: 13, height: 13,
      child: CircularProgressIndicator( strokeWidth: 2 ),
    );
  }

  ///
  Future<void> _getCantResp({bool force = false}) async {

    final invVirt = context.read<InvirtProvider>();
    if(_metrix.isEmpty || force) {
      _metrix = await _invEm.getMetriksFromFile(widget.filename);
    }
    invVirt.triggerResp.clear();
  }

}