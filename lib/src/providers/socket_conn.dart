import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:scp/src/config/sng_manager.dart';
import 'package:scp/src/services/get_paths.dart';
import 'package:scp/src/vars/globals.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import 'dart:convert';
import 'package:network_info_plus/network_info_plus.dart';

import '../config/sng_manager.dart';
import '../entity/request_event.dart';
import '../services/my_http.dart';
import '../vars/globals.dart';

class SocketConn extends ChangeNotifier {

  final Globals globals = getSngOf<Globals>();

  final info = NetworkInfo();
  final String _app = 'SCP';

  String pin = '';
  String? myIp;
  String? ipHarbi;
  String? wifiName;
  String password = '';

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
    ipHarbi = null;
    globals.ipHarbi = '';
    password = '';
    username = 'Anónimo';
    msgErr = 'Coloca tu Contraseña';
    idConn = 0;
    close();
  }

  ///
  void close() {
    if(_socket != null) {
      _socket!.sink.close(status.normalClosure);
    }
    msgErr = 'HARBI sin conección';
    pin = '';
    isConnectedSocked = false;
    _socket == null;
  }

  ///
  Future<void> getNameRed() async {

    if(myIp == null) {
      wifiName ??= await info.getWifiName();
      myIp ??= await info.getWifiIP();
      wifiName ??= 'Oculta';
      globals.myIp = myIp;
      globals.wifiName = wifiName;
      notifyListeners();
    }
  }

  ///
  void ping() {

    RequestEvent event = RequestEvent(event: 'ping', fnc: 'make');
    send(event);
  }

  ///
  void send(RequestEvent event) async {

    if(event.event == 'initConnection' && !isConnectedSocked) {
      if(event.data.containsKey('password')) {
        if(event.data['password'].isEmpty) {
          msgErr = 'Necesitas Password';
          return;
        }else{
          password = event.data['password'];
        }
      }
      _socket = null;
    }

    if(event.event == 'initConnection' && isConnectedSocked) {
      close();
      return;
    }

    msgErr = 'Conectando...';
    pin = '';
    if(_socket == null) {
      await _conectar();
    }else{
      if(_socket!.innerWebSocket != null) {
        if(_socket!.innerWebSocket!.readyState == 3) {
          await _conectar();
        }
      }
    }

    if(event.event != 'initConnection') {
      
      var data = Map<String, dynamic>.from(event.data);
      data['id']  = idConn;
      data['app'] = _app;
      data['user']= username;
      data['password']= password;
      event.data = data;
      try {
        _socket!.sink.add( event.toSend() );
      } catch (e) {
        cerrarConection();
        msgErr = 'HARBI DESCONECTADO';
        return;
      }
    }

    // Esperamos hasta dos segundos si el pin es bacio, estamos desconectados
    await Future.delayed(const Duration(seconds: 2));
    if(pin.isEmpty) {
      isConnectedSocked = false;
    }
  }

  ///
  Future<void> _conectar() async {

    msgErr = 'Contactando a HARBI';

    if(ipHarbi != null) {
      if(_socket == null) {
        try {
          _socket = IOWebSocketChannel.connect(Uri.parse('ws://$ipHarbi:${globals.portHarbi}/socket'));
        } catch (e) {
          return;
        }

        _socket!.stream.listen((event) {
          pin = 'ok';
          msgErr = '';
          isConnectedSocked = true;
          _determinarEvento(Map<String, dynamic>.from(json.decode(event)));
        });
      }
    }else{
      msgErr = 'HARBI no está Funcionando';
      await getIpConnectionToHarbi();
    }
  }

  ///
  Future<void> _determinarEvento(Map<String, dynamic> response) async {

    if(response.containsKey('connId')) {
      idConn = response['connId'];
      msgErr = 'HARBI';

      final e = RequestEvent(
        event: 'initConnection', fnc: 'conectar',
        data: {
          'ip'  : myIp,
          'id'  : idConn,
          'app' : _app,
          'user': username,
          'password':password,
          'token': globals.tkServ
        }
      );
      _socket!.sink.add( e.toSend() );
      isLoged = true;
      return;
    }

    if(response.containsKey('event')) {
      if(response['event'] == 'ping') {
        _msgErr = (response['fnc'] == 'ok') ? 'ping-ok' : 'ping-er';
        return;
      }
      msgErr = 'HARBI';
      await _determinarFunction(response['fnc'], Map<String, dynamic>.from(response['data']));
      return;
    }

    cerrarConection();
  }

  ///
  Future<void> _determinarFunction(String fnc, Map<String, dynamic> params) async {

    switch (fnc) {
      case 'set_data_connx':
        if(params.containsKey('name')) {
          username = params['name'];
        }else{
          cerrarConection();
          _msgErr = 'No Autorizado';
        }
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
  Future<bool> getIpConnectionToHarbi() async {

    String domi = await GetPaths.getDominio(isLocal: false);
    const uri = 'centinela/get-ip-address-harbi/';

    await MyHttp.get('$domi$uri');
    if(!MyHttp.result['abort']) {
      final data = utf8.decode( base64Decode( MyHttp.result['body'] ) );
      if(data.isNotEmpty) {
        if(data.contains(':')) {
          final partes = data.split(':');
          ipHarbi = partes.first;
          globals.ipHarbi = partes.first;
          globals.portHarbi = partes.last;
        }
      }
      return (ipHarbi!.contains('.')) ? true : false;
    }
    return false;
  }


}