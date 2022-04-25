import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:provider/provider.dart';

import '../content/config_sections/widgets/decoration_field.dart';
import '../widgets/texto.dart';
import '../widgets/windows_buttons.dart';
import '../../config/sng_manager.dart';
import '../../entity/request_event.dart';
import '../../providers/socket_conn.dart';
import '../../services/get_paths.dart';
import '../../vars/globals.dart';

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

  late final SocketConn _sock;
  bool _showPass = true;
  bool _otroUser = false;
  bool _isInit = false;
  int _intentosConn = 1;
  String _defaultUser = 'Cargando';
  List<String> items = ['Cargando'];
  final ValueNotifier<Map<String, dynamic>> _users =
      ValueNotifier<Map<String, dynamic>>({});

  @override
  void dispose() {
    _curc.dispose();
    _pass.dispose();
    _fcurc.dispose();
    _fpass.dispose();
    _users.dispose();
    super.dispose();
  }

  @override
  void initState() {
    WidgetsBinding.instance!.addPostFrameCallback(_initWidget);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    
    if (!_isInit) {
      _isInit = true;
      _sock = context.read<SocketConn>();
      _sock.setMsgWithoutNotified('Buscando Conexiones');
    }

    return Scaffold(body: _body());
  }

  ///
  Widget _body() {

    return Column(children: [
      WindowTitleBarBox(
          child: Row(children: [
        Expanded(child: MoveWindow()),
        const WindowButtons()
      ])),
      Expanded(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          const Expanded(child: SizedBox()),
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
                  ValueListenableBuilder<Map<String, dynamic>>(
                      valueListenable: _users,
                      builder: (_, users, __) {
                        if (users.isNotEmpty && items.length == 1) {
                          items.clear();
                          users.forEach((key, val) => items.add(val['nombre']));
                          items.add('Usar Otro Usuario');
                          _curc.text = users.values.first['curc'];
                          _defaultUser = users.values.first['nombre'];
                        }

                        return DecorationField.dropBy(
                          items: items,
                          fco: _fcurc,
                          help: 'Selecciona quien éres',
                          iconoPre: Icons.account_circle_rounded,
                          onChange: (val) {
                            if (val != null) {
                              if (val.contains('Otro')) {
                                _curc.text = '';
                                setState(() {
                                  _otroUser = true;
                                });
                              } else {
                                final us = _users.value.values.where((element) {
                                  return element['nombre'] == val;
                                }).toList();
                                if (us.isNotEmpty) {
                                  _curc.text = us.first['curc'];
                                }
                                if (_otroUser) {
                                  setState(() {
                                    _otroUser = false;
                                  });
                                }
                              }
                            }
                          },
                          orden: 1,
                          defaultValue: _defaultUser,
                        );
                      }),
                  const SizedBox(height: 20),
                  if (_otroUser) ...[
                    DecorationField.fieldBy(
                        ctr: _curc,
                        fco: _fcurc,
                        help: 'Ingresa tu CURC',
                        iconoPre: Icons.account_circle_rounded,
                        orden: 2,
                        isPass: false,
                        showPass: true,
                        onPressed: (val) {},
                        validate: (String? val) {
                          if (val != null) {
                            if (val.length >= 3) {
                              return null;
                            }
                          }
                          return 'Este campo es Requerido';
                        }),
                    const SizedBox(height: 20),
                  ],
                  DecorationField.fieldBy(
                      ctr: _pass,
                      fco: _fpass,
                      help: 'Ingresa tu Contraseña',
                      iconoPre: Icons.security,
                      orden: 3,
                      isPass: true,
                      showPass: _showPass,
                      onPressed: (val) => setState(() {
                            _showPass = val;
                          }),
                      validate: (String? val) {
                        if (val != null) {
                          if (val.length >= 3) {
                            return null;
                          }
                        }
                        return 'Este campo es Requerido';
                      }),
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
                child: const Texto(
                    txt: 'AUTENTICARME', txtC: Colors.black, isBold: true)),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Texto(txt: 'HARBI: ${globals.ipHarbi}'),
                ),
              ),
              if (globals.ipHarbi.isEmpty)
                IconButton(
                    onPressed: () async {
                      bool hasIp = await _sock.getIpConnectionToHarbi();
                      if (hasIp) {
                        _sock.msgErr = 'Identifícate por favor';
                      }
                    },
                    iconSize: 18,
                    color: Colors.white,
                    icon: const Icon(Icons.refresh))
            ],
          )
        ],
      )),
    ]);
  }

  ///
  Future<void> _initWidget(_) async {

    await _sock.getNameRed();
    String uri = await GetPaths.getFileByPath('connpass');
    File filepass = File(uri);
    if (filepass.existsSync()) {
      _users.value = Map<String, dynamic>.from(json.decode(filepass.readAsStringSync()));
    }
  }

  ///
  Future<void> _autenticar() async {

    if (_frmKey.currentState!.validate()) {
      
      _sock.isLoged = false;
      _sock.msgErr = 'Recuperando datos de Conexión';
      bool hasIp = await _sock.getIpConnectionToHarbi(
        pass: _pass.text.toLowerCase().trim(),
        ipNew: (_intentosConn > 1) ? globals.myIp : '0'
      );
      if (hasIp) {
        _sock.msgErr = 'Identifícate por favor';
      }

      bool isConnected = await _sock.ping();

      if (!isConnected) {
        if (globals.ipHarbi.isEmpty) {
          _sock.msgErr = 'Desconocida la IP de HARBI';
        } else {
          if(_intentosConn == 1) {
            _intentosConn = 2;
            _sock.msgErr = 'Probando con mi IP';
            _autenticar();
          }else{
            _sock.msgErr = 'No hay conexión con HARBI';
          }
        }
      } else {
        await validarCredenciales();
      }
    }
  }

  ///
  Future<void> validarCredenciales() async {

    _sock.msgErr = 'Validando Credenciales';

    final data = {
      'username': _curc.text.toLowerCase().trim(),
      'password': _pass.text.toLowerCase().trim()
    };
    if (_otroUser) {
      data['only_check'] = '1';
    }
    bool abort = await _sock.awaitResponseSocket(
      event: RequestEvent(
        event: 'connection', fnc: 'exite_user_local', data: data
      ),
      msgInit: 'Haciendo login en local',
      msgExito: 'Login Autorizado'
    );

    if (!_sock.msgErr.contains('Error')) {
      if (abort) {
        await _hacerLoginFromServer(data);
      } else {
        _sock.isLoged = true;
        globals.password = data['password']!;
        globals.curc = data['username']!;
      }
    } else {
      if (_sock.msgErr.contains('Inexistente')) {
        await _hacerLoginFromServer(data);
      }
    }
  }

  ///
  Future<void> _hacerLoginFromServer(Map<String, dynamic> data) async {

    globals.tkServ = '';
    bool abort = await _sock.awaitResponseSocket(
      event: RequestEvent(
        event: 'connection', fnc: 'make_login_server', data: data
      ),
      msgInit: 'Buscando Credenciales',
      msgExito: 'Login Autorizado');

    if (abort) {
      _sock.msgErr = 'Credenciales Invalidas';
    } else {
      _sock.isLoged = true;
      globals.password = data['password']!;
      globals.curc = data['username']!;
    }
  }
}
