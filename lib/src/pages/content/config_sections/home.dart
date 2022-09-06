import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'widgets/portada_img.dart';
import '../../widgets/texto.dart';
import '../../../config/sng_manager.dart';
import '../../../providers/socket_conn.dart';
import '../../../vars/globals.dart';

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
          const PortadaImg(),
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
            child: FutureBuilder<String>(
              future: sock.makeRegistroUserToHarbi(),
              builder: (_, AsyncSnapshot snap) {

                if(snap.connectionState == ConnectionState.done) {

                  return Texto(
                    txt: snap.data,
                    txtC: Colors.green,
                    sz: 18, isCenter: true,
                  );
                }

                return const Texto(
                  txt: 'Estamos terminando de Registrar tu Ingreso...',
                  txtC: Colors.blue,
                  sz: 18, isCenter: true,
                );
              },
            )
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _datosGenerales(sock),
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
      {'c':'Identificación:', 'v':globals.user.id},
      {'c':'Usuario:', 'v':globals.user.nombre},
      {'c':'CURC:', 'v':globals.user.curc},
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


}