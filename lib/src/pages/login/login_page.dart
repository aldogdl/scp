import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:scp/src/config/sng_manager.dart';
import 'package:scp/src/pages/widgets/texto.dart';
import 'package:scp/src/providers/socket_conn.dart';
import 'package:scp/src/services/get_paths.dart';
import 'package:scp/src/vars/globals.dart';

import '../../entity/request_event.dart';
import '../widgets/windows_buttons.dart';

class LoginPage extends StatefulWidget {

  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final Globals globals = getSngOf<Globals>();

  final GlobalKey<FormState> _frmKey = GlobalKey<FormState>();
  final TextEditingController _curc = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  final FocusNode _fcurc = FocusNode();
  final FocusNode _fpass = FocusNode();

  bool _showPass = true;
  bool _isInit = false;
  late final SocketConn _sock;

  @override
  void dispose() {
    _curc.dispose();
    _pass.dispose();
    _fcurc.dispose();
    _fpass.dispose();
    super.dispose();
  }

  @override
  void initState() {
    WidgetsBinding.instance!.addPostFrameCallback(_initWidget);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    if(!_isInit) {
      _isInit = true;
      _sock = context.read<SocketConn>();
      _sock.setMsgWithoutNotified('Buscando Conecciónes');
    }

    return Scaffold(body: _body());
  }

  ///
  Widget _body() {

    return Column(
      children: [
        WindowTitleBarBox(
          child: Row(
            children: [
              Expanded(
                child: MoveWindow()
              ),
              const WindowButtons()
            ]
          )
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Texto(
                txt: 'Sistema Central de Procesamiento',
                txtC: Color.fromARGB(255, 218, 218, 218),
                sz: 22,
              ),
              Texto(txt: context.watch<SocketConn>().msgErr, txtC: Colors.blue),                
              const SizedBox(height: 10),
              Container(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width * 0.1,
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                width: MediaQuery.of(context).size.width * 0.25,
                child: Form(
                  key: _frmKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _fieldBy(ctr: _curc, fco: _fcurc, help: 'Ingresa tu CURC',
                        validate: (String? val) {
                          if(val != null) {
                            if(val.contains('-')) {
                              return null;
                            }else{

                              return 'El CURC es invalido';
                            }
                          }
                          return 'Este campo es Requerido';
                        }
                      ),
                      const SizedBox(height: 20),
                      _fieldBy(ctr: _pass, fco: _fpass, help: 'Ingresa tu Contraseña',
                        isPass: true,
                        validate: (String? val) {
                          if(val != null) {
                            if(val.length >= 3) {
                              return null;
                            }
                          }
                          return 'Este campo es Requerido';
                        }
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width * 0.1,
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                width: MediaQuery.of(context).size.width * 0.25,
                height: 35,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.green),
                  ),
                  onPressed: () => _autenticar(), 
                  child: const Texto(txt: 'AUTENTICARME', txtC: Colors.black, isBold: true)
                ),
              )
            ],
          )
        ),
      ]
    );
  }

  ///
  Widget _fieldBy({
    required TextEditingController ctr,
    required FocusNode fco,
    required String help,
    required Function validate,
    bool isPass = false
  }) {

    return TextFormField(
      controller: ctr,
      focusNode: fco,
      textInputAction: TextInputAction.next,
      obscureText: (!isPass) ? false : _showPass,
      validator: (val) => validate(val),
      decoration: InputDecoration(
        suffixIcon: (!isPass)
        ? null
        : IconButton(
          onPressed: () => setState((){ _showPass = !_showPass; }),
          icon: Icon((_showPass) ? Icons.visibility : Icons.visibility_off)
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.grey,
            width: 1
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.grey,
            width: 1
          ),
        ),
        errorStyle: const TextStyle(
          color: Color.fromARGB(255, 255, 244, 149)
        ),
        helperText: help
      ),
    );
  }

  ///
  Future<void> _initWidget(_) async {

    final socketPr = context.read<SocketConn>();

    _sock.msgErr = 'Datos de Conección';
    await socketPr.getNameRed();
    bool hasIp = await socketPr.getIpConnectionToHarbi();
    if(hasIp) {
      _sock.msgErr = 'Identifícate por favor';
    }
  }

  ///
  Future<void> _autenticar() async {

    if(_frmKey.currentState!.validate()) {

      _sock.msgErr = 'Validando Credenciales';

      final data = {
        'username' : _curc.text.toLowerCase(),
        'password' : _pass.text.toLowerCase()
      };

      String dom = await GetPaths.getDominio();
      String base = 'secure-api-check';
      http.Response resp = await http.post(Uri.parse('$dom$base'), body: json.encode(data),
         headers: {'Content-type': 'application/json', 'Accept': 'application/json'}
      );
      if(resp.statusCode == 200) {
        final r = Map<String, dynamic>.from(json.decode(resp.body));

        globals.tkServ = '0';
        if(r.containsKey('token')) {
          globals.tkServ = r['token'];
        }
        
        _sock.msgErr = 'Conectando tu Herramienta HARBI';
        final sock = context.read<SocketConn>();
        RequestEvent event = RequestEvent(
          event: 'initConnection', fnc: 'x', data: data
        );
        sock.send(event);
      }else{
        _sock.msgErr = 'Credenciales Invalidas';
      }
    }
  }
}