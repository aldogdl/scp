import 'dart:convert';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:network_info_plus/network_info_plus.dart';

import '../config/sng_manager.dart';
import '../entity/contacto_entity.dart';
import '../entity/request_event.dart';
import '../repository/socket_centinela.dart';
import '../services/my_http.dart';
import '../services/get_paths.dart';
import '../services/get_content_files.dart';
import '../vars/globals.dart';

class SocketConn extends ChangeNotifier {

  final globals = getSngOf<Globals>();
  final _sockCenti = SocketCentinela();
  final info = NetworkInfo();
  final String _app = 'SCP';

  /// ------------ SECCION PARA EL INVENTARIO VIRTUAL --------------------
  
  SocketCentinela get centi => _sockCenti;
  
  ///
  String _isQueryAn = '';
  String get isQueryAn => _isQueryAn;
  set isQueryAn(String isAn) {
    _isQueryAn = isAn;
    notifyListeners();
  }
  String _query ='';
  String get query => _query;
  set query(String nlist) {
    _query = nlist;
    notifyListeners();
  }

  /// ------------ FIN DEL INVENTARIO VIRTUAL --------------------
  
  String verOldCentinela = '';

  String pin = '';
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

  ///
  String _msgCron = 'X';
  String get msgCron => _msgCron;
  void setMsgCronWithoutNotified(String msg) {
    _msgCron = msg;
  }

  set msgCron(String msg) {
    _msgCron = msg;
    notifyListeners();
  }

  ///
  int cantManifest = 0;
  int cantShows = 0;
  List<Map<String, dynamic>> _manifests = [];
  List<Map<String, dynamic>> get manifests => _manifests;
  set manifests(List<Map<String, dynamic>> msg) {
    _manifests = msg;
    notifyListeners();
  }
  void addManifest(Map<String, dynamic> msg) {
    var tmp = List<Map<String, dynamic>>.from(_manifests);
    _manifests = [];
    tmp.insert(0, msg);
    manifests = List<Map<String, dynamic>>.from(tmp);
    tmp = [];
  }

  /// Usado para notificar en el status bar un cambio de version del centinela
  int cantAlert = 0;
  bool _alertCV = false;
  bool get alertCV => _alertCV;
  set alertCV(bool show) {
    _alertCV = show;
    cantAlert++;
    notifyListeners();
  }

  ///
  String _msgErr = '';
  String get msgErr => _msgErr;
  void setMsgWithoutNotified(String msg) => _msgErr = msg;
  set msgErr(String msg) {
    _msgErr = msg;
    notifyListeners();
  }

  ///
  bool makeRegToHarbi = false;

  ///
  int _idConn = 0;
  int get idConn => _idConn;
  set idConn(int conn) {
    _idConn = conn;
    notifyListeners();
  }

  /// Utilizado para indicar una nueva ip para la base de datos o servidor local
  String _hasErrWithIpDbLocal = '';
  String get hasErrWithIpDbLocal => _hasErrWithIpDbLocal;
  set hasErrWithIpDbLocal(String clv) {
    _hasErrWithIpDbLocal = clv;
    notifyListeners();
  }

  ///
  void cerrarConection() {
    isConnectedSocked = false;
    globals.user = ContactoEntity();
    globals.user.nombre = 'Anónimo';
    idConn = 0;
    close();
  }

  ///
  void close() {
    if (_socket != null) {
      _socket!.sink.close(status.normalClosure);
    }
    isConnectedSocked = false;
    _socket == null;
  }

  ///
  Future<void> getNameRed() async {

    if (globals.myIp.isEmpty) {
      try {
        globals.wifiName = await info.getWifiName() ?? '';
        globals.myIp = await info.getWifiIP() ?? '';
      } catch (e) {
        globals.myIp = '';
        globals.wifiName = 'AutoparNet';
      }
      notifyListeners();
    }
  }

  /// Retorna true si la las variables de conexion estan correctas.
  bool checkConeccion() {

    bool isCon = isConnectedSocked;

    if (_socket == null) {
      isCon = false;
    } else {
      if (_socket!.innerWebSocket != null) {
        if (_socket!.innerWebSocket!.readyState == 3) {
          isCon = false;
        }
      } else {
        isCon = false;
      }
    }
    return isCon;
  }

  ///
  void send(RequestEvent event) async {

    event = await _fillMetaData(event);
    try {
      _socket!.sink.add(event.toSend());
    } catch (e) {
      msgErr = 'Se desconecto HARBI';
      return;
    }
  }

