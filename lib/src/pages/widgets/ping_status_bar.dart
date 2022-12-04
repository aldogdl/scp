import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/socket_conn.dart';

class PingStatusBar extends StatelessWidget {

  PingStatusBar({Key? key}) : super(key: key);

  final _isRePing = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    
    return Selector<SocketConn, int>(
      selector: (_, prov) => prov.isMyConn,
      builder: (_, myCon, __) {

        Color cIcon = Colors.white;
        late IconData ico;
        late String tip;
        
        switch (myCon) {
          case 0:
            ico = Icons.content_cut_outlined;
            tip = 'Desconectado a Harbi';
            break;
          case 1:
            ico = Icons.sensors_sharp;
            cIcon = Colors.red;
            tip = 'Buscando coneccion con Harbi';
            break;
          case 2:
            ico = Icons.done;
            tip = 'En espera de respuesta de Harbi';
            break;
          case 3:
            ico = Icons.sensors_sharp;
            cIcon = const Color.fromARGB(255, 165, 29, 19);
            tip = 'Conectado';
            break;
          case 4:
            ico = Icons.slow_motion_video_sharp;
            tip = 'Reconectando...';
            break;
          default:
            ico = Icons.social_distance;
        }

        if(ico == Icons.social_distance) { return _connManual(context); }
        return _icoType(ico, tip, cIcon);
      },
    );
    
  }
  
  ///
  Widget _icoType(IconData ico, String tip, Color cIcon) {

    return _btnIcon(
      tip: 'Enviar Ping de Conexión',
      icono: ico, size: 17, cIcon: cIcon,
      fnc: () {}
    );
  }

  ///
  Widget _connManual(BuildContext context) {

    final readC = context.read<SocketConn>();

    return ValueListenableBuilder(
      valueListenable: _isRePing,
      builder: (_, val, child) {

        if(val){ return child!; }

        return _btnIcon(
          tip: 'Enviar Ping de Conexión',
          icono: Icons.social_distance, size: 17,
          cIcon: Colors.white,
          fnc: () async {
            
            _isRePing.value = true;
            await readC.makeFirstConnection();
            await readC.chechNotiffCurrents();
            _isRePing.value = false;
          }
        );
      },
      child: _loading(),
    );
  }

  ///
  Widget _loading() {

    return const SizedBox(
      width: 10, height: 10,
      child: CircularProgressIndicator(
        color: Color.fromARGB(255, 8, 136, 40),
        backgroundColor: Colors.white,
        strokeWidth: 1,
      ),
    );
  }

  ///
  Widget _btnIcon({
    required IconData icono,
    required Color cIcon,
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
      color: cIcon,
      iconSize: size,
      constraints: BoxConstraints(
        maxHeight: size, maxWidth: size
      ),
    );
  }
}