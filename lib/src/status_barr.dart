import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/sng_manager.dart';
import 'pages/widgets/change_ip_dialog.dart';
import 'pages/widgets/invirt/querys_process.dart';
import 'pages/widgets/texto.dart';
import 'pages/widgets/widgets_utils.dart';
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
  Widget build(BuildContext context) {
    
    final console = context.read<PageProvider>();
    final sock = context.read<SocketConn>();
    final page = context.read<PageProvider>();

    return Selector<SocketConn, List<Map<String, dynamic>>>(
      selector: (_, prov) => prov.manifests,
      builder: (_, manifest, child) {

        if(sock.cantShows != sock.cantManifest) {

          sock.cantShows = sock.cantManifest;
          bool showConcole = false;
          bool showNotif = false;
          bool makeSound = false;

          if(manifest.isNotEmpty) {
            manifest.map((e) {

              if(e.containsKey('cambios')) {
                final cambios = List<String>.from(e['cambios']);
                for (var i = 0; i < cambios.length; i++) {
                  if(cambios[i].endsWith('[IN]')) {
                    makeSound = true;
                    showConcole = true;
                    break;
                  }
                  if(cambios[i].endsWith('[NT]')) {
                    showNotif = true;
                    break;
                  }
                }
              }
            }).toList();
          }
          
          if(showNotif) {
            Future.delayed(const Duration(milliseconds: 250), (){
              sock.alertCV = true;
            });
          }

          if(showConcole && console.closeConsole) {
            Future.delayed(const Duration(milliseconds: 250), (){
              console.putValue(Consola.centinela);
              console.closeConsole = false;
            });
          }

          if(page.page == Paginas.solicitudes) {
            Future.microtask(() => page.refreshLsts = true);
          }

          if(makeSound) { _notiffSound(); }
        }

        return child!;
      },
      child: _bodyBar(context)
    );
  }

  ///
  Widget _bodyBar(BuildContext context) {

    final readC  = context.read<SocketConn>();
    final watchC = context.watch<SocketConn>();
    final pageR  = context.read<PageProvider>();
    final winR   = context.read<WindowCnfProvider>();
    const wid5   = SizedBox(width: 5);
    const wid10   = SizedBox(width: 10);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      height: MediaQuery.of(context).size.height * 0.03,
      color: watchC.isConnectedSocked
      ? winR.sttBarrColorOn : winR.sttBarrColorOff,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _btnIcon(tip: 'Menú Principal', icono: Icons.menu, size: 17, fnc: () {
            pageR.page = Paginas.config;
          }),
          wid10,
          _text('SWP de: ${_globals.user.nombre} [${_globals.user.curc}]'),
          wid10,
          wid5,
          _btnIconAndTxt(txt: '${watchC.manifests.length}', tip: 'Centinela',
            icono: Icons.remove_red_eye_outlined,
            fnc: (){
              pageR.consola = Consola.centinela;
              if(pageR.closeConsole) {
                pageR.closeConsole = false;
              }
            }
          ),
          wid5,
          _btnIconAndTxt(txt: '0', tip: 'Errores', icono: Icons.close, fnc: (){
            pageR.consola = Consola.errores;
            if(pageR.closeConsole) {
              pageR.closeConsole = false;
            }
          }),
          wid5,
          _btnIconAndTxt(txt: '0', tip: 'Alertas', icono: Icons.warning_amber_outlined, fnc: (){
            pageR.consola = Consola.alertas;
            if(pageR.closeConsole) {
              pageR.closeConsole = false;
            }
          }),
          wid5,
          _btnIconAndTxt(txt: '0', tip: 'SCM', icono: Icons.local_post_office_outlined, fnc: (){
            pageR.consola = Consola.scm;
            if(pageR.closeConsole) {
              pageR.closeConsole = false;
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
          _text('HARBI. Ver.: ${_globals.verApp}'),
          wid10,
          _text('Socket. ${watchC.idConn}'),
          wid10,
          _text('REV. ${watchC.msgCron}'),
          if(watchC.alertCV)
            ...[
              wid5,
              _btnIconAndTxt(
                txt: '${watchC.cantAlert}',
                tip: 'Notificacion',
                icono: Icons.notifications_rounded,
                icoColor: const Color(0xFFffffff),
                isBold: true,
                icoSize: 18,
                fnc: (){
                  readC.alertCV = false;
                  readC.cantAlert = 0;
                  pageR.putValue(Consola.centinela);
                  if(pageR.closeConsole) {
                    pageR.closeConsole = false;
                  }
                }
              )
            ],
          const SizedBox(width: 10),
          _btnIcon(tip: 'Enviar Ping de Conexión', icono: Icons.social_distance,
           size: 17, fnc: () {
            readC.sendPing('reping');
          }),
        ],
      ),
    );
  }
  
  ///
  Widget _text(String label) {

    return Text(
      label,
      style: GoogleFonts.inconsolata(
        fontSize: 12,
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