  ///
  Future<RequestEvent> _fillMetaData(RequestEvent event) async {

    var data = Map<String, dynamic>.from(event.data);
    data['id'] = idConn;
    data['app'] = _app;
    data['user'] = globals.user.nombre;
    data['ip'] = globals.myIp;

    if (data.containsKey('username')) {
      if (data['username'].isEmpty) {
        data['username'] = globals.user.curc;
      }
    } else {
      data['username'] = globals.user.curc;
    }

    if (data.containsKey('password')) {
      if (data['password'].isEmpty) {
        data['password'] = globals.user.curc;
      }
    } else {
      data['password'] = globals.user.password;
    }
    event.data = data;
    return event;
  }

  ///
  Future<bool> makeFirstConnection() async {

    const intentos = 3;
    const espera = 1000;
    int intents = 1;
    await _conectar();
    do {
      await Future.delayed(const Duration(milliseconds: espera));
      if(idConn == 0) {
        if(intents == intentos) {
          idConn = -1;
        }
        intents++;
      }
    } while (idConn == 0);
    if(idConn == -1) {
      idConn = 0;
    }
    return false;
  }

  ///
  Future<void> _conectar() async {

    msgErr = 'Contactando a HARBI';
    await Future.delayed(const Duration(milliseconds: 1000));
    try {
      _socket = IOWebSocketChannel.connect(
        Uri.parse('ws://${globals.ipHarbi}:${globals.portHarbi}/socket')
      );
    } catch (e) {
      msgErr = '[X] Error al Intentar conectar a HARBI';
      return;
    }

    msgErr = 'Esperando Respuesta de Conexión';
    await Future.delayed(const Duration(milliseconds: 1000));
    _socket!.stream.listen((event) {
      pin = 'ok';
      isConnectedSocked = true;
      _determinarEvento(Map<String, dynamic>.from(json.decode(event)));
    });
  }

  ///
  Future<void> _determinarEvento(Map<String, dynamic> response) async {

    if (response.containsKey('connId')) {
      idConn = response['connId'];
      return;
    }

    if (response.containsKey('event')) {

      if (response['event'] == 'ping') {
        if(response['fnc'] == 'returnIdConnection') {
          final event = RequestEvent(event: 'ping', fnc: 'returnIdConnection', data: {});
          send(event);
        }
        _msgErr = (response['fnc'] == 'ok') ? 'ping-ok' : 'ping-er';
        return;
      }

      if (response['event'] == 'from_centinela') {
        await _determinarFncCentinela(
          response['fnc'], Map<String, dynamic>.from(response['data'])
        );
        return;
      }

      await _determinarFunction(
        response['fnc'], Map<String, dynamic>.from(response['data'])
      );
      return;
    }

    cerrarConection();
  }

  ///
  Future<void> _determinarFunction(String fnc, Map<String, dynamic> params) async {

    switch (fnc) {
      case 'update_colaborador':
        msgErr = params['msg'];
        break;
      case 'get_data_ctz':
        break;
      case 'new_contact':
        msgErr = (params.containsKey('err')) ? 'new_contact-er' : 'new_contact-ok';
        break;
      default:
        _msgErr = 'Sin Función';
    }
  }

  ///
  Future<void> _determinarFncCentinela(String fnc, Map<String, dynamic> params) async {
    
    switch (fnc) {

      case 'update':
        if(params.containsKey('query')) {
          if(params.containsKey('avo')) {
            if(params['avo'] == '${globals.user.id}') {
              query = json.encode(params);
            }
          }
        }else{

          final manifest = await _sockCenti.buildManifest(globals.user);
          if(manifest.isNotEmpty) {
            cantManifest++;
            addManifest(manifest);
            params['vers'] = manifest['ver'];
          }
        }
        break;

      case 'cron':
        msgCron = '${params['time']} VC: ${params['vers']}';
        break;
        
      default:
        _msgErr = 'Sin Acción';
    }

    if(params.containsKey('vers')) {
      if(verOldCentinela.isEmpty) {
        verOldCentinela = '${params['vers']}';
        globals.currentVersion = verOldCentinela;
      }else{
        if(params['vers'] != verOldCentinela) {
          verOldCentinela = '${params['vers']}';
          globals.currentVersion = verOldCentinela;
          if(manifests.isNotEmpty) {
            alertCV = true;
          }
        }
      }
    }
    sendPing('ping');
  }

  /// Enviando ping a HARBI de Aqui estoy...
  void sendPing(String fnc) => send(RequestEvent(event: 'connection', fnc: fnc, data: {}));

