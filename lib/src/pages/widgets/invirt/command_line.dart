import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'show_help_cmd.dart';
import '../../widgets/texto.dart';
import '../../../entity/orden_entity.dart';
import '../../../repository/socket_centinela.dart';
import '../../../services/inventario_service.dart';
import '../../../providers/socket_conn.dart';
import '../../../providers/invirt_provider.dart';

class CommandLine extends StatefulWidget {

  const CommandLine({Key? key}) : super(key: key);

  @override
  State<CommandLine> createState() => _CommandLineState();
}

class _CommandLineState extends State<CommandLine> {

  final _helpTxt = ValueNotifier<String>('');
  final _frmKey = GlobalKey<FormState>();
  final _ctrCmd = TextEditingController();
  final _focCmd = FocusNode();
  static const String _helpTxtConst = 'Ingresa un comando';

  late final InvirtProvider _invProv;
  bool _isInit = false;
  bool _isShowHelp = false;
  bool _isTestHttp = false;
  bool _isLoadingHttp = false;

  @override
  void initState() {

    _helpTxt.value = _helpTxtConst;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _focCmd.requestFocus();
    });
    super.initState();
  }

  @override
  void dispose() {
    _ctrCmd.dispose();
    _focCmd.dispose();
    _helpTxt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if(!_isInit) {
      _isInit = true;
      _invProv = context.read<InvirtProvider>();
    }

    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.12,
      padding: const EdgeInsets.only(
        left: 10, right: 10, top: 15, bottom: 3
      ),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 17, 17, 17)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _cmd(),
          _lstComandos()
        ],
      ),
    );
  }

  ///
  Widget _lstComandos() {

    return Selector<InvirtProvider, List<String>>(
      selector: (_, prov) => prov.queSelected,
      builder: (_, qs, __) {

        if(qs.isNotEmpty) {
          if(qs.first == 'cc') {
            Future.delayed(const Duration(milliseconds: 250), () {
              _helpTxt.value = _helpTxtConst;
              _invProv.showBtnCC = false;
            });
          }else{
            List<String> results = [];
            qs.map((e) => results.add(e) ).toList();
            if(results.isNotEmpty) {
              Future.delayed(const Duration(milliseconds: 250), () {
                _helpTxt.value = results.join('  ');
                _invProv.showBtnCC = true;
              });
            }
          }
        }else{
          Future.delayed(const Duration(milliseconds: 250), () {
            _helpTxt.value = _helpTxtConst;
            _invProv.showBtnCC = false;
          });
        }

        return const SizedBox();
      },
    );
  }

  ///
  Widget _cmd() {
    
    return Form(
      key: _frmKey,
      child: ValueListenableBuilder<String>(
        valueListenable: _helpTxt,
        builder: (_, txt, child) {

          if(txt.isNotEmpty) { return _formField(txt); }
          return child!;
        },
        child: _formField(null),
      ),
    );
  }

  ///
  Widget _formField(String? txtHelp) {

    return TextFormField(
      controller: _ctrCmd,
      focusNode: _focCmd,
      autocorrect: true,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      autofocus: true,
      onChanged: (val) => (val.isEmpty) ? _frmKey.currentState!.reset() : {},
      onFieldSubmitted: (val) => _sendCommand(),
      validator: (value) {
        if(value != null) {
          if(!value.contains('.')) {
            if(InventarioService.cmds.containsKey(value)) {
              return null;
            }
            return 'El Comando no es valido';
          }
        }
        return null;
      },
      decoration: InputDecoration(
        border: _stylBor(),
        enabledBorder: _stylBor(),
        focusedBorder: _stylBor(c: const Color.fromARGB(255, 116, 116, 116)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        prefixIcon: _changePrefixIconCmd(),
        helperText: txtHelp,
        helperStyle: _getStyleHelp(),
        suffix: Selector<InvirtProvider, String>(
          selector: (_, prov) => prov.cantOrdBanEnt,
          builder: (_, val, __) {
            return Texto(txt: val);
          },
        ),
        // suffixIcon: const Icon(Icons.code, color: Color.fromARGB(255, 119, 67, 241), size: 18)
      ),
    );
  }
  
  ///
  TextStyle _getStyleHelp() {

    Color color = Colors.grey;
    if(_helpTxt.value.contains(' > ')) {
      color = Colors.yellow;
    }

    if(_helpTxt.value.contains('valido')) {
      color = Colors.orange;
    }
    
    return TextStyle(
      fontSize: 13,
      color: color,
    );
  }

  ///
  Widget _changePrefixIconCmd() {

    return Selector<InvirtProvider, bool>(
      selector: (_, prov) => prov.showBtnCC,
      builder: (_, val, __) {

        if(_isTestHttp) {
          if(_isLoadingHttp) {
            return const Padding(
              padding: EdgeInsets.all(10),
              child: SizedBox(
                width: 10, height: 10,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)
              ),
            );
          }
        }

        if(val) {
          return IconButton(
            onPressed: () => _invProv.cmd = {'cmd':'cc'},
            icon: const Icon(Icons.cleaning_services_rounded, size: 18, color: Colors.purple),
          );
        }
        return const Icon(Icons.terminal, size: 18, color: Color.fromARGB(255, 201, 201, 201));
      },
    );
  }

  ///
  OutlineInputBorder _stylBor({Color c = const Color.fromARGB(255, 63, 63, 63)}) {

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide( color: c, width: 0.7)
    );
  }

  ///
  void _sendCommand() async {

    if(_frmKey.currentState!.validate()) {

      String cmd = _ctrCmd.text.trim().toLowerCase();
      if(cmd.isEmpty){ return; }

      bool isOther = await _isOtherCommands(cmd);
      if(isOther){ return; }
      
      _invProv.cmd = {'cmd': cmd};
      _cleanTxtForm();
      return;
    }
  }

  ///
  Future<bool> _isOtherCommands(String cmd) async {

    if(cmd.startsWith('http')) {
      await _sendPushTestToHarbi(cmd.replaceFirst('http.', ''));
      return true;
    }

    if(cmd == 'h') {
      _cleanTxtForm();
      _showDialogBy(const ShowHelpCmd());
      return true;
    }

    if(cmd == 'cc-q') {
      _invProv.querys.clear();
      context.read<SocketConn>().query = 'cc';
      _cleanTxtForm();
      return true;
    }

    return false;
  }

  ///
  void _cleanTxtForm() {
    _ctrCmd.text = '';
    _focCmd.requestFocus();
    _frmKey.currentState!.reset();
  }

  ///
  void _showDialogBy(Widget child) async {

    if(!_isShowHelp) {

      _isShowHelp = true;
      int? acc = await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color.fromARGB(255, 30, 30, 30),
          contentPadding: const EdgeInsets.all(10),
          content: child,
        )
      );

      if(acc == null) {
        _isShowHelp = false;
      }
    }
  }

  ///
  Future<void> _sendPushTestToHarbi(String cmd) async {

    // Que eventos se requiren.
    // 1.- [METRIX][SCM] Necesito saber cuando se esta enviando, en cola o enviado.
    // 2.- [METRIX][HARBI-bin] Cuando alguien ya vio el mensaje y descargo los datos
    // 3.- [METRIX][HARBI] Si un cotizador indica que no la tiene
    // 4.- [RESP][HARBI-bin] Si un cotizador envia una cotizacion
    // 5.- [SELF] Calcular criterios un determinado tiempo.
    //     El cronometro inicia en el moneto que se recibe la primer respuesta.
    // {pzas: 1, scmEst: 1, scmStt: 1, see: 0, rsp: 0, cnt: 0, cotz: 0, cronInit: 0, idOrden: 3}
    // --> para las metricas
    // final query = 'query=scm,idMsg=$idMsg,secc=${OrdCamp.metrik.name},campo=cnt,valor=$cmd,orden=1,avo=2';

    // --> para las respuestas
    if(_isLoadingHttp){ return; }

    setState(() {
      _isLoadingHttp = true;
      _isTestHttp = true;
    });

    final sock = SocketCentinela();
    await Future.delayed(const Duration(milliseconds: 250));

    final idMsg = DateTime.now().millisecondsSinceEpoch.toString();
    final query = 'query=scm,idMsg=$idMsg,secc=${OrdCamp.metrik.name},cotz=0,est=1,orden=1,avo=2';

    String event = 'event%self-fnc%notifAll_UpdateData-data%$query';
    await sock.sendPushToHarbi('push', event);

    setState(() {
      _isLoadingHttp = false;
      _isTestHttp = false;
    });
  }

}