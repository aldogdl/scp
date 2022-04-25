import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/config/sng_manager.dart';
import 'package:scp/src/providers/socket_conn.dart';
import 'package:scp/src/vars/globals.dart';

import '../../../entity/request_event.dart';
import '../../../providers/pages_provider.dart';
import '../../widgets/texto.dart';
import '../../widgets/widgets_utils.dart';

class Home extends StatelessWidget {

  Home({Key? key}) : super(key: key);

  final Globals globals = getSngOf<Globals>();

  @override
  Widget build(BuildContext context) {

    String urlR = 'Desconocido';
    String urlL = 'Desconocido';
    String portL= '0';
    if(globals.ipDbs.isNotEmpty) {
      Uri? uri; 
      if(globals.ipDbs.containsKey('base_r')) {
        uri = Uri.parse(globals.ipDbs['base_r']);
        urlR = uri.host;
      }
      if(globals.ipDbs.containsKey('base_l')) {
        uri = Uri.parse(globals.ipDbs['base_l']);
        urlL = uri.host;
      }
      if(globals.ipDbs.containsKey('port_s')) {
        portL = '${globals.ipDbs['port_s']}';
      }
    }

    final _sock = context.read<SocketConn>();

    List<Map<String, dynamic>> datos = [
      {'c':'Área local:', 'v':globals.wifiName},
      {'c':'La Conexión:', 'v':(globals.isLocalConn) ? 'Es LOCAL': 'Es REMOTA'},
      {'c':'Mi IP:', 'v':globals.myIp},
      {'c':'IP HARBI:', 'v':globals.ipHarbi},
      {'c':'Url al Servidor Local:', 'v':urlL},
      {'c':'URL al Servidor Remoto:', 'v': urlR},
      {'c':'Puerto a HARBI:', 'v':globals.portHarbi},
      {'c':'Puerto a Servidor:', 'v':portL},
      {'c':'ID de Conexión a HARBI:', 'v':_sock.idConn},
      {'c':'MIS DATOS:', 'v':'...'},
      {'c':'Identificación:', 'v':globals.idUser},
      {'c':'Usuario:', 'v':_sock.username},
      {'c':'CURC:', 'v':globals.curc},
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      constraints: BoxConstraints.expand(
        height: MediaQuery.of(context).size.height
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: datos.length,
              itemBuilder: (_, index) => _tileItem(
                index, datos[index]['c'], datos[index]['v']
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _sock.cerrarConection();
                    _sock.isLoged = false;
                    context.read<PageProvider>().resetPage();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Texto(txt: 'Cerrar Sesión')
                ),
                TextButton.icon(
                  onPressed: (){},
                  icon: const Icon(Icons.power_off_rounded),
                  label: const Texto(txt: 'Desconectar a HARBI')
                ),
                TextButton.icon(
                  onPressed: () => _reconectar(context, _sock),
                  icon: const Icon(Icons.settings_power_outlined),
                  label: const Texto(txt: 'Reconectar con HARBI')
                ),
              ],
            )
          )
        ],
      ),
    );
  }

  ///
  Widget _tileItem(int ind, String clave, dynamic valor) {

    return Container(
      color: (ind.isEven) ? Colors.black.withOpacity(0.5) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      child: Row(
        children: [
          Texto(
            txt: clave,
            txtC: ('$valor' == '...') ? Colors.white : const Color.fromARGB(255, 158, 158, 158),
          ),
          const Spacer(),
          Texto(txt: '$valor')
        ],
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
      onlyAlert: false, onlyYES: true, msgOnlyYes: 'HECHO'
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