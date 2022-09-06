import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:scp/src/pages/content/config_sections/widgets/decoration_field.dart';

import '../../config/sng_manager.dart';
import '../../vars/globals.dart';
import '../../entity/request_event.dart';
import '../../providers/socket_conn.dart';

import '../widgets/texto.dart';

class HarbiConsola extends StatefulWidget {

  const HarbiConsola({Key? key}) : super(key: key);

  @override
  State<HarbiConsola> createState() => _HarbiConsolaState();
}

class _HarbiConsolaState extends State<HarbiConsola> {

  final TextEditingController _pass = TextEditingController();
  final FocusNode _passFc = FocusNode();
  final info = NetworkInfo();
  final Globals globals = getSngOf<Globals>();

  bool _hiddePass = true;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _initWidget(null));
    super.initState();
  }

  @override
  void dispose() {
    _pass.dispose();
    _passFc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
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
        SizedBox(
          height: 65,
          child: _txtPass()
        ),
        Selector<SocketConn, String>(
          selector: (_, psock) => psock.msgErr,
          builder: (_, val, __) => Texto(txt: val, sz: 13, txtC: Colors.grey,)
        )
      ],
    );
  }

  ///
  Widget _txtPass() {

    final wath = context.watch<SocketConn>();
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: DecorationField.fieldBy(
              ctr: _pass, fco: _passFc, help: '', orden: 1,
              isPass: true, iconoPre: Icons.security,
              showPass: _hiddePass,
              onPressed: (val) => setState(() {
                _hiddePass = val;
              }),
              validate: (String? val) {
                if(val != null) {
                  return null;
                }
                return 'Tu Contraseña por favor';
              }
            ),
          )
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          style: ButtonStyle(
            padding: MaterialStateProperty.all(
              const EdgeInsets.symmetric(vertical: 18, horizontal: 15)
            ),
            backgroundColor: MaterialStateProperty.all(
              (wath.isConnectedSocked)
              ? Colors.white.withOpacity(0.2) : Colors.red
            )
          ),
          onPressed: () async => await _conectar(),
          child: Texto(
            txt: (wath.isConnectedSocked) ? 'Desconectar' : 'Conectar',
            txtC: (wath.isConnectedSocked)? const Color.fromARGB(255, 255, 141, 133) : Colors.white,
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
                _txtCon(label: 'IP Harbi: ${globals.ipHarbi}'),
                _txtCon(label: 'Puerto: ${globals.portHarbi}'),
                _txtCon(label: 'ID Harbi: ${socketConn.idConn}'),
                _txtCon(label: 'Conexión: ${globals.user.nombre}'),
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
                const Texto(txt: 'Llave de Conexión', txtC: Colors.amber),
                Container(
                  constraints: BoxConstraints.expand(
                    height: MediaQuery.of(context).size.height * 0.13
                  ),
                  child: SelectableText(
                    globals.user.tkServ,
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

    if(globals.ipHarbi.isNotEmpty) {
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