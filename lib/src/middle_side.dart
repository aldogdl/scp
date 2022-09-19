import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/middle/config_page.dart';
import 'pages/middle/invent_virtual.dart';
import 'pages/middle/cotizadores_page.dart';
import 'pages/middle/solicitantes_page.dart';
import 'pages/middle/solicitudes_non_page.dart';
import 'pages/middle/solicitudes_page.dart';
import 'pages/widgets/invirt/command_line.dart';
import 'providers/pages_provider.dart';
import 'providers/window_cnf_provider.dart';

class MiddleSide extends StatelessWidget {
  
  const MiddleSide({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return SizedBox(
        width: context.read<WindowCnfProvider>().tamMiddle,
        child: Container(
          color: context.read<WindowCnfProvider>().middleColor,
          child: Consumer<PageProvider>(
            builder: (_, PageProvider page, __) {

              return Column(
                children: [
                  _middleWidget(page.page),
                  Expanded( child: _determinarWidget(page.page) )
                ],
              );
            }
          )
      )
    );
  }

  ///
  Widget _middleWidget(Paginas pagina) {

    late Widget child;
    switch (pagina) {
      case Paginas.solicitantes:
        child = _barrToSolicitantes();
        break;
      case Paginas.cotizadores:
        child = _barrToSolicitantes();
        break;
      case Paginas.inventVirtual:
        child = const CommandLine();
        break;
      default:
        child = const SizedBox();
    }

    return child;
  }

  ///
  Widget _barrToSolicitantes() {

    return Row(
      children: [
        IconButton(
          onPressed: (){},
          icon: const Icon(Icons.add, size: 18, color: Colors.white),
        )
      ]
    );
  }

  ///
  Widget _determinarWidget(Paginas pagina) {

    late Widget child;

    switch (pagina) {
      case Paginas.solicitudesNon:
        child = const SolicitudesNonPage();
        break;
      case Paginas.solicitudes:
        child = const SolicitudesPage();
        break;
      case Paginas.inventVirtual:
        child = const InventVirtual();
        break;
      case Paginas.solicitantes:
        child = SolicitantesPage();
        break;
      case Paginas.cotizadores:
        child = const CotizadoresPage();
        break;
      case Paginas.config:
        child = const ConfigPage();
        break;
      case Paginas.dataScranet:
        child = const ConfigPage();
        break;
      default:
    }
    return child;
  }
}