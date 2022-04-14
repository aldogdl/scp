import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:network_info_plus/network_info_plus.dart';

import '../config/sng_manager.dart';
import '../services/get_paths.dart';
import '../vars/globals.dart';
import '../entity/request_event.dart';

class SocketConn extends ChangeNotifier {

  final Globals globals = getSngOf<Globals>();

  final info = NetworkInfo();
  final String _app = 'SCP';

  String pin = '';
  bool _isPing = false;
  IOWebSocketChannel? _socket;
  IOWebSocketChannel get socket => _socket!;

  bool _isLocalConn = true;
  bool get isLocalConn => _isLocalConn;
  set isLocalConn(bool conn) {
    _isLocalConn = conn;
    globals.isLocalConn = _isLocalConn;
    notifyListeners();
  }

  bool _isLoged = false;
  bool get isLoged => _isLoged;
  set isLoged(bool logined) {
    _isLoged = logined;
    notifyListeners();
  }

  bool _isConectedSocked = false;
  bool get isConnectedSocked => _isConectedSocked;
  set isConnectedSocked(bool connected) {
    _isConectedSocked = connected;
    notifyListeners();
  }

  String _username = 'Anónimo';
  String get username => _username;
  set username(String connected) {
    _username = connected;
    notifyListeners();
  }

  ///
  String _msgErr = '';
  String get msgErr => _msgErr;
  void setMsgWithoutNotified(String msg) {
    _msgErr = msg;
  }
  set msgErr(String connected) {
    _msgErr = connected;
    notifyListeners();
  }

  ///
  int _idConn = 0;
  int get idConn => _idConn;
  set idConn(int conn) {
    _idConn = conn;
    notifyListeners();
  }

  ///
  void cerrarConection() {

    isConnectedSocked = false;
    globals.ipHarbi = '';
    globals.password = '';
    username = 'Anónimo';
    idConn = 0;
    close();
  }

  ///
  void close() {
    if(_socket != null) {
      _socket!.sink.close(status.normalClosure);
    }
    isConnectedSocked = false;
    _socket == null;
  }

  ///
  Future<void> getNameRed() async {

    if(globals.myIp.isEmpty) {
      globals.wifiName = await info.getWifiName() ?? '';
      globals.myIp = await info.getWifiIP() ?? '';
      globals.wifiName = 'Oculta';
      notifyListeners();
    }
  }

  ///
  Future<bool> ping() async {

    _isPing = true;
    int intentos = 1;
    bool abort = false;
    bool isCon = checkConeccion();

    if(!isCon) {
      if(globals.ipHarbi.isEmpty) {
        await getIpConnectionToHarbi();
      }
      _socket = null;
      pin = '';
      
      await Future.doWhile(() async {
        
        await _conectar();
        await Future.delayed(const Duration(milliseconds: 1000));
        if(pin == 'ok') {
          return false;
        }
        if(intentos >= 5) {
          abort = true;
          msgErr = 'No se alcanzó una conección con HARBI';
          return false;
        }
        intentos++;
        return true;
      });
    }
    
    abort = false;
    intentos = 1;
    final event = RequestEvent(event: 'ping', fnc: 'make', data: {});
    await Future.doWhile(() async {
      send(event);
      await Future.delayed(const Duration(milliseconds: 1000));
      if(msgErr.startsWith('ping')) {
        if(msgErr == 'ping-ok') {
          return false;
        }else{
          abort = true;
          return false;
        }
      }
      
      if(intentos >= 3){
        abort = true;
        return false;
      }
      intentos++;
      return true;
    });

    _isPing = false;
    return !abort;
  }

  /// Retorna true si la las variables de coneccion estan correctas.
  bool checkConeccion() {

    bool isCon = isConnectedSocked;
    
    if(_socket == null) {
      isCon = false;
    }else{
      if(_socket!.innerWebSocket != null) {
        if(_socket!.innerWebSocket!.readyState == 3) {
          isCon = false;
        }
      }else{
        isCon = false;
      }
    }
    return isCon;
  }

  ///
  void xRevisarConectarAHarbi(RequestEvent event) {

    if(event.event == 'initConnection' && !isConnectedSocked) {
      if(event.data.containsKey('password')) {
        if(event.data['password'].isEmpty) {
          msgErr = 'Necesitas Password';
          return;
        }else{
          globals.password = event.data['password'];
          if(event.data.containsKey('username')) {
            globals.curc = event.data['username'];
          }
        }
      }
      _socket = null;
    }

    if(event.event == 'initConnection' && isConnectedSocked) {
      close();
      return;
    }
  }

