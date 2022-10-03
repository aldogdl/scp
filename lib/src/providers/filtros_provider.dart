import 'package:flutter/foundation.dart' show ChangeNotifier;

class FiltrosProvider extends ChangeNotifier {

  ///
  void myDispose() {

    autos = [];
    _marca = {'nombre':'0'};
    _modelo = {'nombre':'0'};
    _aniosD = '0';
    _aniosH = '0';
    _pieza = {'value':'0'};
  }

  /// Todos los autos
  List<Map<String, dynamic>> autos = [];

  ///
  String getMarcaById(Map<String, dynamic> filtroServer) {

    if(filtroServer.containsKey('mk_id')) {
      final has = autos.firstWhere(
        (element) => element['id'] == filtroServer['mk_id'], orElse: () => {}
      );
      if(has.isNotEmpty) {
        return has['nombre'];
      }
    }
    return '0';
  }

  ///
  String getModeloById(Map<String, dynamic> filtroServer) {

    if(filtroServer.containsKey('mk_id')) {
      var has = autos.firstWhere(
        (element) => element['id'] == filtroServer['mk_id'], orElse: () => {}
      );
      if(has.isNotEmpty) {
        has = has['modelos'].firstWhere(
          (element) => element['id'] == filtroServer['md_id'], orElse: () => {}
        );
        if(has.isNotEmpty) {
          return has['nombre'];
        }
      }
    }
    return '0';
  }

  ///
  String getTileGroup(Map<String, dynamic> filtroServer) {

    String t = 'DESCONOCIDO';
    if(filtroServer.containsKey('f_grupo')) {

      final List<String> partes = filtroServer['f_grupo'].split(',');
      if(partes.contains('D')) {
        partes.remove('D');
        t = '[${partes.join('')}]-[D] SÓLO MANEJA ESTA:';
      }
      if(partes.contains('E')) {
        partes.remove('E');
        t = '[${partes.join('')}]-[E] MANEJA TODAS EXCEPTO ESTA:';
      }
    }
    return t;
  }

  ///
  void fechMarca() {

    for (var i = 0; i < autos.length; i++) {
      final lsMd = List<Map<String, dynamic>>.from(autos[i]['modelos']);
      final has = lsMd.where((element) => element['id'] == modelo['id']);
      if(has.isNotEmpty){
        marca = Map<String, dynamic>.from(autos[i]);
        marca.remove('modelos');
        break;
      }
    }
  }

  /// Refrescamos la lista de modelos
  bool _refresMdls = false;
  bool get refresMdls => _refresMdls;
  set refresMdls(bool mrk) {
    _refresMdls = mrk;
    notifyListeners();
  }

  /// La marca seleccionada
  Map<String, dynamic> _marca = {'nombre':'0'};
  Map<String, dynamic> get marca => _marca;
  set marca(Map<String, dynamic> mrk) {
    _marca = mrk;
    notifyListeners();
  }

  /// El modelo seleccionada
  Map<String, dynamic> _modelo = {'nombre':'0'};
  Map<String, dynamic> get modelo => _modelo;
  set modelo(Map<String, dynamic> mrk) {
    _modelo = mrk;
    notifyListeners();
  }

  /// Los Años seleccionada
  String _aniosD = '0';
  String get aniosD => _aniosD;
  set aniosD(String mrk) {
    _aniosD = mrk;
    notifyListeners();
  }

  /// Los Años seleccionada
  String _aniosH = '0';
  String get aniosH => _aniosH;
  set aniosH(String mrk) {
    _aniosH = mrk;
    notifyListeners();
  }

  /// La pieza seleccionada
  Map<String, dynamic> _pieza = {'value':'0'};
  Map<String, dynamic> get pieza => _pieza;
  set pieza(Map<String, dynamic> mrk) {
    _pieza = mrk;
    notifyListeners();
  }

  /// Una restricción Solo manejo esta
  bool _soloEsta = true;
  bool get soloEsta => _soloEsta;
  set soloEsta(bool mrk) {
    _soloEsta = mrk;
    notifyListeners();
  }

  /// Una exepción: Todas excepto esta
  bool _excEsta = false;
  bool get excEsta => _excEsta;
  set excEsta(bool mrk) {
    _excEsta = mrk;
    notifyListeners();
  }
  
  /// Solo maneja multimarcas
  bool _multimrk = true;
  bool get multimrk => _multimrk;
  set multimrk(bool mrk) {
    _multimrk = mrk;
    notifyListeners();
  }

  /// Solo maneja Alta gama
  bool _altaGam = false;
  bool get altaGam => _altaGam;
  set altaGam(bool mrk) {
    _altaGam = mrk;
    notifyListeners();
  }

  /// Solo maneja Autos comerciales
  bool _autoCom = false;
  bool get autoCom => _autoCom;
  set autoCom(bool mrk) {
    _autoCom = mrk;
    notifyListeners();
  }

  ///
  Map<String, dynamic> getDataForSave() {

    Map<String, dynamic> data = {};
    data['emp'] = 0;
    if(marca['nombre'] != '0') {
      data['marca'] = marca['id'];
    }
    if(modelo['nombre'] != '0') {
      data['modelo'] = modelo['id'];
    }
    if(aniosD != '0') {
      data['anioD'] = aniosD;
    }
    if(aniosH != '0') {
      data['anioH'] = aniosH;
    }
    if(pieza['value'] != '0') {
      data['pzaName'] = pieza['id'];
      data['pieza'] = pieza['value'];
    }
    List<String> grupo = [];
    if(altaGam) {
      grupo.add('A');
    }
    if(autoCom) {
      grupo.add('B');
    }
    if(multimrk) {
      grupo.add('C');
    }
    if(soloEsta) {
      grupo.add('D');
    }
    if(excEsta) {
      grupo.add('E');
    }
    data['grupo'] = grupo.join(',');
    return data;
  }
}