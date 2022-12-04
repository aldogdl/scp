import 'dart:convert';
import 'package:cron/cron.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
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
import '../services/push_in/gest_push_in.dart';
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

  /// Usado para notificar en el status bar un cambio de version del centinela
  String _alertCV = '0';
  String get alertCV => _alertCV;
  set alertCV(String show) {
    _alertCV = show;
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
  void cerrarConection() async {
    idConn = 0;
    isConnectedSocked = false;
    globals.user = ContactoEntity();
    globals.user.nombre = 'Anónimo';
    await close();
    await _cronConn.close();
    await Future.delayed(const Duration(milliseconds: 150));
    isMyConn = 0;
  }

  ///
  Future<void> close() async {
    if (_socket != null) {
      await _socket!.sink.close(status.normalClosure);
      await _socket!.innerWebSocket!.close();
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
    idConn = 0;
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
      return false;
    }

    Future.microtask(() {
      isMyConn = 3;
      sendPingAquiToy();
    });
    return true;
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
    try {
      _socket!.stream.listen((event) {
        pin = 'ok';
        isConnectedSocked = true;
        _determinarEvento(Map<String, dynamic>.from(json.decode(event)));
      }).onError((_){
        isMyConn = 0;
      });
    } catch (_) { }
  }

  ///
  Future<void> _determinarEvento(Map<String, dynamic> response) async {

    if (response.containsKey('connId')) {
      idConn = response['connId'];
      return;
    }

    if (response.containsKey('event')) {
      
      // todo tipo de notificaciones push desde harbi.
      if (response['event'] == 'harbi_push') {
        if(response['fnc'] == 'pushall') {
          await _makeAcc(
            response['fnc'],
            Map<String, dynamic>.from(response['data'])
          );
        }
        return;
      }

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
      case 'reping':
        isMyConn = 3;
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

        }
        break;
      default:
        _msgErr = 'Sin Acción';
    }
  }

  /// Recuperamos la Ip de Harbi, pero siempre tiene que ser desde el servidor
  /// remoto, ya que no sabemos desde que maquina se esta corriendo este SCP.
  Future<String> getIpToHarbiFromServer() async {

    String msg = 'Comunicate con Sistemas';

    String url = 'https://autoparnet.com';    
    if(globals.env == 'dev') {
      url = 'http://localhost/autoparnet/public_html';
    }
    url = '$url/home-controller/get-data-connection/2536H/';

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

      if(tipoR.toString().contains('Map')) {

        final c = Map<String, dynamic>.from(MyHttp.result['body']);
        globals.mySwh = '';
        List<Map<String, dynamic>> ops = [];
        c.forEach((key, value) async {
          ops.add({'clv': key, 'con': utf8.decode(base64Decode(value))});
        });

        for (var i = 0; i < ops.length; i++) {

          msg = 'ERROR desconocido, ${ops[i]['con']}';
          if(ops[i]['con'].contains(':')) {
            final partes = List<String>.from(ops[i]['con'].split(':'));
            globals.ipHarbi = partes.first;
            globals.portHarbi = partes.last;
            final response = await probandoConnWithHarbi();
            
            if(!response.contains('ERROR')){
              globals.mySwh = ops[i]['clv'];
              msg = 'Datos de conexión recuperados';
              break;
            }else{
              globals.ipHarbi = '';
              globals.portHarbi = '';
              globals.mySwh = '';
            }
          }
        }
      }
    }

    return msg;
  }

  /// Recuperamos la Ip de Harbi, de manera local.
  Future<String> getIpToHarbiFromLocal() async {

    final ipCode = GetContentFile.ipConectionLocal();
    final ipH = utf8.decode(base64Decode(ipCode));
    if(ipH.contains(':')) {
      final partes = List<String>.from(ipH.split(':'));
      globals.ipHarbi = partes.first;
      globals.portHarbi = partes.last;
      final response = await probandoConnWithHarbi();
      if(!response.contains('ERROR')){
        globals.mySwh = ipCode;
        return 'Datos de conexión recuperados';
      }else{
        globals.ipHarbi = '';
        globals.portHarbi = '';
        globals.mySwh = '';
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

    final url = await GetPaths.getUriApiHarbi(uri, '');
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
  Future<String> getCotizadores() async {

    MyHttp.clean();

    late Uri url;
    String query = 'p0';
    for (var i = 0; i < 50; i++) {
      url = await GetPaths.getUriApiHarbi('get_cotz_by_id', query);
      if(url.host.isNotEmpty) {
        query = '';
        await MyHttp.getHarbi(url);
        if(!MyHttp.result['abort']) {
          final cotz = Map<String, dynamic>.from(MyHttp.result['body']);
          if(cotz.isNotEmpty) {
            GetPaths.setFileCotzFromHarbi({
              'cotz':cotz['cotz'], 'filtros': cotz['filtros']
            });
            query = 'p${cotz['page']}';
          }else{
            break;
          }
        }
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


  /// ----------------------NOTIFICACIONES --------------------------------
  
  int cantAlert = 0;

  ///
  List<String> lostProcess = [];
  List<String> inProcess = [];
  Map<String, String> allNotif = {
    'all': '0', 'bandeja': '0', 'pap': '0', 'alta': '0', 'media': '0', 'baja': '0'
  };

  /// Cada ves que cambie todo lo relacionada a las notificaciones cambiara
  int _refreshNotiff = 0;
  int get refreshNotiff => _refreshNotiff;
  set refreshNotiff(int show) {
    _refreshNotiff = show;
    cantAlert++;
    notifyListeners();
  }
  /// Cada ves que la notificacion indique trabajar con baja prioridad
  String _backgroundProcess = '';
  String get backgroundProcess => _backgroundProcess;
  set backgroundProcess(String show) {
    _backgroundProcess = show;
    notifyListeners();
  }
  String _lastCentinelFile = '';
  
  /// Lista de ids de las ordenes que su IRIS fue actualizado
  List<int> idsOrdsIris = [];
  /// Usado para actualizar a todos los escuchas del IRIS
  int _irisUpdate = -1;
  int get irisUpdate => _irisUpdate;
  set irisUpdate(int show) {
    _irisUpdate = show;
    notifyListeners();
  }

  ///
  Future<void> _makeAcc(String fnc, Map<String, dynamic> params) async {

    switch (fnc) {

      case 'pushall':
        
        // Inicializamos la clase para el manejo de notificaciones
        GestPushIn? pushIn = GestPushIn(socket: this, user: globals.user);

        final receiverFiles = List<String>.from(params['files'].split(','));
        if(receiverFiles.isEmpty) { return; }

        // Revisamos si entre los archivos recibidos tenemos una actualizacion
        // del centinela file, si es asi, vemos que no sea la misma que ya procesamos.
        int indx = receiverFiles.indexWhere(
          (element) => element.startsWith('centinela_update')
        );
        if(indx != -1) {
          String updateC = '';
          final partes = receiverFiles[indx].split('-');
          int iSuf = pushIn.sufixFiles().indexWhere(
            (element) => element == partes.last
          );
          if(iSuf != -1) {
            partes.last = '.json';
          }
          updateC = partes.join('-');
          if(_lastCentinelFile == updateC) {
            receiverFiles.removeAt(indx);
          }else{
            _lastCentinelFile = updateC;
          }
        }
        
        // Antes que nada, primero revisamos si la notificacion trae algo para
        // el usuario de esta SCP, de lo contrario desechamos la notificacion.
        final forGet = pushIn.isForMy(receiverFiles);
        
        // Si hay algo para este usuario de la SCP, lo procesamos.
        pushIn.getRecents(forGet).then((response) {

          if(response.isNotEmpty) {
            // Si los archivos buscados en harbi no se encontraron en la
            // carpeta recientes, se colocan como archivos bacios en la
            // carpeta de lost.
            if(response['lost'].isNotEmpty) {
              lostProcess.addAll(List<String>.from(response['lost']));
            }
            _procesarFilesPush(pushIn!);
          }
          pushIn = null;
        });
        break;
      default:
    }
  }

  /// Revisamos cada ves que se inicia la app from widgets\invirt\querys_process.dart
  Future<void> chechNotiffCurrents() async {

    GestPushIn? pushIn = GestPushIn(socket: this, user: globals.user);
    // Revisar notificaciones perdidas desde harbi.
    _recoveryNotiffLostFromHarbi().then((forGet){

      if(forGet.isNotEmpty) {

        pushIn!.getLost(forGet).then((response) {

          if(response.isNotEmpty) {
            // Si los archivos buscados en harbi no se encontraron en la
            // carpeta recientes, se colocan como archivos bacios en la
            // carpeta de lost.
            if(response['lost'].isNotEmpty) {
              lostProcess.addAll(List<String>.from(response['lost']));
            }
            _procesarFilesPush(pushIn!);
          }
          pushIn = null;
        });
      }
    });
  }

  ///
  void _procesarFilesPush(GestPushIn pushIn) {

    pushIn.categorizar();
    allNotif = pushIn.cuantificar(allNotif);
    int? cant = int.tryParse(allNotif['all']!);
    if(cant != null) {

      bool hasBaja = false;
      bool hasAlta = false;

      if(allNotif['baja'] != '0') {
        // Todas las notificaciones de baja prioridad deben procesarce
        // en background y no son intrusivos.
        int? cantB = int.tryParse(allNotif['baja']!);
        if(cantB != null) {
          cant = cant - cantB;
        }
        hasBaja = true;
      }

      if(allNotif['alta'] != '0') {
        // Todas las notificaciones de alta prioridad deben ser intrusivos
        int? cantA = int.tryParse(allNotif['baja']!);
        if(cantA != null) {
          hasAlta = true;
        }
      }

      if(hasAlta) {
        // Forzamos un cambio en los escuchas del refresnNotiff.
        // lib\src\consola.dart:
        //  a) La pestaña de notificaciones
        //  b) La consola de notificaciones
        refreshNotiff = (refreshNotiff != cant) ? cant : (refreshNotiff + 1);
      }

      // Procesamos notificaciones de baja prioridad
      if(hasBaja) {
        _procesarFilesPushInBG(pushIn);
      }
    }
  }

  ///
  void _procesarFilesPushInBG(GestPushIn pushIn) {

    backgroundProcess = '<BG>';

    pushIn.processBackground().listen((event) {

      if(event.startsWith('Versionando')) {
        final partes = event.split(':');
        updateVersionCentinelaFile(partes.last.trim());
      }
      
      if(event.startsWith('Asignaci')) {

        int? a = int.tryParse(allNotif['all']!);
        int? c = int.tryParse(allNotif['alta']!);
        if(c != null && a != null) {
          final cant = a + 1;
          allNotif['all'] = '$cant';
          allNotif['alta'] = '${c + 1}';
          refreshNotiff = (refreshNotiff != cant) ? cant : (refreshNotiff + 1);
        }
      }

      if(event.contains('Métricas')) {
        // No se hace nada, ya que es la actualizacion no intrusiva.
      }

      if(event.contains('IRIS')) {
        idsOrdsIris = pushIn.idsOrdsChanged;
        irisUpdate = irisUpdate +1;
      }

      if(event == 'Listo...') {
        backgroundProcess = '<BG>';
        return;
      }

      backgroundProcess = event;
    }).onError((_){
      debugPrint('error en el SocketConn, Stream de push de baja');
    });
  }

  ///
  Future<List<String>> _recoveryNotiffLostFromHarbi() async {

    List<String> filesType = ['${globals.user.id}', 'centinela_update'];
    if(globals.user.roles.contains('ROLE_ADMIN')) {
      filesType.add('admin');
    }

    MyHttp.clean();
    final uri = await GetPaths.getPathToApiHarbi('push');
    if(!uri.contains('null')) {
      try {
        await MyHttp.getHarbi(Uri.parse('http://$uri/lost%${filesType.join(',')}-getnames'));
      } catch (_) {}
    }

    List<String> filesLost = [];
    if(!MyHttp.result['abort'] && MyHttp.result['msg'] == 'ok.') {
      
      final resp = MyHttp.result['body'];
      if(resp.runtimeType == String) {
        final content = Map<String, dynamic>.from(json.decode(resp));
        if(content.containsKey('files')) {

          filesLost = List<String>.from(content['files']);
          if(filesLost.isNotEmpty) {
            GestPushIn? pushIn = GestPushIn(socket: this, user: globals.user);
            pushIn.setFilesLost(filesLost);
          }
        }
      }
    }

    return filesLost;
  }

  ///
  void updateVersionCentinelaFile(String ver) async {

    if(verOldCentinela.isEmpty) { verOldCentinela = '0'; }

    if(ver != verOldCentinela) {
      verOldCentinela = ver;
      globals.currentVersion = verOldCentinela;
    }
    alertCV = globals.currentVersion;
  }

  ///
  Future<void> cleanAllNotiff() async {

    GestPushIn? pushIn = GestPushIn(socket: this, user: globals.user);
    allNotif = pushIn.cleanAll(allNotif);
    int? cant = int.tryParse(allNotif['all']!);
    if(cant != null) {
      refreshNotiff = (refreshNotiff == cant) ? cant : (refreshNotiff + 1);
    }
  }

  /// ---------------------- FIN NOTIFICACIONES -----------------------------
  
  /// -------------------- CRON DE CONECCION PING ---------------------------
  
  Cron _cronConn = Cron();
  // 0 no conectado, 1 buscando coneccion, 2 en espera de respuesta, 3 conectado, 
  // 4 reconectando, 5 conección manual.
  int _isMyConn = 0;
  int get isMyConn => _isMyConn;
  set isMyConn(int myC) {
    _isMyConn = myC;
    notifyListeners();
  }
  
  ///
  void sendPingAquiToy() async {

    try {
      _cronConn.schedule(Schedule.parse('*/5 * * * * *'), () async {
        _goCheckConectMyWhitHarbi();
      });
    } catch (e) {

      if(idConn != 0) {
        if(e.toString().contains('Close')) {
          _cronConn = Cron();
          await Future.delayed(const Duration(milliseconds: 500));
          sendPingAquiToy();
        }else{
          isMyConn = 0;
        }
      }
    }
  }

  ///
  Future<void> _goCheckConectMyWhitHarbi() async {

    isMyConn = 1;
    if(idConn == 0){ return; }
    
    await Future.delayed(const Duration(milliseconds: 150));
    send(RequestEvent(event: 'ping', fnc: 'reping', data: {
      'avo': globals.user.id
    }));
    isMyConn = 2;
    await Future.delayed(const Duration(milliseconds: 3500));
    
    if(_isMyConn < 3) {

      await _cronConn.close();
      isMyConn = 4;
      if(idConn != 0) {
        // Necesitamos reconectar
        bool res = await makeFirstConnection();
        if(!res) {
          isMyConn = 5;
        }else{
          await chechNotiffCurrents();
        }
      }
    }
  }

  /// ------------------- FIN CRON DE CONECCION PING ------------------------
}