  ///
  void send(RequestEvent event) async {

    event = await _fillMetaData(event);
    try {
      _socket!.sink.add( event.toSend() );
    } catch (e) {
      msgErr = 'Se desconecto HARBI';
      return;
    }
  }

  ///
  Future<RequestEvent> _fillMetaData(RequestEvent event) async {

    var data = Map<String, dynamic>.from(event.data);
    data['id']  = idConn;
    data['app'] = _app;
    data['user']= username;
    data['ip']  = globals.myIp;

    if(data.containsKey('username')) {
      if(data['username'].isEmpty) {
        data['username']= globals.curc;
      }
    }else{
      data['username']= globals.curc;
    }

    if(data.containsKey('password')) {
      if(data['password'].isEmpty) {
        data['password']= globals.curc;
      }
    }else{
      data['password']= globals.password;
    }
    event.data = data;
    return event;
  }

  ///
  Future<bool> awaitResponseSocket({
    required RequestEvent event,
    required String msgInit,
    required String msgExito
  }) async {

    bool abort = true;
    int intentos = 1;
    msgErr = msgInit;
    send(event);
    await Future.doWhile(() async {
      if(msgErr == msgExito){ abort = false; return false; }
      if(msgErr.contains('Error')){ return false; }
      await Future.delayed(const Duration(milliseconds: 1000));
      if(intentos >= 5){ return false; }
      intentos++;
      return true;
    });

    return abort;
  }

  ///
  Future<void> _conectar() async {

    msgErr = 'Contactando a HARBI';
    await Future.delayed(const Duration(milliseconds: 1000));
    try {
      _socket = IOWebSocketChannel.connect(Uri.parse('ws://${globals.ipHarbi}:${globals.portHarbi}/socket'));
    } catch (e) {
      msgErr = 'Error al Intentar conectar a HARBI';
      return;
    }

    msgErr = 'Esperando Respuesta de Conección';
    await Future.delayed(const Duration(milliseconds: 1000));
    _socket!.stream.listen((event) {
      pin = 'ok';
      isConnectedSocked = true;
      _determinarEvento(Map<String, dynamic>.from(json.decode(event)));
    });
  }

  ///
  Future<void> _determinarEvento(Map<String, dynamic> response) async {

    if(response.containsKey('connId')) {
      idConn = response['connId'];
      return;
    }

    if(response.containsKey('event')) {
      if(response['event'] == 'ping') {
        _msgErr = (response['fnc'] == 'ok') ? 'ping-ok' : 'ping-er';
        return;
      }
      await _determinarFunction(response['fnc'], Map<String, dynamic>.from(response['data']));
      return;
    }

    cerrarConection();
  }

  ///
  Future<void> _determinarFunction(String fnc, Map<String, dynamic> params) async {

    switch (fnc) {
      case 'set_data_connx':
        _registrarVariablesDeUsuario(params);
        _msgErr = (params.containsKey('err')) ? params['err'] : 'No Autorizado';
        break;
      case 'make_login':
        _registrarVariablesDeUsuario(params);
        msgErr = (params.containsKey('err')) ? params['err'] : 'Login Autorizado';
        break;
      case 'update_colaborador':
        msgErr = params['msg'];
        break;
      case 'set_orden':
        print(params);
        break;
      case 'get_data_ctz':
        
        break;
      case 'new_contact':
        msgErr = (params.containsKey('err')) ? 'new_contact-er' : 'new_contact-ok';
        break;
      default:
        _msgErr = 'Sin Acción';
    }
  }

  ///
  void _registrarVariablesDeUsuario(Map<String, dynamic> params) {

    if(params.containsKey('nombre')) {
      username = params['nombre'];
      globals.curc  = params['curc'];
      globals.idUser= params['id'];
      globals.roles = List<String>.from(params['roles']);
    }
  }

  ///
  Future<bool> getIpConnectionToHarbi() async {

    String pathCon = await GetPaths.getFileByPath('harbi_connx');
    final file = File(pathCon);
    if(file.existsSync()) {
      final contenido = Map<String, dynamic>.from(json.decode( file.readAsStringSync() ));
      if(contenido.isNotEmpty) {
        globals.ipHarbi = contenido['ipHarbi'];
        globals.portHarbi = '${contenido['ptoHarbi']}';
      }
    }
    return (globals.ipHarbi.contains('.')) ? true : false;
  }


}