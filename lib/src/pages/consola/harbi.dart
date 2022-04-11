import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../../config/sng_manager.dart';
import '../../vars/globals.dart';
import '../../entity/request_event.dart';
import '../../providers/socket_conn.dart';
import '../../providers/window_cnf_provider.dart';

import '../widgets/texto.dart';

class HarbiConsola extends StatefulWidget {

  const HarbiConsola({Key? key}) : super(key: key);

  @override
  State<HarbiConsola> createState() => _HarbiConsolaState();
}

class _HarbiConsolaState extends State<HarbiConsola> {

  final TextEditingController _pass = TextEditingController();
  final info = NetworkInfo();
  final Globals globals = getSngOf<Globals>();

  @override
  void initState() {
    WidgetsBinding.instance!.addPostFrameCallback((_) => _initWidget(null));
    super.initState();
  }

  @override
  void dispose() {
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _coneccion(),
        ),
        Expanded(
          flex: 4,
          child: _dataConeccion(),
        )
      ],
    );
  }

  ///
  Widget _coneccion() {

    return ListView(
      children: [

        Text(
          'Actualmente ${ (context.watch<SocketConn>().isConnectedSocked) ? 'CONECTADO' : 'DESCONECTADO' }',
          textScaleFactor: 1,
          textAlign: TextAlign.left,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.blue
          ),
        ),
        const Divider(color: Colors.grey),
        Row(
          children: [
            _txtCon(
              label: 'IP: ${globals.myIp}', color: Colors.green
            ),
            const Spacer(),
            if(context.watch<WindowCnfProvider>().contentSize.width > 665)
              _txtCon(
                label: 'Nombre: ${globals.wifiName}', color: Colors.green
              ),
          ],
        ),
        SizedBox(
          height: 45,
          child: Padding(
            padding: const EdgeInsets.only(
              right: 10, top: 5, bottom: 5
            ),
            child: _txtPass()
          )
        ),
        Selector<SocketConn, String>(
          selector: (_, psock) => psock.msgErr,
          builder: (_, val, __) => Text(
            val,
            textScaleFactor: 1,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: Colors.grey
            ),
          ),
        )
      ],
    );
  }

  ///
  Widget _txtPass() {

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _pass,
            onSubmitted: (v) async => await _conectar(),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(
                  color: Colors.green,
                  width: 1
                )
              )
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(
              (context.watch<SocketConn>().isConnectedSocked)
              ? Colors.white.withOpacity(0.2) : Colors.red
            )
          ),
          onPressed: () async => await _conectar(),
          child: Text(
            (context.watch<SocketConn>().isConnectedSocked) ? 'Desconectar' : 'Conectar',
            textScaleFactor: 1,
            style: TextStyle(
              color: (context.watch<SocketConn>().isConnectedSocked)
              ? Colors.red : Colors.white
            ),
          )
        )
      ],
    );
  }

  ///
  Widget _dataConeccion() {

    final socketConn = context.read<SocketConn>();

    return Container(
      padding: const EdgeInsets.only(left: 20),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: ListView(
              children: [
                _txtCon(label: 'IP Harbi: ${socketConn.ipHarbi ?? '...'}'),
                _txtCon(label: 'Puerto: ${globals.portHarbi}'),
                _txtCon(label: 'ID Harbi: ${socketConn.idConn}'),
                _txtCon(label: 'Conección: ${socketConn.username}'),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Texto(txt: 'Llave de Conección', txtC: Colors.amber),
                Container(
                  constraints: BoxConstraints.expand(
                    height: MediaQuery.of(context).size.height * 0.13
                  ),
                  child: SelectableText(
                    globals.tkServ,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey
                    ),
                  ),
                )
              ],
            ),
          )
        ]
      ),
    );
  }

  ///
  Widget _txtCon({
    required String label,
    Color color = Colors.amber
  }) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        label,
        textScaleFactor: 1,
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: color
        ),
      ),
    );
  }

  ///
  Future<void> _initWidget(_) async {

    final socketPr = context.read<SocketConn>();

    if(socketPr.ipHarbi != null) {
      socketPr.msgErr = 'Coloca tu contraseña...';
    }else{
      socketPr.msgErr = 'ERROR!! no se encontró la IP de Harbi';
    }
    if(mounted) {
      setState(() {});
    }
  }

  ///
  Future<void> _conectar() async {

    RequestEvent event = RequestEvent(
      event: 'initConnection', fnc: 'x', data: {
        'password': _pass.text
      }
    );
    setState(() {
      _pass.text = '';
    });
    context.read<SocketConn>().send(event);
  }
}