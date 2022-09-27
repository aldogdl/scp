import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/middle/cotiza_frm_page.dart';
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
      case Paginas.almacenVirtual:
        child = const CommandLine();
        break;
      case Paginas.cotiza:
        child = _tituloPage('Generando Cotización', Icons.shopify_outlined);
        break;
      default:
        child = const SizedBox();
    }

    return child;
  }

  ///
  Widget _tituloPage(String titulo, IconData ico) {

    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: const BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8)
        )
      ),
      child: Row(
        children: [
          Icon(ico),
          const SizedBox(width: 10),
          Text(
            titulo,
            textScaleFactor: 1,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      )
    );
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
      case Paginas.almacenVirtual:
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
      case Paginas.cotiza:
        child = const CotizaFrmPage();
        break;
      default:
    }
    return child;
  }

}