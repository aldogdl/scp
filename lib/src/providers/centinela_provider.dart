import 'package:flutter/foundation.dart' show ChangeNotifier;

class CentinelaProvider extends ChangeNotifier{

  int idOrdenCurrent = 0;
  Map<String, dynamic> data = {};

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
  Map<String, dynamic> noTengo = {};
  /// Lista de cotizadores a los que se les envio esta orden.
  List<Map<String, dynamic>> resps = [];

  /// Lista de cotizadores a los que se les envio esta orden.
  List<Map<String, dynamic>> _cotz = [];
  List<Map<String, dynamic>> get cotz => _cotz;
  set cotz(List<Map<String, dynamic>> cz) {
    _cotz = cz;
    notifyListeners();
  }

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
  
  ///
  String extraerOfData(String que) {

    if(data.containsKey('metrik')) {
      if(data['metrik'].containsKey('cotz')) {
        final partes = List<String>.from(data['metrik']['cotz'].split('|'));
        String parte = '';
        switch (que) {
          case 'enviados':
            parte = partes.firstWhere((e) => e.trim().startsWith('E'), orElse: () => 'N/E');
            if(parte != 'N/E') {
              return parte.replaceAll('E:', '').trim();
            }
            break;
          case 'pape':
            parte = partes.firstWhere((e) => e.trim().startsWith('P'), orElse: () => 'N/E');
            if(parte != 'N/E') {
              return parte.replaceAll('P:', '').trim();
            }
            break;
          case 'cotz':
            parte = partes.firstWhere((e) => e.trim().startsWith('T'), orElse: () => 'N/E');
            if(parte != 'N/E') {
              return parte.replaceAll('T:', '').trim();
            }
            break;
          default:
        }
      }
    }
    return 'N/E';
  }

  ///
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