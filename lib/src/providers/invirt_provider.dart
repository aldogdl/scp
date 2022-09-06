import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../services/inventario_service.dart';

class InvirtProvider extends ChangeNotifier {

  ///
  void cleanVars() {

    _cmd = {};
    _cotsAlmacen    = [];
    _pzaResults     = [];    
    _trigger        = [];
    _triggerResp    = [];
    
    Future.microtask((){
      rebuildLstAlmacen = !rebuildLstAlmacen;
      setCostosSel({});
      queSelected = [];
    });
  }

  // Trampas para refrescar la sección 0, ya que no refresca correcto cuando
  // se envia varias veces el mismo comando.
  String _trampRfs0 = 'o';

  /// La lista de cronos
  Map<int, dynamic> cronos = {};

  /// Los cosotos que han sido seleccionados para la zona financiera
  bool _recalcular = false;
  bool get recalcular => _recalcular;
  set recalcular(bool rc) {
    _recalcular = rc;
    Future.microtask(() => notifyListeners());
  }
  /// Los cosotos que han sido seleccionados para la zona financiera
  Map<int, dynamic> _costosSel = {};
  Map<int, dynamic> get costosSel => _costosSel;
  set costosSel(Map<int, dynamic> val){
    _costosSel = val;
    Future.microtask(() => recalcular = !recalcular);
  }
  void setCostosSel(Map<String, dynamic> cost) {

    var costosSelT = Map<int, dynamic>.from(_costosSel);
    _costosSel.clear();
    if(cost.isEmpty) {
      costosSelT = {};
    }else{
      costosSelT[cost['p_id']] = cost['costo'];
    }
    _costosSel = costosSelT;
    notifyListeners();
    Future.microtask(() => recalcular = !recalcular);
  }

  ///
  List<Map<String, dynamic>> sortCotsByPrice(List<Map<String, dynamic>> rsp)
    => InventarioService.sortCotsByPrice(rsp);

  ///
  List<Map<String, dynamic>> sortCotsByPriceMinToMax(List<Map<String, dynamic>> rsp)
    => InventarioService.sortCotsByPriceMinToMax(rsp);

  /// Usado para el almacen virtual, switchear entre distintas vistas
  String typeViewLst = 'table';

  ///
  bool _rebuildLstAlmacen = false;
  bool get rebuildLstAlmacen => _rebuildLstAlmacen;
  set rebuildLstAlmacen(bool ref) {
    _rebuildLstAlmacen = ref;
    notifyListeners();
  }

  /// Lista de cotizaciones en el almacen
  List<Map<String, dynamic>> _cotsAlmacen = [];
  List<Map<String, dynamic>> get cotsAlmacen => _cotsAlmacen;
  set cotsAlmacen(List<Map<String, dynamic>> cots) {
    _cotsAlmacen = cots;
    notifyListeners();
  }
  
  ///
  Map<String, dynamic> _cmd = {};
  Map<String, dynamic> get cmd => _cmd;
  set cmd(Map<String, dynamic> c) {
    
    if(c.isEmpty){
      _cmd = {};
      Future.microtask(() => notifyListeners());
      return;
    }

    // Evaluamos si el comando es CC.
    if(c['cmd'].startsWith('cc')) {
      cleanVars();
      c = {'cmd':'trfs.1'};
    }

    final cmdProcess = InventarioService.spell(c['cmd']);
    if(cmdProcess.isEmpty || cmdProcess.containsKey('err')) { return; }

    // Revisamos trampas para el comando de refresh
    if(cmdProcess['clv'] == 'rfs') {
      if(cmdProcess['eval'] == '0' || cmdProcess['eval'] == 'o') {
        cmdProcess['eval'] = (_trampRfs0 == '0') ? 'o' : '0';
        _trampRfs0 = cmdProcess['eval'];
      }
    }
    
    _cmd.clear();
    if(cmdProcess.isNotEmpty) {
      _cmd = cmdProcess;
      notifyListeners();
    }

  }

