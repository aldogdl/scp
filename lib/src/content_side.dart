import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/pages/content/c_config_page.dart';
import 'package:scp/src/pages/widgets/windows_buttons.dart';
import 'package:scp/src/providers/socket_conn.dart';
import 'providers/pages_provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

import 'package:scp/src/consola.dart';
import 'pages/content/c_cotizadores_page.dart';
import 'pages/content/c_solicitantes_page.dart';
import 'pages/content/c_solicitudes_page.dart';
import 'package:scp/src/providers/window_cnf_provider.dart';

class ContentSide extends StatelessWidget {

  const ContentSide({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final winCnf = context.read<WindowCnfProvider>();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            winCnf.backgroundStartColor,
            winCnf.backgroundStartColor,
            winCnf.backgroundEndColor
          ],
          stops: const [0.0, 0.5, 1.0]
        ),
      ),
      child: Column(
        children: [
          WindowTitleBarBox(
            child: Row(
              children: [
                Expanded(
                  child: MoveWindow(
                    child: _head(context),
                  )
                ),
                const WindowButtons()
              ]
            )
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Consumer<PageProvider>(
                  builder: (_, PageProvider page, __) => _determinarWidget(page.page),
                ),
                if(!context.watch<WindowCnfProvider>().closeConsole)
                  const Positioned(
                    bottom: 0, left: 0,
                    child: ConsolaSide(),
                  )
              ],
            ),
          ),
        ]
      )
    );
  }

  ///
  Widget _head(BuildContext context) {

    return Row(
      children: [
        const SizedBox(width: 5),
        const Icon(Icons.pages, size: 20, color: Color.fromARGB(255, 33, 150, 243)),
        const SizedBox(width: 10),
        _txt(label: context.watch<PageProvider>().page.name.toUpperCase()),
        const Spacer(),
        ..._headSwithConnection(context),
        const SizedBox(width: 10),
      ],
    );
  }

  ///
  List<Widget> _headSwithConnection(BuildContext context) {

    return [
      _txt(
        label: 'Remoto',
        color: (!context.watch<SocketConn>().isLocalConn)
        ? Colors.white : Colors.grey
      ),
      SizedBox(
        height: 40,
        child: FittedBox(
          fit: BoxFit.fill,
          child: Switch(
            value: context.watch<SocketConn>().isLocalConn,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (val){
              context.read<SocketConn>().isLocalConn = val;
            }
          ),
        ),
      ),
      _txt(
        label: 'Local',
        color: (context.watch<SocketConn>().isLocalConn)
        ? Colors.white : Colors.grey
      )
    ];
  }

  ///
  Widget _txt({
    required String label,
    Color color = Colors.green,
    double size = 12,
  }) {

    return Text(
      label,
      textScaleFactor: 1,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.bold,
        color: color
      ),
    );
  }

  ///
  Widget _determinarWidget(Paginas pagina) {

    late Widget child;
    switch (pagina) {
      case Paginas.solicitudes:
        child = const CSolicitudesPage();
        break;
      case Paginas.solicitantes:
        child = const CSolicitantesPage();
        break;
      case Paginas.cotizadores:
        child = const CCotizadoresPage();
        break;
      case Paginas.config:
        child = const CConfigPage();
        break;
      default:
    }
    return child;
  }
}
