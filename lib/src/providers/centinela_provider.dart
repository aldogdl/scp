import 'package:flutter/foundation.dart' show ChangeNotifier;

class CentinelaProvider extends ChangeNotifier{

  int idOrdenCurrent = 0;
  Map<String, dynamic> data = {};

  /// Pestaña seleccionada para las diferentes Secciones
  List<Map<String, String>> pestanias = [
    {'slug':'dashboard', 'tit': 'DashBoard'},
    {'slug':'report', 'tit': 'Comportamiento'},
  ];
  int _pestania = 0;
  int get pestania => _pestania;
  set pestania(int cz) {
    _pestania = cz;
    notifyListeners();
  }

  /// Usada para saber si es necesario refrescar la lista de cotizadores en el
  /// dashboard, o mostrar la lista anterior para que no se vea un brinco en diseño
  bool isUpdateCots = false;

  /// Refrescamos la seccion de metricas.
  bool _refreshSeccMetrix = false;
  bool get refreshSeccMetrix => _refreshSeccMetrix;
  set refreshSeccMetrix(bool cz) {
    _refreshSeccMetrix = cz;
    notifyListeners();
  }

  /// Lista de cotizadores a los que se les envio esta orden.
  Map<String, double> _dataChartProv = {};
  Map<String, double> get dataChartProv => _dataChartProv;
  cleanDataChartProv() => _dataChartProv.clear();
  set dataChartProv(Map<String, double> cz) {
    _dataChartProv = cz;
    notifyListeners();
  }

  /// Lista de cotizadores a los que se les envio esta orden.
  List<Map<String, dynamic>> resps = [];

  /// Lista de cotizadores a los que se les envio esta orden.
  List<Map<String, dynamic>> _cotz = [];
  List<Map<String, dynamic>> get cotz => _cotz;
  set cotz(List<Map<String, dynamic>> cz) {
    _cotz = cz;
    notifyListeners();
  }
  void forceRefreshCotz() {
    final tmp = List<Map<String, dynamic>>.from(_cotz);
    _cotz.clear();
    tmp.add({'refresh':'force'});
    cotz = List<Map<String, dynamic>>.from(tmp);
    tmp.clear();
  }

  /// Revisamos para ver si la orden esta marcada vista por parte del
  /// cotizador enviado por parametro.
  /// [RETURN] En caso de exito, retornamos de donde se realizo la accion
  Map<String, dynamic> isSee(int indexCotz, String idO, Map<String, dynamic> iris) {

    final idC = cotz[indexCotz]['c_id'];
    
    if(iris.containsKey('see')) {
      if(iris['see'].containsKey('$idC')) {
        final mi = List<Map<String, dynamic>>.from(iris['see']['$idC']);
        final prefix = '$idO$idC${iris['avo']}';
        final where = mi.last['id'].replaceAll(prefix, '').toString().trim();
        mi.last['clv'] = getWhere(where);
        return mi.last;
      }
    }

    Map<String, dynamic> res = {};
    iris.forEach((clv, value) {
      
      if(clv != 'avo' && clv != 'version') {
        if(value.isNotEmpty) {
          final v = Map<String, dynamic>.from(value);
          if(v.containsKey('$idC')) {
            res = {'clv': 'home'};
            return;
          }
        }
      }
    });

    return res;
  }

  /// Revisamos para ver si la pieza cuenta con una respuesta por parte del
  /// cotizador enviado por parametro.
  /// [RETURN] En caso de exito, retornamos el contenido de iris
  Future<Map<String, dynamic>> hasRsp(String idC, String idPza, String idO, Map<String, dynamic> iris) async {

    if(iris.containsKey('rsp')) {
      if(iris['rsp'].containsKey(idPza)) {

        final mi = List<Map<String, dynamic>>.from(iris['rsp'][idPza]);
        final has = mi.where((p) => '${p['idCot']}' == idC);
        if(has.isNotEmpty) {
          return Map<String, dynamic>.from(has.first);
        }
      }
    }

    return {};
  }

  /// Revisamos para ver si la pieza esta marcada como No tengo por parte del
  /// cotizador enviado por parametro.
  /// [RETURN] En caso de exito, retornamos de donde se realizo la accion
  Future<Map<String, dynamic>> isNtg(String idC, String idPza, String idO, Map<String, dynamic> iris) async {

    if(iris.containsKey('ntg')) {
      if(iris['ntg'].containsKey(idC)) {
        final mi = List<Map<String, dynamic>>.from(iris['ntg'][idC]);
        final has = mi.where((p) => '${p['idPieza']}' == idPza);
        if(has.isNotEmpty) {
          final prefix = '$idO$idC${iris['avo']}';
          final where = has.last['id'].replaceAll(prefix, '').toString().trim();
          has.last['clv'] = getWhere(where);
          return has.last;
        }
      }
    }

    return {};
  }

  /// Revisamos para ver si la pieza esta marcada como Apartada por parte del
  /// cotizador enviado por parametro.
  /// [RETURN] En caso de exito, retornamos de donde se realizo la accion
  Future<Map<String, dynamic>> isApr(String idC, String idPza, String idO, Map<String, dynamic> iris) async {

    if(iris.containsKey('apr')) {
      if(iris['apr'].containsKey(idC)) {
        final mi = List<Map<String, dynamic>>.from(iris['apr'][idC]);
        final has = mi.where((p) => p['idPieza'] == idPza);
        if(has.isNotEmpty) {
          final prefix = '$idO$idC${iris['avo']}';
          final where = has.last['id'].replaceAll(prefix, '').toString().trim();
          has.last['clv'] = where;
          return has.last;
        }
      }
    }

    return {};
  }

  ///
  String getWhere(String clv) {

    final lug = <String, String>{
       'apr': 'APARTADA', 'seh': 'HOME', 'sel': 'LINK', 'seca': 'CARNADA',
       'ntca': 'CARNADA', 'nth': 'HOME'
    };
    return (lug.containsKey(clv)) ? lug[clv]! : 'X';
  }

  /// posible borrar
  /// Lista de tareas que se estan presentando en la consola
  List<String> _tConsole = [];
  List<String> get tConsole => _tConsole;
  set tConsole(List<String> cz) {
    _tConsole = cz;
    notifyListeners();
  }
  void addConsole(String task) {

    var tmp = List<String>.from(_tConsole);
    if(tmp.length > 50) {
      tmp = [];
    } 
    _tConsole.clear();
    tmp.add(task);
    tConsole = List<String>.from(tmp);
    tmp = [];
  }
  
  /// Posible borrar
  void buildChartProv() {
    double atendidas = 0;
    double ignoradas = 0;
    double total = double.parse('${cotz.length}');

    for (var i = 0; i < cotz.length; i++) {
      if(cotz[i]['stt_clv'] == 'i') {
        ignoradas++;
      }
      if(cotz[i]['stt_clv'] == 'a') {
        atendidas++;
      }
    }
    dataChartProv = {
      'total': total,
      'Atendidas': atendidas,
      'Ignoradas': ignoradas,
    };
  }
}