  /// Recuperamos la Ip de Harbi, pero siempre tiene que ser desde el servidor
  /// remoto, ya que no sabemos desde que maquina se esta corriendo la SCP.
  Future<String> getIpToHarbiFromServer() async {

    String ipH = 'Comunicate con Sistemas';
    String url = 'https://autoparnet.com/home-controller/get-data-connection/123H/';    
    try {
      await MyHttp.get(url);
    } catch (e) {
      return 'ERROR, Revisa tu conexión a Internet';
    }

    final tipoR = MyHttp.result['body'].runtimeType;
    
    if(tipoR == String) {
      if(MyHttp.result['body'].contains('ERROR')) {
        return MyHttp.result['body'];
      }
    }

    if(MyHttp.result['msg'] == 'ok') {
      
      if(MyHttp.result['body'].isEmpty) {
        return 'ERROR, Reinicia HARBI y revisa la conexión a Internet.';
      }

      ipH = utf8.decode(base64Decode(MyHttp.result['body']));

      if(ipH.contains(':')) {
        final partes = List<String>.from(ipH.split(':'));
        globals.ipHarbi = partes.first;
        globals.portHarbi = partes.last;
        return 'Datos de conexión recuperados';
      }
    }

    return 'ERROR desconocido, $ipH';
  }

  ///
  Future<String> probandoConnWithHarbi() async {

    await MyHttp.get('http://${globals.ipHarbi}:${globals.portHarbi}/api_harbi/get_ipdb');

    if(!MyHttp.result['abort']) {
      
      final resp = MyHttp.result['body'];
      if(resp.runtimeType != String) {
        if(resp.containsKey('base_r')) {
          globals.ipDbs = Map<String, dynamic>.from(resp);
          MyHttp.clean();
          return 'Conexión via API exitosa';
        }
      }
    }
    return 'ERROR, No hay conexión con HARBI';
  }

  ///
  Future<String> hasFilePathProduction() async {

    await MyHttp.get('http://${globals.ipHarbi}:${globals.portHarbi}/api_harbi/get_path_prod');
    if(!MyHttp.result['abort']) {
      return await GetPaths.setPathsProduction(Map<String, dynamic>.from(MyHttp.result['body']));
    }else{
      return MyHttp.result['body'];
    }
  }

  ///
  Future<String> getDataFixed(String folder) async {

    String uri = '';
    MyHttp.clean();

    if(folder == 'cargos') { uri = 'get_cargos'; }
    if(folder == 'roles') { uri = 'get_roles'; }
    if(folder == 'rutas') { uri = 'get_all_rutas'; }
    if(folder == 'autos') { uri = 'get_autos'; }
    if(folder == 'centinela') { uri = 'get_centinela'; }

    Uri url = await GetPaths.getUriApiHarbi(uri, '');
    if(url.host.isNotEmpty) {

      await MyHttp.getHarbi(url);
      if(!MyHttp.result['abort']) {
        await GetPaths.setDataFixed(folder, MyHttp.result['body']);
        return 'ok';
      }else{
        return MyHttp.result['body'];
      }
    }

    return 'ERROR, Comunicate con Sistemas';
  }

  ///
  Future<bool> hacerLoginFromServer(Map<String, dynamic> data) async {

    String domi = await GetPaths.getDominio(isLocal: false);

    final isToken = await MyHttp.makeLogin(domi, data);
    if(isToken.isNotEmpty) {
      final existe = await GetContentFile.hidratarUserFromFile(data);
      globals.user.tkServ = isToken;
      if(existe) { return true; }
      final isOk = await getDataUserByCampo(data['username']);
      if(isOk) {
        globals.user.curc = data['username'];
        globals.user.password = data['password'];
        return true;
      }
    }
    return false;
  }

  ///
  Future<bool> getDataUserByCampo(String curc) async {

    String domi = await GetPaths.getUri('get_user_by_campo', isLocal: false);
    await MyHttp.get('$domi?campo=curc&valor=$curc');
    if(!MyHttp.result['abort']) {

      final data = Map<String, dynamic>.from(MyHttp.result['body']);
      globals.user.roles = List<String>.from(data['roles']);
      globals.user.id = data['id'];
      globals.user.nombre = data['nombre'];
      return true;
    }
    return false;
  }

  ///
  Future<String> makeRegistroUserToHarbi() async {

    const String txtC = 'Bienvenido al Sistema de Cotización y Procesamiento';

    if(!makeRegToHarbi) {
      Uri uri = await GetPaths.getUriApiHarbi('set_conection', '');
      final data = globals.user.userConectado(
        app: _app, idCon: '$idConn', ip: globals.myIp
      );
      await MyHttp.postHarbi(uri, data);
      if(!MyHttp.result['abort']) {
        makeRegToHarbi = true;
        return txtC;
      }
      return '[X] Error al registrar tu conexión en HARBI';
    }else{
      return txtC;
    }
  }


}
