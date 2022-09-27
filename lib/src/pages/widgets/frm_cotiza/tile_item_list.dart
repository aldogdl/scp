import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../texto.dart';
import '../../../providers/cotiza_provider.dart';

class TileItemList extends StatelessWidget {

  final String item;
  final IconData ico;
  final bool isOptions;
  final ValueChanged<String> onTap;
  const TileItemList({
    Key? key,
    required this.item,
    required this.ico,
    required this.onTap,
    this.isOptions = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final ctzP = context.read<CotizaProvider>();

    double fontS = 17;
    bool isBold = false;
    if(ctzP.seccion == 'anios') {
      fontS = 20;
      isBold= true;
    }

    return TextButton(
      style: ButtonStyle(
        alignment: Alignment.centerLeft,
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(vertical: 3)
        )
      ),
      onPressed: () => onTap(item),
      child: Row(
        children: [
          Icon(ico, size: 15),
          const SizedBox(width: 10),
          Texto(
            txt: item, sz: fontS, isBold: isBold,
            txtC: (isOptions) ? Colors.amber : Colors.grey,
          )
        ],
      ),
    );
  }
}