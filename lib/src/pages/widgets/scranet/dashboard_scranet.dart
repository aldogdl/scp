import 'package:flutter/material.dart';

import 'piezas_cp.dart';
import 'marcas_cp.dart';
import 'modelos_cp.dart';
import 'my_navigator_rail.dart';

class DashboardScranet extends StatelessWidget {

  const DashboardScranet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final seccShow = ValueNotifier<String>('piezas');

    return Row(
      children: [
        MyNavigatorRail(
          onSelected: (secc) {
            seccShow.value = secc;
          }
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox.expand(
              child: ValueListenableBuilder<String>(
                valueListenable: seccShow,
                builder: (_, secc, __) {
                  return _showSeccion(secc);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  ///
  Widget _showSeccion(String secc) {

    switch (secc) {
      case 'marcas':
        return const MarcasCp();
      case 'modelos':
        return const ModelosCp();
      case 'piezas':
        return const PiezasCp();
      default:
        return const Text('Sección no Encontrada');
    }
  }
}