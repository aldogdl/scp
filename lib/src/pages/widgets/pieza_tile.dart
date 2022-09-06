import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../entity/piezas_entity.dart';
import '../../pages/widgets/texto.dart';
import '../../providers/items_selects_glob.dart';
import '../../services/status/est_stt.dart';

class PiezaTile extends StatelessWidget {

  final PiezasEntity pieza;
  final ValueChanged<int> onSelect;
  const PiezaTile({
    Key? key,
    required this.pieza,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    // isOnlyShow
    final prov = context.read<ItemSelectGlobProvider>();

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: (context.watch<ItemSelectGlobProvider>().idPzaSelect == pieza.id)
        ? Colors.white.withOpacity(0.1)
        : null,
      ),
      child: ListTile(
        dense: true,
        onTap: () => _selectedPza(context),
        mouseCursor: SystemMouseCursors.click,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        visualDensity: VisualDensity.compact,
        minLeadingWidth: 20,
        leading: (context.watch<ItemSelectGlobProvider>().idPzaSelect == pieza.id)
          ? Texto(txt: '${pieza.id}', sz: 17, txtC: Colors.blue, isBold: true)
          : Texto(txt: '${pieza.id}', sz: 17, txtC: Colors.white.withOpacity(0.3)),
        trailing: Chip(
          label: Texto(txt: '${pieza.fotos.length}', sz: 12, txtC: const Color(0xFFFFFFFF),),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(2),
          labelPadding: const EdgeInsets.all(1),
        ),
        title: Texto(txt: pieza.piezaName, sz: 13,),
        subtitle: (prov.isOnlyShow)
          ? Texto(txt: '${pieza.lado} ${pieza.posicion}', txtC: Colors.blue, sz: 11)
          : Texto(txt: EstStt.getSttByEst(pieza.status()), txtC: Colors.blue, sz: 11)
      ),
    );
  }

  ///
  Future<void> _selectedPza(BuildContext context) async {

    context.read<ItemSelectGlobProvider>().idPzaSelect = pieza.id;
    onSelect(pieza.id);
  }
}