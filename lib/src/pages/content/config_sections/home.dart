import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/config/sng_manager.dart';
import 'package:scp/src/providers/socket_conn.dart';
import 'package:scp/src/services/get_paths.dart';
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

    final sock = context.read<SocketConn>();

    return Container(
      padding: const EdgeInsets.all(10),
      constraints: BoxConstraints.expand(
        height: MediaQuery.of(context).size.height
      ),
      child: Column(
        children: [
          Container(
            constraints: BoxConstraints.expand(
              height: MediaQuery.of(context).size.height * 0.4,
            ),
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: Image.file(
              File(GetPaths.getNextPortadas()),
              fit: BoxFit.cover,
            ),
          ),
          Container(
            padding: const EdgeInsets.only(top: 8),
            constraints: BoxConstraints.expand(
              height: MediaQuery.of(context).size.height * 0.05,
            ),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20)
              )
            ),
            child: const Texto(
              txt: 'Bienvenido al Sistema Central de Procesamiento de Piezas',
              txtC: Colors.green,
              sz: 18, isCenter: true,
            )
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _datosGenerales(sock),
          ),
          SizedBox(
            height: 40,
            child: _acciones(context, sock),
          )
        ],
      )
    );
  }

  ///
  Widget _datosGenerales(SocketConn sock) {

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
    
    List<Map<String, dynamic>> datosIzq = [
      {'c':'DATOS DE CONEXIÓN:', 'v':'...'},
      {'c':'Área local:', 'v':globals.wifiName},
      {'c':'La Conexión:', 'v':(globals.isLocalConn) ? 'Es LOCAL': 'Es REMOTA'},
      {'c':'Mi IP:', 'v':globals.myIp},
      {'c':'IP HARBI:', 'v':globals.ipHarbi},
      {'c':'Url al Servidor Local:', 'v':urlL},
      {'c':'URL al Servidor Remoto:', 'v': urlR},
    ];

    List<Map<String, dynamic>> datosDer = [
      {'c':'Puerto a HARBI:', 'v':globals.portHarbi},
      {'c':'Puerto a Servidor:', 'v':portL},
      {'c':'ID de Conexión a HARBI:', 'v':sock.idConn},
      {'c':'MIS DATOS:', 'v':'...'},
      {'c':'Identificación:', 'v':globals.idUser},
      {'c':'Usuario:', 'v':sock.username},
      {'c':'CURC:', 'v':globals.curc},
    ];

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: ListView.builder(
            itemCount: datosIzq.length,
            itemBuilder: (_, index) => _tileItem(
              index, datosIzq[index]['c'], datosIzq[index]['v']
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 1,
          child: ListView.builder(
            itemCount: datosDer.length,
            itemBuilder: (_, index) => _tileItem(
              index, datosDer[index]['c'], datosDer[index]['v']
            ),
          )
        )
      ],
    );
  }

  ///
  Widget _acciones(BuildContext context, SocketConn sock) {

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () {
            sock.cerrarConection();
            sock.isLoged = false;
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
          onPressed: () => _reconectar(context, sock),
          icon: const Icon(Icons.settings_power_outlined),
          label: const Texto(txt: 'Reconectar con HARBI')
        ),
      ],
    );
  }
  ///
  Widget _tileItem(int ind, String clave, dynamic valor) {

    double op = (ind.isEven) ? 0.3 : 0.5;
    return Container(
      color: Colors.black.withOpacity(op),
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
  Future<void> _reconectar(BuildContext context, SocketConn sock) async {

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
    await sock.awaitResponseSocket(
      event: RequestEvent(event: 'connection', fnc: 'exite_user_local', data: data),
      msgInit: 'Haciendo login en local',
      msgExito: 'Login Autorizado'
    );

    if(!sock.msgErr.contains('Error')) {
        sock.msgCron= 'OK.';
        sock.isLoged = true;
    }else{
      sock.msgCron= 'ERROR';
    }

  }


}