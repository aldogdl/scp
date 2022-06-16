import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/providers/socket_conn.dart';

import 'pages/consola/alertas.dart';
import 'pages/consola/errores.dart';
import 'pages/consola/scm.dart';
import 'pages/consola/centinela.dart';
import 'providers/pages_provider.dart';
import 'providers/window_cnf_provider.dart';

class ConsolaSide extends StatelessWidget {

  const ConsolaSide({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final winCnf = context.read<WindowCnfProvider>();
    
    double widthOfResto = winCnf.tamMiddle;
    double w = (widthOfResto * 100) / MediaQuery.of(context).size.width;
    double wt = MediaQuery.of(context).size.width * ((100 - w) / 100);
    
    return Container(
      width: wt,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color.fromARGB(255, 75, 75, 75), width: 0.8),
        )
      ),
      height: MediaQuery.of(context).size.height * 0.25,
      child: Column(
        children: [
          _pestaniasConsole(context),
          const SizedBox(height: 1),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 17, 17, 17),
              ),
              child: Consumer<PageProvider>(
                builder: (_, PageProvider consola, __) => _determinarWidget(consola.consola),
              ),
            ),
          )
        ],
      ),
    );
  }

  ///
  Widget _pestaniasConsole(BuildContext context) {

    final winCnf = context.read<WindowCnfProvider>();
    final pageProvi = context.read<PageProvider>();
    final sock = context.read<SocketConn>();

    return Container(
      decoration: BoxDecoration(
        color: winCnf.backgroundStartColor,
        border: const Border(
          top: BorderSide(color: Color.fromARGB(255, 185, 185, 185), width: 0.3)
        ),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 2),
            blurRadius: 1,
            spreadRadius: 1
          ),
        ]
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          const SizedBox(width: 5),
          Text(
            '<C:>',
            textScaleFactor: 1,
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontWeight: FontWeight.bold,
              fontSize: 11
            ),
          ),
          const SizedBox(width: 10),
          _btn(
            label: 'Centinela',
            isActive: (pageProvi.consola == Consola.centinela) ? true : false,
            value: '${context.watch<SocketConn>().manifests.length}',
            fnc: () => pageProvi.consola = Consola.centinela,
          ),
          _btn(
            label: 'Alertas',
            fnc: () => pageProvi.consola = Consola.alertas,
            isActive: (pageProvi.consola == Consola.alertas) ? true : false
          ),
          _btn(
            label: 'Errores',
            fnc: () => pageProvi.consola = Consola.errores,
            isActive: (pageProvi.consola == Consola.errores) ? true : false
          ),
          _btn(
            label: 'SCM',
            fnc: () => pageProvi.consola = Consola.scm,
            isActive: (pageProvi.consola == Consola.scm) ? true : false
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              sock.cantManifest = 0;
              sock.cantShows = 0;
              sock.manifests = [];
              pageProvi.closeConsole = true;
            },
            icon: const Icon(Icons.cleaning_services_rounded, color: Colors.white, size: 15)
          ),
          IconButton(
            onPressed: () => pageProvi.closeConsole = true,
            icon: const Icon(Icons.close, color: Color.fromARGB(255, 238, 111, 111), size: 20)
          )
        ],
      ),
    );
  }

  ///
  Widget _btn({
    required bool isActive,
    required String label,
    required Function fnc,
    String value = '',
  }) {

    return TextButton(
      onPressed: () => fnc(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textScaleFactor: 1,
            style: TextStyle(
              color: (isActive)
              ?const Color.fromARGB(255, 255, 255, 255)
              :const Color.fromARGB(255, 158, 158, 158)
            ),
          ),
          if(value.isNotEmpty && value != '0')
            ...[
              const SizedBox(width: 5),
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: const Color.fromARGB(255, 82, 82, 82)
                ),
                child: Center(
                  child: Text(
                    value,
                    textScaleFactor: 1,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color.fromARGB(255, 255, 255, 255)
                    ),
                  ),
                )
              )
            ]
        ],
      )
    );
  }

  ///
  Widget _determinarWidget(Consola pagina) {

    late Widget child;
    switch (pagina) {
      case Consola.centinela:
        child = const CentinelaConsola();
        break;
      case Consola.alertas:
        child = const AlertasConsola();
        break;
      case Consola.errores:
        child = const ErroresConsola();
        break;
      case Consola.scm:
        child = const ScmConsola();
        break;
      default:
        child = const ScmConsola();
    }
    return child;
  }

}