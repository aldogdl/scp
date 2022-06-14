import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:scp/src/pages/widgets/texto.dart';
import 'package:scp/src/services/my_http.dart';

import '../../config/sng_manager.dart';
import '../../vars/globals.dart';
import '../content/config_sections/widgets/decoration_field.dart';

class ChangeIpDialog extends StatefulWidget {

  final String ipCurrent;
  final String msgHelp;
  final ValueChanged<String> onSave;
  const ChangeIpDialog({
    Key? key,
    required this.ipCurrent,
    required this.msgHelp,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ChangeIpDialog> createState() => _ChangeIpDialogState();
}

class _ChangeIpDialogState extends State<ChangeIpDialog> {

  final Globals _globals = getSngOf<Globals>();
  final _ctlIp = TextEditingController();

  String _msg = '...';
  bool _abosorbing = false;

  @override
  void initState() {

    late Uri uri;
    if(_globals.isLocalConn) {
      uri = Uri.parse(_globals.ipDbs['base_l']);
    }else{
      uri = Uri.parse(_globals.ipDbs['base_r']);
    }
    _msg = 'Alternativa: ${uri.host}';
    _ctlIp.text = widget.ipCurrent;
    super.initState();
  }

  @override
  void dispose() {
    _ctlIp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        DecorationField.fieldBy(
          ctr: _ctlIp,
          fco: FocusNode(),
          help: widget.msgHelp,
          iconoPre: Icons.account_circle_rounded,
          orden: 1,
          validate: (val) {},
          isPass: false,
          onPressed: (val){},
          showPass: true
        ),
        const SizedBox(height: 10),
        AbsorbPointer(
          absorbing: _abosorbing,
          child: ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.purple)
            ),
            onPressed: () async => await _probarConectividad(),
            child: const Texto(txt: 'CAMBIAR', isBold: true, isCenter: true, txtC: Colors.white)
          ),
        ),
        const SizedBox(height: 10),
        Container(
          color: const Color.fromARGB(255, 31, 31, 31),
          constraints: const BoxConstraints.expand(
            height: 35
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if(_abosorbing)
                  ...[
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()),
                    const SizedBox(width: 10),
                  ],
                Texto(txt: _msg, isBold: true, isCenter: true, sz: 13, txtC: Colors.amber)
              ],
            ),
          ),
        )
      ],
    );
  }

  ///
  Future<void> _probarConectividad() async {

    bool resultado = false;
    late Uri uri;
    if(_globals.isLocalConn) {
      uri = Uri.parse(_globals.ipDbs['base_l']);
    }else{
      uri = Uri.parse(_globals.ipDbs['base_r']);
    }
    uri = uri.replace(host: _ctlIp.text);
    String uriPath = 'home-controller/get-data-connection/${_globals.user.password}/';
    _msg = 'Probando Conectividad';
    _abosorbing = true;
    setState(() {});
    
    final nav = Navigator.of(context);
    await MyHttp.get('${uri.toString()}$uriPath');
    
    if(MyHttp.result['body'].contains('ERROR') || MyHttp.result['body'].contains('ok')) {
      if(!MyHttp.result['body'].contains('Host')) {
        resultado = true;
      }
    }else{
      String ipH = utf8.decode(base64Decode(MyHttp.result['body']));
      if(ipH.contains(':')) {
        resultado = true;
      }
    }
    if(resultado) {
      _msg = 'Satisfactorio';
      await Future.delayed(const Duration(milliseconds: 300));
      nav.pop(true);
      widget.onSave(_ctlIp.text);
    }else{
      _msg = 'Intenta con otra IP';
      _abosorbing = false;
      setState(() {});
    }
  }
}