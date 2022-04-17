import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/vars/widgets_utils.dart';

import 'config/sng_manager.dart';
import 'entity/request_event.dart';
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
    
    final readC = context.read<SocketConn>();
    final watchC = context.watch<SocketConn>();
    const String reint = '[Reconectar]';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      height: MediaQuery.of(context).size.height * 0.03,
      color: watchC.isConnectedSocked
       ? context.read<WindowCnfProvider>().sttBarrColorOn
       : context.read<WindowCnfProvider>().sttBarrColorOff,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _btnIcon(tip: 'Cerrar Sesión', icono: Icons.logout, fnc: () {
            readC.cerrarConection();
            readC.isLoged = false;
            context.read<PageProvider>().resetPage();
          }),
          const SizedBox(width: 10),
          Texto(txt: 'SWP de: ${watchC.username} [${globals.curc}]', sz: 12, txtC: const Color(0xFFFFFFFF)),
          _btnTxt(label: '<C:>', fnc: () => context.read<PageProvider>().closeConsole = false),
          const SizedBox(width: 5),
          _btnIconAndTxt(txt: '0', tip: 'Errores', icono: Icons.close, fnc: (){}),
          const SizedBox(width: 5),
          _btnIconAndTxt(txt: '0', tip: 'Alertas', icono: Icons.warning_amber_outlined, fnc: (){}),
          const SizedBox(width: 5),
          _btnIconAndTxt(txt: '0', tip: 'SCM', icono: Icons.local_post_office_outlined, fnc: (){}),
          const Spacer(),
          Texto(txt: 'HARBI. ${watchC.idConn}', sz: 12, txtC: const Color.fromARGB(255, 255, 255, 255)),
          const SizedBox(width: 5),
          if(readC.msgCron == 'X' || readC.msgCron.startsWith('ERROR'))
            _btnTxt(
              label: (readC.msgCron.startsWith('ERROR')) ? 'ERROR $reint' : reint,
              fnc: () async => await _reconectar(context, readC)
            )
          else
            Texto(txt: 'REV. ${watchC.msgCron}', sz: 12, txtC: const Color.fromARGB(255, 255, 255, 255),),
          if(watchC.alertCV)
            ...[
              const SizedBox(width: 10),
              _btnIcon(
                icono: Icons.notifications_on_rounded,
                tip: 'Se realizó una Actualización del Centinela',
                fnc: (){
                  readC.alertCV = false;
                  context.read<PageProvider>().consola = Consola.centinela;
                  context.read<PageProvider>().closeConsole = false;
                }
              )
            ]
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


  ///
  Future<void> _reconectar(BuildContext context, SocketConn _sock) async {

    await WidgetsAndUtils.showAlert(
      context,
      titulo: 'RECONECTANDO A HARBI',
      msg: 'Recuerda antes de reconectar a Harbi, necesitas reiniciarlo, por favor '
      'realiza primeramente dicha acción y posteriormente presiona el botón de HECHO.',
      onlyYES: true, msgOnlyYes: 'HECHO'
    );

    final data = {
      'username' : globals.curc,
      'password' : globals.password
    };
    await _sock.awaitResponseSocket(
      event: RequestEvent(event: 'connection', fnc: 'exite_user_local', data: data),
      msgInit: 'Haciendo login en local',
      msgExito: 'Login Autorizado'
    );

    if(!_sock.msgErr.contains('Error')) {
        _sock.msgCron= 'OK.';
        _sock.isLoged = true;
    }else{
      _sock.msgCron= 'ERROR';
    }

  }

}
