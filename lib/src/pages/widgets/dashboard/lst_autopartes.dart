import 'package:flutter/material.dart';
import 'package:scp/src/pages/widgets/texto.dart';

import '../../../vars/scroll_config.dart';

class LstAutopartes extends StatefulWidget {

  final List<Map<String, dynamic>> piezas;
  const LstAutopartes({
    Key? key,
    required this.piezas
  }) : super(key: key);

  @override
  State<LstAutopartes> createState() => _LstAutopartesState();
}

class _LstAutopartesState extends State<LstAutopartes> {

  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scrollbar(
      controller: _scroll,
      thumbVisibility: true,
      radius: const Radius.circular(3),
      trackVisibility: true,
      child: ScrollConfiguration(
        behavior: MyCustomScrollBehavior(),
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          controller: _scroll,
          padding: const EdgeInsets.only(right: 10),
          itemCount: widget.piezas.length,
          itemBuilder: (_, ind) => _tilePza(ind)
        ),
      )
    );
  }

  ///
  Widget _tilePza(int ind) {

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: (ind.isEven) ? Colors.black.withOpacity(0.1) : Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.extension, size: 15, color: Colors.green),
              const SizedBox(width: 5),
              Texto(txt: widget.piezas[ind]['piezaName'], txtC: Colors.white),
              const Spacer(),
              Texto(txt: 'ID: ${widget.piezas[ind]['id']}'),
            ],
          ),
          Row(
            children: [
              Texto(txt: '${widget.piezas[ind]['lado']} ${widget.piezas[ind]['posicion']}', sz: 11),
              const Spacer(),
              Texto(txt: '${widget.piezas[ind]['origen']}', sz: 11, txtC: Colors.white.withOpacity(0.2),),
            ],
          )
        ],
      )
    );
  }

}