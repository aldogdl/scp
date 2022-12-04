import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/sng_manager.dart';
import 'pages/widgets/change_ip_dialog.dart';
import 'pages/widgets/invirt/querys_process.dart';
import 'pages/widgets/texto.dart';
import 'pages/widgets/widgets_utils.dart';
import 'pages/widgets/ping_status_bar.dart';
import 'providers/pages_provider.dart';
import 'providers/socket_conn.dart';
import 'providers/window_cnf_provider.dart';
import 'services/get_content_files.dart';
import 'vars/globals.dart';

class StatusBarr extends StatelessWidget {

  final AudioPlayer player;
  StatusBarr({
    Key? key,
    required this.player
  }) : super(key: key);

  final Globals _globals = getSngOf<Globals>();
  
  @override
  Widget build(BuildContext context) => _bodyBar(context);

  ///
  Widget _bodyBar(BuildContext context) {

    final readC  = context.read<SocketConn>();
    final pageR  = context.read<PageProvider>();

    const wid5   = SizedBox(width: 5);
    const wid10  = SizedBox(width: 10);

    return _barrContainer(
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _btnIcon(tip: 'Menú Principal', icono: Icons.menu, size: 17, fnc: () {
            pageR.resetPage();
            pageR.page = Paginas.config;
          }),
          wid10,
          _text('SCP de: ${_globals.user.nombre} [${_globals.user.curc}] V.${_globals.verApp}'),
          wid10,
          wid5,
          Selector<SocketConn, int>(
            selector: (_, prov) => prov.refreshNotiff,
            builder: (_, val, __) {

              if(readC.allNotif['alta'] != '0') {
                Future.delayed(const Duration(milliseconds: 250), (){  
                  pageR.consola = Consola.notiff;
                  _notiffSound();
                  _abrirConsola(pageR);
                });
              }
              return _btnIconAndTxt(txt: readC.allNotif['all']!, tip: 'Notificaciones', icono: Icons.notifications_none_outlined, fnc: (){
                pageR.consola = Consola.notiff;
                _abrirConsola(pageR);
              });
            },
          ),
          wid5,
          _btnIconAndTxt(
            txt: '0', tip: 'Alertas',
            icono: Icons.warning_amber_outlined,
            fnc: (){
              pageR.consola = Consola.alertas;
              _abrirConsola(pageR);
            }
          ),
          wid5,
          _btnIconAndTxt(txt: '0', tip: 'SCM', icono: Icons.local_post_office_outlined, fnc: (){
            pageR.consola = Consola.scm;
            _abrirConsola(pageR);
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
                    fontSize: 11,
                    color: Colors.white,
                    backgroundColor: Color.fromARGB(255, 146, 35, 27)
                  ),
                )
              ),
            ],
          wid10,
          const QuerysProcess(),
          const Spacer(),
          Selector<SocketConn, String>(
            selector: (_, prov) => prov.backgroundProcess,
            builder: (_, val, child) {
              if(val.isEmpty){ return child!; }
              return _text('$val  ');
            },
            child: _text('<BG> '),
          ),
          Selector<SocketConn, int>(
            selector: (_, prov) => prov.idConn,
            builder: (_, ic, __) {
              return _text('HARBI Socket. $ic');
            },
          ),
          wid10,
          Selector<SocketConn, String>(
            selector: (_, prov) => prov.alertCV,
            builder: (_, val, __) {
              return _text(' VCF: $val  ');
            },
          ),
          PingStatusBar()
        ],
      ),
      MediaQuery.of(context).size.height * 0.035
    );
  }
  
  ///
  Widget _barrContainer(Widget child, double alto) {

    return Selector<SocketConn, bool>(
      selector: (_, prov) => prov.isConnectedSocked,
      builder: (cnt, isc, __) {

        final winR = cnt.read<WindowCnfProvider>();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
          height: alto,
          color: isc
          ? winR.sttBarrColorOn : winR.sttBarrColorOff,
          child: child
        );
      },
    );
  }

  ///
  Widget _text(String label) {

    return Text(
      label,
      style: GoogleFonts.inconsolata(
        fontSize: 12,
        fontWeight: FontWeight.w300,
        letterSpacing: 1.05,
        color: const Color(0xFFFFFFFF)
      )
    );
  }

  ///
  Widget _btnIconAndTxt({
    required IconData icono,
    required String txt,
    required String tip,
    required Function fnc,
    Color icoColor = const Color(0xFFFFFFFF),
    double icoSize = 13,
    bool isBold = false})
  {

    return Row(
      children: [
        IconButton(
          onPressed: () => fnc(),
          icon: Icon(icono, color:icoColor),
          padding: const EdgeInsets.all(0),
          visualDensity: VisualDensity.compact,
          tooltip: tip,
          alignment: Alignment.center,
          color: const Color(0xFFFFFFFF),
          iconSize: icoSize,
          constraints: BoxConstraints(
            maxHeight: icoSize, minWidth: 25
          ),
        ),
        Texto(
          txt: txt, sz: 11, txtC: icoColor, isBold: isBold,
        )
      ],
    );
  }

  ///
  Widget _btnIcon({
    required IconData icono,
    required String tip,
    required Function fnc,
    double size = 13})
  {

    return IconButton(
      onPressed: () => fnc(),
      icon: Icon(icono),
      padding: const EdgeInsets.all(0),
      visualDensity: VisualDensity.compact,
      tooltip: tip,
      alignment: Alignment.center,
      color: const Color(0xFFFFFFFF),
      iconSize: size,
      constraints: BoxConstraints(
        maxHeight: size, maxWidth: size
      ),
    );
  }


  // ---------------------- CONTROLADOR --------------------------------

  ///
  void _abrirConsola(PageProvider pageR) {
    if(pageR.sttConsole == 0 || pageR.sttConsole == 1) {
      pageR.sttConsole = 2;
    }
  }

  ///
  void _notiffSound() async => player.play();

  ///
  Future<void> _changeIp(BuildContext context, SocketConn sock) async {

    String help = 'La IP hacia el servidor LOCAL';
    if(!_globals.isLocalConn) {
      help = 'La IP hacia el servidor REMOTO';
    }
    List<int> ipN = [];
    var regExp = RegExp(r'[0-9]{1,3}');
    var str = sock.hasErrWithIpDbLocal;
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
            sock.hasErrWithIpDbLocal = '';
          }
        ),
      )
    );

  }

}
