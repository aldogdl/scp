import 'package:flutter/material.dart';

import '../../../entity/modelos_entity.dart';
import '../my_tool_tip.dart';
import '../texto.dart';
import '../widgets_utils.dart';

class TileModelosAnet extends StatelessWidget {

  final ModelosEntity md;
  final ValueChanged<ModelosEntity> onTap;
  final ValueChanged<bool> onDelete;
  final int withNumbers;
  final bool hasDelete;
  const TileModelosAnet({
    Key? key,
    required this.md,
    required this.onTap,
    required this.onDelete,
    this.hasDelete = true,
    this.withNumbers = -1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    IconData? ico;
    switch (md.hasChanges) {
      case 1:
        ico = Icons.circle_rounded;
        break;
      case 2:
        ico = Icons.add;
        break;
      case 3:
        ico = Icons.done_all;
        break;
      case 4:
        ico = Icons.minimize_outlined;
        break;
      default:
        ico = null;
    }

    return TextButton(
      onPressed: () => onTap(md),
      child: Row(
        children: [
          if(md.hasChanges != 0)
            ...[
              MyToolTip(
                msg: ModelosEntity().getTipoCambio(md.hasChanges),
                child: Icon(ico, size: 10, color: Colors.white)
              ),
              const SizedBox(width: 7)
            ],
          if(withNumbers > -1)
            Text(
              '.$withNumbers ',
              textScaleFactor: 1,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13
              ),
            ),
          Text(
            md.modelo,
            textScaleFactor: 1,
          ),
          const Spacer(),
          MyToolTip(
            msg: '${md.simyls['radec']}',
            child: _tileCraw('RDC', (md.simyls['radec'] != '0'))
          ),
          const SizedBox(width: 10),
          MyToolTip(
            msg: '${md.simyls['aldo']}',
            child: _tileCraw('ALD', (md.simyls['aldo'] != '0'))
          ),
          if(hasDelete)
            ...[
              const SizedBox(width: 10),
              MyToolTip(
                msg: 'Borrar Modelo',
                child: InkWell(
                  onTap: () async {
                    bool? res = await _alertDialogBorrar(context, md.modelo);
                    res = (res == null) ? false : res;
                    onDelete(res);
                  },
                  child: const Texto(
                    txt: '[ X ]', sz: 13,
                    txtC: Color.fromARGB(255, 247, 118, 108),
                  ),
                )
              ),
            ]
        ],
      )
    );
  }

  ///
  Widget _tileCraw(String label, bool haSymil) {

    return Text(
      label,
      textScaleFactor: 1,
      style: TextStyle(
        decorationColor: Colors.white,
        decoration: (haSymil)
          ? TextDecoration.none : TextDecoration.lineThrough,
        fontSize: 12,
        color: (haSymil)
          ? Colors.green : const Color.fromARGB(255, 95, 95, 95),
      ),
    );
  }

  ///
  Future<bool?> _alertDialogBorrar(BuildContext context, String modelo) async {

    return await WidgetsAndUtils.showAlertBody(
      context,
      titulo: 'Borrar Modelo de la Base de Datos',
      body: SizedBox(
        width: MediaQuery.of(context).size.width * 0.35,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Texto(
            txt: 'Estás a punto de ELIMINAR la Modelo $modelo, '
            'la cual se borrará permanentemente de las Bases de Datos '
            'y ésta no podrá ser recuperada.\n\n'
            '¿Estás segur@ de continuar borrando $modelo?',
            isCenter: true, txtC: Colors.white.withOpacity(0.7),
          ),
        ),
      ),
      dismissible: true,
      withYesOrNot: true,
      msgOnlyYes: 'Si Borrar',
      onlyAlert: false
    );
  }

}