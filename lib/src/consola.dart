import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final pageProv = context.read<PageProvider>();
    double widthOfResto = winCnf.tamToolBar + winCnf.tamMiddle;
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
          _pestaniasConsole(pageProv, winCnf),
          const SizedBox(height: 1),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: winCnf.backgroundStartColor,
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
  Widget _pestaniasConsole(PageProvider pageProvi, WindowCnfProvider winCnf) {

    return Container(
      decoration: BoxDecoration(
        color: winCnf.backgroundStartColor,
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
            fnc: () => pageProvi.consola = Consola.centinela,
            isActive: (pageProvi.consola == Consola.centinela) ? true : false
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
            onPressed: () => pageProvi.closeConsole = true,
            icon: const Icon(Icons.cleaning_services_rounded, color: Colors.white, size: 15)
          ),
          IconButton(
            onPressed: () => pageProvi.closeConsole = true,
            icon: const Icon(Icons.close, color: Colors.white, size: 20)
          )
        ],
      ),
    );
  }

  ///
  Widget _btn({
    required Function fnc,
    required String label,
    required bool isActive,
  }) {

    return TextButton(
      onPressed: () => fnc(),
      child: Text(
        label,
        textScaleFactor: 1,
        style: TextStyle(
          color: (isActive)
          ?const Color.fromARGB(255, 255, 255, 255)
          :const Color.fromARGB(255, 158, 158, 158)
        ),
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