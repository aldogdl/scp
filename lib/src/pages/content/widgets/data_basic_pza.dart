import 'package:flutter/material.dart';
import 'package:scp/src/entity/piezas_entity.dart';

import '../../widgets/texto.dart';

class DataBasicPza extends StatelessWidget {

  final PiezasEntity pza;
  final ScrollController scrollTxtCtl;
  const DataBasicPza({
    Key? key,
    required this.pza,
    required this.scrollTxtCtl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Scrollbar(
            controller: scrollTxtCtl,
            radius: const Radius.circular(3),
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: scrollTxtCtl,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Texto(txt: pza.obs),
              ),
            ),
          )
        ),
        const Divider(color: Color.fromARGB(255, 48, 48, 48), thickness: 3, height: 20),
        Texto(txt: pza.piezaName, isBold: true, txtC: Colors.white,),
        const SizedBox(height: 5),
        Texto(txt: '${pza.posicion} ${pza.lado}', sz: 12),
        Row(
          children: [
            Texto(txt: pza.origen, sz: 10, txtC: Colors.amber),
            const Spacer(),
            Texto(txt: 'ID: ${pza.id}', sz: 13, txtC: Colors.white),
          ],
        ),
      ],
    );
  }
}