  ///
  Map<String, dynamic> speelCmd(String c) => InventarioService.spell(c);

  /// Guardamos los datos de que orden y pieza esta seleccionada actualmente.
  List<String> _queSelected = [];
  List<String> get queSelected => _queSelected;
  set queSelected(List<String> qs) {

    List<String> x = [];
    if(qs.isEmpty) {
      _queSelected = [];
      notifyListeners();
      return;
    }

    for (var i = 0; i < qs.length; i++) {
      if(qs[i].length > 1 && qs[i].isNotEmpty) {
        if(!x.contains(qs[i])) {
          x.add(qs[i]);
        }
      }
    }
    
    _queSelected.clear();
    _queSelected = List<String>.from(x);
    notifyListeners();
  }

  ///
  Map<String, dynamic> _cmdErr = {};
  Map<String, dynamic> get cmdErr => _cmdErr;
  set cmdErr(Map<String, dynamic> err) {
    _cmdErr = err;
    notifyListeners();
  }

  /// ------------------------------------------------------------------------
  
  /// La lista de las piezas resultantes de los filtros ingresados.
  List<Map<String, dynamic>> _pzaResults = [];
  List<Map<String, dynamic>> get pzaResults => _pzaResults;
  set pzaResults(List<Map<String, dynamic>> pzas) {
    _pzaResults = pzas;
    notifyListeners();
  }

  /// Usada en la pagina query_process, para saber que orden es la que necesita
  /// reconstruirce cuando una query es procesada.
  int idOrdenAfectada = 0;

  /// La cantidad de ordenes en la Bandeja de entrada
  bool _showBtnCC = false;
  bool get showBtnCC => _showBtnCC;
  set showBtnCC(bool nv) {
    _showBtnCC = nv;
    notifyListeners();
  }

  /// El quiery que se esta procesando actualmente
  String query = '';
  /// La lista de querys a procesar
  List<String> _querys = [];
  List<String> get querys => _querys;
  set querys(List<String> nlist) {
    _querys = nlist;
    notifyListeners();
  }
  ///
  void addQuerys(String nlist) async {

    var tmp = List<String>.from(_querys);
    _querys.clear();
    tmp.add(nlist);
    querys = List<String>.from(tmp);
    query = nlist;
    tmp = [];
  }

  /// El diparador para actualizar las metricas.
  List<int> _trigger = [];
  List<int> get trigger => _trigger;
  set trigger(List<int> ordenes) {
    _trigger = ordenes;
    notifyListeners();
  }
  ///
  void addTrigger(int orden) {

    var tmp = List<int>.from(_trigger);
    _trigger.clear();
    tmp.add(orden);
    trigger = List<int>.from(tmp);
    tmp = [];
  }

  /// El diparador para actualizar las Respuestas, los IDs de las ordenes que
  /// cuentan con nuevas respuestas
  List<int> _triggerResp = [];
  List<int> get triggerResp => _triggerResp;
  set triggerResp(List<int> ordenes) {
    _triggerResp = ordenes;
    notifyListeners();
  }
  ///
  void addTriggerResp(int orden) {

    var tmp = List<int>.from(_triggerResp);
    _triggerResp.clear();
    tmp.add(orden);
    triggerResp = List<int>.from(tmp);
    tmp = [];
  }

  /// La cantidad de ordenes en la Bandeja de entrada
  String _cantOrdBanEnt = '';
  String get cantOrdBanEnt => _cantOrdBanEnt;
  set cantOrdBanEnt(String num) {
    _cantOrdBanEnt = num;
    notifyListeners();
  }

  /// La lista de los nombres de los archivos
  /// de las ordenes locales en bandeja de entrada
  List<String> _ordInvBEFiles = [];
  List<String> get ordInvBEFiles => _ordInvBEFiles;
  void cleanOrdInvBEFiles() => _ordInvBEFiles.clear();
  set ordInvBEFiles(List<String> nlist) {
    _ordInvBEFiles = nlist;
    notifyListeners();
  }


}