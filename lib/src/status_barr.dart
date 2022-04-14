import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/sng_manager.dart';
import 'providers/pages_provider.dart';
import 'providers/socket_conn.dart';
import 'providers/window_cnf_provider.dart';
import 'vars/globals.dart';
import 'pages/widgets/texto.dart';

class StatusBarr extends StatelessWidget {

  StatusBarr({Key? key}) : super(key: key);

  final Globals globals = getSngOf<Globals>();

  @override
  Widget build(BuildContext context) {
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      height: MediaQuery.of(context).size.height * 0.03,
      color: context.watch<SocketConn>().isConnectedSocked
       ? context.read<WindowCnfProvider>().sttBarrColorOn
       : context.read<WindowCnfProvider>().sttBarrColorOff,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _btnIcon(tip: 'Cerrar Sesión', icono: Icons.logout, fnc: () {
            context.read<SocketConn>().cerrarConection();
            context.read<SocketConn>().isLoged = false;
            context.read<PageProvider>().resetPage();
          }),
          const SizedBox(width: 10),
          Texto(txt: 'SWP de: ${context.watch<SocketConn>().username} [${globals.curc}]', sz: 12, txtC: const Color(0xFFFFFFFF)),
          _btnTxt(label: '<C:>', fnc: () => context.read<WindowCnfProvider>().closeConsole = false),
          const SizedBox(width: 5),
          _btnIconAndTxt(txt: '0', tip: 'Errores', icono: Icons.close, fnc: (){}),
          const SizedBox(width: 5),
          _btnIconAndTxt(txt: '0', tip: 'Alertas', icono: Icons.warning_amber_outlined, fnc: (){}),
          const SizedBox(width: 5),
          _btnIconAndTxt(txt: '0', tip: 'SCM', icono: Icons.local_post_office_outlined, fnc: (){}),
        ],
      ),
    );
  }

  ///
  Widget _btnIconAndTxt({
    required IconData icono,
    required String txt,
    required String tip,
    required Function fnc,
  }) {

    return Row(
      children: [
        IconButton(
          onPressed: () => fnc(),
          icon: Icon(icono),
          padding: const EdgeInsets.all(0),
          visualDensity: VisualDensity.compact,
          tooltip: tip,
          alignment: Alignment.center,
          color: const Color(0xFFFFFFFF),
          iconSize: 15,
          constraints: const BoxConstraints(
            maxHeight: 15, minWidth: 25
          ),
        ),
        Texto(txt: txt, sz: 12, txtC: const Color(0xFFFFFFFF))
      ],
    );
  }

  ///
  Widget _btnIcon({
    required IconData icono,
    required String tip,
    required Function fnc,
  }) {

    return IconButton(
      onPressed: () => fnc(),
      icon: Icon(icono),
      padding: const EdgeInsets.all(0),
      visualDensity: VisualDensity.compact,
      tooltip: tip,
      alignment: Alignment.center,
      color: const Color(0xFFFFFFFF),
      iconSize: 15,
      constraints: const BoxConstraints(
        maxHeight: 15, maxWidth: 15
      ),
    );
  }

  ///
  Widget _btnTxt({
    required String label,
    required Function fnc,
  }) {

    return TextButton(
      onPressed: () => fnc(),
      child: Texto(
        txt: label, sz: 13, txtC: const Color(0xffFFFFFF), 
      )
    );
  }
}