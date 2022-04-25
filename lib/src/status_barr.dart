import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/widgets/change_ip_dialog.dart';
import 'services/get_content_files.dart';
import 'pages/widgets/widgets_utils.dart';
import 'config/sng_manager.dart';
import 'entity/request_event.dart';
import 'providers/pages_provider.dart';
import 'providers/socket_conn.dart';
import 'providers/window_cnf_provider.dart';
import 'vars/globals.dart';
import 'pages/widgets/texto.dart';

class StatusBarr extends StatelessWidget {

  StatusBarr({Key? key}) : super(key: key);

  final Globals _globals = getSngOf<Globals>();
  
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
          Texto(txt: 'SWP de: ${watchC.username} [${_globals.curc}]', sz: 12, txtC: const Color(0xFFFFFFFF)),
          const SizedBox(width: 15),
          _btnIconAndTxt(txt: '0', tip: 'Errores', icono: Icons.close, fnc: (){
            context.read<PageProvider>().consola = Consola.errores;
            if(context.read<PageProvider>().closeConsole) {
              context.read<PageProvider>().closeConsole = false;
            }
          }),
          const SizedBox(width: 5),
          _btnIconAndTxt(txt: '0', tip: 'Alertas', icono: Icons.warning_amber_outlined, fnc: (){
            context.read<PageProvider>().consola = Consola.alertas;
            if(context.read<PageProvider>().closeConsole) {
              context.read<PageProvider>().closeConsole = false;
            }
          }),
          const SizedBox(width: 5),
          _btnIconAndTxt(txt: '0', tip: 'SCM', icono: Icons.local_post_office_outlined, fnc: (){
            context.read<PageProvider>().consola = Consola.scm;
            if(context.read<PageProvider>().closeConsole) {
              context.read<PageProvider>().closeConsole = false;
            }
          }),
          if(readC.hasErrWithIpDbLocal.isNotEmpty)
            ...[
              const SizedBox(width: 8),
              TextButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.transparent),
                  padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () async => await _changeIp(context, readC),
                child: Text(
                  ' ${readC.hasErrWithIpDbLocal} ',
                  textScaleFactor: 1,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    backgroundColor: Color.fromARGB(255, 146, 35, 27)
                  ),
                )
              ),
            ],
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

  // ---------------------- CONTROLADOR --------------------------------

  ///
  Future<void> _reconectar(BuildContext context, SocketConn _sock) async {

    await WidgetsAndUtils.showAlert(
      context,
      titulo: 'RECONECTANDO A HARBI',
      msg: 'Recuerda antes de reconectar a Harbi, necesitas reiniciarlo, por favor '
      'realiza primeramente dicha acción y posteriormente presiona el botón de HECHO.',
      onlyAlert: false, onlyYES: true, msgOnlyYes: 'HECHO'
    );

    final data = {
      'username' : _globals.curc,
      'password' : _globals.password
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

  ///
  Future<void> _changeIp(BuildContext context, SocketConn _sock) async {

    String help = 'La IP hacia el servidor LOCAL';
    if(!_globals.isLocalConn) {
      help = 'La IP hacia el servidor REMOTO';
    }
    List<int> ipN = [];
    var regExp = RegExp(r'[0-9]{1,3}');
    var str = _sock.hasErrWithIpDbLocal;
    Iterable<Match> matches = regExp.allMatches(str);
    for (Match m in matches) {
      int? ip = int.tryParse(m[0]!);
      if(ip != null) {
        ipN.add(ip);
      }
    }
    
    await WidgetsAndUtils.showAlertBody(
      context,
      titulo: 'CAMBIANDO PROTOCOLO IP',
      onlyAlert: true,
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ChangeIpDialog(
          ipCurrent: (ipN.isNotEmpty) ? ipN.join('.') : '',
          msgHelp: help,
          onSave: (String ipNew) async {
            await GetContentFile.cambiarIpEnArchivoPath(ipNew);
            _sock.hasErrWithIpDbLocal = '';
          }
        ),
      )
    );

  }

}
