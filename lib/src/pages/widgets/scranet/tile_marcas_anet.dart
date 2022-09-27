import 'package:flutter/material.dart';
import 'package:scp/src/entity/marcas_entity.dart';

import '../my_tool_tip.dart';
import '../texto.dart';
import '../widgets_utils.dart';

class TileMarcasAnet extends StatelessWidget {
  
  final MarcasEntity auto;
  final ValueChanged<MarcasEntity> onTap;
  final ValueChanged<bool> onDelete;
  final bool hasDelete;
  final int withNumbers;
  const TileMarcasAnet({
    Key? key,
    required this.auto,
    required this.onTap,
    required this.onDelete,
    this.hasDelete = true,
    this.withNumbers = -1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    IconData? ico;
    switch (auto.hasChanges) {
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
      onPressed: () async => onTap(auto),
      child: Row(
        children: [
          if(auto.hasChanges != 0)
            ...[
              MyToolTip(
                msg: MarcasEntity().getTipoCambio(auto.hasChanges),
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
            auto.marca,
            textScaleFactor: 1,
          ),
          const Spacer(),
          MyToolTip(
            msg: '${auto.simyls['radec']}',
            child: _tileCraw('RDC', (auto.simyls['radec'] != '0'))
          ),
          const SizedBox(width: 10),
          MyToolTip(
            msg: '${auto.simyls['aldo']}',
            child: _tileCraw('ALD', (auto.simyls['aldo'] != '0'))
          ),
          const SizedBox(width: 10),
          MyToolTip(
            msg: (auto.grupo == 'b') ? "Comercial" : "Alta Gama",
            child: Texto(
              txt: '[ ${auto.grupo} ]', sz: 13,
              txtC: Colors.amber,
            )
          ),
          if(hasDelete)
            ...[
              const SizedBox(width: 10),
              MyToolTip(
                msg: 'Borrar Modelo',
                child: InkWell(
                  onTap: () async {
                    bool? res = await _alertDialogBorrar(context, auto.marca);
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
  Future<bool?> _alertDialogBorrar(BuildContext context, String marca) async {

    return await WidgetsAndUtils.showAlertBody(
      context,
      titulo: 'Borrar Marca de la Base de Datos',
      body: SizedBox(
        width: MediaQuery.of(context).size.width * 0.35,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Texto(
            txt: 'Estás a punto de ELIMINAR la marca $marca, '
            'la cual se borrará permanentemente de las Bases de Datos '
            'y ésta no podrá ser recuperada.\n\n'
            '¿Estás segur@ de continuar borrando $marca?',
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