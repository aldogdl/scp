import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scp/src/entity/contacts_entity.dart';
import 'package:scp/src/pages/widgets/filtros/lst_items_filtros.dart';
import 'package:scp/src/pages/widgets/filtros/panel_filtros.dart';
import 'package:scp/src/providers/filtros_provider.dart';

class FiltrosMain extends StatelessWidget {

  final ContacsEntity contact;
  const FiltrosMain({
    Key? key,
    required this.contact
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Builder(
      builder: (context) {
        
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: LayoutBuilder(
                  builder: (_, c) {
                    return LstItemsFiltros(
                      index: 1,
                      ofBy: 'marcas',
                      width: c.maxWidth,
                      onSelected: (item) {
                        final prov = context.read<FiltrosProvider>();
                        if(prov.marca['id'] != item['id']) {
                          prov.modelo = {'nombre':'0'};
                        }
                        prov.marca = item;

                        prov.refresMdls = !prov.refresMdls;
                      }
                    );
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: LayoutBuilder(
                  builder: (_, c) {
                    return LstItemsFiltros(
                      index: 2,
                      ofBy: 'modelos',
                      width: c.maxWidth,
                      onSelected: (item) {
                        final prov = context.read<FiltrosProvider>();
                        prov.modelo = item;
                        prov.fechMarca();
                      }
                    );
                  }
                ),
              ),
              Expanded(
                flex: 2,
                child: LayoutBuilder(
                  builder: (_, c) => Column(
                    children: [
                      Expanded(
                        child: LstItemsFiltros(
                          index: 3,
                          ofBy: 'anios_desde',
                          width: c.maxWidth,
                          onSelected: (Map<String, dynamic> item) {
                            context.read<FiltrosProvider>().aniosD = item['anio'];
                          }
                        ),
                      ),
                      Expanded(
                        child: LstItemsFiltros(
                          index: 3,
                          ofBy: 'anios_hasta',
                          width: c.maxWidth,
                          onSelected: (Map<String, dynamic> item) {
                            context.read<FiltrosProvider>().aniosH = item['anio'];
                          }
                        ),
                      )
                    ],
                  )
                ),
              ),
              Expanded(
                flex: 3,
                child: LayoutBuilder(
                  builder: (_, c) {

                    return LstItemsFiltros(
                      index: 4,
                      ofBy: 'piezas',
                      width: c.maxWidth,
                      onSelected: (item) {
                        
                        context.read<FiltrosProvider>().pieza = item;
                      }
                    );
                  }
                ),
              ),
              Expanded(
                flex: 3,
                child: LayoutBuilder(
                  builder: (_, c) {

                    return Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Color.fromARGB(255, 54, 54, 54))
                        )
                      ),
                      child: PanelFiltros(width: c.maxWidth, idEmp: contact.idEmp),
                    );
                  }
                ),
              ),
            ],
          )
        );
      },
    );
  }

}