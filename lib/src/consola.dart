import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/consola/alertas.dart';
import 'pages/consola/notiff.dart';
import 'pages/consola/scm.dart';
import 'providers/socket_conn.dart';
import 'providers/pages_provider.dart';
import 'providers/window_cnf_provider.dart';

class ConsolaSide extends StatelessWidget {

  final int stt;
  const ConsolaSide({
    Key? key,
    required this.stt,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final winCnf = context.read<WindowCnfProvider>();
    
    double widthOfResto = winCnf.tamMiddle;
    double w = (widthOfResto * 100) / MediaQuery.of(context).size.width;
    double wt = MediaQuery.of(context).size.width * ((100 - w) / 100);
    double h = MediaQuery.of(context).size.height * 0.25;
    if(stt == 1) { h = 43.5; }
    if(stt == 0) { h = 0; }

    return Container(
      width: wt,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color.fromARGB(255, 75, 75, 75), width: 0.8),
        )
      ),
      height: h,
      child: Column(
        children: [
          _pestaniasConsole(context),
          const SizedBox(height: 1),
          if(stt == 2)
            Expanded(
              child: Container(
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
            label: 'Alertas',
            fnc: () => _changeSttConsola(pageProvi, Consola.alertas),
            isActive: (pageProvi.consola == Consola.alertas) ? true : false
          ),
          Selector<SocketConn, int>(
            selector: (_, prov) => prov.refreshNotiff,
            builder: (_, inte, __) {
              return Row(
                children: [
                  _btn(
                    label: 'Notificaciones',
                    fnc: () => _changeSttConsola(pageProvi, Consola.notiff),
                    isActive: (pageProvi.consola == Consola.notiff) ? true : false
                  ),
                  if(sock.allNotif['all'] != '0')
                    _badged(sock.allNotif['all']!),
                ],
              );
            },
          ),
          _btn(
            label: 'SCM',
            fnc: () => pageProvi.consola = Consola.scm,
            isActive: (pageProvi.consola == Consola.scm) ? true : false
          ),
          const Spacer(),
          IconButton(
            onPressed: () async {
              pageProvi.sttConsole = 1;
              await sock.cleanAllNotiff();
            },
            icon: const Icon(Icons.cleaning_services_rounded, color: Colors.white, size: 15)
          ),
          IconButton(
            onPressed: () => pageProvi.sttConsole = 1,
            padding: const EdgeInsets.symmetric(horizontal: 0),
            icon: const Icon(Icons.minimize, color: Color.fromARGB(255, 238, 111, 111), size: 20)
          ),
          IconButton(
            onPressed: () => pageProvi.sttConsole = 2,
            padding: const EdgeInsets.symmetric(horizontal: 0),
            icon: const Icon(Icons.check_box_outline_blank, color: Color.fromARGB(255, 238, 111, 111), size: 20)
          ),
          IconButton(
            onPressed: () => pageProvi.sttConsole = 0,
            padding: const EdgeInsets.symmetric(horizontal: 0),
            icon: const Icon(Icons.close, color: Color.fromARGB(255, 238, 111, 111), size: 20)
          )
        ],
      ),
    );
  }
  
  ///
  Widget _badged(String cant) {

    const double radius = 15;

    return Container(
      width: radius, height: radius,
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(radius)
      ),
      child: Center(
        child: Text(
          cant, 
          textScaleFactor: 1,
          style: const TextStyle(
            fontWeight: FontWeight.w300,
            color: Colors.white,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  ///
  Widget _btn({
    required bool isActive,
    required String label,
    required Function fnc,
    String value = ''}) 
  {

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
              :const Color.fromARGB(255, 158, 158, 158),
              fontWeight: FontWeight.w200,
              letterSpacing: 1.05
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
      case Consola.alertas:
        child = const AlertasConsola();
        break;
      case Consola.notiff:
        child = Selector<SocketConn, int>(
          selector: (_, prov) => prov.refreshNotiff,
          builder: (_, inte, __) => NotiffConsola(isRefresh: inte)
        );
        break;
      case Consola.scm:
        child = const ScmConsola();
        break;
      default:
        child = const ScmConsola();
    }
    return child;
  }

  ///
  void _changeSttConsola(PageProvider pageR, Consola pressIn) {

    if(_isCloseConsole(pageR)) {
      if(pageR.sttConsole == 0 || pageR.sttConsole == 1) {
        pageR.sttConsole = 2;
        return;
      }
    }

    if(pageR.consola == pressIn) {
      pageR.sttConsole = 1;
    }
    pageR.consola = pressIn;
  }

  ///
  bool _isCloseConsole(PageProvider pageR) {
    if(pageR.sttConsole == 0 || pageR.sttConsole == 1) {
      return true;
    }
    return false;
  }

}