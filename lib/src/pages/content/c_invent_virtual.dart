import 'package:flutter/material.dart';

import '../widgets/invirt/carrito_secc_finanzas.dart';
import '../widgets/invirt/titulo_seccion.dart';
import '../widgets/invirt/almacen_virtual.dart';

class CInventVirtualPage extends StatelessWidget {

  const CInventVirtualPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.2,
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            color: Colors.black12,
            border: Border(
              left: BorderSide(color: Color.fromARGB(255, 71, 71, 71))
            )
          ),
          child: Column(
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 3),
                child: TituloSeccion(
                  ico: Icons.money_sharp,
                  titulo: 'ZONA FINANCIERA', chip: '',
                ),
              ),
              Expanded(
                child: CarritoSeccFinanzas()
              )
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(top: 8),
            child: LayoutBuilder(
              builder: (_, constraints) {
                return AlmacenVirtual(maxW: constraints.maxWidth);
              }
            ),
          )
        ),
      ],
    );
  }

}