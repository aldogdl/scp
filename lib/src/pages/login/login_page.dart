import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:provider/provider.dart';

import '../content/config_sections/widgets/decoration_field.dart';
import '../splash/splash_page.dart';
import '../widgets/texto.dart';
import '../widgets/windows_buttons.dart';
import '../../config/sng_manager.dart';
import '../../services/get_paths.dart';
import '../../services/get_content_files.dart';
import '../../providers/pages_provider.dart';
import '../../providers/socket_conn.dart';
import '../../vars/globals.dart';

class LoginPage extends StatefulWidget {

  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final globals = getSngOf<Globals>();

  final _frmKey = GlobalKey<FormState>();
  final _curc = TextEditingController();
  final _pass = TextEditingController();
  final _fcurc = FocusNode();
  final _fpass = FocusNode();

  late final SocketConn _sock;
  bool _showPass = true;
  bool _otroUser = false;
  bool _isInit = false;
  bool _absorbing = false;
  String _defaultUser = 'Cargando';
  List<String> items = ['Cargando'];
  final _users = ValueNotifier<List<Map<String, dynamic>>>([]);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_initWidget);
  }

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
  Widget build(BuildContext context) {
    
    if (!_isInit) {
      _isInit = true;
      _sock = context.read<SocketConn>();
      _sock.setMsgWithoutNotified('Identificate por favor.');
    }

    return Scaffold(
      body: Column(
        children: [
          WindowTitleBarBox(
            child: Row(
              children: [
                Expanded(child: MoveWindow()),
                const WindowButtons()
              ]
            )
          ),
          Expanded(
            child: Selector<PageProvider, bool>(
              selector: (_, prov) => prov.isSplash,
              builder: (_, val, __) {

                if(val) { return const SplasPage(); }
                return _body();
              }
            )
          ),
        ]
      )
    );
  }

  ///
  Widget _body() {

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
        const Expanded(child: SizedBox()),
        const Texto(
          txt: 'Sistema de Cotización y Procesamiento',
          txtC: Color.fromARGB(255, 218, 218, 218),
          sz: 22,
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.25,
          child: const Image(
            image: AssetImage('assets/logo_1024.png'),
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 5),
        Texto(
          txt: context.watch<SocketConn>().msgErr,
          txtC: (context.watch<SocketConn>().msgErr.startsWith('[X]'))
            ? Colors.orange : Colors.blue
        ),
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
            child: _frm(),
          ),
        ),
        Container(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width * 0.1,
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          width: MediaQuery.of(context).size.width * 0.25,
          height: 35,
          child: AbsorbPointer(
            absorbing: _absorbing,
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.green),
              ),
              onPressed: () => _autenticar(),
              child: const Texto(
                txt: 'AUTENTICARME', txtC: Colors.black, isBold: true
              )
            ),
          )
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
          ],
        )
      ],
    );
  }

  ///
  Widget _frm() {

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: _users,
          builder: (_, users, __) {
            if(items.first == 'Cargando') {
              return _txtUser();
            }
            return _dropUsers();
          }
        ),
        const SizedBox(height: 20),
        if (_otroUser)
          ...[
            _txtUser(),
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
          }
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  ///
  Widget _txtUser() {

    return DecorationField.fieldBy(
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
      }
    );
  }

  ///
  Widget _dropUsers() {

    return DecorationField.dropBy(
      items: items,
      fco: _fcurc,
      help: 'Selecciona quien éres',
      iconoPre: Icons.account_circle_rounded,
      onChange: (val) {

        if (val != null) {
          if (val.contains('Otro')) {
            _curc.text = '';
            setState(() { _otroUser = true; });
          } else {

            final us = _users.value.firstWhere((u) => u['nombre'] == val);
            if (us.isNotEmpty) { _curc.text = us['curc']; }
            if (_otroUser) {
              setState(() { _otroUser = false; });
            }
          }
        }
      },
      orden: 1,
      defaultValue: _defaultUser,
    );
  }
  
  ///
  Future<void> _initWidget(_) async {

    await _sock.getNameRed();
    String uri = await GetPaths.getFileByPath('connpass');
    if(uri.isEmpty){ return; }
    
    File filepass = File(uri);
    if (filepass.existsSync()) {
      final data = filepass.readAsStringSync();
      if(data.isNotEmpty) {
        final cont = List<Map<String, dynamic>>.from(json.decode(data));
        if(cont.isNotEmpty) {
          if (items.length == 1) {
            items.clear();
            cont.map((u) => items.add(u['nombre'])).toList();
            items.add('Usar Otro Usuario');
            _defaultUser = cont.first['nombre'];
            _curc.text = cont.first['curc'];
          }
          _users.value = cont;
        }
      }
    }else{
      filepass.createSync();
    }
  }

  ///
  Future<void> _autenticar() async {

    if (_frmKey.currentState!.validate()) {

      setState(() { _absorbing = true; });
      await Future.delayed(const Duration(milliseconds: 300));

      _sock.isLoged = false;
      _sock.msgErr = 'Validando Credenciales';
      final data = {
        'username': _curc.text.toLowerCase().trim(),
        'password': _pass.text.toLowerCase().trim()
      };

      bool isValid = await _sock.hacerLoginFromServer(data);
      if (!isValid) {
        _sock.msgErr = '[X] Credenciales Invalidas.';
        setState(() { _absorbing = false; });
        return;
      }

      if(isValid) {
        // Tenemos que registrar al usuario guardandolo en el archivo de connpass
        await GetContentFile.saveUserValid();
        // Tenemos que conectarnos a HARBi y guardar el idConn.
        await _sock.makeFirstConnection();
        _sock.isLoged = true;
        _sock.isQueryAn = 'Analizando...';
      }
      setState(() { _absorbing = false; });
    }
  }

}
